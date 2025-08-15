import SwiftUI

// MARK: - Palette
private let pageBG      = Color(uiColor: .systemGroupedBackground)
private let borderColor = Color.black.opacity(0.25)
private let supportBG   = Color(uiColor: .systemGray5)

// MARK: - Today in History
private struct HistoryTodayCard: View {
    let person: Person
    let imageName: String    // имя картинки в Assets (1:1)

    private let side: CGFloat = 126

    var body: some View {
        HStack(spacing: 14) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: side, height: side)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderColor, lineWidth: 1))

            VStack(alignment: .leading, spacing: 6) {
                // Заголовок карточки
                Text("Сегодня в истории")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Имя персоналии
                Text(person.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Короткое пояснение
                Text(person.subtitle)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            .frame(height: side, alignment: .topLeading)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(borderColor, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Сегодня в истории. \(person.name). \(person.subtitle)")
    }
}

// MARK: - Reusable tile
private struct OutlineTileButton: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .lineSpacing(2)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(borderColor, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Screen
struct HomeScreen: View {
    private let columns = [GridItem(.flexible(), spacing: 14),
                           GridItem(.flexible(), spacing: 14)]

    private let featured = Person(
        name: "Месроп Маштоц",
        subtitle: "создатель армянского алфавита",
        section: .science
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Поддержать проект (сверху)
                NavigationLink { SupportScreen() } label: {
                    Text("Поддержать проект")
                        .font(.system(size: 18, weight: .thin, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(supportBG)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.top, 8)

                // Сегодня в истории
                NavigationLink {
                    PersonDetailView(person: featured)
                } label: {
                    HistoryTodayCard(person: featured, imageName: "mesrop")
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Карта
                NavigationLink { MapScreen() } label: {
                    OutlineTileButton(title: "Карта храмов и святынь")
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Плитка разделов 2xN
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(ArmenianSection.allCases) { section in
                        NavigationLink { CategoryListView(section: section) } label: {
                            OutlineTileButton(title: section.title)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                // Контакты (внизу)
                NavigationLink { ContactsScreen() } label: {
                    Text("Контакты")
                        .font(.system(size: 18, weight: .thin, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(supportBG)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.top, 4)

                Spacer(minLength: 12)
            }
            .padding(.bottom, 24)
        }
        .background(pageBG.ignoresSafeArea())
    }
}

// MARK: - Stubs
struct MapScreen: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Карта храмов и святынь")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text("Здесь появится интерактивная карта с точками и кластерами.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .padding(.top, 24)
    }
}

struct SupportScreen: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Поддержать проект").font(.title2).bold()
            Text("Здесь появятся варианты пожертвований.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct ContactsScreen: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Контакты").font(.title2).bold()
            Text("Здесь будут контактные данные проекта.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
