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
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    // Применяем выбранный язык ко всему UI
                    .environment(\.locale, lang.current.locale)
                    // Делаем менеджер доступным во всём дереве вью
                    .environmentObject(lang)
                    // Форсируем пересоздание корневого экрана при смене языка
                    .id(lang.current.rawValue)

                if showSplash {
                    MinimalSplashView {
                        withAnimation(.easeOut(duration: 0.2)) { showSplash = false }
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(nil, value: showSplash)
        }
    }
}
