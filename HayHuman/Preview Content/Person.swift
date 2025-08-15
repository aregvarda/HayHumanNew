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
    let name: String                // полное имя (например: "Месроп Маштоц")
    let subtitle: String            // короткое описание
    let section: ArmenianSection
    let imageName: String           // имя ассета (квадрат 1:1)

    // Большой титл на карточке
    var overlayTitle: String {
        // Возьми последний токен как «фамилию», или сделай капсом всё имя
        let tokens = name.split(separator: " ")
        let last = tokens.last.map(String.init) ?? name
        return last.uppercased()
    }
}
