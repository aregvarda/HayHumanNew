// MARK: - Share
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

// Fullscreen photo viewer state
@State private var showPhotoViewer = false
@SceneStorage("HHMap.pendingFocusID") private var pendingFocusID: Int = 0
@SceneStorage("HHNav.popToMap") private var popToMap: Bool = false
@SceneStorage("HHNav.closeList") private var closeList: Bool = false

@State private var cachedShareURL: URL? = nil

// MARK: - Derived data from JSON
private var composedAddress: String? {
    if let addr = church.address, !addr.isEmpty {
        return addr
    }
    return nil
}

@ViewBuilder
private var photoSection: some View {
    if let name = church.photoName, !name.isEmpty {
        Button {
            showPhotoViewer = true
        } label: {
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(.black.opacity(0.5))
                        .clipShape(Circle())
                        .padding(6),
                    alignment: .bottomTrailing
                )
                .clipped()
        }
        .buttonStyle(.plain)
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

// Pretty URL helpers
private func prettySlug(for church: Church) -> String {
    let base = slugify(church.name)
    let hashSource = "\(church.name)-\(church.coordinate.latitude)-\(church.coordinate.longitude)"
    let short = shortHash(hashSource)
    return short.isEmpty ? base : "\(base)-\(short)"
}

private func slugify(_ text: String) -> String {
    var mutable = text as NSString
    let mutableStr = NSMutableString(string: mutable)
    CFStringTransform(mutableStr, nil, kCFStringTransformToLatin, false)
    CFStringTransform(mutableStr, nil, kCFStringTransformStripCombiningMarks, false)
    var s = String(mutableStr)
    s = s.lowercased()
    s = s.replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
    s = s.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    return s.isEmpty ? "church" : s
}

private func shortHash(_ input: String) -> String {
    let data = Array(input.utf8)
    var hash: UInt64 = 0xcbf29ce484222325
    for b in data { hash ^= UInt64(b); hash &*= 0x100000001b3 }
    let base36 = String(hash, radix: 36)
    return String(base36.prefix(6))
}

private func shareChurch() {
    if cachedShareURL == nil {
        let slug = prettySlug(for: church)
        cachedShareURL = URL(string: "https://hayhuman.app/church/\(slug)")
    }
    guard let url = cachedShareURL else { return }
    let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let root = scene.windows.first?.rootViewController {
        root.present(activity, animated: true)
    }
}

private func openInMaps() {
    let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    let options: [String : Any] = [
        MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: church.coordinate),
        MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: span)
    ]
    let placemark = MKPlacemark(coordinate: church.coordinate)
    let item = MKMapItem(placemark: placemark)
    item.name = church.name
    item.openInMaps(launchOptions: options)
}
var body: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {

            // Мини‑карта с пином локации
            ZStack {
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
                .allowsHitTesting(false)

                // Full-size tap target
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        pendingFocusID = church.id
                        closeList = true
                        popToMap = true
                        dismiss()
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Открыть на общей карте")
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
                Text("address").font(.subheadline).foregroundStyle(.secondary)
                if let address = composedAddress {
                    Text(address)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("address_placeholder")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            // Координаты (читаемые подписи)
            VStack(alignment: .leading, spacing: 4) {
                Text("coordinates").font(.subheadline).foregroundStyle(.secondary)
                ViewThatFits(in: .horizontal) {
                    // Two columns when there's enough width
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("latitude")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("\(church.coordinate.latitude, specifier: "%.5f")")
                                .font(.body.monospaced())
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("longitude")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("\(church.coordinate.longitude, specifier: "%.5f")")
                                .font(.body.monospaced())
                        }
                    }
                    // Fallback: stack vertically on narrow widths
                    VStack(alignment: .leading, spacing: 6) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("latitude").font(.caption).foregroundStyle(.secondary)
                            Text("\(church.coordinate.latitude, specifier: "%.5f")").font(.body.monospaced())
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("longitude").font(.caption).foregroundStyle(.secondary)
                            Text("\(church.coordinate.longitude, specifier: "%.5f")").font(.body.monospaced())
                        }
                    }
                }
            }

            // Описание из JSON
            VStack(alignment: .leading, spacing: 6) {
                Text("description").font(.subheadline).foregroundStyle(.secondary)
                if let desc = church.descriptionText, !desc.isEmpty {
                    Text(desc)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("description_placeholder")
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
                        Text("support_project")
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
                    pendingFocusID = church.id
                    closeList = true
                    popToMap = true
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "map")
                        Text("view_on_map")
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
    .onAppear {
        if cachedShareURL == nil {
            let slug = prettySlug(for: church)
            cachedShareURL = URL(string: "https://hayhuman.app/church/\(slug)")
        }
    }
    .navigationTitle("church_profile")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                shareChurch()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Поделиться")
        }
    }
    .fullScreenCover(isPresented: $showPhotoViewer) {
        if let name = church.photoName, !name.isEmpty {
            PhotoViewer(imageName: name)
        }
    }
}
}

