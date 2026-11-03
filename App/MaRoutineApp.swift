import SwiftUI
import UserNotifications

/// Affiche aussi les rappels (avec leur son) quand l'appli est ouverte.
final class Delegue: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}

@main
struct MaRoutineApp: App {
    @UIApplicationDelegateAdaptor(Delegue.self) private var delegue
    @StateObject private var m = Magasin()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RacineView().environmentObject(m)
                // « maroutine://pas?n=8421 » : envoyé par le raccourci « Pas pour Ma routine » (il lit Santé).
                .onOpenURL { url in
                    guard url.host == "pas",
                          let n = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "n" })?.value,
                          let pas = Int(Double(n.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? -1),
                          pas >= 0 else { return }
                    let cle = Temps.journee()
                    var j = m.d.marche[cle] ?? JourMarche(date: cle)
                    j.pas = max(j.pas, pas)
                    m.d.marche[cle] = j
                    UserDefaults.standard.set(1, forKey: "sousSport")
                    UserDefaults.standard.set(1, forKey: "onglet")
                }
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
                IntroView(prenom: m.d.profil.prenom, photo: m.d.profil.photo, fige: Capture.arguments.contains("-intro")) {
                    withAnimation(.easeOut(duration: 0.45)) { intro = false }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.08)))
                .zIndex(1)
            }
        }
        .onAppear {
            // Pour les captures automatiques sur le simulateur (jamais utilisé sur ton iPhone) :
            // « -capture 2 » ouvre l'onglet 2 sans l'intro, « -demo » ajoute des séances et pesées d'exemple,
            // « -intro » garde l'intro affichée, « -seance » ouvre une séance en cours, « -marche » la marche.
            let a = Capture.arguments
            if let i = a.firstIndex(of: "-capture"), i + 1 < a.count, let n = Int(a[i + 1]) { onglet = n; intro = false }
            guard Capture.actif else { return }
            m.d.ajouterDemo()
            UserDefaults.standard.set(a.contains("-marche") ? 1 : 0, forKey: "sousSport")
            if a.contains("-seance") { m.d.demarrerDemo() } else { m.d.enCours = nil }
        }
        .task {
            if !Capture.actif { Rappels.demander() }
            Rappels.planifier(m.d)
            if let s = m.d.enCours { ActiviteDirect.mettreAJour(s) }
        }
    }
}

/// Arguments de lancement des captures automatiques.
enum Capture {
    static let arguments = ProcessInfo.processInfo.arguments
    static let actif = arguments.contains("-demo")
}

/// « Bonjour Rayan » pendant 2 secondes au lancement, avec ta photo. Un appui la passe.
struct IntroView: View {
    let prenom: String
    let photo: Data?
    var fige = false
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
            guard !fige else { return }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            fin()
        }
    }
}
