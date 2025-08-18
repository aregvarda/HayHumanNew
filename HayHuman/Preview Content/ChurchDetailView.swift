//
//  ChurchDetailView.swift
//  HayHuman
//
//  Created by Арег Варданян on 17.08.2025.
//

import SwiftUI
import MapKit
import UIKit

/// Детальный экран профиля церкви.
/// Ожидает модель `Church` из `ChurchMapView`.
struct ChurchDetailView: View {
    let church: Church
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var statusText: LocalizedStringKey {
        church.isActive ? LocalizedStringKey("active_church") : LocalizedStringKey("lost_church")
    }

    private var statusColor: Color {
        church.isActive ? .purple : .black
    }

    /// Ссылка на поддержку проекта (как на HomeScreen)
    private let donateURL = URL(string: "https://www.donationalerts.com/r/hayhuman")

    // MARK: - Derived data from JSON
    private var composedAddress: String? {
        var parts: [String] = []
        if let city = church.city, !city.isEmpty { parts.append(city) }
        if let addr = church.address, !addr.isEmpty { parts.append(addr) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
    
    @ViewBuilder
    private var photoSection: some View {
        if let name = church.photoName, !name.isEmpty {
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
                .clipped()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemBackground))
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.secondary)
                    Text("Фото появится позже")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 180)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Мини‑карта с пином локации
                Map(
                    initialPosition: .region(
                        MKCoordinateRegion(
                            center: church.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                        )
                    ),
                    interactionModes: []
                ) {
                    Annotation(church.name, coordinate: church.coordinate) {
                        Image(systemName: "mappin.and.ellipse.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(statusColor)
                            .shadow(radius: 2, y: 1)
                    }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )

                // Фото из JSON (или плейсхолдер)
                photoSection

                // Название
                Text(church.name)
                    .font(.title2).bold()
                    .fixedSize(horizontal: false, vertical: true)

                // Статус
                HStack(spacing: 8) {
                    Circle().fill(statusColor).frame(width: 10, height: 10)
                    Text(statusText).font(.callout).foregroundStyle(.secondary)
                }

                // Адрес из JSON
                VStack(alignment: .leading, spacing: 4) {
                    Text("Адрес").font(.subheadline).foregroundStyle(.secondary)
                    if let address = composedAddress {
                        Text(address)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Адрес появится позже")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                // Координаты (читаемые подписи)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Координаты").font(.subheadline).foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        Text(String(format: "Широта: %.5f", church.coordinate.latitude))
                            .font(.body.monospaced())
                        Text(String(format: "Долгота: %.5f", church.coordinate.longitude))
                            .font(.body.monospaced())
                    }
                }

                // Описание из JSON
                VStack(alignment: .leading, spacing: 6) {
                    Text("Описание").font(.subheadline).foregroundStyle(.secondary)
                    if let desc = church.descriptionText, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Текст описания будет добавлен позже.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                // Кнопки действий
                VStack(spacing: 12) {
                    Button {
                        guard let url = donateURL else { return }
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                            Text("Поддержать проект")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 14))
                    .tint(.purple)
                    .accessibilityLabel("Поддержать проект в Donationalerts")

                    Button {
                        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        let options: [String : Any] = [
                            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: church.coordinate),
                            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: span)
                        ]
                        let placemark = MKPlacemark(coordinate: church.coordinate)
                        let item = MKMapItem(placemark: placemark)
                        item.name = church.name
                        item.openInMaps(launchOptions: options)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "map")
                            Text("Посмотреть на карте")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 14))
                    .tint(.secondary)
                    .accessibilityLabel("Открыть это место в «Картах»")
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Профиль церкви")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    // Превью с заглушкой
    ChurchDetailView(
        church: Church(
            name: "Сурб Аствацацин",
            coordinate: CLLocationCoordinate2D(latitude: 40.18, longitude: 44.51),
            isActive: true,
            city: "Эчмиадзин",
            address: "Армавирская область, Армения",
            descriptionText: "Предварительное описание для превью.",
            photoName: "zoravor_astsavatsin"
        )
    )
}
