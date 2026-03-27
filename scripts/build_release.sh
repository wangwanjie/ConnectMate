#!/usr/bin/env bash
#
# 参考 HostsEditor 的发布流程构建 ConnectMate：
# 1. archive Release 产物
# 2. 校验并补全 Developer ID Application 签名与 secure timestamp
# 3. 使用全局 create_pretty_dmg.sh 生成 DMG
# 4. 可选提交公证并 staple
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE="ConnectMate.xcworkspace"
SCHEME="ConnectMate"
CONFIGURATION="Release"
BUILD_DIR="$PROJECT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
ARCHIVE_PATH="$BUILD_DIR/ConnectMate.xcarchive"
DMG_OUTPUT_DIR="$BUILD_DIR/dmg"
PBXPROJ="$PROJECT_DIR/ConnectMate.xcodeproj/project.pbxproj"
APP_ENTITLEMENTS="$PROJECT_DIR/ConnectMate/ConnectMate-Release.entitlements"
KEYCHAIN_PROFILE="vanjay_mac_stapler"
DO_NOTARIZE=true

usage() {
    cat <<'EOF'
用法:
  ./scripts/build_release.sh [--keychain-profile PROFILE] [--no-notarize]

选项:
  --keychain-profile PROFILE   notarytool 使用的 Keychain Profile，默认 vanjay_mac_stapler
  --no-notarize                跳过公证与 staple
  -h, --help                   显示帮助
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

current_signing_authority() {
    local target_path="$1"
    codesign -dv --verbose=4 "$target_path" 2>&1 | sed -n 's/^Authority=\(Developer ID Application:.*\)$/\1/p' | head -1
}

first_developer_id_authority() {
    security find-identity -v -p codesigning 2>/dev/null \
        | sed -n 's/.*"\(Developer ID Application: .* ([A-Z0-9]\+)\)"/\1/p' \
        | head -1
}

developer_id_authority_for_team() {
    local team_id="$1"
    security find-identity -v -p codesigning 2>/dev/null \
        | sed -n "s/.*\"\\(Developer ID Application: .* (${team_id})\\)\"/\\1/p" \
        | head -1
}

resolve_signing_authority() {
    local target_path="$1"
    local project_team_id="$2"
    local authority=""

    authority="$(current_signing_authority "$target_path")"
    if [[ -n "$authority" ]]; then
        echo "$authority"
        return 0
    fi

    if [[ -n "$project_team_id" ]]; then
        authority="$(developer_id_authority_for_team "$project_team_id")"
        if [[ -n "$authority" ]]; then
            echo "$authority"
            return 0
        fi
    fi

    authority="$(first_developer_id_authority)"
    echo "$authority"
}

verify_signature() {
    local target_path="$1"
    local target_name="$2"
    local sign_info

    echo "校验签名: $target_name"
    sign_info="$(codesign -dv --verbose=4 "$target_path" 2>&1)"

    if ! grep -q "Authority=Developer ID Application" <<<"$sign_info"; then
        echo "错误: $target_name 未使用 Developer ID Application 签名" >&2
        echo "$sign_info" >&2
        exit 1
    fi

    if ! grep -q "Timestamp=" <<<"$sign_info"; then
        echo "错误: $target_name 缺少 secure timestamp" >&2
        echo "$sign_info" >&2
        exit 1
    fi
}

resign_macho_file() {
    local target_path="$1"
    local identity="$2"
    /usr/bin/codesign --force --sign "$identity" --timestamp --options runtime "$target_path"
}

resign_bundle() {
    local target_path="$1"
    local identity="$2"
    /usr/bin/codesign --force --sign "$identity" --timestamp --options runtime "$target_path"
}

resign_for_notarization() {
    local identity="$1"
    local frameworks_dir="$APP_PATH/Contents/Frameworks"

    echo "重新签名发布产物并补充 secure timestamp..."

    if [[ -d "$frameworks_dir" ]]; then
        while IFS= read -r -d '' file_path; do
            if file "$file_path" | grep -q "Mach-O"; then
                resign_macho_file "$file_path" "$identity"
            fi
        done < <(find "$frameworks_dir" -type f -print0)

        while IFS= read -r -d '' nested_app; do
            resign_bundle "$nested_app" "$identity"
        done < <(find "$frameworks_dir" -type d -name "*.app" -print0)

        while IFS= read -r -d '' framework_path; do
            resign_bundle "$framework_path" "$identity"
        done < <(find "$frameworks_dir" -type d -name "*.framework" -print0)
    fi

    /usr/bin/codesign --force --sign "$identity" --timestamp --options runtime \
        --entitlements "$APP_ENTITLEMENTS" \
        "$APP_PATH"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --keychain-profile)
            if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
                echo "错误: --keychain-profile 需要指定 profile 名称" >&2
                exit 1
            fi
            KEYCHAIN_PROFILE="$2"
            shift 2
            ;;
        --no-notarize)
            DO_NOTARIZE=false
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

