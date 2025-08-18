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

        // Имя файла для секции (без суффиксов языка!)
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

        // ВАЖНО: не добавляем .en/.ru/.hy. iOS сама выберет локализованный ресурс
        // из соответствующей *.lproj (English.lproj, Russian.lproj, Armenian.lproj, Base.lproj).
        // Достаточно запросить файл по базовому имени.
        let url = Bundle.main.url(forResource: filename, withExtension: "json")

        guard let url else {
            // Попробуем явный Base как запасной вариант (на случай нестандартной структуры)
            let baseURL = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Base.lproj")
            guard let baseURL else {
                print("❌ Не найден локализованный JSON \(filename).json ни в текущей локали, ни в Base.lproj")
                print("ℹ️ Доступные локали бандла: \(Bundle.main.localizations)")
                return []
            }
            do {
                let data = try Data(contentsOf: baseURL)
                let decoded = try JSONDecoder().decode([Person].self, from: data)
                return sortByBirthYearAsc(decoded)
            } catch {
                print("❌ Ошибка парсинга Base \(filename).json: \(error)")
                return []
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Person].self, from: data)
            let sorted = sortByBirthYearAsc(decoded)
            print("✅ Загружено \(sorted.count) персон из \(filename).json (локализованный ресурс)")
            return sorted
        } catch {
            print("❌ Ошибка парсинга локализованного \(filename).json: \(error)")
            if let text = String(data: (try? Data(contentsOf: url)) ?? Data(), encoding: .utf8) {
                print("—— Содержимое \(filename).json ——\n\(text)\n—— конец ——")
            }
            return []
        }
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

            // Заголовок внизу (авто‑уменьшение, если не влезает)
            Text(person.overlayTitle)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)   // сжимать до 50% от размера
                .allowsTightening(true)
                .padding(.horizontal, 10)
                .shadow(radius: 6)
                .padding(.bottom, 14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
}
