import SwiftUI

// Палитра
private let pageBG      = Color(uiColor: .systemGroupedBackground)
private let borderColor = Color.black.opacity(0.15)
private let supportBG   = Color(uiColor: .systemGray5)

// Универсальная плитка-кнопка
private struct OutlineTileButton: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 100)
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
    private let cardHeight: CGFloat = 148
    private let imageSide: CGFloat = 96
    private let corner: CGFloat = 22

    var body: some View {
        HStack(spacing: 14) {
            Image(person.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: imageSide, height: imageSide)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 6) {
                Text("Сегодня в истории")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .layoutPriority(1)

                Text(person.name)
                    .font(.system(size: 24, weight: .bold))   // << bold
                    .lineLimit(1)
                    .allowsTightening(false)
                    .layoutPriority(2)                         // << не даём сжимать

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
                .stroke(Color.black.opacity(0.15), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: corner))
    }
}

struct HomeScreen: View {
    private let columns = [GridItem(.flexible(), spacing: 14),
                           GridItem(.flexible(), spacing: 14)]

    // «Сегодняшний» — как заглушка берём первого из моков
    private var featured: Person {
        mockPeople.first ?? Person(name: "Месроп Маштоц",
                                   subtitle: "Создатель армянского алфавита",
                                   section: .science,
                                   imageName: "mesrop")
    }

    // Фильтрация людей по разделу
    private func people(for section: ArmenianSection) -> [Person] {
        section == .all ? mockPeople : mockPeople.filter { $0.section == section }
    }

    // Порядок разделов с «Все личности» в начале
    private var sections: [ArmenianSection] {
        ArmenianSection.allCases
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Поддержать проект (сверху)
                NavigationLink { SupportScreen() } label: {
                    Text("Поддержать проект")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(supportBG)
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
                    OutlineTileButton(title: "Карта храмов и святынь")
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Плитка разделов (включая «Все личности»)
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(sections) { section in
                        NavigationLink {
                            CategoryListView(section: section,
                                             people: people(for: section))
                        } label: {
                            OutlineTileButton(title: section.rawValue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                // Контакты (снизу)
                NavigationLink { ContactsScreen() } label: {
                    Text("Контакты")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(supportBG)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.top, 4)

                Spacer(minLength: 12)
            }
            .padding(.vertical, 8)
        }
        .background(pageBG.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Заглушки
struct MapScreen: View { var body: some View { Text("Здесь будет карта").padding() } }
struct SupportScreen: View { var body: some View { Text("Экран доната (заглушка)").padding() } }
struct ContactsScreen: View { var body: some View { Text("Контакты проекта (заглушка)").padding() } }
