//
//  LocalPeopleStore.swift
//  HayHuman
//
//  Created by Арег Варданян on 16.08.2025.
//

import Foundation

enum PeopleFile {
    static func filename(for section: ArmenianSection) -> String {
        switch section {
        case .all:      return "__all__"      // служебно, не используется как файл
        case .culture:  return "people_culture"
        case .military: return "people_military"
        case .politics: return "people_politics"
        case .religion: return "people_religion"
        case .sport:    return "people_sport"
        case .business: return "people_business"
        case .science:  return "people_science"
        }
    }
}

enum LocalPeopleStore {
    /// Загрузить одну секцию из бандла
    static func load(section: ArmenianSection) -> [Person] {
        if section == .all { return loadAll() }

        let name = PeopleFile.filename(for: section)
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Person].self, from: data) else {
            print("⚠️ Не удалось загрузить \(name).json")
            return []
        }
        return decoded
    }

    /// Собрать «все личности» из всех секций
    static func loadAll() -> [Person] {
        ArmenianSection.allCases
            .filter { $0 != .all }
            .flatMap { load(section: $0) }
    }
}
