import SwiftUI
import UIKit

struct CategoryListView: View {
    let section: ArmenianSection
    @State private var people: [Person] = []

    @State private var searchText = ""

    init(section: ArmenianSection) {
        self.section = section
        _people = State(initialValue: LocalPeopleStore.load(section: section))
    }

    // Подгрузка людей из локализованных JSON через общий стор
    private func reloadPeople() {
        people = LocalPeopleStore.load(section: section)
    }

    private var searchPlaceholder: LocalizedStringKey {
        switch section {
        case .all:      return "search_all"
        case .culture:  return "search_culture"
        case .military: return "search_military"
        case .politics: return "search_politics"
        case .religion: return "search_religion"
        case .sport:    return "search_sport"
        case .business: return "search_business"
        case .science:  return "search_science"
        }
    }

    private var filtered: [Person] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return people.sorted { ($0.birthYear ?? Int.max) < ($1.birthYear ?? Int.max) } }
        return people
            .filter {
                $0.name.lowercased().contains(q) ||
                $0.subtitle.lowercased().contains(q)
            }
            .sorted { ($0.birthYear ?? Int.max) < ($1.birthYear ?? Int.max) }
    }

    private let hPadding: CGFloat = 20
    private let vSpacing: CGFloat = 16
    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: vSpacing),
         GridItem(.flexible(), spacing: vSpacing)]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: vSpacing) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(searchPlaceholder, text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color(uiColor: .systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, hPadding)
                .padding(.top, 8)

                LazyVGrid(columns: columns, alignment: .center, spacing: vSpacing) {
                    ForEach(filtered) { person in
                        NavigationLink {
                            PersonDetailView(person: person)
                        } label: {
                            PersonPhotoTile(person: person)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, hPadding)
                .padding(.vertical, 12)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            reloadPeople()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageChanged)) { _ in
            reloadPeople()
        }
    }
}

private struct PersonPhotoTile: View {
    let person: Person

    // Проверяем, есть ли ассет с таким именем
    private var hasImage: Bool {
        UIImage(named: person.imageName, in: .main, with: nil) != nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if hasImage {
                    Image(person.imageName)
                        .resizable()
                        .scaledToFill()
                        .grayscale(1.0)
                } else {
                    // Фолбэк: чёрный квадрат, если изображения нет
                    Rectangle()
                        .fill(Color.black)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                // Лёгкое затемнение только для фото, для фолбэка не нужно
                RoundedRectangle(cornerRadius: 22)
                    .fill(hasImage ? Color.black.opacity(0.18) : Color.clear)
            )

            // Заголовок внизу (нормализованная типографика)
            Text(person.name)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)                 // до двух строк
                .minimumScaleFactor(0.85)     // лёгкое сжатие, но без «каши» размеров
                .allowsTightening(true)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .shadow(radius: 6)
                .frame(height: 58, alignment: .bottom) // одинаковый блок под заголовок у всех карточек
                .padding(.bottom, 12)
        }
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
}
