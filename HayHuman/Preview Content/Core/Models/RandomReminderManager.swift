//
//  RandomReminderManager.swift
//  HayHuman
//
//  Created by Арег Варданян on 01.09.2025.
//


//
//  RandomReminderManager.swift
//  HayHuman
//
//  Created by Арег Варданян on 01.09.2025.
//

import Foundation
import UserNotifications

// Лёгкие модели-источники
public struct PersonLite: Hashable, Codable { public let id: Int; public let name: String }
public struct EventLite:  Hashable, Codable { public let id: Int; public let title: String }

/// Менеджер случайных напоминаний: каждые 3 дня, без повторов, с диплинком в приложение
enum RandomReminderManager {

    // MARK: — Публичная настройка провайдеров
    /// Провайдеры источников (задать из вашего слоя данных)
    static var getPersons: () -> [PersonLite] = { [] }
    static var getEvents:  () -> [EventLite]  = { [] }

    // MARK: — Публичные API
    /// Запланировать серию уведомлений на `days` вперёд. Каждые 3 дня в `hour:minute`.
    /// Не меняет UI, только планирует локальные уведомления.
    static func scheduleSeries(days: Int = 90, hour: Int = 19, minute: Int = 0) {
        // очистим предыдущие «рандомные» заявки
        cancelSeries()

        // соберём уникальный пул кандидатов (персоны+события)
        let payloads = buildUniqueShuffledPayloads()
        guard !payloads.isEmpty else { return }

        let totalNotifications = max(1, days / 3)

        // Берём первые N из перемешанного пула; если их меньше — берём без повторов сколько есть
        let picked = Array(payloads.prefix(totalNotifications))

        // Запомним использованные id, чтобы в следующую серию не повторять
        let usedIDs = picked.map { usedKey(kind: $0.kind, id: $0.id) }
        saveUsed(ids: usedIDs)

        // Запланируем цепочку уведомлений каждые 3 дня (DST‑safe)
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = hour; comps.minute = minute; comps.second = 0
        let firstCandidate = cal.date(from: comps) ?? now
        let firstFire = (firstCandidate > now) ? firstCandidate : (cal.date(byAdding: .day, value: 1, to: firstCandidate) ?? firstCandidate)

        var pendingIDs: [String] = []
        let center = UNUserNotificationCenter.current()
        for (idx, p) in picked.enumerated() {
            guard let fireDate = cal.date(byAdding: .day, value: idx * 3, to: firstFire) else { continue }
            let dc = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
            let id = "random.series.\(p.kind.rawValue).\(p.id).\(idx)"
            pendingIDs.append(id)
            let content = makeContent(for: p)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }

        // Сохраним список заявок, чтобы потом отменить
        UserDefaults.standard.set(pendingIDs, forKey: Keys.pendingIDs)
    }

    /// Отменить только «рандомную» серию (не трогает остальные напоминания)
    static func cancelSeries() {
        let defaults = UserDefaults.standard
        if let ids = defaults.stringArray(forKey: Keys.pendingIDs), !ids.isEmpty {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
        defaults.removeObject(forKey: Keys.pendingIDs)
    }
}

// MARK: — Private
private extension RandomReminderManager {
    enum Keys {
        static let usedIDs    = "RandomReminderManager.usedIDs"
        static let pendingIDs = "RandomReminderManager.pendingIDs"
    }

    static func usedKey(kind: ReminderKind, id: Int) -> String { "\(kind.rawValue).\(id)" }

    static func saveUsed(ids: [String]) {
        var set = Set(UserDefaults.standard.stringArray(forKey: Keys.usedIDs) ?? [])
        set.formUnion(ids)
        UserDefaults.standard.set(Array(set), forKey: Keys.usedIDs)
    }

    static func buildUniqueShuffledPayloads() -> [ReminderPayload] {
        // прочитаем уже использованные
        let used = Set(UserDefaults.standard.stringArray(forKey: Keys.usedIDs) ?? [])

        // кандидаты персон
        let persons = getPersons()
            .filter { !used.contains(usedKey(kind: .person, id: $0.id)) }
            .map { ReminderPayload(kind: .person, id: $0.id, title: $0.name) }
        // кандидаты событий
        let events  = getEvents()
            .filter { !used.contains(usedKey(kind: .event, id: $0.id)) }
            .map { ReminderPayload(kind: .event, id: $0.id, title: $0.title) }

        var all = persons + events
        all.shuffle()
        return all
    }

    static func makeContent(for payload: ReminderPayload) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        switch payload.kind {
        case .person:
            content.title = "HayHuman"
            content.body  = "5 минут истории: кто такой \(payload.title)?"
        case .event:
            content.title = "HayHuman"
            content.body  = "История на вечер: \(payload.title)"
        }
        content.sound = .default
        content.userInfo = ["deeplink": payload.deeplink]
        return content
    }

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
}
