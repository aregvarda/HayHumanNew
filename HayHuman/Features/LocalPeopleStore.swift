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
    // Deterministic stable ID (FNV-1a 64-bit) over normalized title+year
    private static func stableID(for p: Person) -> Int {
        let key = normalizedKey(for: p)
        let hash64 = fnv1a64(key)
        return Int(truncatingIfNeeded: hash64)
    }

    // Normalize to Latin and strip diacritics/spaces to be language-agnostic
    private static func normalizedKey(for p: Person) -> String {
        var base = p.overlayTitle
        if let y = p.birthYear { base += "|\(y)" } else { base += "|0" }
        let ms = NSMutableString(string: base.lowercased())
        CFStringTransform(ms, nil, kCFStringTransformToLatin, false)
        CFStringTransform(ms, nil, kCFStringTransformStripCombiningMarks, false)
        let allowed = CharacterSet.alphanumerics.union(["|"])
        let filtered = (ms as String).unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }

    // FNV-1a 64-bit hash (deterministic across runs)
    private static func fnv1a64(_ s: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x00000100000001B3
        for b in s.utf8 { hash ^= UInt64(b); hash &*= prime }
        return hash
    }

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

    /// Полная модель Person по индексу в общем списке (соответствует allPeopleLite())
    static func personFull(at index: Int) -> Person? {
        let all = loadAll()
        guard index >= 0 && index < all.count else { return nil }
        return all[index]
    }

    /// Full model by stable generated id
    static func personFull(byStableID id: Int) -> Person? {
        let all = loadAll()
        return all.first { stableID(for: $0) == id }
    }

    /// Лёгкие модели для уведомлений (стабильный Int id = индекс в общем списке)
    static func allPeopleLite() -> [PersonLite] {
        let all = loadAll()
        return all.map { p in
            PersonLite(id: stableID(for: p), name: p.name)
        }
    }
}
