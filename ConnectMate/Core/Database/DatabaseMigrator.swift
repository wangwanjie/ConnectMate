import Foundation
import GRDB

extension DatabaseMigrator {
    static var connectMate: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createCoreSchema") { db in
            try db.create(table: "api_keys") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("name", .text).notNull()
                table.column("issuer_id", .text).notNull()
                table.column("key_id", .text).notNull()
                table.column("p8_path", .text).notNull()
                table.column("profile_name", .text)
                table.column("is_active", .boolean).notNull().defaults(to: false)
                table.column("last_verified_at", .datetime)
                table.column("last_validation_status", .text)
                table.uniqueKey(["issuer_id", "key_id", "p8_path"])
            }

            try db.create(table: "apps") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("account_key_id", .integer).references("api_keys", onDelete: .cascade)
                table.column("asc_id", .text).notNull()
                table.column("name", .text).notNull()
                table.column("bundle_id", .text).notNull()
                table.column("sku", .text)
                table.column("platform", .text).notNull()
                table.column("app_state", .text)
                table.column("icon_url", .text)
                table.column("raw_json", .text)
                table.column("cached_at", .datetime).notNull()
                table.uniqueKey(["account_key_id", "asc_id"])
            }

            try db.create(index: "idx_apps_account_key_id", on: "apps", columns: ["account_key_id"])

            try db.create(table: "builds") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("account_key_id", .integer).references("api_keys", onDelete: .cascade)
                table.column("asc_id", .text).notNull()
                table.column("app_asc_id", .text).notNull()
                table.column("version", .text).notNull()
                table.column("build_number", .text).notNull()
                table.column("processing_state", .text).notNull()
                table.column("platform", .text)
                table.column("expired", .boolean).notNull().defaults(to: false)
                table.column("uploaded_at", .datetime)
                table.column("raw_json", .text)
                table.column("cached_at", .datetime).notNull()
                table.uniqueKey(["account_key_id", "asc_id"])
            }

            try db.create(index: "idx_builds_app_asc_id", on: "builds", columns: ["app_asc_id"])

            try db.create(table: "review_submissions") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("account_key_id", .integer).references("api_keys", onDelete: .cascade)
                table.column("submission_id", .text).notNull()
                table.column("app_asc_id", .text).notNull()
                table.column("version_id", .text)
                table.column("build_id", .text)
                table.column("status", .text).notNull()
                table.column("raw_json", .text)
                table.column("updated_at", .datetime).notNull()
                table.uniqueKey(["account_key_id", "submission_id"])
            }

            try db.create(table: "testers") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("account_key_id", .integer).references("api_keys", onDelete: .cascade)
                table.column("tester_id", .text).notNull()
                table.column("app_asc_id", .text)
                table.column("email", .text).notNull()
                table.column("first_name", .text)
                table.column("last_name", .text)
                table.column("invite_status", .text)
                table.column("raw_json", .text)
                table.column("cached_at", .datetime).notNull()
                table.uniqueKey(["account_key_id", "tester_id"])
            }

            try db.create(table: "beta_groups") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("account_key_id", .integer).references("api_keys", onDelete: .cascade)
                table.column("group_id", .text).notNull()
                table.column("app_asc_id", .text)
                table.column("name", .text).notNull()
                table.column("is_internal", .boolean).notNull().defaults(to: false)
                table.column("raw_json", .text)
                table.column("cached_at", .datetime).notNull()
                table.uniqueKey(["account_key_id", "group_id"])
            }

            try db.create(table: "iap_products") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("account_key_id", .integer).references("api_keys", onDelete: .cascade)
                table.column("iap_id", .text).notNull()
                table.column("app_asc_id", .text).notNull()
                table.column("product_id", .text).notNull()
                table.column("reference_name", .text)
                table.column("product_type", .text).notNull()
                table.column("status", .text)
                table.column("price_summary", .text)
                table.column("raw_json", .text)
                table.column("cached_at", .datetime).notNull()
                table.uniqueKey(["account_key_id", "iap_id"])
            }

            try db.create(table: "command_logs") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("command", .text).notNull()
                table.column("arguments_json", .text).notNull()
                table.column("stdout_text", .text).notNull()
                table.column("stderr_text", .text).notNull()
                table.column("exit_code", .integer)
                table.column("duration_ms", .integer).notNull()
                table.column("status", .text).notNull()
                table.column("executed_at", .datetime).notNull()
            }

            try db.create(index: "idx_command_logs_executed_at", on: "command_logs", columns: ["executed_at"])
        }

        migrator.registerMigration("extendBuildsWithMetadata") { db in
            let columns = Set(try Row
                .fetchAll(db, sql: "PRAGMA table_info(builds)")
                .compactMap { row in row["name"] as String? })

            if !columns.contains("platform") {
                try db.alter(table: "builds") { table in
                    table.add(column: "platform", .text)
                }
            }

            if !columns.contains("expired") {
                try db.alter(table: "builds") { table in
                    table.add(column: "expired", .boolean).notNull().defaults(to: false)
                }
            }
        }

        return migrator
    }
}
