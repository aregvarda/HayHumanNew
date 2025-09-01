//
//  NotificationDelegate.swift
//  HayHuman
//
//  Created by Арег Варданян on 01.09.2025.
//

import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    // Показать баннер, если приложение открыто
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Обработка тапа по уведомлению
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let deeplink = userInfo["deeplink"] as? String, let url = URL(string: deeplink) {
            // Persist for cold start
            UserDefaults.standard.set(deeplink, forKey: "pendingDeepLinkApp")
            // Post for warm state
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .HayHumanOpenDeepLink, object: url, userInfo: ["deeplink": deeplink])
            }
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let HayHumanOpenDeepLink = Notification.Name("HayHumanOpenDeepLink")
}
