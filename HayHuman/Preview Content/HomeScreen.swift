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

struct HomeScreen: View {
    private let columns = [GridItem(.flexible(), spacing: 14),
                           GridItem(.flexible(), spacing: 14)]
    
    @EnvironmentObject private var lang: LanguageManager
    @State private var showLanguageSheet = false

    // «Сегодняшний» — берём первого из локальных JSON, иначе заглушка
    private var featured: Person {
        LocalPeopleStore.loadAll().first
        ?? Person(
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
    }


    // Порядок разделов с «Все личности» в начале
    private var sections: [ArmenianSection] {
        ArmenianSection.allCases
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

                // Язык (слева квадрат) + Контакты (справа длинная)
                HStack(spacing: 14) {
                    Button {
                        showLanguageSheet = true
                    } label: {
                        // Компактная квадратная кнопка языка
                        Text(LocalizedStringKey("language"))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(width: 120, height: 56) // квадратная по сути
                            .background(supportBG)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
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
struct ContactsScreen: View { var body: some View { Text(LocalizedStringKey("contacts")).padding() } }
