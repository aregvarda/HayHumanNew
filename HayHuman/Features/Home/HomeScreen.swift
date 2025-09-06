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
import UserNotifications

// File-level helper so it is visible from debug functions too
fileprivate func hhStableEventID(title: String, year: Int) -> Int {
    let key = "\(title.lowercased())|\(year)"
    var hash: UInt64 = 0xcbf29ce484222325
    let prime: UInt64 = 0x00000100000001B3
    for b in key.utf8 { hash ^= UInt64(b); hash &*= prime }
    return Int(truncatingIfNeeded: hash)
}

// Палитра
private let pageBG      = Color.white
private let borderColor = Color.black.opacity(0.15)
private let supportBG   = Color(uiColor: .systemGray5)

// Measure view height via preference
private struct SearchHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 64
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

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
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.purple.opacity(0.65), lineWidth: 2.5)
        )
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
        .accessibilityLabel(LocalizedStringKey("search_everything"))
    }
}

// Placeholder passport screen (to be implemented later)
struct PilgrimPassportView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "book.and.wrench")
                    .font(.system(size: 48, weight: .bold))
                    .padding(8)
                Text("Pilgrim Passport")
                    .font(.title2.bold())
                Text("Your visits, stamps and achievements will appear here.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        }
        .background(pageBG.ignoresSafeArea())
        .navigationTitle(Text("pilgrim_passport"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Big card for Passport preview
private struct PassportCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                // Left side: two-line title
                VStack(alignment: .leading, spacing: 0) {
                    Text(NSLocalizedString("passport_word", tableName: "Localizable", bundle: .main, value: "Паспорт", comment: ""))
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                    Text(NSLocalizedString("pilgrim_genitive", tableName: "Localizable", bundle: .main, value: "паломника", comment: ""))
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right side: large rounded image (no background square)
                Image("pasport")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
            }

            HStack(spacing: 12) {
                Label("0 visits", systemImage: "mappin.and.ellipse")
                Label("0 stamps", systemImage: "seal")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(borderColor, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}

// Neutral monochrome tile (Yandex-like)
private struct NeutralTileButton: View {
    let titleKey: LocalizedStringKey
    let systemIcon: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemIcon)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24, height: 24)
            Text(titleKey)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

// Icon-only neutral tile (for grid with captions below)
private struct NeutralTileIconButton: View {
    let systemIcon: String
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Image(systemName: systemIcon)
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(alignment: .trailing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

// Icon-only neutral tile using asset image (for custom logos)
private struct NeutralTileAssetIconButton: View {
    let assetName: String
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ZStack {
                Color.clear
                // Equalize perceived size across different logo assets
                let iconSize: CGFloat = (assetName == "people logo") ? 48 : 56
                Image(assetName)
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .antialiased(true)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(width: 64, height: 64)
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(alignment: .trailing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct HomeScreen: View {
    private let columns = [GridItem(.flexible(), spacing: 14),
                           GridItem(.flexible(), spacing: 14)]
    
    @EnvironmentObject private var lang: LanguageManager
    @State private var showLanguageSheet = false
    @State private var showSearch = false

    @State private var searchHeightMeasured: CGFloat = 64

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

    // Placeholder story for deep link navigation
    private let placeholderStory = Story(id: "placeholder", title: "-", year: 0, imageName: nil, summary: nil, tags: [])

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
        let all = LocalPeopleStore.load(section: .all)
        if let savedDate = defaults.string(forKey: "featuredDate"),
           savedDate == keyToday,
           let savedId = defaults.string(forKey: "featuredId"),
           let found = all.first(where: { $0.imageName == savedId }) {
            return found
        }
        // Pick new and persist
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

    // Stable event ID (deterministic): FNV-1a 64-bit of "title|year"
    private func stableEventID(title: String, year: Int) -> Int {
        let key = "\(title.lowercased())|\(year)"
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x00000100000001B3
        for b in key.utf8 { hash ^= UInt64(b); hash &*= prime }
        return Int(truncatingIfNeeded: hash)
    }

    // MARK: - Start 3-day person reminders
    private func startPersonReminders() {
        // Only provide persons, clear events provider
        RandomReminderManager.getPersons = { LocalPeopleStore.allPeopleLite() }
        RandomReminderManager.getEvents  = { [] }
        // Планируем основную серию: каждые 3 дня, первый пуш ~через минуту
        let now = Date()
        let cal = Calendar.current
        let hour = cal.component(.hour, from: now)
        let minute = (cal.component(.minute, from: now) + 1) % 60
        RandomReminderManager.scheduleSeries(days: 90, hour: hour, minute: minute)

    }

    // MARK: - Start 3-day event reminders
    private func startEventReminders() {
        // Only provide events, clear persons provider
        RandomReminderManager.getPersons = { [] }
        RandomReminderManager.getEvents = {
            let stories = StoriesStore.load()
            return stories.map { s in
                EventLite(id: hhStableEventID(title: s.title, year: s.year), title: s.title)
            }
        }
        let now = Date()
        let cal = Calendar.current
        let hour = cal.component(.hour, from: now)
        let minute = (cal.component(.minute, from: now) + 1) % 60
        RandomReminderManager.scheduleSeries(days: 90, hour: hour, minute: minute)
    }

    var body: some View {
        GeometryReader { viewport in
            ScrollView {
                VStack(spacing: 16) {
                    // Top spacer — centers content vertically within the viewport
                    Spacer()
                    Spacer().frame(height: viewport.size.height * 0.08)

                // Search centered between top and bottom spacers
                // Brand header (Inter)
                VStack(alignment: .leading, spacing: 6) {
                    Text("HayHuman")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .fontWeight(.bold)
                        .kerning(0.5)
                        .foregroundStyle(.black)
                    Text(NSLocalizedString("hayhuman_tagline", tableName: "Localizable", bundle: .main, value: "История армян в одном приложении", comment: ""))
                        .font(.system(size: 19, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                HStack {
                    Spacer(minLength: 0)
                    Button { showSearch = true } label: { UniversalSearchBar() }
                        .buttonStyle(.plain)
                        .fullScreenCover(isPresented: $showSearch) {
                            UniversalSearchFullScreen(isPresented: $showSearch)
                                .environmentObject(lang)
                                .environment(\.locale, lang.current.locale)
                                .id(showSearch)
                        }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: SearchHeightKey.self, value: proxy.size.height)
                    }
                )
                .onPreferenceChange(SearchHeightKey.self) { h in
                    searchHeightMeasured = h
                }

                    // Passport card directly under search
                    NavigationLink { PilgrimPassportView() } label: { PassportCard() }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                    // Bottom tiles with captions below (icon-only tiles + text under)
                    HStack(spacing: 14) {
                        VStack(spacing: 8) {
                            NavigationLink { CategoryListView(section: .all) } label: {
                                NeutralTileAssetIconButton(assetName: "people logo")
                            }.buttonStyle(.plain)
                            Text(LocalizedStringKey("all_people"))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 8) {
                            NavigationLink { EventsScreen() } label: {
                                NeutralTileAssetIconButton(assetName: "stories logo")
                            }.buttonStyle(.plain)
                            Text(LocalizedStringKey("events"))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 8) {
                            NavigationLink { MapScreen() } label: {
                                NeutralTileAssetIconButton(assetName: "map logo")
                            }.buttonStyle(.plain)
                            Text(LocalizedStringKey("map"))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                // Fill the viewport so Spacers truly center the search block
                .frame(minHeight: viewport.size.height)
            }
        }
        .background(pageBG.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { showLanguageSheet = true } label: {
                    let code: String = {
                        switch lang.current {
                        case .ru: return "RU"
                        case .en: return "EN"
                        case .hy: return "AM"
                        }
                    }()
                    Text(code)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("change_language"))
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    if let url = URL(string: "https://www.donationalerts.com/r/hayhuman") { UIApplication.shared.open(url) }
                } label: {
                    Text(LocalizedStringKey("Поддержать"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                NavigationLink { ContactsScreen() } label: {
                    Image(systemName: "info")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
        }
        .confirmationDialog("", isPresented: $showLanguageSheet, actions: {
            Button("Русский") { lang.current = .ru }
            Button("English") { lang.current = .en }
            Button("Հայերեն") { lang.current = .hy }
        })
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, lang.current.locale)
        .task {
            // Ежедневный выбор: безопасно обновляем состояние после монтирования вью
            let f = dailyFeatured()
            featured = f
        }
        .task(id: lang.current.locale.identifier) {
            let f = dailyFeatured()
            featured = f
        }
    }
}


#if DEBUG
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeScreen()
                .environmentObject(LanguageManager())
        }
        .previewDisplayName("Home")
    }
}

struct PassportCard_Previews: PreviewProvider {
    static var previews: some View {
        PassportCard()
            .padding()
            .background(Color.white)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Passport Card")
    }
}
#endif



// MARK: - Universal Search Sheet (soft sheet with live suggestions)
private struct UniversalSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var people: [Person] = []
    @State private var churches: [Church] = []
    @State private var stories: [Story] = []
    @FocusState private var isSearchFocused_sheet: Bool

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
                        .focused($isSearchFocused_sheet)
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
            .onAppear { isSearchFocused_sheet = true }
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
                    Text("Меня зовут Варданян Арег. Я являюсь руководителем международной IT-компании Websiberia, специализирующейся на создании современных цифровых решений, приложений и платформ для бизнеса и общественных проектов.\n\nЭтот проект создан мной по благословению Главы Российской и Ново-Нахичеванской епархии ААЦ, Архиепископа Езраса Нерсисяна. В его основе желание сохранить то, что для меня особенно важно: веру, культуру и память.\n\nЕсли оно оказалось полезным для вас, значит труд был не напрасен.")
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
                Button {
                    if let url = URL(string: "https://websiberia.com/") { openURL(url) }
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        Image("websiberia")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: corner))
                            .overlay(RoundedRectangle(cornerRadius: corner).stroke(cardStroke, lineWidth: 1))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)

                        // Bottom gradient strip to indicate interactivity
                        LinearGradient(
                            colors: [Color.black.opacity(0.0), Color.black.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: corner))

                        // Button-like caption
                        HStack(spacing: 8) {
                            Image(systemName: "safari.fill")
                            Text("Открыть websiberia.com")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .padding(.leading, 14)
                        .padding(.bottom, 12)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: corner))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Открыть websiberia.com")
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
    @State private var debouncedQuery: String = ""
    @State private var people: [Person] = []
    @State private var churches: [Church] = []
    @State private var stories: [Story] = []
    @FocusState private var isSearchFocused_full: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Search field with purple outline (fixed on top)
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(LocalizedStringKey("search_everything"), text: $query)
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isSearchFocused_full)
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
                let q = debouncedQuery
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
            .onChange(of: query) { _, newValue in
                let value = newValue.lowercased()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    if value == query.lowercased() { debouncedQuery = value }
                }
            }
        }
        .navigationTitle(LocalizedStringKey("search"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            people = LocalPeopleStore.load(section: .all)
            churches = ChurchesStore.load()
            stories = StoriesStore.load()
            isSearchFocused_full = true
            debouncedQuery = ""
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

#if DEBUG
private func debugPersonOnce() {
    let people = LocalPeopleStore.allPeopleLite()
    guard let pl = people.randomElement() else { return }
    let content = UNMutableNotificationContent()
    content.title = "HayHuman"
    content.body  = "5 минут истории: кто такой \(pl.name)?"
    content.sound = .default
    let deeplink = "hayhuman://person/\(pl.id)"
    content.userInfo = ["deeplink": deeplink]
    print("[DEBUG] scheduling person deeplink:", deeplink)
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "debug.person.once", content: content, trigger: trigger))
}

private func debugEventOnce() {
    let stories = StoriesStore.load()
    guard !stories.isEmpty else { return }
    let index = Int.random(in: 0..<stories.count)
    let st = stories[index]
    let content = UNMutableNotificationContent()
    content.title = "HayHuman"
    content.body  = "История на вечер: \(st.title)"
    content.sound = .default
    let eid = hhStableEventID(title: st.title, year: st.year)
    let deeplink = "hayhuman://event/\(eid)"
    content.userInfo = ["deeplink": deeplink]
    print("[DEBUG] scheduling event deeplink:", deeplink)
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "debug.event.once", content: content, trigger: trigger))
}
#endif

