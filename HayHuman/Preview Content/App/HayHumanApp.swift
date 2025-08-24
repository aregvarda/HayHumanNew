//
//  HayHumanApp.swift
//  HayHuman
//
//  Created by Арег Варданян on 15.08.2025.
//

import SwiftUI

@main
struct HayHumanApp: App {
    @StateObject private var lang = LanguageManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Применяем выбранный язык ко всему UI
                .environment(\.locale, lang.current.locale)
                // Делаем менеджер доступным во всём дереве вью
                .environmentObject(lang)
                // Форсируем пересоздание корневого экрана при смене языка
                .id(lang.current.rawValue)
        }
    }
}
