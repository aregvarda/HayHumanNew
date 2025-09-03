//
//  ChurchMapView.swift
//  HayHuman
//
//  Created by Арег Варданян on 17.08.2025.
//

import Foundation




import SwiftUI
import MapKit
import CoreLocation

private extension Double {
    func rounded(to places: Int) -> Double {
        let p = pow(10.0, Double(places))
        return (self * p).rounded() / p
    }
}


private func L(_ key: String) -> LocalizedStringKey { LocalizedStringKey(key) }

fileprivate struct _ChurchCache {
    static var byLang: [String: [Church]] = [:]
    static let io = DispatchQueue(label: "HH.ChurchIO", qos: .userInitiated)
}

struct ChurchMapView: View {
    private enum ChurchFilter: String, CaseIterable, Identifiable {
        case all, active, inactive
        var id: Self { self }
        var title: LocalizedStringKey {
            switch self {
            case .all: return L("filter_all")
            case .active: return L("filter_active")
            case .inactive: return L("filter_inactive")
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
    @State private var debouncedQuery: String = ""
    @State private var searchIndex: [Int: String] = [:] // church.id -> lowercased "name address city"
    @State private var showList = false
    @StateObject private var locationManager = HHLocationManager()
    @State private var didAutoCenter = false
    @State private var allowAutoLock = false
    @State private var saveRegionWorkItem: DispatchWorkItem? = nil

    // Caches to avoid heavy recomputation
    @State private var listCacheKey: String = ""
    @State private var cachedList: [Church] = []
    @State private var cachedCountriesKey: String = ""
    @State private var cachedAvailableCountries: [String] = []
    @State private var distCache: [Int: CLLocationDistance] = [:]
    // Async compute & movement threshold
    @State private var rebuildWorkItem: DispatchWorkItem? = nil
    private let computeQueue = DispatchQueue(label: "HH.MapCompute", qos: .userInitiated)
    @State private var lastDistanceOrigin: CLLocationCoordinate2D? = nil
    private let locationThreshold: CLLocationDistance = 400 // meters

    // List filters
    @State private var nearMeOn: Bool = false
    @State private var withPhotoOn: Bool = false
    @State private var selectedCountry: String? = nil // nil = all
    private let nearMeRadius: CLLocationDistance = 25_000 // 25 km
    // --- Filters/List Mode Sheets
    @State private var showFiltersSheet = false
    @State private var showCountrySheet = false

    private enum SortMode: String, CaseIterable, Identifiable { case distance, name; var id: Self { self } }
    @State private var sortMode: SortMode = .name

    // Controls visibility of bottom mini-map in list mode
    @State private var showBottomMiniMapInList = false

    @State private var isActive: Bool = false

    @SceneStorage("HHMap.didFreshInit") private var didFreshInit: Bool = false

    // Persist map region & user intent across pushes so we return where user left off
    @SceneStorage("HHMap.centerLat") private var storedCenterLat: Double = 0
    @SceneStorage("HHMap.centerLon") private var storedCenterLon: Double = 0
    @SceneStorage("HHMap.spanLat") private var storedSpanLat: Double = 0
    @SceneStorage("HHMap.spanLon") private var storedSpanLon: Double = 0
    @SceneStorage("HHMap.userLocked") private var userLockedRegion: Bool = false
    @SceneStorage("HHMap.pendingFocusID") private var pendingFocusID: Int = 0
    @SceneStorage("HHNav.popToMap") private var popToMap: Bool = false
    @SceneStorage("HHNav.closeList") private var closeList: Bool = false

    // City-scale span for first auto-centering (show whole city around user)
    private let citySpan = MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)

    private var searchResults: [Church] {
        let q = debouncedQuery
        guard !q.isEmpty else { return [] }
        let results = churches.filter { c in
            if let hay = searchIndex[c.id] { return hay.contains(q) }
            return false
        }
        return Array(results.prefix(6))
    }

    // Center map to church location WITHOUT selecting it (no sheet)
    private func center(on church: Church) {
        let target = MKCoordinateRegion(
            center: church.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        withAnimation(.easeInOut) {
            region = target
        }
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

    private func focusByID(_ id: Int) {
        guard let church = churches.first(where: { $0.id == id }) else { return }
        focus(on: church)
    }

    private func nearestChurch(to coordinate: CLLocationCoordinate2D) -> Church? {
        guard !churches.isEmpty else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var best: (Church, CLLocationDistance)? = nil
        for ch in churches {
            let d = target.distance(from: CLLocation(latitude: ch.coordinate.latitude,
                                                    longitude: ch.coordinate.longitude))
            if let current = best {
                if d < current.1 { best = (ch, d) }
            } else {
                best = (ch, d)
            }
        }
        return best?.0
    }

    // MARK: - Zoom helpers (big steps)
    private func zoom(by factor: Double) {
        withAnimation(.easeInOut) {
            let lat = max(min(region.span.latitudeDelta * factor, 80), 0.0003)
            let lon = max(min(region.span.longitudeDelta * factor, 80), 0.0003)
            region = MKCoordinateRegion(center: region.center,
                                        span: MKCoordinateSpan(latitudeDelta: lat,
                                                               longitudeDelta: lon))
        }
    }

    private func zoomInBig() {
        // 4x closer per tap
        zoom(by: 0.25)
    }

    private func zoomOutBig() {
        // 4x farther per tap
        zoom(by: 4.0)
    }

    // MARK: - Region persistence helpers
    private func restoreRegionIfAvailable() -> Bool {
        // If we have a previously saved region, restore it and tell caller we did
        guard storedSpanLat > 0, storedSpanLon > 0 else { return false }
        let restored = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: storedCenterLat, longitude: storedCenterLon),
            span: MKCoordinateSpan(latitudeDelta: storedSpanLat, longitudeDelta: storedSpanLon)
        )
        region = restored
        return true
    }

    private func saveCurrentRegion() {
        storedCenterLat = region.center.latitude
        storedCenterLon = region.center.longitude
        storedSpanLat = region.span.latitudeDelta
        storedSpanLon = region.span.longitudeDelta
    }

    private func saveAndLockRegion() {
        guard allowAutoLock else { return }
        saveCurrentRegion()
        userLockedRegion = true
    }

    private func scheduleSaveRegion() {
        guard allowAutoLock else { return }
        saveRegionWorkItem?.cancel()
        let work = DispatchWorkItem { saveAndLockRegion() }
        saveRegionWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
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

    // Apply search text to a church array (name + address)
    private func applySearch(_ arr: [Church]) -> [Church] {
        let q = debouncedQuery
        guard !q.isEmpty else { return arr }
        return arr.filter { c in
            if let hay = searchIndex[c.id] { return hay.contains(q) }
            return false
        }
    }

    private func makeListKey() -> String {
        let q = debouncedQuery
        let photo = withPhotoOn ? "1" : "0"
        let near = nearMeOn ? "1" : "0"
        let country = selectedCountry ?? "*"
        let sort = sortMode.rawValue
        let filt = filter.rawValue
        let loc = locationManager.lastLocation.map { "\($0.coordinate.latitude.rounded(to: 3))|\($0.coordinate.longitude.rounded(to: 3))" } ?? "nil"
        return [filt, photo, near, country, sort, q, loc].joined(separator: "#")
    }

    private func rebuildCachesIfNeeded() {
        let newKey = makeListKey()
        // If nothing important changed, skip
        if newKey == listCacheKey { return }
        // Cancel previous scheduled compute
        rebuildWorkItem?.cancel()
        let work = DispatchWorkItem { [newKey] in
            // Heavy compute off main
            var arr = applySearch(filteredChurches)
            if withPhotoOn { arr = arr.filter { ($0.photoName ?? "").isEmpty == false } }
            if let country = selectedCountry { arr = arr.filter { countryOf($0) == country } }
            var localDistCache: [Int: CLLocationDistance] = [:]
            if (sortMode == .distance || nearMeOn), let _ = locationManager.lastLocation {
                arr = arr.compactMap { ch in
                    if let d = distanceFromUser(ch) { localDistCache[ch.id] = d; return nearMeOn ? (d <= nearMeRadius ? ch : nil) : ch }
                    return nearMeOn ? nil : ch
                }
            }
            switch sortMode {
            case .distance:
                if locationManager.lastLocation != nil {
                    arr.sort { (localDistCache[$0.id] ?? .greatestFiniteMagnitude) < (localDistCache[$1.id] ?? .greatestFiniteMagnitude) }
                } else {
                    arr.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                }
            case .name:
                arr.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
            let countriesAll = applySearch(filteredChurches).compactMap { countryOf($0) }
            let counts = Dictionary(grouping: countriesAll, by: { $0 }).mapValues { $0.count }
            let countriesTop = countriesAll.uniqued().sorted { (counts[$0] ?? 0) > (counts[$1] ?? 0) }.prefix(6).map { $0 }
            // Publish to UI on main
            DispatchQueue.main.async {
                // Do not publish if view is no longer active
                guard isActive else { return }
                listCacheKey = newKey
                cachedList = arr
                distCache = localDistCache
                cachedAvailableCountries = countriesTop
            }
        }
        rebuildWorkItem = work
        computeQueue.asyncAfter(deadline: .now() + 0.05, execute: work)
    }
    private func isSignificantMove(_ newLoc: CLLocation) -> Bool {
        guard let origin = lastDistanceOrigin else { return true }
        let dist = newLoc.distance(from: CLLocation(latitude: origin.latitude, longitude: origin.longitude))
        return dist > locationThreshold
    }

    // Helpers for list filters
    private func distanceFromUser(_ church: Church) -> CLLocationDistance? {
        guard let loc = locationManager.lastLocation else { return nil }
        let c = CLLocation(latitude: church.coordinate.latitude, longitude: church.coordinate.longitude)
        return c.distance(from: loc)
    }

    private func countryOf(_ church: Church) -> String? {
        guard let addr = church.address, !addr.isEmpty else { return nil }
        let parts = addr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return parts.last
    }

    private var availableCountries: [String] { cachedAvailableCountries }
    private var topCountries: [String] { Array(availableCountries.prefix(3)) }

    // List mode uses filter + search + extra filters
    private var listFilteredChurches: [Church] { cachedList }
    
    // Compact Apple/Maps-like preview card shown in the bottom sheet
    private struct PreviewCard: View {
        let church: Church
        let openProfile: () -> Void

        private var statusKey: LocalizedStringKey {
            church.isActive ? L("active_church") : L("lost_church")
        }
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
                        Text(statusKey)
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
                TextField("", text: $text, prompt: Text(L("search_churches")))
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


    private func loadChurches() {
        let lang = LocalPeopleStore.currentLangCode()
        if let cached = _ChurchCache.byLang[lang], !cached.isEmpty {
            self.churches = cached
            // index too
            var idx: [Int: String] = [:]
            idx.reserveCapacity(cached.count)
            for c in cached { idx[c.id] = [c.name, c.address ?? "", c.city ?? ""].joined(separator: " ").lowercased() }
            self.searchIndex = idx
            return
        }
        // Load on background queue
        _ChurchCache.io.async {
            let filename = "churches"
            var url: URL?
            // localized first
            url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: nil, localization: lang)
            if url == nil { url = Bundle.main.url(forResource: filename, withExtension: "json") }
            guard let u = url, let data = try? Data(contentsOf: u),
                  let decoded = try? JSONDecoder().decode([DecChurch].self, from: data) else {
                DispatchQueue.main.async { self.churches = [] }
                return
            }
            let mapped = decoded.map { Church(from: $0) }
            // cache
            _ChurchCache.byLang[lang] = mapped
            // build index
            var idx: [Int: String] = [:]
            idx.reserveCapacity(mapped.count)
            for c in mapped { idx[c.id] = [c.name, c.address ?? "", c.city ?? ""].joined(separator: " ").lowercased() }
            DispatchQueue.main.async {
                self.churches = mapped
                self.searchIndex = idx
                // If a focus was requested earlier, apply once data is loaded
                if pendingFocusID != 0, let ch = mapped.first(where: { $0.id == pendingFocusID }) {
                    focus(on: ch); userLockedRegion = true; pendingFocusID = 0
                }
                rebuildCachesIfNeeded()
            }
        }
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
                        .frame(width: 32, height: 32)
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
                .accessibilityLabel(L("search_churches"))

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
            Picker("", selection: $filter) {
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

    // Group heavy overlays separately to help the type-checker
    private var mapWithOverlays: some View {
        mapContent
            .overlay(alignment: .top) {
                ZStack(alignment: .top) {
                    TopScrim()
                    topOverlay
                }
            }
            .overlay(alignment: .bottomTrailing) {
                VStack(spacing: 10) {
                    Button(action: zoomInBig) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(14)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: zoomOutBig) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(14)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 14)
                .padding(.bottom, 48)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            }
            .overlay(alignment: .bottom) {
                if !showList {
                    Button(action: { showList = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet").font(.system(size: 16, weight: .semibold))
                            Text("Список").font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                Capsule().fill(Color(.systemBackground).opacity(0.92))
                                Capsule().fill(.ultraThinMaterial)
                            }
                        )
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 72)
                    .shadow(color: .black.opacity(0.16), radius: 6, y: 2)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                }
            }
    }

    // Attach presentation modifiers in a generic helper (reduces type-checking load)
    private func attachPresentations<V: View>(_ base: V) -> some View {
        base
            .sheet(item: $selectedChurch) { church in
                PreviewCard(church: church) {
                    // Lock current region so coming back restores this viewpoint
                    saveCurrentRegion()
                    userLockedRegion = true
                    selectedChurch = nil
                    navTarget = church
                }
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.hidden)
            }
            .navigationDestination(item: $navTarget) { church in
                ChurchDetailView(church: church)
            }
    }

    // MARK: - Lifecycle handlers (reduce type-check complexity)
    private func handleOnAppearMain() {
        if !didFreshInit {
            userLockedRegion = false
            didAutoCenter = false
            allowAutoLock = false
            storedSpanLat = 0
            storedSpanLon = 0
        }
        loadChurches()
        locationManager.request()

        // If another screen requested to focus a church, center on it now
        if pendingFocusID != 0 {
            if let ch = churches.first(where: { $0.id == pendingFocusID }) {
                focus(on: ch)
                userLockedRegion = true
            }
            pendingFocusID = 0
            didAutoCenter = true
        }

        if restoreRegionIfAvailable() {
            didAutoCenter = true
        } else if !userLockedRegion, let loc = locationManager.lastLocation {
            let targetCoord = nearestChurch(to: loc.coordinate)?.coordinate ?? loc.coordinate
            withAnimation(.easeInOut) {
                region = MKCoordinateRegion(center: targetCoord, span: citySpan)
            }
            didAutoCenter = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            allowAutoLock = true
        }
        didFreshInit = true
        rebuildCachesIfNeeded()
    }

    private func handleLocationChangeMain(_ loc: CLLocation) {
        if !didAutoCenter && !userLockedRegion && selectedChurch == nil {
            let targetCoord = nearestChurch(to: loc.coordinate)?.coordinate ?? loc.coordinate
            withAnimation(.easeInOut) {
                region = MKCoordinateRegion(center: targetCoord, span: citySpan)
            }
            didAutoCenter = true
        }
    }

    var body: some View {
        let base = mapWithOverlays
        let presented = attachPresentations(base)
        let v1 = presented
            .onAppear { handleOnAppearMain() }
            .onAppear { isActive = true }
            .onAppear {
                if popToMap || closeList {
                    popToMap = false; closeList = false
                    showList = false
                }
            }
            .onChange(of: locationManager.lastLocation) { oldValue, newValue in
                if let loc = newValue {
                    handleLocationChangeMain(loc)
                    if (sortMode == .distance || nearMeOn) && isSignificantMove(loc) {
                        lastDistanceOrigin = loc.coordinate
                        rebuildCachesIfNeeded()
                    }
                }
            }

        let v2 = v1
            .navigationTitle(L("map_churches_and_shrines"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)

        let v3 = v2
            .onChange(of: region.center.latitude) { _, _ in scheduleSaveRegion() }
            .onChange(of: region.center.longitude) { _, _ in scheduleSaveRegion() }
            .onChange(of: region.span.latitudeDelta) { _, _ in scheduleSaveRegion() }
            .onChange(of: region.span.longitudeDelta) { _, _ in scheduleSaveRegion() }

        let v4 = v3
            .onDisappear {
                isActive = false
                rebuildWorkItem?.cancel()
                saveRegionWorkItem?.cancel()
            }
            .onChange(of: popToMap) { _, newValue in
                if newValue { popToMap = false; showList = false }
            }
            .onChange(of: closeList) { _, newValue in
                if newValue { closeList = false; showList = false }
            }
            .onChange(of: searchText) { _, newValue in
                let value = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    if value == searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                        debouncedQuery = value
                    }
                }
            }
            .onChange(of: filter) { _, _ in rebuildCachesIfNeeded() }
            .onChange(of: withPhotoOn) { _, _ in rebuildCachesIfNeeded() }
            .onChange(of: nearMeOn) { _, _ in rebuildCachesIfNeeded() }
            .onChange(of: selectedCountry) { _, _ in rebuildCachesIfNeeded() }
            .onChange(of: sortMode) { _, _ in rebuildCachesIfNeeded() }
            .onChange(of: debouncedQuery) { _, _ in rebuildCachesIfNeeded() }
            .onChange(of: churches) { _, _ in rebuildCachesIfNeeded() }

        return v4
            .fullScreenCover(isPresented: $showList) {
                ChurchListView(churches: $churches, locationManager: locationManager)
            }
    }
}



// Preference key for tracking top mini-map position in list mode
private struct TopMapMaxYKey: PreferenceKey {
    static var defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

