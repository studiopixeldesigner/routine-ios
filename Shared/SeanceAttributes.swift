import ActivityKit
import Foundation

/// Données de l'activité en direct (Dynamic Island et écran verrouillé) pendant une séance.
struct SeanceAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var exercice: String
        var serie: String
        var finRepos: Date?
        var faites: Int
        var total: Int
    }
    var nomSeance: String
    var debut: Date
}
