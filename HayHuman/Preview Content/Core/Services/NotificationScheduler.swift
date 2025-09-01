//
//  NotificationScheduler.swift
//  HayHuman
//
//  Created by Арег Варданян on 01.09.2025.
//


//
//  NotificationScheduler.swift
//  HayHuman
//
//  Created by Арег Варданян on 01.09.2025.
//

import Foundation
import UserNotifications

// Тип напоминания: биография личности или событие
enum ReminderKind: String, Codable {
    case person
    case event
}

// Полезная нагрузка для уведомления (минимум нужен id и заголовок)
struct ReminderPayload: Codable {
    let kind: ReminderKind
    let id: Int
    let title: String

    var deeplink: String {
        switch kind {
        case .person: return "hayhuman://person/\(id)"
        case .event:  return "hayhuman://event/\(id)"
        }
    }
}

/// Планировщик локальных уведомлений без сервера
enum NotificationScheduler {

    /// Запланировать напоминание каждые 3 дня в указанное время (по умолчанию 10:00)
    /// - Parameters:
    ///   - payload: данные (что открыть и как подписать)
    ///   - hour: час (локальное время устройства)
    ///   - minute: минута
    ///   - identifier: свой идентификатор (если не указан — будет reminder.<kind>.<id>)
    static func scheduleEvery3Days(payload: ReminderPayload,
                                   at hour: Int = 10,
                                   minute: Int = 0,
                                   identifier: String? = nil) {
        let id = identifier ?? "reminder.\(payload.kind.rawValue).\(payload.id)"
        let secondsTillHour = secondsUntil(hour: hour, minute: minute)
        // Первое уведомление в ближайшее окно (чтобы начался цикл в нужное время)
        scheduleOnce(payload: payload, after: secondsTillHour, repeatEvery: nil, id: id + ".first")
        // Дальше — каждые 3 суток
        scheduleOnce(payload: payload, after: 3*24*3600, repeatEvery: 3*24*3600, id: id)
    }

    /// Отменить конкретное напоминание
    static func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id, id + ".first"]) }

    /// Отменить все напоминания приложения
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Private helpers
private extension NotificationScheduler {

    static func secondsUntil(hour: Int, minute: Int) -> TimeInterval {
        var cal = Calendar.current
        cal.timeZone = .current
        let now = Date()
        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        comps.hour = hour; comps.minute = minute; comps.second = 0
        let targetToday = cal.date(from: comps) ?? now
        if targetToday > now { return targetToday.timeIntervalSince(now) }
        return (targetToday.addingTimeInterval(24*3600)).timeIntervalSince(now)
    }

    /// Единичное или повторяющееся уведомление через time interval
    static func scheduleOnce(payload: ReminderPayload,
                             after: TimeInterval,
                             repeatEvery: TimeInterval?,
                             id: String) {
        let content = UNMutableNotificationContent()
        // Заголовок/текст
        switch payload.kind {
        case .person:
            content.title = NSLocalizedString("Напоминание", comment: "")
            content.body  = String(format: NSLocalizedString("Почитайте биографию: %@", comment: ""), payload.title)
        case .event:
            content.title = NSLocalizedString("Напоминание", comment: "")
            content.body  = String(format: NSLocalizedString("Почитайте о событии: %@", comment: ""), payload.title)
        }
        content.sound = .default
        content.userInfo = ["deeplink": payload.deeplink]

        // Триггеры: первая — одноразовая; повтор — интервал с repeats
        if let interval = repeatEvery {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(interval, 60), repeats: true)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        } else {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(after, 60), repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
}
