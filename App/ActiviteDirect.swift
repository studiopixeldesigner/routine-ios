import ActivityKit
import Foundation

/// Séance affichée dans la Dynamic Island et sur l'écran verrouillé.
enum ActiviteDirect {
    static func contenu(_ s: SeanceEnCours) -> SeanceAttributes.ContentState {
        let total = s.exos.reduce(0) { $0 + $1.series.count }
        let faites = s.exos.reduce(0) { $0 + $1.series.filter(\.fait).count }
        let exo = s.exos.first { $0.series.contains { !$0.fait } } ?? s.exos.last
        let n = exo.map { e in (e.series.firstIndex { !$0.fait } ?? (e.series.count - 1)) + 1 } ?? 0
        let serie = exo.map { "Série \(n)/\($0.series.count)" } ?? ""
        let repos = s.finRepos.flatMap { $0 > Date() ? $0 : nil }
        return .init(exercice: exo?.nom ?? s.nom, serie: serie, finRepos: repos, faites: faites, total: total)
    }

    static func demarrer(_ s: SeanceEnCours) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        terminer()
        let attr = SeanceAttributes(nomSeance: s.nom, debut: s.debut)
        _ = try? Activity.request(attributes: attr, content: .init(state: contenu(s), staleDate: nil))
    }

    static func mettreAJour(_ s: SeanceEnCours) {
        let etat = contenu(s)
        Task {
            if Activity<SeanceAttributes>.activities.isEmpty { demarrer(s); return }
            for a in Activity<SeanceAttributes>.activities { await a.update(.init(state: etat, staleDate: nil)) }
        }
    }

    static func terminer() {
        Task { for a in Activity<SeanceAttributes>.activities { await a.end(nil, dismissalPolicy: .immediate) } }
    }
}
