#!/usr/bin/env bash
#
# 上传 ConnectMate DMG 到 GitHub Release，并更新 Sparkle appcast.xml。
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_DMG_DIR="$PROJECT_DIR/build/dmg"
PBXPROJ="$PROJECT_DIR/ConnectMate.xcodeproj/project.pbxproj"
INFO_PLIST="$PROJECT_DIR/ConnectMate/Info.plist"
GITHUB_API_BASE="https://api.github.com"

DMG_PATH=""
REPO=""
TAG=""
TITLE=""
NOTES=""
NOTES_FILE=""
GENERATE_NOTES=false
DRAFT=false
PRERELEASE=false

usage() {
    cat <<'EOF'
用法:
  ./scripts/publish_release.sh [--dmg PATH] [--repo OWNER/REPO] [--tag TAG]
                               [--title TITLE] [--notes TEXT | --notes-file FILE | --generate-notes]
                               [--draft] [--prerelease]
EOF
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "错误: 未找到命令 $cmd" >&2
        exit 1
    fi
}

read_project_setting() {
    local key="$1"
    grep -m1 "$key" "$PBXPROJ" | sed "s/.*$key = \\([^;]*\\);/\\1/" | tr -d ' '
}

read_plist_string() {
    local key="$1"
    /usr/libexec/PlistBuddy -c "Print :$key" "$INFO_PLIST" 2>/dev/null || true
}

