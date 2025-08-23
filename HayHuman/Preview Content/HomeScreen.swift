// ArmenianSection localization extension
extension ArmenianSection {
    /// Key for Localizable.strings
    var localizationKey: String {
        switch self {
        case .all:      return "all_people"
        case .culture:  return "culture"
        case .military: return "military"
        case .politics: return "politics"
        case .religion: return "religion"
        case .sport:    return "sport"
        case .business: return "business"
        case .science:  return "science"
        }
    }
    
    /// Localized plain String (force-resolves from the bundle)
    var localizedString: String {
        NSLocalizedString(self.localizationKey,
                          tableName: "Localizable",
                          bundle: .main,
                          value: "",
                          comment: "")
    }
    
    /// Localized title from String Catalog / Localizable.strings
    var localizedTitle: LocalizedStringKey {
        LocalizedStringKey(self.localizationKey)
    }
}

import SwiftUI

// Палитра
private let pageBG      = Color(uiColor: .systemGroupedBackground)
private let borderColor = Color.black.opacity(0.15)
private let supportBG   = Color(uiColor: .systemGray5)

// Универсальная плитка-кнопка
private struct OutlineTileButton: View {
    /// Localization key from String Catalog (Localizable)
    let titleKey: LocalizedStringKey
    var body: some View {
        // Resolve from Localizable.xcstrings at runtime
        Text(titleKey)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .lineLimit(2)
            .allowsTightening(false)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 124)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}

// Карточка «Сегодня в истории»
private struct HistoryTodayCard: View {
    let person: Person

    // размеры карточки
    private let cardHeight: CGFloat = 152
    private let imageSide: CGFloat = 108
    private let corner: CGFloat = 22

    var body: some View {
        HStack(spacing: 14) {
            Image(person.imageName)
                .resizable()
                .scaledToFill()
                .grayscale(1.0)
                .frame(width: imageSide, height: imageSide)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey("history_today"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 2)

                Text(person.name)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.92)
                    .layoutPriority(2)

                Text(person.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .layoutPriority(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: cardHeight, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: corner))
        .overlay(
            RoundedRectangle(cornerRadius: corner)
                .stroke(Color.black.opacity(0.12), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: corner))
    }
}

// Универсальная поисковая строка (plain view, purple border)
private struct UniversalSearchBar: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(LocalizedStringKey("search_everything"))
                .foregroundStyle(.secondary)
                .font(.system(size: 19, weight: .regular))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.65), lineWidth: 2.5)
        )
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
        .accessibilityLabel(LocalizedStringKey("search_everything"))
    }
}

struct HomeScreen: View {
    private let columns = [GridItem(.flexible(), spacing: 14),
                           GridItem(.flexible(), spacing: 14)]
    
    @EnvironmentObject private var lang: LanguageManager
    @State private var showLanguageSheet = false
    @State private var showSearch = false

    // Fallback person for "Today in history" in case data is missing
    private let fallbackFeatured = Person(
        name: "Месроп Маштоц",
        subtitle: "Создатель армянского алфавита",
        section: .science,
        imageName: "mesrop",
        birthCity: "Ахтала",
        birthCountry: "Армения",
        birthLat: 41.1500,
        birthLon: 44.8333,
        bio: "Создатель армянского алфавита, живший в V веке.",
        birthYear: 360
    )

    @State private var featured: Person = Person(
        name: "Месроп Маштоц",
        subtitle: "Создатель армянского алфавита",
        section: .science,
        imageName: "mesrop",
        birthCity: "Ахтала",
        birthCountry: "Армения",
        birthLat: 41.1500,
        birthLon: 44.8333,
        bio: "Создатель армянского алфавита, живший в V веке.",
        birthYear: 360
    )

    // Порядок разделов с «Все личности» в начале
    private var sections: [ArmenianSection] {
        ArmenianSection.allCases
    }

