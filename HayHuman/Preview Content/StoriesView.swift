import SwiftUI
import MapKit

// MARK: - Model
struct Story: Identifiable, Decodable, Hashable {
    let id: String
    let title: String
    let year: Int
    let imageName: String?
    let summary: String?
    let tags: [String]?
}

// MARK: - Store
enum StoriesStore {
    static func load() -> [Story] {
        do {
            // stories.json должен быть локализован (Base / en / ru / hy)
            // Используем LocalizedJSON, если он есть в проекте; иначе падаем на Base
            if let _ = NSClassFromString("LocalizedJSON") {
                // Пытаемся динамически вызвать наш удобный загрузчик, если присутствует
                // Но на всякий случай оставим прямой путь через Bundle
            }

            // Подтягиваем локализованный stories.json c помощью API Bundle
            let filename = "stories"
            let codes: [String] = {
                // Попробуем сначала язык приложения (как у людей/церквей)
                var arr: [String] = []
                if let saved = UserDefaults.standard.string(forKey: "appLanguage"), !saved.isEmpty {
                    arr.append(saved)
                }
                // Затем системные предпочтения
                arr.append(contentsOf: Bundle.main.preferredLocalizations)
                // Добавим явные
                for c in ["en","ru","hy"] where !arr.contains(c) { arr.append(c) }
                return arr
            }()

            var data: Data?
            var used: String = "Base"
            for code in codes {
                if let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: nil, localization: code) {
                    data = try? Data(contentsOf: url)
                    used = code
                    break
                }
            }
            if data == nil, let url = Bundle.main.url(forResource: filename, withExtension: "json") {
                data = try? Data(contentsOf: url)
                used = "Base"
            }
            guard let data else { return [] }
            let decoded = try JSONDecoder().decode([Story].self, from: data)
            print("[Stories] Loaded stories.json from \(used).lproj/Base")
            return decoded
        } catch {
            print("[Stories] Decode error:", error)
            return []
        }
    }
}

// MARK: - View
struct StoriesView: View {
    enum SortMode: String, CaseIterable, Identifiable { case oldestFirst, newestFirst; var id: Self { self } }

    @State private var stories: [Story] = []
    @State private var sortMode: SortMode = .oldestFirst
    @State private var searchText: String = ""
    @State private var showingSortMenu: Bool = false

