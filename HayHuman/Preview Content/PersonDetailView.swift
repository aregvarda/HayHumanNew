import SwiftUI

struct PersonDetailView: View {
    let person: Person
    var body: some View {
        VStack(spacing: 12) {
            Image(person.imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text(person.name).font(.title.bold())
            Text(person.subtitle).foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
