import SwiftUI

/// Supported app languages.
enum AppLanguage: String, CaseIterable, Identifiable {
    case ru = "ru"
    case en = "en"
    case hy = "hy"

    var id: String { rawValue }

    /// Human‑readable name for the picker/button.
    var displayName: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        case .hy: return "Հայերեն"
        }
    }

    /// Locale to inject into SwiftUI environment.
    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

/// Simple manager that persists the selected language
/// and publishes changes so SwiftUI updates immediately.
final class LanguageManager: ObservableObject {
    @AppStorage("appLanguage") private var stored = AppLanguage.ru.rawValue

    @Published var current: AppLanguage = .ru {
        didSet { stored = current.rawValue }
    }

    init() {
        current = AppLanguage(rawValue: stored) ?? .ru
    }

    /// Optional helper to cycle RU → EN → HY → RU
    func cycle() {
        let all = AppLanguage.allCases
        if let idx = all.firstIndex(of: current) {
            let next = all.index(after: idx)
            current = next < all.endIndex ? all[next] : all.first ?? .ru
        }
    }
}