    private var sortedStories: [Story] {
        var filtered = stories
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        switch sortMode {
        case .oldestFirst:
            return filtered.sorted { $0.year < $1.year }
        case .newestFirst:
            return filtered.sorted { $0.year > $1.year }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    HStack(spacing: 8) {
                        TextField("Поиск событий", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 20))
                            .padding(.vertical, 12)
                            .padding(.leading, 14)
                            .padding(.trailing, 8) // space from button

                        Button {
                            withAnimation(.snappy(duration: 0.2)) {
                                sortMode = (sortMode == .oldestFirst) ? .newestFirst : .oldestFirst
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.subheadline.weight(.semibold))
                                .padding(10)
                                .foregroundStyle(.primary)
                                .background(
                                    Circle().fill(Color(uiColor: .tertiarySystemFill))
                                )
                                .overlay(
                                    Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                )
                                .rotationEffect(.degrees(sortMode == .newestFirst ? 180 : 0))
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 6)
                    }
                    .frame(height: 60)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )
                }
                .padding(.top, 6)

                // Карточки событий
                GeometryReader { proxy in
                    let contentWidth = max(proxy.size.width, 0)
                    LazyVStack(spacing: 14) {
                        ForEach(sortedStories) { story in
                            NavigationLink {
                                StoryDetailView(story: story, allStories: sortedStories)
                            } label: {
                                StoryCard(story: story)
                                    .frame(width: contentWidth)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("События")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            stories = StoriesStore.load()
        }
    }
}

// MARK: - Story Card
private struct StoryCard: View {
    let story: Story

    var body: some View {
        ZStack {
            // Бекграунд: арт или плейсхолдер
            ZStack {
                Group {
                    if let name = story.imageName, let ui = UIImage(named: name) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .saturation(0)
                            .contrast(1.05)
                            .brightness(-0.05)
                    } else {
                        LinearGradient(colors: [Color.black.opacity(0.25), Color.black.opacity(0.05)],
                                        startPoint: .top, endPoint: .bottom)
                            .overlay(
                                Image(systemName: "book.pages")
                                    .font(.system(size: 44, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.5))
                            )
                    }
                }

                // Общий мягкий затемняющий слой
                Rectangle().fill(Color.black.opacity(0.25))

                // Градиент для читаемости текста
                LinearGradient(colors: [.clear, .black.opacity(0.65)],
                               startPoint: .center, endPoint: .bottom)
            }
            .padding(1)
        }
        .compositingGroup()
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            Text("\(story.year)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(radius: 1)
                .padding(.top, 12)
                .padding(.leading, 14)
        }
        .overlay(alignment: .bottomLeading) {
            Text(story.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(radius: 2)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Detail Stub
private struct StoryDetailView: View {
    let allStories: [Story]
    @State private var current: Story
    init(story: Story, allStories: [Story]) {
        self._current = State(initialValue: story)
        self.allStories = allStories
    }

    private var index: Int? { allStories.firstIndex(of: current) }
    private var previousStory: Story? {
        guard let i = index, allStories.count > 1 else { return nil }
        return (i > 0) ? allStories[i - 1] : allStories.last
    }
    private var nextStory: Story? {
        guard let i = index, allStories.count > 1 else { return nil }
        return (i < allStories.count - 1) ? allStories[i + 1] : allStories.first
    }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = max(proxy.size.width - 32, 0) // 16pt поля слева и справа
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Image
                    if let name = current.imageName, let ui = UIImage(named: name) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: contentWidth, height: 240)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(alignment: .topLeading) {
                                Text("\(current.year)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .padding(.top, 12)
                                    .padding(.leading, 12)
                            }
                    }

                    // Title
                    Text(current.title)
                        .font(.title2.bold())
                        .frame(width: contentWidth, alignment: .leading)

                    // Summary
                    if let summary = current.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: contentWidth, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Prev / Next (aligned to contentWidth with rounded background)
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)

                        HStack(spacing: 12) {
                            if let prev = previousStory {
                                Button { current = prev } label: {
                                    StoryMiniCard(story: prev)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 110)
                                }
                            } else {
                                StoryMiniCardPlaceholder(title: "–")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 110)
                                    .opacity(0.35)
                            }

                            if let next = nextStory {
                                Button { current = next } label: {
                                    StoryMiniCard(story: next)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 110)
                                }
                            } else {
                                StoryMiniCardPlaceholder(title: "–")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 110)
                                    .opacity(0.35)
                            }
                        }
                        .padding(12)
                    }
                    .frame(width: contentWidth)

                    // Support button
                    Button {
                        if let url = URL(string: "https://www.donationalerts.com/r/hayhuman") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill").foregroundColor(.white)
                            Text(LocalizedStringKey("support_project"))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color.purple.opacity(0.8), Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .frame(width: contentWidth)
                    .padding(.top, 8)

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Событие")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StoryMiniCard: View {
    let story: Story
    var body: some View {
        ZStack {
            ZStack {
                if let name = story.imageName, let ui = UIImage(named: name) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .saturation(0)
                        .brightness(-0.05)
                } else {
                    Color.black.opacity(0.1)
                }
                LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
            }
            .clipped()

            // year
            VStack { HStack {
                Text("\(story.year)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(radius: 1)
                Spacer() }
                Spacer() }
                .padding(.top, 8)
                .padding(.horizontal, 10)

            // title
            VStack {
                Spacer()
                Text(story.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .shadow(radius: 1)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct StoryMiniCardPlaceholder: View {
    let title: String
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.secondary.opacity(0.08))
            .frame(height: 110)
    }
}

//#Preview {
//    NavigationStack {
//        StoriesView()
//    }
//}
