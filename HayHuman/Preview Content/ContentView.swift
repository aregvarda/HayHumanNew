import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack { // теперь NavigationLink будет работать
            HomeScreen()
        }
    }
}

#Preview {
    ContentView()
}