    // MARK: - Daily featured logic (persist 24h)
    private func todayKey() -> String {
        DailyFormatter.shared.string(from: Date())
    }
    private func dailyFeatured() -> Person {
        let defaults = UserDefaults.standard
        let keyToday = todayKey()
        if let savedDate = defaults.string(forKey: "featuredDate"),
           savedDate == keyToday,
           let savedId = defaults.string(forKey: "featuredId") {
            // Try to find saved person by id in current locale data
            let all = LocalPeopleStore.load(section: .all)
            if let found = all.first(where: { $0.imageName == savedId }) {
                return found
            }
        }
        // Pick new and persist
        let all = LocalPeopleStore.load(section: .all)
        let picked = all.randomElement() ?? fallbackFeatured
        defaults.set(keyToday, forKey: "featuredDate")
        defaults.set(picked.imageName, forKey: "featuredId")
        return picked
    }

    private struct DailyFormatter {
        static let shared: DateFormatter = {
            let df = DateFormatter()
            df.calendar = Calendar(identifier: .gregorian)
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = .current
            df.dateFormat = "yyyy-MM-dd"
            return df
        }()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Поддержать проект (сверху) — открываем ссылку сразу
                Button {
                    if let url = URL(string: "https://www.donationalerts.com/r/hayhuman") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.white)
                        Text(LocalizedStringKey("support_project"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.8), Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Сегодня в истории — крупнее
                NavigationLink { PersonDetailView(person: featured) } label: {
                    HistoryTodayCard(person: featured)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Поиск по церквям, событиям и личностям
                Button { showSearch = true } label: { UniversalSearchBar() }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .fullScreenCover(isPresented: $showSearch) {
                    UniversalSearchFullScreen(isPresented: $showSearch)
                        .environmentObject(lang)
                        .environment(\.locale, lang.current.locale)
                        .id(showSearch) // force fresh NavigationView each time to avoid re-presentation crash
                }

                // Карта
                NavigationLink { MapScreen() } label: {
                    OutlineTileButton(titleKey: LocalizedStringKey("map"))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Плитка разделов (включая «Все личности»)
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(sections) { section in
                        NavigationLink {
                            CategoryListView(section: section)
                        } label: {
                            OutlineTileButton(titleKey: LocalizedStringKey(section.localizationKey))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                // События
                NavigationLink { EventsScreen() } label: {
                    OutlineTileButton(titleKey: LocalizedStringKey("events"))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Язык (слева квадрат) + Контакты (справа длинная)
                HStack(spacing: 14) {
                    Button {
                        showLanguageSheet = true
                    } label: {
                        // Компактная квадратная кнопка языка
                        Image(systemName: "globe")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 56, height: 56)
                            .background(supportBG)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink { ContactsScreen() } label: {
                        Text(LocalizedStringKey("contacts"))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(supportBG)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.top, 4)
                // Диалог выбора языка
                .confirmationDialog("", isPresented: $showLanguageSheet, actions: {
                    Button("Русский") { lang.current = .ru }
                    Button("English") { lang.current = .en }
                    Button("Հայերեն") { lang.current = .hy }
                })

                Spacer(minLength: 12)
            }
            .padding(.vertical, 8)
        }
        .background(pageBG.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, lang.current.locale)
        .onAppear {
            // Ежедневный выбор: хранится 24 часа
            featured = dailyFeatured()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageChanged)) { _ in
            // Сохраняем того же человека по id, но подтягиваем локализованные поля
            featured = dailyFeatured()
        }
    }
}


// MARK: - Universal Search Sheet (soft sheet with live suggestions)
private struct UniversalSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var people: [Person] = []
    @State private var churches: [Church] = []
    @State private var stories: [Story] = []

    private func filter<T>(_ arr: [T], by predicate: (T) -> Bool) -> [T] { arr.filter(predicate) }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // Search field with purple outline
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField(LocalizedStringKey("search_everything"), text: $query)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.purple.opacity(0.7), lineWidth: 2.5))
                .padding(.horizontal)
                .padding(.top, 8)