// MARK: - Fullscreen photo viewer
private struct PhotoViewer: View {
let imageName: String
@Environment(\.dismiss) private var dismiss

@State private var scale: CGFloat = 1.0
@State private var lastScale: CGFloat = 1.0
@State private var offset: CGSize = .zero
@State private var lastOffset: CGSize = .zero
@State private var showSaveAlert = false
@State private var saveErrorMessage: String? = nil

private final class ImageSaver: NSObject {
    var onFinish: ((Error?) -> Void)?
    func save(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(done(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    @objc private func done(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        onFinish?(error)
    }
}

private func saveImageToPhotos() {
    guard let uiImg = UIImage(named: imageName) else {
        saveErrorMessage = "Изображение не найдено"
        showSaveAlert = true
        return
    }
    let saver = ImageSaver()
    saver.onFinish = { error in
        if let error = error {
            saveErrorMessage = error.localizedDescription
        } else {
            saveErrorMessage = nil
        }
        showSaveAlert = true
    }
    saver.save(uiImg)
}

var body: some View {
    ZStack {
        Color.black.ignoresSafeArea()

        GeometryReader { proxy in
            let container = proxy.size

            Image(imageName)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                // Drag only when zoomed in; clamp so изображение не «уплывает»
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard scale > 1.0 else { return }
                            let proposed = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            offset = clampedOffset(proposed, in: container, scale: scale)
                        }
                        .onEnded { _ in
                            guard scale > 1.0 else { return }
                            lastOffset = offset
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            // keep current center; update scale
                            let newScale = min(max(lastScale * value, 1.0), 4.0)
                            scale = newScale
                            // while pinch, also clamp current offset to new bounds
                            offset = clampedOffset(offset, in: container, scale: scale)
                        }
                        .onEnded { _ in
                            lastScale = scale
                            // if вернулись в 1x — сбросить оффсет
                            if scale <= 1.01 {
                                withAnimation(.easeOut) {
                                    offset = .zero
                                    lastOffset = .zero
                                    scale = 1.0
                                    lastScale = 1.0
                                }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut) {
                        if scale > 1.01 {
                            // сброс
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            // зум в 2x, оставляя центр (без рывков)
                            scale = 2.0
                            lastScale = 2.0
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(.black.opacity(0.5))
                    .clipShape(Circle())
                    .shadow(radius: 6)
            }
        }
        .padding(.top, 12)
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

        HStack {
            Button { saveImageToPhotos() } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(.black.opacity(0.5))
                    .clipShape(Circle())
                    .shadow(radius: 6)
            }
            Spacer()
        }
        .padding(.top, 12)
        .padding(.leading, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .alert(isPresented: $showSaveAlert) {
        if let msg = saveErrorMessage {
            return Alert(title: Text("Не удалось сохранить"), message: Text(msg), dismissButton: .default(Text("OK")))
        } else {
            return Alert(title: Text("Сохранено"), message: Text("Фото добавлено в Фотоплёнку"), dismissButton: .default(Text("OK")))
        }
    }
}

// Ограничиваем смещение, чтобы чёрные поля не «вылазили» при зуме
private func clampedOffset(_ proposed: CGSize, in container: CGSize, scale: CGFloat) -> CGSize {
    // Допустимый отступ = половина разницы между увеличенной картинкой и контейнером
    // Для scaledToFit неизвестны точные размеры изображения; берём допуск по контейнеру.
    let maxX = max((scale - 1) * container.width / 2, 0)
    let maxY = max((scale - 1) * container.height / 2, 0)
    let clampedX = min(max(proposed.width, -maxX), maxX)
    let clampedY = min(max(proposed.height, -maxY), maxY)
    return CGSize(width: clampedX, height: clampedY)
}
}
