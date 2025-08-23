import SwiftUI
import CoreLocation
import MapKit

struct ChurchListView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var churches: [Church]
    @ObservedObject var locationManager: HHLocationManager

    @State private var searchText: String = ""
    @State private var filter: ChurchFilter = .all
    @State private var nearMeOn: Bool = false
    @State private var withPhotoOn: Bool = false
    @State private var selectedCountry: String? = nil
    @State private var sortMode: SortMode = .name
    @State private var showFiltersSheet = false
    @State private var showCountrySheet = false

    @State private var showBottomMiniMap = false
    @State private var previewRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.0, longitude: 45.0), span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15))

    private let nearMeRadius: CLLocationDistance = 25_000 // 25 km

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    // Mini map header (scrolls with list)
                    ZStack {
                        Map(coordinateRegion: $previewRegion)
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .background(
                                GeometryReader { proxy in
                                    Color.clear.preference(key: TopMapMaxYKey.self, value: proxy.frame(in: .named("listScroll")).maxY)
                                }
                            )
                        Button(action: { dismiss() }) {
                            HStack { Image(systemName: "map"); Text("На карте") }
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
                        ForEach(listFilteredChurches) { church in
                            NavigationLink {
                                ChurchDetailView(church: church)
                            } label: {
                                ChurchCardView(church: church)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .coordinateSpace(name: "listScroll")
                .onPreferenceChange(TopMapMaxYKey.self) { maxY in
                    showBottomMiniMap = maxY < 100
                }
                .overlay(alignment: .bottom) {
                    if showBottomMiniMap {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 8) { Image(systemName: "map"); Text("На карте") }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.black.opacity(0.12), lineWidth: 1))
                                .shadow(color: .black.opacity(0.16), radius: 6, y: 2)
                        }
                        .padding(.bottom, 28)
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 8) {
                    // Back + Search + Filters
                    HStack(spacing: 10) {
                        Button(action: { dismiss() }) {
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
                                    .textFieldStyle(.plain)
                                    .padding(.vertical, 6)
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
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(selectedCountry == nil ? Color.purple.opacity(0.15) : Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            ForEach(topCountries, id: \.self) { c in
                                Button { selectedCountry = c } label: {
                                    Text(c)
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(selectedCountry == c ? Color.purple.opacity(0.15) : Color(.systemGray6))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }

                            Button { showCountrySheet = true } label: {
                                HStack(spacing: 6) { Image(systemName: "ellipsis"); Text("more") }
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
            }
            .sheet(isPresented: $showFiltersSheet) { filtersSheet }
            .sheet(isPresented: $showCountrySheet) { countrySheet }
            .onAppear {
                if let first = churches.first { previewRegion.center = first.coordinate }
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
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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

    private var countrySheet: some View {
        NavigationStack {
            List {
                Button { selectedCountry = nil; showCountrySheet = false } label: {
                    HStack { Text("all_countries"); if selectedCountry == nil { Spacer(); Image(systemName: "checkmark") } }
                }
                ForEach(Array(Set(churches.compactMap { countryOf($0) })), id: \.self) { c in
                    Button { selectedCountry = c; showCountrySheet = false } label: {
                        HStack { Text(c); if selectedCountry == c { Spacer(); Image(systemName: "checkmark") } }
                    }
                }
            }
            .navigationTitle(Text("countries"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { showCountrySheet = false }
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
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                HStack {
                    Text(church.isActive ? "active_church" : "lost_church")
                        .font(.caption.weight(.semibold))
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
