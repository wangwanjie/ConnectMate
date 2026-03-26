import Foundation

struct SidebarItem: Identifiable, Equatable {
    let section: AppSection

    var id: String { section.rawValue }
    var title: String { section.title }
    var symbolName: String { section.symbolName }
}
