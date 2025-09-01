//
//  HayHumanApp.swift
//  HayHuman
//
//  Created by Арег Варданян on 15.08.2025.
//

import SwiftUI
import UserNotifications

@main
struct HayHumanApp: App {
    @AppStorage("pendingDeepLinkApp") private var pendingDeepLinkApp: String = ""
    @StateObject private var lang = LanguageManager()
    @State private var showSplash = true

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Notifications permission: \(granted)")
        }
        RandomReminderManager.getPersons = {
            // Лёгкие модели персон из локального стора (стабильный Int id = индекс)
            LocalPeopleStore.allPeopleLite()
        }
        RandomReminderManager.getEvents = {
            StoriesStore.load().enumerated().map { (idx, s) in
                EventLite(id: idx, title: s.title)
            }
        }
    }

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
            .onAppear {
                if !pendingDeepLinkApp.isEmpty, let url = URL(string: pendingDeepLinkApp) {
                    // Wait until splash is dismissed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        if !showSplash {
                            NotificationCenter.default.post(name: .HayHumanOpenDeepLink, object: url, userInfo: ["deeplink": url.absoluteString])
                            pendingDeepLinkApp = ""
                        }
                    }
                }
            }
            .onChange(of: pendingDeepLinkApp) { newValue in
                if !newValue.isEmpty, let url = URL(string: newValue) {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .HayHumanOpenDeepLink, object: url, userInfo: ["deeplink": url.absoluteString])
                        pendingDeepLinkApp = ""
                    }
                }
            }
        }
    }
}
