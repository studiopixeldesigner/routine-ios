import SwiftUI

@main
struct MaRoutineApp: App {
    @StateObject private var m = Magasin()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RacineView().environmentObject(m)
        }
        .onChange(of: phase) { _, p in
            if p == .active { m.recharger() }
            if p == .background { m.enregistrer() }
        }
    }
}

struct RacineView: View {
    @EnvironmentObject var m: Magasin
    @AppStorage("onglet") private var onglet = 0
    @State private var intro = true

    var body: some View {
        ZStack {
            TabView(selection: $onglet) {
                JourneeView().tabItem { Label("Journée", systemImage: "sun.max.fill") }.tag(0)
                SportView().tabItem { Label("Sport", systemImage: "dumbbell.fill") }.tag(1)
                NutritionView().tabItem { Label("Nutrition", systemImage: "fork.knife") }.tag(2)
                ProgresView().tabItem { Label("Progrès", systemImage: "chart.bar.fill") }.tag(3)
                ProfilView().tabItem { Label("Profil", systemImage: "person.crop.circle.fill") }.tag(4)
            }
            .tint(Theme.accent)

            if intro {
                IntroView(prenom: m.d.profil.prenom, photo: m.d.profil.photo) {
                    withAnimation(.easeOut(duration: 0.45)) { intro = false }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.08)))
                .zIndex(1)
            }
        }
        .task {
            Rappels.demander()
            Rappels.planifier(m.d)
            if let s = m.d.enCours { ActiviteDirect.mettreAJour(s) }
        }
    }
}

/// « Bonjour Rayan » pendant 2 secondes au lancement, avec ta photo. Un appui la passe.
struct IntroView: View {
    let prenom: String
    let photo: Data?
    let fin: () -> Void
    @State private var visible = false

    var body: some View {
        let h = Calendar.current.component(.hour, from: Date())
        let salut = (5..<18).contains(h) ? "Bonjour" : "Bonsoir"
        let sous = (5..<12).contains(h) ? "Prêt pour ta journée ?" : (5..<18).contains(h) ? "On continue sur ta lancée ?" : "On prépare la soirée ?"
        let nom = prenom.trimmingCharacters(in: .whitespaces).isEmpty ? "Rayan" : prenom
        ZStack {
            Theme.degrade.ignoresSafeArea()
            Circle().fill(RadialGradient(colors: [Color.white.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: 200))
                .frame(width: 380, height: 380).offset(x: 140, y: -300).blur(radius: 10)
            VStack(spacing: 18) {
                Group {
                    if let photo, let image = UIImage(data: photo) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Text(String(nom.prefix(1)).uppercased()).font(.system(size: 44, weight: .heavy, design: .rounded))
                    }
                }
                .frame(width: 104, height: 104)
                .background(Color.white.opacity(0.22))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 3))
                .shadow(color: Theme.rose4.opacity(0.4), radius: 18, y: 10)
                .scaleEffect(visible ? 1 : 0.4).opacity(visible ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: visible)

                VStack(spacing: 0) {
                    Text(salut)
                    Text(nom)
                }
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .offset(y: visible ? 0 : 24).opacity(visible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: visible)

                Text(sous).font(.headline).opacity(visible ? 0.95 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: visible)
            }
            .foregroundStyle(.white)
            .padding(24)
        }
        .contentShape(Rectangle())
        .onTapGesture { fin() }
        .task {
            visible = true
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            fin()
        }
    }
}
