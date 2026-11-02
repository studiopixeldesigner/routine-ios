import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct MaRoutineWidgets: WidgetBundle {
    var body: some Widget {
        JourneeWidget()
        SeanceLiveActivity()
    }
}

private let rose = LinearGradient(colors: [Color(red: 0.95, green: 0.27, blue: 0.56), Color(red: 0.87, green: 0.16, blue: 0.47), Color(red: 0.71, green: 0.09, blue: 0.37)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
private let roseClair = Color(red: 1.0, green: 0.48, blue: 0.72)

// MARK: - Widget de la journée

struct EntreeJournee: TimelineEntry {
    let date: Date
    let cle: String
    let type: String
    let faites: Int
    let total: Int
    let actuelle: Etape?
    let suivantes: [(etape: Etape, faite: Bool)]
}

struct FournisseurJournee: TimelineProvider {
    func entree(_ d: Donnees, a date: Date) -> EntreeJournee {
        let cle = Temps.journee(date), j = d.jour(cle), t = d.type(j.type), liste = d.activites(cle)
        let actif = d.indexActif(liste, Temps.maintenant(date))
        let depuis = actif ?? 0
        let suivantes = liste.indices.filter { $0 >= depuis }.prefix(3).map { (etape: liste[$0].etape, faite: j.faits[liste[$0].id] == true) }
        return EntreeJournee(date: date, cle: cle, type: "\(t.emoji) \(t.nom)", faites: liste.filter { j.faits[$0.id] == true }.count,
                             total: liste.count, actuelle: actif.map { liste[$0].etape }, suivantes: Array(suivantes))
    }

    func placeholder(in context: Context) -> EntreeJournee { entree(Donnees(), a: .now) }
    func getSnapshot(in context: Context, completion: @escaping (EntreeJournee) -> Void) { completion(entree(Stockage.charger(), a: .now)) }

    /// Une entrée maintenant, puis une à chaque heure d'activité : « Maintenant » change tout seul.
    func getTimeline(in context: Context, completion: @escaping (Timeline<EntreeJournee>) -> Void) {
        let d = Stockage.charger(), maintenant = Date(), cle = Temps.journee(maintenant)
        var dates = [maintenant]
        for a in d.activites(cle) {
            if let x = Temps.dateReelle(cle, a.etape.heure), x > maintenant { dates.append(x) }
        }
        if let lendemain = Temps.dateReelle(Temps.demain(maintenant), "05:00") { dates.append(lendemain) }
        let entrees = dates.sorted().prefix(20).map { entree(d, a: $0) }
        completion(Timeline(entries: Array(entrees), policy: .atEnd))
    }
}

struct VueJournee: View {
    @Environment(\.widgetFamily) var famille
    let e: EntreeJournee
    var progression: Double { e.total > 0 ? Double(e.faites) / Double(e.total) : 0 }

    var body: some View {
        switch famille {
        case .accessoryCircular:
            Gauge(value: progression) { Text("Jour") } currentValueLabel: { Text("\(e.faites)/\(e.total)") }
                .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("\(e.faites)/\(e.total) · \(e.type)").font(.headline)
                if let a = e.actuelle { Text("Maintenant : \(a.titre)").lineLimit(1) }
                if let s = e.suivantes.first(where: { !$0.faite && $0.etape.id != e.actuelle?.id }) {
                    Text("\(Temps.affiche(s.etape.heure)) \(s.etape.titre)").lineLimit(1).foregroundStyle(.secondary)
                }
            }
        case .systemMedium, .systemLarge:
            HStack(spacing: 14) {
                anneau.frame(width: 76, height: 76)
                VStack(alignment: .leading, spacing: 6) {
                    Text(e.type).font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.9))
                    ForEach(e.suivantes, id: \.etape.id) { s in
                        Button(intent: CocherActivite(cle: e.cle, id: s.etape.id)) {
                            HStack(spacing: 8) {
                                Image(systemName: s.faite ? "checkmark.circle.fill" : "circle").font(.body.weight(.semibold))
                                Text(s.etape.titre).font(.subheadline.weight(.semibold)).lineLimit(1).strikethrough(s.faite)
                                Spacer(minLength: 0)
                                Text(s.etape.id == e.actuelle?.id ? "Maint." : Temps.affiche(s.etape.heure)).font(.caption).monospacedDigit()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .foregroundStyle(.white)
        default:
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    anneau.frame(width: 50, height: 50)
                    Spacer()
                    Text(e.type).font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.9))
                }
                Spacer(minLength: 0)
                if let a = e.actuelle {
                    Text("Maintenant").font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.85))
                    Text(a.titre).font(.subheadline.weight(.bold)).lineLimit(2)
                } else if let s = e.suivantes.first {
                    Text("À \(Temps.affiche(s.etape.heure))").font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.85))
                    Text(s.etape.titre).font(.subheadline.weight(.bold)).lineLimit(2)
                }
            }
            .foregroundStyle(.white)
        }
    }

    var anneau: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.28), lineWidth: 8)
            Circle().trim(from: 0, to: max(0.001, progression)).stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90)).opacity(e.faites > 0 ? 1 : 0)
            Text("\(e.faites)/\(e.total)").font(.system(.headline, design: .rounded).weight(.heavy)).foregroundStyle(.white)
        }
    }
}

