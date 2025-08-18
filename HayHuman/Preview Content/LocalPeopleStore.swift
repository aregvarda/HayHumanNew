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
    /// Current 2-letter language code (from app settings or system fallback)
    static func currentLangCode() -> String {
        // 1) explicit app setting
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"), !saved.isEmpty {
            if saved.hasPrefix("en") { return "en" }
            if saved.hasPrefix("ru") { return "ru" }
            if saved.hasPrefix("hy") { return "hy" }
        }
        // 2) system languages
        for id in Locale.preferredLanguages {
            if id.hasPrefix("en") { return "en" }
            if id.hasPrefix("ru") { return "ru" }
            if id.hasPrefix("hy") { return "hy" }
        }
        // 3) base fallback
        return "Base"
    }

    /// Загрузить одну секцию из бандла
    static func load(section: ArmenianSection) -> [Person] {
        if section == .all { return loadAll() }

        let name = PeopleFile.filename(for: section)
        let lang = currentLangCode()
        var data: Data?
        var usedLocalization: String = "<none>"

        // Try localized files in priority order: selected, then en/ru/hy
        let candidates: [String] = {
            var arr: [String] = []
            arr.append(lang)
            if !arr.contains("en") { arr.append("en") }
            if !arr.contains("ru") { arr.append("ru") }
            if !arr.contains("hy") { arr.append("hy") }
            return arr
        }()

        for code in candidates where code != "Base" {
            if let url = Bundle.main.url(forResource: name,
                                         withExtension: "json",
                                         subdirectory: nil,
                                         localization: code),
               let d = try? Data(contentsOf: url) {
                data = d
                usedLocalization = "\(code).lproj"
                print("[People] Loaded \(name).json from \(usedLocalization)")
                break
            } else {
                print("[People] Miss \(name).json for lang=\(code)")
            }
        }

        // Final fallback — unlocalized (Base)
        if data == nil {
            if let url = Bundle.main.url(forResource: name, withExtension: "json"),
               let d = try? Data(contentsOf: url) {
                data = d
                usedLocalization = "Base (unlocalized)"
                print("[People] Loaded \(name).json from \(usedLocalization)")
            }
        }

        guard let data = data,
              let decoded = try? JSONDecoder().decode([Person].self, from: data) else {
            print("⚠️ [People] Failed to load \(name).json (lang=\(lang))")
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
