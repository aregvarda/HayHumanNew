import Foundation
import CoreLocation

// Модель под JSON
struct DecChurch: Codable {
    let name: String
    let descriptionText: String?
    let address: String?
    let city: String?        // может не быть в JSON — ок
    let photoName: String?
    let latitude: Double
    let longitude: Double
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case descriptionText = "description"
        case address
        case city
        case photoName
        case latitude = "lat"
        case longitude = "lon"
        case isActive
    }
}

// Модель для UI
struct Church: Identifiable {
    let id: Int
    let name: String
    let address: String?
    let city: String?
    let photoName: String?
    let descriptionText: String?
    let coordinate: CLLocationCoordinate2D
    let isActive: Bool

    // Конструктор из DecChurch
    init(from raw: DecChurch) {
        self.name = raw.name
        self.address = raw.address
        self.city = raw.city
        self.photoName = raw.photoName
        self.descriptionText = raw.descriptionText
        self.coordinate = CLLocationCoordinate2D(latitude: raw.latitude, longitude: raw.longitude)
        self.isActive = raw.isActive ?? false
        self.id = Church.makeId(name: raw.name, lat: raw.latitude, lon: raw.longitude)
    }

    // Удобный init для превью (DEBUG)
    #if DEBUG
    init(sample name: String, lat: Double, lon: Double, isActive: Bool = true, address: String? = nil, city: String? = nil, photoName: String? = nil, descriptionText: String? = nil) {
        self.name = name
        self.address = address
        self.city = city
        self.photoName = photoName
        self.descriptionText = descriptionText
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.isActive = isActive
        self.id = Church.makeId(name: name, lat: lat, lon: lon)
    }
    #endif

    private static func makeId(name: String, lat: Double, lon: Double) -> Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(lat.bitPattern)
        hasher.combine(lon.bitPattern)
        return hasher.finalize()
    }
}


extension Church: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Church: Equatable {
    static func == (lhs: Church, rhs: Church) -> Bool { lhs.id == rhs.id }
}

// Утилиты
extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

// Страна из адреса
func countryOf(_ church: Church) -> String? {
    guard let addr = church.address, !addr.isEmpty else { return nil }
    return addr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.last
}
