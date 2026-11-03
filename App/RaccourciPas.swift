import AppIntents
import Foundation
import WidgetKit

extension Notification.Name {
    /// Envoyée quand un raccourci a modifié le fichier de données pendant que l'appli tourne.
    static let donneesModifiees = Notification.Name("donneesModifiees")
}

/// Reçoit le nombre de pas depuis l'app Raccourcis, qui, elle, a accès à Santé.
/// (Avec un compte Apple gratuit, l'appli n'a pas le droit de lire Santé elle-même.)
struct EnregistrerPas: AppIntent {
    static let title: LocalizedStringResource = "Enregistrer mes pas"
    static let description = IntentDescription("Envoie à Ma routine ton nombre de pas d'aujourd'hui, par exemple depuis Santé.")
    static let openAppWhenRun = false

    @Parameter(title: "Nombre de pas", inclusiveRange: (0, 200_000)) var pas: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Enregistrer \(\.$pas) pas aujourd'hui")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Même journée que dans l'appli (elle commence à 5 h) ; entre minuit et 5 h, le total de Santé
        // repart de zéro, et le « max » ci-dessous garde alors celui de la veille.
        let cle = Temps.journee()
        var d = Stockage.charger()
        var j = d.marche[cle] ?? JourMarche(date: cle)
        j.pas = max(j.pas, pas)          // les pas ne font qu'augmenter dans la journée
        d.marche[cle] = j
        Stockage.sauver(d)
        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .donneesModifiees, object: nil)
        return .result(dialog: "\(j.pas) pas enregistrés dans Ma routine.")
    }
}

struct RaccourcisMaRoutine: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: EnregistrerPas(),
                    phrases: ["Enregistrer mes pas dans \(.applicationName)"],
                    shortTitle: "Enregistrer mes pas",
                    systemImageName: "figure.walk")
    }
}
