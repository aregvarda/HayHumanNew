import Foundation

enum ArmenianSection: String, CaseIterable, Identifiable, Hashable {
    case all = "Все личности"
    case culture = "Культура"
    case military = "Военное дело"
    case politics = "Политика"
    case religion = "Религия"
    case sport = "Спорт"
    case business = "Бизнес"
    case science = "Наука\nи образование"

    var id: Self { self }
    var title: String { rawValue }
}

struct Person: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let section: ArmenianSection
}