struct JourneeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "journee", provider: FournisseurJournee()) { e in
            VueJournee(e: e).containerBackground(for: .widget) { rose }
        }
        .configurationDisplayName("Ma journée")
        .description("Où tu en es dans ta routine, avec les coches.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

// MARK: - Séance en direct (Dynamic Island et écran verrouillé)

struct SeanceLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SeanceAttributes.self) { context in
            HStack(spacing: 14) {
                Image(systemName: "dumbbell.fill").font(.title2).foregroundStyle(.white)
                    .frame(width: 48, height: 48).background(rose, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.nomSeance).font(.caption.weight(.bold)).foregroundStyle(roseClair)
                    Text(context.state.exercice).font(.headline).lineLimit(1)
                    Text(context.state.serie).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let fin = context.state.finRepos, fin > Date() {
                        Text("Repos").font(.caption.weight(.bold)).foregroundStyle(roseClair)
                        Text(timerInterval: Date()...fin, countsDown: true).font(.title2.weight(.bold)).monospacedDigit().multilineTextAlignment(.trailing).frame(width: 80)
                    } else {
                        Text("\(context.state.faites)/\(context.state.total)").font(.title2.weight(.bold)).monospacedDigit()
                        Text("séries").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.55))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "dumbbell.fill").font(.title2).foregroundStyle(roseClair).padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let fin = context.state.finRepos, fin > Date() {
                        Text(timerInterval: Date()...fin, countsDown: true).font(.title2.weight(.bold)).monospacedDigit().foregroundStyle(roseClair).frame(width: 76)
                    } else {
                        Text("\(context.state.faites)/\(context.state.total)").font(.title2.weight(.bold)).monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.exercice).font(.headline).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        HStack {
                            Text(context.state.serie)
                            Spacer()
                            Text(context.state.finRepos.map { $0 > Date() ? "Repos en cours" : "À toi de jouer" } ?? "À toi de jouer")
                        }
                        .font(.subheadline).foregroundStyle(.secondary)
                        ProgressView(value: Double(context.state.faites), total: Double(max(1, context.state.total))).tint(roseClair)
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill").foregroundStyle(roseClair)
            } compactTrailing: {
                if let fin = context.state.finRepos, fin > Date() {
                    Text(timerInterval: Date()...fin, countsDown: true).monospacedDigit().foregroundStyle(roseClair).frame(width: 42)
                } else {
                    Text("\(context.state.faites)/\(context.state.total)").monospacedDigit()
                }
            } minimal: {
                Image(systemName: "dumbbell.fill").foregroundStyle(roseClair)
            }
            .keylineTint(roseClair)
        }
    }
}
