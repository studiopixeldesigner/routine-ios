import Combine
import SwiftUI
import WidgetKit

/// Garde toutes les données en mémoire, les enregistre peu après chaque changement,
/// prévient le widget et replanifie les rappels.
@MainActor
final class Magasin: ObservableObject {
    @Published var d: Donnees
    /// Avance toutes les 30 s pour que « Maintenant » et les minuteurs suivent l'heure.
    @Published var maintenant = Date()
    private var abonnements = Set<AnyCancellable>()
    private var derniereEcriture = Date.distantPast

    init() {
        d = Stockage.charger()
        derniereEcriture = Date()      // le fichier vient d'être lu : pas besoin de le relire à l'ouverture
        $d.dropFirst()
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] donnees in self?.enregistrer(donnees) }
            .store(in: &abonnements)
        Timer.publish(every: 30, on: .main, in: .common).autoconnect()
            .sink { [weak self] t in self?.maintenant = t }
            .store(in: &abonnements)
    }

    func enregistrer(_ donnees: Donnees? = nil) {
        let x = donnees ?? d
        Stockage.sauver(x)
        derniereEcriture = Date()
        WidgetCenter.shared.reloadAllTimelines()
        Rappels.planifier(x)
    }

    /// Au retour dans l'appli : reprend ce que le widget a pu cocher entre-temps.
    func recharger() {
        maintenant = Date()
        let attrs = try? FileManager.default.attributesOfItem(atPath: Stockage.fichier.path)
        if let modif = attrs?[.modificationDate] as? Date, modif > derniereEcriture.addingTimeInterval(1) {
            d = Stockage.charger()
        }
    }
}
