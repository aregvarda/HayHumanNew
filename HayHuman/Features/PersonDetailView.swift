import SwiftUI
import MapKit
import UIKit

struct PersonDetailView: View {
    let person: Person

    // Размеры
    private let mapHeight: CGFloat = 260
    private let avatarSize: CGFloat = 160
    private let pagePadding: CGFloat = 20

    // Камера карты (если есть координаты)
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ===== MAP =====
                if mapRegion != nil {
                    ZStack(alignment: .bottomLeading) {
                        Map(position: $camera) {
                            if let coordinate = coordinate {
                                // Маркер города рождения
                                Annotation("", coordinate: coordinate) {
                                    ZStack {
                                        Circle().fill(.white).frame(width: 16, height: 16)
                                        Circle().fill(.red).frame(width: 10, height: 10)
                                    }
                                    .shadow(radius: 2)
                                }
                            }
                        }
                        .frame(height: mapHeight)
                        .overlay(alignment: .top) {
                            // лёгкий светлый градиент, чтобы надпись читалась, но не затемнял карту
                            LinearGradient(
                                colors: [.white.opacity(0.4), .clear],
                                startPoint: .top, endPoint: .center
                            )
                            .frame(height: 48)
                        }
                        .overlay(alignment: .bottom) {
                            // градиент снизу — под фото
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.15)],
                                startPoint: .center, endPoint: .bottom
                            )
                            .frame(height: 60)
                        }
                        .onAppear {
                            if let region = mapRegion {
                                camera = .region(region)
                            }
                        }

                        // Название города на карте (тёмная подпись)
                        if let city = person.birthCity {
                            Text(city)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.black.opacity(0.85))
                                .padding(.leading, pagePadding + 90)
                                .padding(.bottom, avatarSize/2 + 12)
                        }
                    }
                    .overlay(
                        // Круглая аватарка "поверх" карты
                        Circle()
                            .fill(.clear)
                            .frame(width: avatarSize, height: avatarSize)
                            .overlay(
                                Group {
                                    if UIImage(named: person.imageName) != nil {
                                        Image(person.imageName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: avatarSize, height: avatarSize)
                                            .clipShape(Circle())
                                    } else {
                                        ZStack {
                                            Color.black
                                            Text(person.overlayTitle)
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                        .frame(width: avatarSize, height: avatarSize)
                                        .clipShape(Circle())
                                    }
                                }
                            )
                            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
                            .overlay(
                                Circle().stroke(.white, lineWidth: 6)
                            )
                            .offset(y: avatarSize/2) // наполовину свешиваем вниз
                            .frame(maxWidth: .infinity, alignment: .center),
                        alignment: .bottom
                    )
                    .padding(.bottom, avatarSize/2 + 12) // место под свешенную аватарку
                }

                // ===== TEXTS =====
                VStack(alignment: .leading, spacing: 12) {
                    // Имя
                    Text(person.name)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.top, 4)

                    // Локация мелким
                    if let city = person.birthCity {
                        let country = person.birthCountry ?? ""
                        Text([city, country].filter { !$0.isEmpty }.joined(separator: ", "))
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }

                    // Короткое описание
                    Text(person.subtitle)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.top, 4)

                    Divider().padding(.vertical, 6)

                    // Биография
                    if let bio = person.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 17))
                            .foregroundStyle(.primary)
                            .lineSpacing(2.5)
                    } else {
                        Text(NSLocalizedString("bio_placeholder", comment: ""))
                            .font(.system(size: 17))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, pagePadding)
                .padding(.bottom, 24)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Кнопка “Открыть в Картах”, если есть координаты
            if let coordinate = coordinate {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let placemark = MKPlacemark(coordinate: coordinate)
                        let item = MKMapItem(placemark: placemark)
                        item.name = person.birthCity ?? person.name
                        item.openInMaps(launchOptions: [
                            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate)
                        ])
                    } label: {
                        Image(systemName: "map")
                            .accessibilityLabel(Text(NSLocalizedString("open_in_maps", comment: "")))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var coordinate: CLLocationCoordinate2D? {
        if let lat = person.birthLat, let lon = person.birthLon {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return nil
    }

    private var mapRegion: MKCoordinateRegion? {
        guard let coord = coordinate else { return nil }
        return MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    }
}
