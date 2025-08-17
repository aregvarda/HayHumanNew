//
//  ChurchMapView.swift
//  HayHuman
//
//  Created by Арег Варданян on 17.08.2025.
//



import SwiftUI
import MapKit

struct Church: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let isActive: Bool
    let city: String?
    let address: String?
    let descriptionText: String?
    let photoName: String?

    init(
        name: String,
        coordinate: CLLocationCoordinate2D,
        isActive: Bool,
        city: String? = nil,
        address: String? = nil,
        descriptionText: String? = nil,
        photoName: String? = nil
    ) {
        self.name = name
        self.coordinate = coordinate
        self.isActive = isActive
        self.city = city
        self.address = address
        self.descriptionText = descriptionText
        self.photoName = photoName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ChurchMapView: View {
    private enum ChurchFilter: String, CaseIterable, Identifiable {
        case all, active, inactive
        var id: Self { self }
        var title: String {
            switch self {
            case .all: return "Все"
            case .active: return "Действующие"
            case .inactive: return "Утраченные"
            }
        }
    }
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.1772, longitude: 44.5035), // Ереван
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    @State private var filter: ChurchFilter = .all
    @State private var churches: [Church] = []
    @State private var selectedChurch: Church? = nil
    @State private var navTarget: Church? = nil
    @State private var searchText: String = ""

    private var searchResults: [Church] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        let results = churches.filter { c in
            let hay = [c.name, c.address ?? "", c.city ?? ""].joined(separator: " ").lowercased()
            return hay.contains(q)
        }
        return Array(results.prefix(6))
    }

    private func focus(on church: Church) {
        let target = MKCoordinateRegion(
            center: church.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        withAnimation(.easeInOut)
        {
            region = target
            selectedChurch = church
        }
    }

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    private var filteredChurches: [Church] {
        switch filter {
        case .all: return churches
        case .active: return churches.filter { $0.isActive }
        case .inactive: return churches.filter { !$0.isActive }
        }
    }
    
    // Compact Apple/Maps-like preview card shown in the bottom sheet
    private struct PreviewCard: View {
        let church: Church
        let openProfile: () -> Void

        private var statusText: String { church.isActive ? "Действующая" : "Утраченная" }
        private var statusColor: Color { church.isActive ? .purple : .black }

        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                // Thumbnail (compact 80pt)
                ZStack {
                    if let photo = church.photoName, !photo.isEmpty {
                        Image(photo)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(.systemGray6)
                            .overlay(
                                Image("churchmap")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(statusColor.opacity(0.9))
                                    .padding(16)
                            )
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(.systemGray4), lineWidth: 0.6)
                )

                // Text block
                VStack(alignment: .leading, spacing: 6) {
                    Text(church.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    if let address = church.address, !address.isEmpty {
                        Text(address)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if let city = church.city, !city.isEmpty {
                        Text(city)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(statusText)
                            .font(.caption.weight(.medium))
                            .foregroundColor(church.isActive ? .primary : .secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Accessory (chevron.right) with gray rounded background
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                    .padding()
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        openProfile()
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                openProfile()
            }
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
    }
    
    // Compact floating search bar
    private struct SearchBar: View {
        @Binding var text: String
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Поиск по церквям", text: $text)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(.regularMaterial) // более плотный фон, чем ultraThin
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
                    .blendMode(.overlay)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        }
    }

    // Soft top scrim to separate controls from the map under Dynamic Island / status bar
    private struct TopScrim: View {
        var body: some View {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.06),
                    .clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            .ignoresSafeArea(edges: .top)
        }
    }

    // Helper model to decode JSON (lat/lon) and map to `Church`
    private struct DecChurch: Codable {
        let name: String
        let lat: Double
        let lon: Double
        let isActive: Bool
        let city: String?
        let address: String?
        let descriptionText: String?
        let photoName: String?
    }

    private func loadChurches() {
        // Try to load from bundled JSON first
        if let url = Bundle.main.url(forResource: "churches", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([DecChurch].self, from: data)
                self.churches = decoded.map { item in
                    Church(
                        name: item.name,
                        coordinate: CLLocationCoordinate2D(latitude: item.lat, longitude: item.lon),
                        isActive: item.isActive,
                        city: item.city,
                        address: item.address,
                        descriptionText: item.descriptionText,
                        photoName: item.photoName
                    )
                }
                // Fit region to data (basic)
                if let first = self.churches.first {
                    self.region.center = first.coordinate
                }
                return
            } catch {
                print("[ChurchMap] Failed to decode churches.json: \(error)")
            }
        } else {
            print("[ChurchMap] churches.json not found in bundle")
        }
        // Fallback to a tiny mock if JSON is missing
        self.churches = [
            Church(name: "Действующая церковь", coordinate: CLLocationCoordinate2D(latitude: 40.18, longitude: 44.51), isActive: true, city: nil),
            Church(name: "Разрушенная церковь", coordinate: CLLocationCoordinate2D(latitude: 40.16, longitude: 44.49), isActive: false, city: nil)
        ]
    }

    // Split heavy layout into smaller subtrees to help the type-checker
    private var mapContent: some View {
        let annotations = filteredChurches
        return Map(coordinateRegion: $region, annotationItems: annotations) { church in
            MapAnnotation(coordinate: church.coordinate) {
                Button {
                    selectedChurch = church
                } label: {
                    Image("churchmap")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(church.isActive ? .purple : .black)
                        .frame(width: 42, height: 42)
                        .scaleEffect(selectedChurch == church ? 1.15 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selectedChurch == church)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var topOverlay: some View {
        VStack(spacing: 10) {
            // Search
            SearchBar(text: $searchText)
                .accessibilityLabel("Поиск по церквям")

            // Suggestions under the search field
            if !searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchResults, id: \.id) { church in
                        Button {
                            let target = church
                            searchText = ""
                            DispatchQueue.main.async { focus(on: target) }
                        } label: {
                            HStack(spacing: 12) {
                                // small thumbnail
                                ZStack {
                                    if let name = church.photoName, !name.isEmpty {
                                        Image(name)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Color(.systemGray5)
                                            .overlay(
                                                Image("churchmap")
                                                    .renderingMode(.template)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundColor(church.isActive ? .purple : .black)
                                                    .padding(6)
                                            )
                                    }
                                }
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(church.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Text((church.address?.isEmpty == false ? church.address! : (church.city ?? "")))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if church != searchResults.last { Divider() }
                    }
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        .blendMode(.overlay)
                )
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
            }

            // Filter chips
            Picker("Фильтр", selection: $filter) {
                ForEach(ChurchFilter.allCases) { f in
                    Text(f.title).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding(6)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    .blendMode(.overlay)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    var body: some View {
        mapContent
            .overlay(alignment: .top) {
                ZStack(alignment: .top) {
                    TopScrim()
                    topOverlay
                }
            }
            .sheet(item: $selectedChurch) { church in
                PreviewCard(church: church) {
                    // open profile
                    selectedChurch = nil
                    navTarget = church
                }
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.hidden)
            }
            .navigationDestination(item: $navTarget) { church in
                ChurchDetailView(church: church)
            }
            .onAppear { loadChurches() }
            // Let the map go under the home indicator, but keep the top area clean
            .ignoresSafeArea(.container, edges: [.bottom])
            .navigationTitle("Карта церквей и святынь")
            .navigationBarTitleDisplayMode(.inline)
            // Hide the default nav bar material/underline to avoid white/gray bands under the Dynamic Island
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}


extension Church {
    static func == (lhs: Church, rhs: Church) -> Bool { lhs.id == rhs.id }
}
