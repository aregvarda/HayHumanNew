import SwiftUI
import CoreLocation
import MapKit

struct ChurchListView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var churches: [Church]
    @ObservedObject var locationManager: HHLocationManager

    @State private var searchText: String = ""
    @State private var searchDebounced: String = ""
    @State private var searchTimer: Timer? = nil
    @State private var focusWorkItem: DispatchWorkItem? = nil
    @FocusState private var isSearchFocused: Bool
    @State private var filter: ChurchFilter = .all
    @State private var nearMeOn: Bool = false
    @State private var withPhotoOn: Bool = false
    @State private var selectedCountry: String? = nil
    @State private var sortMode: SortMode = .name
    @State private var showFiltersSheet = false
    @State private var showCountrySheet = false

    @State private var showBottomMiniMap = false
    @State private var previewRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.0, longitude: 45.0), span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15))
    @SceneStorage("HHNav.popToMap") private var popToMap: Bool = false

    private let nearMeRadius: CLLocationDistance = 25_000 // 25 km

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    // Mini map header with sticky measurement
                    ZStack {
                        Map(coordinateRegion: $previewRegion)
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .background(
                                GeometryReader { proxy in
                                    Color.clear.preference(key: TopMapMaxYKey.self,
                                                           value: proxy.frame(in: .named("listScroll")).maxY)
                                }
                            )
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "map")
                                Text("На карте")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                    .truncationMode(.tail)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    LazyVStack(spacing: 16) {
                        ForEach(listFilteredChurchesUnique, id: \.id) { church in
                            NavigationLink {
                                ChurchDetailView(church: church)
                            } label: {
                                ChurchCardView(church: church)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 80) // leave space for floating button
                }
                .coordinateSpace(name: "listScroll")
                .onPreferenceChange(TopMapMaxYKey.self) { maxY in
                    showBottomMiniMap = maxY < 100
                }
                .onChange(of: popToMap) { newValue in
                    if newValue {
                        popToMap = false
                        dismiss()
                    }
                }
                .overlay(alignment: .bottom) {
                    if showBottomMiniMap {
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "map")
                                Text("На карте")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                    .truncationMode(.tail)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 8) {
                    // Back + Search + Filters
                    HStack(spacing: 10) {
                        Button(action: {
                            // Safely cancel focus/timers before dismissing to avoid crash
                            isSearchFocused = false
                            focusWorkItem?.cancel(); focusWorkItem = nil
                            searchTimer?.invalidate(); searchTimer = nil
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color(.systemGray5)))
                        }
                        .buttonStyle(.plain)

                        ZStack(alignment: .trailing) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                                TextField("Поиск по церквям", text: $searchText)
                                    .focused($isSearchFocused)
                                    .textFieldStyle(.plain)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .padding(.vertical, 6)
                                    .onChange(of: searchText) { newValue in
                                        searchTimer?.invalidate()
                                        let t = Timer(timeInterval: 0.25, repeats: false) { _ in
                                            searchDebounced = newValue
                                        }
                                        RunLoop.main.add(t, forMode: .common)
                                        searchTimer = t
                                    }
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            Button(action: { showFiltersSheet = true }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(width: 34, height: 34)
                                    .background(Circle().fill(Color(.systemGray5)))
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 6)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Countries chips row (now floating)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button { selectedCountry = nil } label: {
                                Text("all_countries")
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1).minimumScaleFactor(0.8).truncationMode(.tail)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(selectedCountry == nil ? Color.purple.opacity(0.15) : Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            ForEach(topCountries, id: \.self) { c in
                                Button { selectedCountry = c } label: {
                                    Text(c)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1).minimumScaleFactor(0.8).truncationMode(.tail)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(selectedCountry == c ? Color.purple.opacity(0.15) : Color(.systemGray6))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }

                            Button { showCountrySheet = true } label: {
                                HStack(spacing: 6) { Image(systemName: "ellipsis"); Text("more").lineLimit(1).minimumScaleFactor(0.8).truncationMode(.tail) }
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 2)
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(.regularMaterial)
                .zIndex(2)
            }
            .sheet(isPresented: $showFiltersSheet) { filtersSheet }
            .sheet(isPresented: $showCountrySheet) { countrySheet }
            .onAppear {
                if let first = churches.first { previewRegion.center = first.coordinate }
                // Не фокусируем поиск автоматически при открытии
                isSearchFocused = false
                focusWorkItem?.cancel(); focusWorkItem = nil
            }
            .onDisappear {
                isSearchFocused = false
                focusWorkItem?.cancel(); focusWorkItem = nil
                searchTimer?.invalidate(); searchTimer = nil
            }
        }
    }

    // Filtering + Search
    private var listFilteredChurches: [Church] {
        var arr = applySearch(churches)
        switch filter {
        case .all: break
        case .active: arr = arr.filter { $0.isActive }
        case .inactive: arr = arr.filter { !$0.isActive }
        }
        if withPhotoOn { arr = arr.filter { ($0.photoName ?? "").isEmpty == false } }
        if let country = selectedCountry { arr = arr.filter { countryOf($0) == country } }
        if nearMeOn, let _ = locationManager.lastLocation {
            arr = arr.compactMap { ch in
                if let d = distanceFromUser(ch), d <= nearMeRadius { return ch } else { return nil }
            }
        }
        
     
        
        switch sortMode {
        case .distance:
            if locationManager.lastLocation != nil {
                arr = arr.sorted { (distanceFromUser($0) ?? .greatestFiniteMagnitude) < (distanceFromUser($1) ?? .greatestFiniteMagnitude) }
            } else { fallthrough }
        case .name:
            arr = arr.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        return arr
    }

    private func applySearch(_ arr: [Church]) -> [Church] {
        let q = searchDebounced.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return arr }
        return arr.filter { c in
            let hay = [c.name, c.address ?? ""].joined(separator: " ").lowercased()
            return hay.contains(q)
        }
    }

    private func distanceFromUser(_ church: Church) -> CLLocationDistance? {
        guard let loc = locationManager.lastLocation else { return nil }
        let c = CLLocation(latitude: church.coordinate.latitude, longitude: church.coordinate.longitude)
        return c.distance(from: loc)
    }

    private var topCountries: [String] {
        let arr = applySearch(churches)
        let all = arr.compactMap { countryOf($0) }
        let counts = Dictionary(grouping: all, by: { $0 }).mapValues { $0.count }
        return all.uniqued().sorted { (counts[$0] ?? 0) > (counts[$1] ?? 0) }.prefix(2).map { $0 }
    }
    
    private var listFilteredChurchesUnique: [Church] {
        var seen = Set<Int>()
        var result: [Church] = []
        for ch in listFilteredChurches {
            if seen.insert(ch.id).inserted {
                result.append(ch)
            }
        }
        return result
    }

    // Sheets
    private var filtersSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("status")) {
                    Picker("status", selection: $filter) {
                        Text("filter_all").tag(ChurchFilter.all)
                        Text("filter_active").tag(ChurchFilter.active)
                        Text("filter_inactive").tag(ChurchFilter.inactive)
                    }
                    .pickerStyle(.segmented)
                }
                Section(header: Text("distance")) {
                    Toggle("near_me", isOn: $nearMeOn)
                }
                Section(header: Text("media")) {
                    Toggle("with_photo", isOn: $withPhotoOn)
                }
                Section(header: Text("sort")) {
                    Picker("sort", selection: $sortMode) {
                        Text("sort_distance").tag(SortMode.distance)
                        Text("sort_name").tag(SortMode.name)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(Text("filters"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done") { showFiltersSheet = false }
                }
            }
        }
    }

    @State private var countrySearch: String = ""

    private var groupedCountries: [Character: [String]] {
        let all = Array(Set(churches.compactMap { countryOf($0) }))
            .sorted()
            .filter { countrySearch.isEmpty ? true : $0.lowercased().contains(countrySearch.lowercased()) }
        return Dictionary(grouping: all) { $0.first ?? "#" }
    }

    @ViewBuilder
    private func countryRowLabel(_ title: String, isSelected: Bool) -> some View {
        let bg = isSelected ? Color.black : Color.white
        let fg = isSelected ? Color.white : Color.primary

        HStack {
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(fg)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: isSelected ? 0 : 1)
        )
    }

    private var countrySheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Поиск по странам
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Поиск по странам", text: $countrySearch)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 6)
                    if !countrySearch.isEmpty {
                        Button { countrySearch = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 2)      // было 10
                .padding(.bottom, 8)   // чтобы отделить от списка

                List {
                    Section {
                        Button {
                            selectedCountry = nil
                            showCountrySheet = false
                        } label: {
                            countryRowLabel("Все страны", isSelected: selectedCountry == nil)
                        }
                    }
                    ForEach(groupedCountries.keys.sorted(), id: \.self) { letter in
                        if let items = groupedCountries[letter] {
                            Section(header: Text(String(letter)).font(.caption).foregroundStyle(.secondary)) {
                                ForEach(items, id: \.self) { c in
                                    Button {
                                        selectedCountry = c
                                        showCountrySheet = false
                                    } label: {
                                        countryRowLabel(c, isSelected: selectedCountry == c)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)

                // Липкая нижняя панель
                HStack(spacing: 12) {
                    Button {
                        selectedCountry = nil
                        countrySearch = ""
                    } label: {
                        Text("Сбросить")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button { showCountrySheet = false } label: {
                        Text("Готово")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Страны")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { showCountrySheet = false }
                }
            }
        }
    }
}

// MARK: - Supporting Types
enum ChurchFilter { case all, active, inactive }
enum SortMode: String, CaseIterable, Identifiable { case distance, name; var id: Self { self } }

// MARK: - Card View
struct ChurchCardView: View {
    let church: Church

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                if let photo = church.photoName, !photo.isEmpty {
                    Image(photo)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                } else {
                    Color(.systemGray5)
                        .frame(height: 200)
                }
                LinearGradient(colors: [.clear, Color.black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
                    .frame(height: 200)
                Text(church.name)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .lineLimit(2).minimumScaleFactor(0.8).truncationMode(.tail)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                HStack {
                    Text(church.isActive ? "active_church" : "lost_church")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1).minimumScaleFactor(0.8).truncationMode(.tail)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(church.isActive ? Color.purple.opacity(0.9) : Color.black.opacity(0.85))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding(8)
                    Spacer()
                }, alignment: .topLeading
            )

            if let address = church.address, !address.isEmpty {
                Text(address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1).truncationMode(.tail)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
        .padding(.horizontal, 16)
    }
}

private struct TopMapMaxYKey: PreferenceKey {
    static var defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}