resolve_path() {
    local input_path="$1"
    local candidate="$input_path"

    if [[ ! "$candidate" = /* ]]; then
        if [[ -e "$candidate" ]]; then
            :
        elif [[ -e "$PROJECT_DIR/$candidate" ]]; then
            candidate="$PROJECT_DIR/$candidate"
        fi
    fi

    if [[ ! -e "$candidate" ]]; then
        echo ""
        return 0
    fi

    (
        cd "$(dirname "$candidate")"
        printf '%s/%s\n' "$(pwd)" "$(basename "$candidate")"
    )
}

extract_github_repo_from_url() {
    local remote_url="$1"

    if [[ "$remote_url" =~ ^https://github\.com/([^/]+)/([^/]+)(\.git)?/?$ ]]; then
        printf '%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return 0
    fi

    if [[ "$remote_url" =~ ^git@github\.com:([^/]+)/([^/]+)(\.git)?$ ]]; then
        printf '%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return 0
    fi

    if [[ "$remote_url" =~ ^ssh://git@github\.com/([^/]+)/([^/]+)(\.git)?$ ]]; then
        printf '%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return 0
    fi

    return 1
}

detect_repo() {
    local remote_url
    local repo_name

    remote_url="$(read_plist_string "ConnectMateGitHubURL")"
    if [[ -n "$remote_url" ]]; then
        if repo_name="$(extract_github_repo_from_url "$remote_url" 2>/dev/null)"; then
            printf '%s\n' "$repo_name"
            return 0
        fi
    fi

    if remote_url="$(git remote get-url origin 2>/dev/null)"; then
        if repo_name="$(extract_github_repo_from_url "$remote_url" 2>/dev/null)"; then
            printf '%s\n' "$repo_name"
            return 0
        fi
    fi

    while IFS=$'\t' read -r _remote_name candidate_url; do
        if repo_name="$(extract_github_repo_from_url "$candidate_url" 2>/dev/null)"; then
            printf '%s\n' "$repo_name"
            return 0
        fi
    done < <(git remote -v | awk '$3=="(push)" {print $1 "\t" $2}' | awk '!seen[$1]++')

    return 1
}

find_latest_dmg() {
    local latest_path=""
    local latest_mtime=0
    local file_path
    local file_mtime

    shopt -s nullglob
    for file_path in "$DEFAULT_DMG_DIR"/*.dmg; do
        [[ -f "$file_path" ]] || continue
        file_mtime="$(stat -f '%m' "$file_path")"
        if [[ -z "$latest_path" || "$file_mtime" -gt "$latest_mtime" ]]; then
            latest_path="$file_path"
            latest_mtime="$file_mtime"
        fi
    done
    shopt -u nullglob

    printf '%s\n' "$latest_path"
}

resolve_github_token() {
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        printf '%s\n' "$GITHUB_TOKEN"
        return 0
    fi

    if [[ -n "${GH_TOKEN:-}" ]]; then
        printf '%s\n' "$GH_TOKEN"
        return 0
    fi

    local credential_output
    local password

    credential_output="$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill 2>/dev/null || true)"
    password="$(printf '%s\n' "$credential_output" | sed -n 's/^password=//p' | head -1)"

    if [[ -n "$password" ]]; then
        printf '%s\n' "$password"
        return 0
    fi

    return 1
}

url_encode() {
    /usr/bin/python3 - "$1" <<'PY'
import sys
import urllib.parse

print(urllib.parse.quote(sys.argv[1], safe=""))
PY
}

json_get() {
    local path="$1"

    /usr/bin/python3 - "$path" <<'PY'
import json
import sys

path = [part for part in sys.argv[1].split(".") if part]
value = json.load(sys.stdin)

for part in path:
    if isinstance(value, dict):
        value = value.get(part)
    elif isinstance(value, list):
        try:
            index = int(part)
        except ValueError:
            value = None
            break
        value = value[index] if 0 <= index < len(value) else None
    else:
        value = None
        break

if value is None:
    raise SystemExit(1)

if isinstance(value, (dict, list)):
    print(json.dumps(value))
else:
    print(value)
PY
}

json_find_release_asset_id() {
    local asset_name="$1"

    /usr/bin/python3 - "$asset_name" <<'PY'
import json
import sys

asset_name = sys.argv[1]
assets = json.load(sys.stdin).get("assets") or []

for asset in assets:
    if asset.get("name") == asset_name:
        asset_id = asset.get("id")
        if asset_id is not None:
            print(asset_id)
        break
PY
}

github_api_request() {
    local method="$1"
    local url="$2"
    shift 2

    curl -fsSL \
        -X "$method" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_API_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "$@" \
        "$url"
}

github_create_release_payload() {
    local tag="$1"
    local title="$2"
    local draft="$3"
    local prerelease="$4"
    local generate_notes="$5"

    RELEASE_NOTES_CONTENT="${RELEASE_NOTES_CONTENT:-}" /usr/bin/python3 - "$tag" "$title" "$draft" "$prerelease" "$generate_notes" <<'PY'
import json
import os
import sys

tag, title, draft, prerelease, generate_notes = sys.argv[1:6]
payload = {
    "tag_name": tag,
    "name": title,
    "draft": draft == "true",
    "prerelease": prerelease == "true",
}

if generate_notes == "true":
    payload["generate_release_notes"] = True
else:
    payload["body"] = os.environ.get("RELEASE_NOTES_CONTENT", "")

print(json.dumps(payload))
PY
}

publish_with_github_api() {
    local dmg_name
    local release_json
    local release_id
    local release_url
    local release_body
    local asset_id
    local payload
    local upload_name
    local encoded_name
    local upload_url

    GITHUB_API_TOKEN="$(resolve_github_token)"
    if [[ -z "$GITHUB_API_TOKEN" ]]; then
        echo "错误: 未找到 GitHub 凭据，请设置 GITHUB_TOKEN 或确保 gh / git 已缓存 github.com 凭据" >&2
        exit 1
    fi

    dmg_name="$(basename "$DMG_PATH")"

    if release_json="$(github_api_request GET "$GITHUB_API_BASE/repos/$REPO/releases/tags/$TAG" 2>/dev/null)"; then
        echo "Release 已存在，上传并覆盖同名资源..."
    else
        echo "Release 不存在，正在创建..."

        if [[ "$GENERATE_NOTES" == true ]]; then
            RELEASE_NOTES_CONTENT=""
        elif [[ -n "$NOTES_FILE" ]]; then
            RELEASE_NOTES_CONTENT="$(<"$NOTES_FILE")"
        else
            RELEASE_NOTES_CONTENT="${NOTES:-Release $TAG}"
        fi

        payload="$(github_create_release_payload "$TAG" "$TITLE" "$DRAFT" "$PRERELEASE" "$GENERATE_NOTES")"
        release_json="$(github_api_request POST "$GITHUB_API_BASE/repos/$REPO/releases" \
            -H "Content-Type: application/json" \
            -d "$payload")"
    fi

    release_id="$(printf '%s' "$release_json" | json_get "id")"
    release_url="$(printf '%s' "$release_json" | json_get "html_url")"
    release_body="$(printf '%s' "$release_json" | json_get "body" 2>/dev/null || true)"

    asset_id="$(printf '%s' "$release_json" | json_find_release_asset_id "$dmg_name")"
    if [[ -n "$asset_id" ]]; then
        github_api_request DELETE "$GITHUB_API_BASE/repos/$REPO/releases/assets/$asset_id" >/dev/null
    fi

    upload_name="$dmg_name"
    encoded_name="$(url_encode "$upload_name")"
    upload_url="https://uploads.github.com/repos/$REPO/releases/$release_id/assets?name=$encoded_name"

    github_api_request POST "$upload_url" \
        -H "Content-Type: application/octet-stream" \
        --data-binary @"$DMG_PATH" >/dev/null

    echo "完成: $release_url"

    APPCAST_NOTES="$release_body"
    if [[ -z "$APPCAST_NOTES" ]]; then
        APPCAST_NOTES="$(github_api_request GET "$GITHUB_API_BASE/repos/$REPO/releases/tags/$TAG" | json_get "body" 2>/dev/null || true)"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dmg)
            DMG_PATH="${2:-}"
            shift 2
            ;;
        --repo)
            REPO="${2:-}"
            shift 2
            ;;
        --tag)
            TAG="${2:-}"
            shift 2
            ;;
        --title)
            TITLE="${2:-}"
            shift 2
            ;;
        --notes)
            NOTES="${2:-}"
            shift 2
            ;;
        --notes-file)
            NOTES_FILE="${2:-}"
            shift 2
            ;;
        --generate-notes)
            GENERATE_NOTES=true
            shift
            ;;
        --draft)
            DRAFT=true
            shift
            ;;
        --prerelease)
            PRERELEASE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "未知参数: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -n "$NOTES" && -n "$NOTES_FILE" ]]; then
    echo "错误: --notes 和 --notes-file 只能二选一" >&2
    exit 1
fi

if [[ "$GENERATE_NOTES" == true && ( -n "$NOTES" || -n "$NOTES_FILE" ) ]]; then
    echo "错误: --generate-notes 不能与 --notes 或 --notes-file 同时使用" >&2
    exit 1
fi

require_command git
require_command /usr/libexec/PlistBuddy
require_command /usr/bin/python3

if gh auth status >/dev/null 2>&1; then
    HAS_GH=true
else
    HAS_GH=false
fi

if [[ -n "$DMG_PATH" ]]; then
    DMG_PATH="$(resolve_path "$DMG_PATH")"
else
    DMG_PATH="$(find_latest_dmg)"
fi

if [[ -z "$DMG_PATH" || ! -f "$DMG_PATH" ]]; then
    echo "错误: 未找到可上传的 DMG，请先执行 ./scripts/build_release.sh 或通过 --dmg 指定文件" >&2
    exit 1
fi

if [[ -n "$NOTES_FILE" ]]; then
    NOTES_FILE="$(resolve_path "$NOTES_FILE")"
    if [[ -z "$NOTES_FILE" || ! -f "$NOTES_FILE" ]]; then
        echo "错误: 未找到 notes 文件" >&2
        exit 1
    fi
fi

if [[ -z "$REPO" ]]; then
    if ! REPO="$(detect_repo)"; then
        echo "错误: 无法推断 GitHub 仓库，请通过 --repo OWNER/REPO 显式指定" >&2
        exit 1
    fi
fi

VERSION="$(read_project_setting "MARKETING_VERSION")"
if [[ -z "$VERSION" ]]; then
    echo "错误: 无法从工程读取 MARKETING_VERSION" >&2
    exit 1
fi

if [[ -z "$TAG" ]]; then
    TAG="v$VERSION"
fi

if [[ -z "$TITLE" ]]; then
    TITLE="ConnectMate v$VERSION"
fi

echo "仓库: $REPO"
echo "Tag: $TAG"
echo "标题: $TITLE"
echo "DMG: $DMG_PATH"

if [[ "$HAS_GH" == true ]]; then
    if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
        echo "Release 已存在，上传并覆盖同名资源..."
        gh release upload "$TAG" "$DMG_PATH" -R "$REPO" --clobber
    else
        echo "Release 不存在，正在创建..."
        create_args=(release create "$TAG" "$DMG_PATH" -R "$REPO" --title "$TITLE")

        if [[ "$GENERATE_NOTES" == true ]]; then
            create_args+=(--generate-notes)
        elif [[ -n "$NOTES_FILE" ]]; then
            create_args+=(--notes-file "$NOTES_FILE")
        else
            create_args+=(--notes "${NOTES:-Release $TAG}")
        fi

        if [[ "$DRAFT" == true ]]; then
            create_args+=(--draft)
        fi

        if [[ "$PRERELEASE" == true ]]; then
            create_args+=(--prerelease)
        fi

        gh "${create_args[@]}"
    fi

    echo "完成: https://github.com/$REPO/releases/tag/$TAG"
    APPCAST_NOTES="$(gh release view "$TAG" -R "$REPO" --json body --jq '.body // ""' 2>/dev/null || true)"
else
    echo "未检测到可用的 GitHub CLI，改用 GitHub API 发布..."
    publish_with_github_api
fi

APPCAST_ARGS=(--repo "$REPO" --archive "$DMG_PATH")
if [[ -n "${APPCAST_NOTES:-}" ]]; then
    APPCAST_ARGS+=(--notes "$APPCAST_NOTES")
fi

"$PROJECT_DIR/scripts/generate_appcast.sh" "${APPCAST_ARGS[@]}"

echo "appcast 已更新: $PROJECT_DIR/appcast.xml"
