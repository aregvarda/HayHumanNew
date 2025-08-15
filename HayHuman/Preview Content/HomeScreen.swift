import SwiftUI

// MARK: - Palette
private let pageBG      = Color(uiColor: .systemGroupedBackground)
private let borderColor = Color.black.opacity(0.25)
private let supportBG   = Color(uiColor: .systemGray5)

// MARK: - Press / Button helpers
private struct PressableCard: ViewModifier {
    @GestureState private var isPressed = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1)
            .opacity(isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: isPressed)
            .gesture(DragGesture(minimumDistance: 0).updating($isPressed) { _, s, _ in s = true })
    }
}

// MARK: - Today in History card
private struct HistoryTodayCard: View {
    // заглушка: Месроп Маштоц
    var imageName: String = "mesrop"
    var title: String = "Месроп Маштоц"
    var subtitle: String = "Сегодня в истории: создатель армянского алфавита"

    private let side: CGFloat = 84 // высота/ширина фото и максимальная высота текста

    var body: some View {
        HStack(spacing: 12) {
            // Фото слева
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: side, height: side)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 1))

            // Текст справа
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(subtitle)
                    .font(.system(size: 14, weight: .thin, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)                 // не длиннее высоты фото
                    .truncationMode(.tail)
            }
            .frame(height: side, alignment: .top) // ограничиваем высоту блока текстов
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(borderColor, lineWidth: 1))
        .modifier(PressableCard())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
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
            .accessibilityAddTraits(.isButton)
            .modifier(PressableCard())
    }
}

// MARK: - Sections
enum ArmenianSection: CaseIterable, Identifiable {
    case all, culture, military, politics, religion, sport, business, science
    var id: Self { self }
    var title: String {
        switch self {
        case .all:      return "Все личности"
        case .culture:  return "Культура"
        case .military: return "Военное дело"
        case .politics: return "Политика"
        case .religion: return "Религия"
        case .sport:    return "Спорт"
        case .business: return "Бизнес"
        case .science:  return "Наука\nи образование"
        }
    }
}

// MARK: - Screen
struct HomeScreen: View {
    private let columns = [GridItem(.flexible(), spacing: 14),
                           GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Блок «Сегодня в истории» с фото и текстом
                HistoryTodayCard()
                    .padding(.horizontal)
                    .padding(.top, 12)

                // Карта
                NavigationLink { MapScreen() } label: {
                    OutlineTileButton(title: "Карта храмов и святынь")
                }
                .padding(.horizontal)

                // Плитка разделов 2xN
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(ArmenianSection.allCases) { section in
                        NavigationLink { CategoryScreen(section: section) } label: {
                            OutlineTileButton(title: section.title)
                        }
                    }
                }
                .padding(.horizontal)

                // Поддержать проект — серый фон
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
struct MapScreen: View { var body: some View { Text("Здесь будет карта") } }
struct CategoryScreen: View {
    let section: ArmenianSection
    var body: some View { Text(section.title).navigationTitle(section.title) }
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
