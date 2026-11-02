import SwiftUI

@main
struct MaRoutineApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Aujourd'hui").tabItem { Label("Journée", systemImage: "sun.max") }
            Text("Sport").tabItem { Label("Sport", systemImage: "dumbbell") }
            Text("Nutrition").tabItem { Label("Nutrition", systemImage: "fork.knife") }
            Text("Progrès").tabItem { Label("Progrès", systemImage: "chart.bar") }
            Text("Profil").tabItem { Label("Profil", systemImage: "person.crop.circle") }
        }
        .tint(Color.accentColor)
    }
}