                // Suggestions list
                List {
                    if !query.isEmpty {
                        let q = query.lowercased()
                        let peopleFiltered = people.filter { $0.name.lowercased().contains(q) || $0.subtitle.lowercased().contains(q) }
                        let churchesFiltered = churches.filter {
                            $0.name.lowercased().contains(q) || (($0.address ?? "").lowercased().contains(q))
                        }
                        let storiesFiltered = stories.filter { $0.title.lowercased().contains(q) || ($0.summary ?? "").lowercased().contains(q) }

                        if !peopleFiltered.isEmpty {
                            Section(header: Text(LocalizedStringKey("people_section"))) {
                                ForEach(peopleFiltered) { p in
                                    NavigationLink { PersonDetailView(person: p) } label: {
                                        HStack(spacing: 12) {
                                            Image(p.imageName).resizable().scaledToFill().grayscale(1)
                                                .frame(width: 40, height: 40)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(p.name).font(.system(size: 16, weight: .semibold))
                                                Text(p.subtitle).font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if !churchesFiltered.isEmpty {
                            Section(header: Text(LocalizedStringKey("churches_section"))) {
                                ForEach(churchesFiltered) { c in
                                    NavigationLink { ChurchDetailView(church: c) } label: {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(c.name).font(.system(size: 16, weight: .semibold))
                                            if let addr = c.address, !addr.isEmpty {
                                                Text(addr).font(.system(size: 13)).foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if !storiesFiltered.isEmpty {
                            Section(header: Text(LocalizedStringKey("events_section"))) {
                                ForEach(storiesFiltered) { s in
                                    NavigationLink { StoryQuickView(story: s) } label: {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(s.title).font(.system(size: 16, weight: .semibold))
                                            Text(String(s.year)).font(.system(size: 13)).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .animation(.easeInOut(duration: 0.2), value: query)
            }
            .navigationTitle(LocalizedStringKey("search"))
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            people = LocalPeopleStore.load(section: .all)
            churches = ChurchesStore.load()
            stories = StoriesStore.load()
        }
    }
}

// Lightweight quick view for Story (to avoid depending on private StoryDetailView)
private struct StoryQuickView: View {
    let story: Story
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let name = story.imageName, let ui = UIImage(named: name) {
                    Image(uiImage: ui)
                        .resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 220)
                        .clipped().clipShape(RoundedRectangle(cornerRadius: 16))
                }
                Text(story.title).font(.title2.bold())
                Text(String(story.year)).foregroundStyle(.secondary)
                if let summary = story.summary, !summary.isEmpty {
                    Text(summary).font(.body)
                }
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey("event"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Minimal Churches loader (reads the same JSON as map)
private enum ChurchesStore {
    static func load() -> [Church] {
        // Reuse ChurchMapView decoding rules by reading localized churches.json
        guard let url = Bundle.main.url(forResource: "churches", withExtension: "json") else { return [] }
        do {
            let data = try Data(contentsOf: url)
            let dec = JSONDecoder()
            let raw = try dec.decode([DecChurch].self, from: data)
            let items = raw.map { Church(from: $0) }
            return items
        } catch {
            print("[ChurchesStore] decode error:", error)
            return []
        }
    }
}

import MapKit

struct MapScreen: View {
    var body: some View {
        ChurchMapView()
            .navigationTitle(LocalizedStringKey("map"))
            .navigationBarTitleDisplayMode(.inline)
    }
}
struct ContactsScreen: View {
    @Environment(\.openURL) private var openURL

    private let corner: CGFloat = 20
    private let cardStroke = Color.black.opacity(0.12)
    private let primaryGradient = LinearGradient(colors: [Color.purple.opacity(0.9), Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Intro card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Здравствуйте!")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Меня зовут Варданян Арег. Это приложение создано мной по благословению Российской и Ново-Нахичеванской епархии ААЦ. В его основе желание сохранить то, что для меня особенно важно: веру, культуру и память.\n\nЕсли оно оказалось полезным для вас, значит труд был не напрасен.")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("По вопросам сотрудничества, а также для замечаний и пожеланий вы можете связаться со мной по указанным контактам.")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: corner))
                .overlay(RoundedRectangle(cornerRadius: corner).stroke(cardStroke, lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal)

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        if let url = URL(string: "https://t.me/aregvarda") { openURL(url) }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "paperplane.fill")
                            Text("Написать в Telegram")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: corner))
                        .overlay(RoundedRectangle(cornerRadius: corner).stroke(cardStroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button {
                        if let url = URL(string: "mailto:aregvarda@yandex.ru") { openURL(url) }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                            Text("Написать на почту")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: corner))
                        .overlay(RoundedRectangle(cornerRadius: corner).stroke(cardStroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button {
                        if let url = URL(string: "https://www.donationalerts.com/r/hayhuman") { openURL(url) }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "heart.fill")
                            Text(LocalizedStringKey("support_project"))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: corner))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                // Photo at bottom
                VStack(spacing: 8) {
                    Image("areg")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: corner))
                        .overlay(RoundedRectangle(cornerRadius: corner).stroke(cardStroke, lineWidth: 1))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    Text("Арег Варданян")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                .padding(.horizontal)

                Spacer(minLength: 24)
            }
            .padding(.top, 12)
            .padding(.bottom, 72)
        }
        .background(pageBG.ignoresSafeArea())
        .navigationTitle(LocalizedStringKey("contacts"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
struct EventsScreen: View { var body: some View { StoriesView() } }


// MARK: - Universal Search Fullscreen (push)
private struct UniversalSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var people: [Person] = []
    @State private var churches: [Church] = []
    @State private var stories: [Story] = []

    var body: some View {
        VStack(spacing: 12) {
            // Search field with purple outline (fixed on top)
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(LocalizedStringKey("search_everything"), text: $query)
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.purple.opacity(0.7), lineWidth: 2.5))
            .padding(.horizontal)
            .padding(.top, 8)

            // Suggestions list
            List {
                let q = query.lowercased()
                if !q.isEmpty {
                    let peopleFiltered = people.filter { $0.name.lowercased().contains(q) || $0.subtitle.lowercased().contains(q) }
                    let churchesFiltered = churches.filter {
                        $0.name.lowercased().contains(q) || (($0.address ?? "").lowercased().contains(q))
                    }
                    let storiesFiltered = stories.filter { $0.title.lowercased().contains(q) || ($0.summary ?? "").lowercased().contains(q) }

                    if !peopleFiltered.isEmpty {
                        Section(header: Text(LocalizedStringKey("people_section"))) {
                            ForEach(peopleFiltered) { p in
                                NavigationLink { PersonDetailView(person: p) } label: {
                                    HStack(spacing: 12) {
                                        Image(p.imageName).resizable().scaledToFill().grayscale(1)
                                            .frame(width: 40, height: 40)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(p.name).font(.system(size: 16, weight: .semibold))
                                            Text(p.subtitle).font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !churchesFiltered.isEmpty {
                        Section(header: Text(LocalizedStringKey("churches_section"))) {
                            ForEach(churchesFiltered) { c in
                                NavigationLink { ChurchDetailView(church: c) } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(c.name).font(.system(size: 16, weight: .semibold))
                                        if let addr = c.address, !addr.isEmpty {
                                            Text(addr).font(.system(size: 13)).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !storiesFiltered.isEmpty {
                        Section(header: Text(LocalizedStringKey("events_section"))) {
                            ForEach(storiesFiltered) { s in
                                NavigationLink { StoryQuickView(story: s) } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(s.title).font(.system(size: 16, weight: .semibold))
                                        Text(String(s.year)).font(.system(size: 13)).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle(LocalizedStringKey("search"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            people = LocalPeopleStore.load(section: .all)
            churches = ChurchesStore.load()
            stories = StoriesStore.load()
        }
    }
}

// MARK: - Fullscreen presenter (bottom-to-top)
private struct UniversalSearchFullScreen: View {
    @Binding var isPresented: Bool
    var body: some View {
        NavigationView {
            UniversalSearchView()
                .navigationTitle(LocalizedStringKey("search"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { isPresented = false } } }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
