import AppIntents
import Foundation
import WidgetKit

/// Coche ou décoche une activité directement depuis le widget.
struct CocherActivite: AppIntent {
    static let title: LocalizedStringResource = "Cocher une activité"
    static let description = IntentDescription("Coche une activité de ta journée.")

    @Parameter(title: "Jour") var cle: String
    @Parameter(title: "Activité") var id: String

    init() {}
    init(cle: String, id: String) {
        self.cle = cle
        self.id = id
    }

    func perform() async throws -> some IntentResult {
        var d = Stockage.charger()
        d.basculer(cle, id)
        Stockage.sauver(d)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
