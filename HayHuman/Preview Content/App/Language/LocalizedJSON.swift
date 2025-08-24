//
//  LocalizedJSON.swift
//  HayHuman
//
//  Created by Арег Варданян on 17.08.2025.
//

import Foundation

// Языки, которые у тебя есть
enum AppLang: String {
    case ru, en, hy

    static func current() -> AppLang {
        // 1) Берём выбранный язык из LanguageManager (@AppStorage("appLanguage"))
        if let raw = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLang(rawValue: raw) {
            return lang
        }
        // 2) Иначе — из системных локализаций
        let pref = Bundle.main.preferredLocalizations.first?.lowercased() ?? "ru"
        if pref.hasPrefix("hy") { return .hy }
        if pref.hasPrefix("en") { return .en }
        return .ru
    }
}

/// Утилита для поиска и загрузки локализованных JSON
enum LocalizedJSON {

    /// Ищет файл в таком порядке:
    /// 1) people_localizable/<lang>/<base>.<lang>.json
    /// 2) people_localizable/ru/<base>.ru.json
    /// 3) people_localizable/<lang>/<base>.json
    /// 4) <base>.json (старый дефолт рядом с бандлом)
    static func url(for base: String, lang: AppLang = .current()) -> URL? {
        // 1)
        if let url = Bundle.main.url(
            forResource: "people_localizable/\(lang.rawValue)/\(base).\(lang.rawValue)",
            withExtension: "json"
        ) { return url }

        // 2)
        if let url = Bundle.main.url(
            forResource: "people_localizable/ru/\(base).ru",
            withExtension: "json"
        ) { return url }

        // 3)
        if let url = Bundle.main.url(
            forResource: "people_localizable/\(lang.rawValue)/\(base)",
            withExtension: "json"
        ) { return url }

        // 4)
        if let url = Bundle.main.url(forResource: base, withExtension: "json") {
            return url
        }

        return nil
    }

    /// Универсальная загрузка массива моделей
    static func loadArray<T: Decodable>(base: String, as type: T.Type) throws -> [T] {
        guard let url = url(for: base) else {
            throw NSError(
                domain: "LocalizedJSON",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "JSON not found for base \(base)"]
            )
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([T].self, from: data)
    }
}
