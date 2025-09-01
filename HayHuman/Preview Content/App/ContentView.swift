import SwiftUI
import UIKit
import Combine

#if DEBUG
private struct DebugLog: View {
    let message: String
    var body: some View {
        Color.clear.frame(width: 0, height: 0)
            .onAppear { print(message) }
    }
}
#endif

private struct EventDetailScreen: View {
    let story: Story
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(story.title)
                    .font(.title.bold())
                if let name = story.imageName, !name.isEmpty, let ui = UIImage(named: name) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                if story.year != 0 {
                    Text("\(story.year)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let summary = story.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.body)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContentView: View {
    // Навигационный путь корневого стека
    @State private var path = NavigationPath()
    // Отложенный диплинк (на случай холодного старта)
    @AppStorage("pendingDeepLinkApp") private var pendingDeepLinkApp: String = ""
    @State private var deepLinkToast: String? = nil
    @State private var lastDeepLinkHandled: String = ""

    // Маршруты для навигации
    enum Route: Hashable {
        case personID(Int)     // stable model id
        case eventID(Int)
    }

    private func handleDeepLink(_ url: URL) {
        print("[DeepLink] handle: \(url.absoluteString)")
        if url.absoluteString == lastDeepLinkHandled {
            #if DEBUG
            print("[DeepLink] skip duplicate deeplink")
            #endif
            return
        }
        lastDeepLinkHandled = url.absoluteString
        guard url.scheme == "hayhuman" else { return }
        guard let kind = url.host else { return }              // person / event
        let idStr = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let idx = Int(idStr) else { return }
        deepLinkToast = url.absoluteString
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { deepLinkToast = nil }
        DispatchQueue.main.async {
            #if DEBUG
            print("[DeepLink] will navigate kind=\(kind) id=\(idx) currentPathCount=\(path.count)")
            #endif
            path = NavigationPath()
            #if DEBUG
            print("[DeepLink] path reset")
            #endif
            if kind == "person" {
                #if DEBUG
                print("[DeepLink] appending route: personID(\(idx))")
                #endif
                path.append(Route.personID(idx))
            } else if kind == "event" {
                #if DEBUG
                print("[DeepLink] appending route: eventID(\(idx))")
                #endif
                path.append(Route.eventID(idx))
            }
        }
    }

    // Helper to normalize incoming deeplinks from notifications (URL or String)
    private func urlFromNotificationObject(_ obj: Any?) -> URL? {
        if let url = obj as? URL { return url }
        if let s = obj as? String, let u = URL(string: s) { return u }
        if let dict = obj as? [String: Any], let s = dict["deeplink"] as? String, let u = URL(string: s) { return u }
        return nil
    }

    private func normalized(_ s: String) -> String {
        let ms = NSMutableString(string: s)
        // to Latin + strip diacritics
        CFStringTransform(ms, nil, kCFStringTransformToLatin, false)
        CFStringTransform(ms, nil, kCFStringTransformStripCombiningMarks, false)
        let latin = (ms as String).lowercased()
        let allowed = CharacterSet.alphanumerics
        return latin.unicodeScalars.filter { allowed.contains($0) }.map { String($0) }.joined()
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeScreen()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .personID(let modelID):
                        if let pByStable = LocalPeopleStore.personFull(byStableID: modelID) {
                            #if DEBUG
                            DebugLog(message: "[DeepLink] destination resolved person by stable id: \(modelID)")
                            #endif
                            PersonDetailView(person: pByStable)
                        } else if let pByIndex = LocalPeopleStore.personFull(at: modelID) { // backward compatibility
                            #if DEBUG
                            DebugLog(message: "[DeepLink] destination resolved person by index: \(modelID)")
                            #endif
                            PersonDetailView(person: pByIndex)
                        } else {
                            #if DEBUG
                            DebugLog(message: "[DeepLink] destination NOT resolved, param=\(modelID)")
                            #endif
                            let all = LocalPeopleStore.load(section: .all)
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                                Text("Person not found").font(.headline)
                                Text("param=\(modelID) allCount=\(all.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }

                    case .eventID(let modelID):
                        if let story = StoriesStore.find(byStableID: modelID) {
                            EventDetailScreen(story: story)
                                .navigationTitle(story.title)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                                Text("Event not found").font(.headline)
                                Text("id=\(modelID)").font(.caption).foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .HayHumanOpenDeepLink)) { note in
            if let url = urlFromNotificationObject(note.object) {
                print("[DeepLink] received(object): \(url.absoluteString)")
                handleDeepLink(url)
            } else if let info = note.userInfo,
                      let s = info["deeplink"] as? String,
                      let url = URL(string: s) {
                print("[DeepLink] received(userInfo): \(s)")
                handleDeepLink(url)
            } else {
                print("[DeepLink] received but no URL")
            }
        }
        .onAppear {
            if !pendingDeepLinkApp.isEmpty, let url = URL(string: pendingDeepLinkApp) {
                // small delay to ensure stack is mounted
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    handleDeepLink(url)
                    pendingDeepLinkApp = ""
                }
            }
        }
    }
}
