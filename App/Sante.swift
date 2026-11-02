import Foundation
import HealthKit

/// Pas lus dans l'app Santé. Si SideStore n'a pas accordé l'accès à Santé,
/// l'appli continue avec la saisie des pas à la main.
@MainActor
final class Sante: ObservableObject {
    static let partage = Sante()
    private let store = HKHealthStore()
    @Published var pasParJour: [String: Int] = [:]
    @Published var etat: Etat = .inconnu

    enum Etat: Equatable { case inconnu, indisponible, actif, refuse(String) }

    var disponible: Bool { HKHealthStore.isHealthDataAvailable() }

    func demander() async {
        guard disponible else { etat = .indisponible; return }
        do {
            try await store.requestAuthorization(toShare: [], read: [HKQuantityType(.stepCount)])
            etat = .actif
            await lirePas()
        } catch {
            etat = .refuse(error.localizedDescription)
        }
    }

    /// Total de pas par jour sur les 14 derniers jours.
    func lirePas() async {
        guard disponible else { return }
        let cal = Temps.calendrier
        let aujourdhui = cal.startOfDay(for: Date())
        guard let debut = cal.date(byAdding: .day, value: -13, to: aujourdhui) else { return }
        let type = HKQuantityType(.stepCount)
        let predicat = HKQuery.predicateForSamples(withStart: debut, end: nil)
        let requete = HKStatisticsCollectionQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicat),
            options: .cumulativeSum, anchorDate: aujourdhui, intervalComponents: DateComponents(day: 1))
        do {
            let resultat = try await requete.result(for: store)
            var m: [String: Int] = [:]
            resultat.enumerateStatistics(from: debut, to: Date()) { stat, _ in
                m[Temps.cle(stat.startDate)] = Int(stat.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            }
            pasParJour = m
            if etat != .actif { etat = .actif }
        } catch {
            etat = .refuse(error.localizedDescription)
        }
    }
}
