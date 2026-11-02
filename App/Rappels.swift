import Foundation
import UserNotifications

/// Rappels de la journée, fin du repos et fin de la marche : de vraies notifications,
/// qui arrivent même appli fermée, avec le son « Velours ».
enum Rappels {
    static let son = UNNotificationSound(named: UNNotificationSoundName("velours.wav"))

    static func demander() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Replanifie les rappels d'aujourd'hui et de demain (iOS en garde 64 au maximum).
    static func planifier(_ d: Donnees) {
        var demandes: [UNNotificationRequest] = []
        for cle in [Temps.journee(), Temps.demain()] {
            for a in d.activites(cle) where a.etape.rappel {
                guard let date = Temps.dateReelle(cle, a.etape.heure), date > Date() else { continue }
                let c = UNMutableNotificationContent()
                c.title = a.etape.titre
                c.body = a.etape.note.isEmpty ? "Prévu à \(Temps.affiche(a.etape.heure))" : a.etape.note
                c.sound = son
                let comps = Temps.calendrier.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                demandes.append(UNNotificationRequest(identifier: "act-\(cle)-\(a.id)", content: c,
                                                      trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
            }
        }
        let centre = UNUserNotificationCenter.current()
        centre.getPendingNotificationRequests { attente in
            centre.removePendingNotificationRequests(withIdentifiers: attente.map(\.identifier).filter { $0.hasPrefix("act-") })
            for r in demandes.prefix(60) { centre.add(r) }
        }
    }

    static func programmer(_ id: String, dans secondes: TimeInterval, titre: String, texte: String) {
        guard secondes > 0 else { return }
        let c = UNMutableNotificationContent()
        c.title = titre; c.body = texte; c.sound = son
        if #available(iOS 15.0, *) { c.interruptionLevel = .timeSensitive }
        let centre = UNUserNotificationCenter.current()
        centre.removePendingNotificationRequests(withIdentifiers: [id])
        centre.add(UNNotificationRequest(identifier: id, content: c, trigger: UNTimeIntervalNotificationTrigger(timeInterval: secondes, repeats: false)))
    }
    static func annuler(_ id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
    }
}
