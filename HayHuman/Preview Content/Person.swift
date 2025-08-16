import Foundation

// Разделы (локализованные названия остаются как раньше)
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

// Позволяем декодировать секцию как из англ. слага ("culture"), так и из русского названия
extension ArmenianSection: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self).trimmingCharacters(in: .whitespacesAndNewlines)
        let v = raw.lowercased()
        switch v {
        case "all", "все личности": self = .all
        case "culture", "культура": self = .culture
        case "military", "военное дело": self = .military
        case "politics", "политика": self = .politics
        case "religion", "религия": self = .religion
        case "sport", "спорт": self = .sport
        case "business", "бизнес": self = .business
        case "science", "наука", "наука и образование", "наука\nи образование", "science_education": self = .science
        default:
            if let m = ArmenianSection.allCases.first(where: { $0.rawValue.lowercased() == v }) {
                self = m
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown section: \(raw)")
            }
        }
    }
}

// Модель человека. Добавлены опциональные поля для экрана с картой и биографией
struct Person: Identifiable, Hashable, Decodable {
    let id = UUID()
    let name: String                 // полное имя (например: "Месроп Маштоц")
    let subtitle: String             // короткое описание
    let section: ArmenianSection
    let imageName: String            // имя ассета (квадрат 1:1)

    // НОВОЕ: опциональные поля
    let birthCity: String?           // город рождения (текст)
    let birthCountry: String?        // страна рождения (текст)
    let birthLat: Double?            // широта
    let birthLon: Double?            // долгота
    let bio: String?                 // длинная биография
    let birthYear: Int?               // год рождения для сортировки

    // Большой титл на карточке
    var overlayTitle: String {
        let tokens = name.split(separator: " ")
        let last = tokens.last.map(String.init) ?? name
        return last.uppercased()
    }

    // Явно укажем ключи (id генерируется локально и не читается из JSON)
    enum CodingKeys: String, CodingKey {
        case name, subtitle, section, imageName, birthCity, birthCountry, birthLat, birthLon, bio
        case birthYear
    }
}