require_command xcodebuild
require_command codesign
require_command xcrun
require_command create_pretty_dmg.sh
require_command security

cd "$PROJECT_DIR"

echo "读取版本信息..."
MARKETING_VERSION="$(read_project_setting "MARKETING_VERSION")"
BUILD_VERSION="$(read_project_setting "CURRENT_PROJECT_VERSION")"
PROJECT_TEAM_ID="$(read_project_setting "DEVELOPMENT_TEAM")"

if [[ -z "$MARKETING_VERSION" || -z "$BUILD_VERSION" || -z "$PROJECT_TEAM_ID" ]]; then
    echo "错误: 无法从 project.pbxproj 读取版本信息或签名 Team ID" >&2
    exit 1
fi

echo "版本号: $MARKETING_VERSION ($BUILD_VERSION)"
echo "签名 Team ID: $PROJECT_TEAM_ID"

echo "归档 $SCHEME (Release, arm64 + x86_64)..."
xcodebuild -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    clean archive

APP_PATH="$ARCHIVE_PATH/Products/Applications/ConnectMate.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "错误: 未找到构建产物 $APP_PATH" >&2
    exit 1
fi

SIGNING_AUTHORITY="$(resolve_signing_authority "$APP_PATH" "$PROJECT_TEAM_ID")"
if [[ -z "$SIGNING_AUTHORITY" ]]; then
    echo "错误: 未能解析可用的 Developer ID Application 签名身份" >&2
    exit 1
fi

echo "重签名身份: $SIGNING_AUTHORITY"
resign_for_notarization "$SIGNING_AUTHORITY"
verify_signature "$APP_PATH" "ConnectMate.app"

mkdir -p "$DMG_OUTPUT_DIR"

echo "生成 DMG..."
dmg_path="$(create_pretty_dmg.sh \
    --app-path "$APP_PATH" \
    --dmg-name "ConnectMate" \
    --append-version \
    --append-build \
    --output-dir "$DMG_OUTPUT_DIR" | awk -F': ' '/^DMG_PATH: / {print $2}' | tail -n 1)"

if [[ -z "$dmg_path" || ! -f "$dmg_path" ]]; then
    echo "错误: create_pretty_dmg.sh 未返回有效 DMG 路径" >&2
    exit 1
fi

DMG_PATH="$dmg_path"
echo "DMG 已生成: $DMG_PATH"

if [[ "$DO_NOTARIZE" == true ]]; then
    echo "提交公证 (keychain-profile: $KEYCHAIN_PROFILE)..."
    NOTARY_OUTPUT="$(xcrun notarytool submit "$DMG_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait 2>&1)" || true
    echo "$NOTARY_OUTPUT"

    if echo "$NOTARY_OUTPUT" | grep -q "status: Accepted"; then
        echo "公证成功，正在 stapler 钉合..."
        xcrun stapler staple "$DMG_PATH"
        echo "公证并钉合完成。"
    else
        echo "公证未通过 (status 非 Accepted)。" >&2
        if echo "$NOTARY_OUTPUT" | grep -q "id:"; then
            NOTARY_ID="$(echo "$NOTARY_OUTPUT" | sed -n 's/.*id:[[:space:]]*\\([^[:space:]]*\\).*/\\1/p' | head -1)"
            [[ -n "$NOTARY_ID" ]] && echo "查看失败原因: xcrun notarytool log $NOTARY_ID --keychain-profile \"$KEYCHAIN_PROFILE\"" >&2
        fi
        exit 1
    fi
else
    echo "已跳过公证 (--no-notarize)。"
fi

echo "APP_PATH: $APP_PATH"
echo "DMG_PATH: $DMG_PATH"
