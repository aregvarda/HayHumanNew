import SwiftUI
import UIKit

struct CategoryListView: View {
    let section: ArmenianSection
    @State private var people: [Person] = []

    @State private var searchText = ""
    @State private var selectedSection: ArmenianSection

    init(section: ArmenianSection) {
        self.section = section
        _people = State(initialValue: LocalPeopleStore.load(section: .all))
        _selectedSection = State(initialValue: section)
    }

    // Подгрузка людей из локализованных JSON через общий стор
    private func reloadPeople() {
        people = LocalPeopleStore.load(section: .all)
    }

    private func title(for s: ArmenianSection) -> LocalizedStringKey {
        switch s {
        case .all: return "people_all"
        case .culture: return "people_culture"
        case .military: return "people_military"
        case .politics: return "people_politics"
        case .religion: return "people_religion"
        case .sport: return "people_sport"
        case .business: return "people_business"
        case .science: return "people_science"
        }
    }

    private var searchPlaceholder: LocalizedStringKey {
        switch selectedSection {
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
        // by section first
        let base: [Person] = selectedSection == .all ? people : people.filter { $0.section == selectedSection }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let result: [Person]
        if q.isEmpty {
            result = base
        } else {
            result = base.filter {
                $0.name.lowercased().contains(q) ||
                $0.subtitle.lowercased().contains(q)
            }
        }
        return result.sorted { ($0.birthYear ?? Int.max) < ($1.birthYear ?? Int.max) }
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

                // Filter chips by section (below search)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ArmenianSection.allCases, id: \.self) { s in
                            Button {
                                selectedSection = s
                            } label: {
                                Text(title(for: s))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedSection == s ? Color.purple.opacity(0.15) : Color(uiColor: .systemGray6))
                                    .foregroundStyle(.black)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(Color.black.opacity(0.12), lineWidth: selectedSection == s ? 0 : 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, hPadding)
                    .padding(.top, 4)
                }

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
