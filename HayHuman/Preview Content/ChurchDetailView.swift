//
//  ChurchDetailView.swift
//  HayHuman
//
//  Created by Арег Варданян on 17.08.2025.
//


//
//  ChurchDetailView.swift
//  HayHuman
//
//  Created by Арег Варданян on 17.08.2025.
//

import SwiftUI
import MapKit

/// Детальный экран профиля церкви.
/// Ожидает модель `Church` из `ChurchMapView`.
struct ChurchDetailView: View {
    let church: Church
    @Environment(\.dismiss) private var dismiss

    private var statusText: String {
        church.isActive ? NSLocalizedString("Действующая", comment: "Active church") :
                          NSLocalizedString("Утраченная", comment: "Lost/destroyed church")
    }

    private var statusColor: Color {
        church.isActive ? .purple : .black
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

                // Фото (плейсхолдер под одну картинку)
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

                // Название
                Text(church.name)
                    .font(.title2).bold()
                    .fixedSize(horizontal: false, vertical: true)

                // Статус
                HStack(spacing: 8) {
                    Circle().fill(statusColor).frame(width: 10, height: 10)
                    Text(statusText).font(.callout).foregroundStyle(.secondary)
                }

                // Адрес (плейсхолдер)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Адрес").font(.subheadline).foregroundStyle(.secondary)
                    Text("Адрес появится позже")
                        .font(.body)
                        .foregroundStyle(.primary)
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

                // Описание (плейсхолдер)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Описание").font(.subheadline).foregroundStyle(.secondary)
                    Text("Текст описания будет добавлен позже.")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Кнопки действий
                VStack(spacing: 12) {
                    // Открыть в Картах
                    Button {
                        let placemark = MKPlacemark(coordinate: church.coordinate)
                        let item = MKMapItem(placemark: placemark)
                        item.name = church.name
                        item.openInMaps()
                    } label: {
                        Label("Открыть в «Картах»", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    // Закрыть
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Text("Закрыть")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
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
            isActive: true
        )
    )
}
