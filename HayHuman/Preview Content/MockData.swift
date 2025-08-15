import Foundation

enum MockData {
    static let people: [Person] = [
        Person(name: "Месроп Маштоц", subtitle: "Создатель армянского алфавита", section: .science),
        Person(name: "Комитас", subtitle: "Композитор, этномузыковед", section: .culture),
        Person(name: "Хачатур Абовян", subtitle: "Писатель, педагог", section: .culture),
        Person(name: "Тигран Петросян", subtitle: "Чемпион мира по шахматам", section: .sport),
        Person(name: "Андраник Озаян", subtitle: "Военный и общественный деятель", section: .military),
        Person(name: "Гареґин I", subtitle: "Католикос всех армян", section: .religion),
        Person(name: "Армен Саркисян", subtitle: "Государственный деятель", section: .politics),
        Person(name: "Гурген Арсенян", subtitle: "Предприниматель", section: .business)
    ]

    static func filtered(by section: ArmenianSection) -> [Person] {
        guard section != .all else { return people }
        return people.filter { $0.section == section }
    }
}
