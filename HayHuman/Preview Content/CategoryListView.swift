import SwiftUI

struct CategoryListView: View {
    let section: ArmenianSection
    let people: [Person]

    @State private var searchText = ""

    // Плейсхолдер для поиска
    private var searchPlaceholder: String {
        switch section {
        case .all:      return "Поиск по всем личностям"
        case .culture:  return "Поиск по культуре"
        case .military: return "Поиск по военному делу"
        case .politics: return "Поиск по политике"
        case .religion: return "Поиск по религии"
        case .sport:    return "Поиск по спорту"
        case .business: return "Поиск по бизнесу"
        case .science:  return "Поиск по науке и образованию"
        }
    }

    // Фильтр
    private var filtered: [Person] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return people }
        return people.filter {
            $0.name.lowercased().contains(q) ||
            $0.subtitle.lowercased().contains(q)
        }
    }

    // Лейаут
    private let hPadding: CGFloat = 20
    private let vSpacing: CGFloat = 16
    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: vSpacing),
         GridItem(.flexible(), spacing: vSpacing)]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: vSpacing) {

                // Поиск
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

                // Сетка
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
    }
}

// Карточка-фото
private struct PersonPhotoTile: View {
    let person: Person

    var body: some View {
        ZStack(alignment: .bottom) {
            Image(person.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    // лёгкое затемнение
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.black.opacity(0.18))
                )

            // Текст по центру по горизонтали, снизу
            Text(person.overlayTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 6)
                .padding(.bottom, 14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
}
