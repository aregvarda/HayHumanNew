import SwiftUI
import UIKit

struct CategoryListView: View {
    let section: ArmenianSection
    @State private var people: [Person] = []

    @State private var searchText = ""

    init(section: ArmenianSection) {
        self.section = section
        _people = State(initialValue: Self.loadPeople(for: section))
    }

    // Загрузчик JSON + сортировка по году рождения (старшие — выше)
    private static func loadPeople(for section: ArmenianSection) -> [Person] {
        // Удобный сортировщик: неизвестные года (nil) отправляем в конец
        func sortByBirthYearAsc(_ arr: [Person]) -> [Person] {
            arr.sorted { (lhs, rhs) in
                let l = lhs.birthYear ?? Int.max
                let r = rhs.birthYear ?? Int.max
                return l < r
            }
        }

        // .all — собираем из всех секций и сортируем общим списком
        if section == .all {
            let merged = ArmenianSection.allCases
                .filter { $0 != .all }
                .flatMap { loadPeople(for: $0) }  // внутри секции уже отсортированы
            return sortByBirthYearAsc(merged)
        }

        // Имя файла для секции
        let filename: String
        switch section {
        case .culture:  filename = "people_culture"
        case .military: filename = "people_military"
        case .politics: filename = "people_politics"
        case .religion: filename = "people_religion"
        case .sport:    filename = "people_sport"
        case .business: filename = "people_business"
        case .science:  filename = "people_science"
        case .all:      filename = "" // сюда не попадём
        }

        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("❌ Файл \(filename).json не найден в бандле")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Person].self, from: data)
            let sorted = sortByBirthYearAsc(decoded)
            print("✅ Загружено \(sorted.count) записей из \(filename).json (отсортировано по году)")
            return sorted
        } catch {
            print("❌ Ошибка парсинга \(filename).json: \(error)")
            if let text = String(data: (try? Data(contentsOf: url)) ?? Data(), encoding: .utf8) {
                print("—— Содержимое \(filename).json ——\n\(text)\n—— конец ——")
            }
            return []
        }
    }

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

            // Заголовок внизу
            Text(person.overlayTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 6)
                .padding(.bottom, 14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
}
