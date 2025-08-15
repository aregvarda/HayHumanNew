import SwiftUI

struct CategoryListView: View {
    let section: ArmenianSection

    var body: some View {
        List(MockData.filtered(by: section)) { person in
            NavigationLink(value: person) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(person.name)
                        .font(.system(.headline, design: .rounded)).bold()
                    Text(person.subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(section == .all
                         ? "Все личности"
                         : section.title.replacingOccurrences(of: "\n", with: " "))
        .navigationDestination(for: Person.self) { person in
            PersonDetailView(person: person)
        }
    }
}

struct PersonDetailView: View {
    let person: Person

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // сюда позже добавим фото, таймлайн, ссылки
                Text(person.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(person.subtitle)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)

                Divider().padding(.vertical, 8)

                Text("Здесь будет биография, фото, карта и ссылки…")
                    .font(.system(.body, design: .rounded))
            }
            .padding()
        }
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
