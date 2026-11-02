import Charts
import SwiftUI

struct ProgresView: View {
    @EnvironmentObject var m: Magasin
    @State private var exo = ""
    @State private var aSupprimer: SeanceFaite?
    let objectifSeances = 4

    var body: some View {
        let d = m.d, auj = Temps.journee(m.maintenant), lundi = Temps.lundi(auj)
        let semaine = d.seances.filter { $0.date >= lundi }
        let jours = Temps.semaine(auj).filter { $0 <= auj }
        let pas = jours.compactMap { d.marche[$0]?.pas }.filter { $0 > 0 }
        let repasOk = jours.filter { k in let p = d.planDu(k), n = d.nutritionDu(k); return !p.isEmpty && p.allSatisfy { n.manges[$0.id] == true } }.count
        let pesees = d.pesees.sorted { $0.key < $1.key }
        let ecartPoids: Double? = pesees.count > 1 ? (pesees.last!.value - pesees.first!.value) : nil
        let mois = String(auj.prefix(7))
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        tuile("\(semaine.count) / \(objectifSeances)", "séances muscu cette semaine", vedette: true)
                        tuile("\(entier(semaine.reduce(0) { $0 + $1.volume })) kg", "volume soulevé cette semaine")
                        tuile(pas.isEmpty ? "–" : entier(Double(pas.reduce(0, +)) / Double(pas.count)), "pas par jour en moyenne cette semaine")
                        tuile("\(repasOk) / \(jours.count)", "jours où tu as suivi tout ton plan repas")
                        tuile(pesees.isEmpty ? "–" : "\(decimal(d.poidsActuel)) kg",
                              ecartPoids.map { "poids · \($0 > 0 ? "+" : $0 < 0 ? "−" : "")\(decimal(abs($0))) kg depuis le début" } ?? "poids (à noter dans Profil)")
                        tuile("\(d.seances.filter { $0.date.hasPrefix(mois) }.count)", "séances ce mois")
                    }
                    courbeCharge
                    historique
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progrès")
            .confirmationDialog("Supprimer cette séance de l'historique ?", isPresented: Binding(get: { aSupprimer != nil }, set: { if !$0 { aSupprimer = nil } }), titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) { if let s = aSupprimer { m.d.seances.removeAll { $0.id == s.id } } }
            }
        }
    }

    func tuile(_ valeur: String, _ legende: String, vedette: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(valeur).font(.system(size: 26, weight: .heavy, design: .rounded)).monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
            Text(legende).font(.caption).foregroundStyle(vedette ? .white.opacity(0.9) : .secondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .padding(14)
        .foregroundStyle(vedette ? .white : .primary)
        .background {
            if vedette { RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.degrade) }
            else { RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.secondarySystemGroupedBackground)) }
        }
    }

    struct Point: Identifiable { let id: String; let date: Date; let max: Double; let reps: Double }

    var courbeCharge: some View {
        let noms = Array(Set(m.d.seances.flatMap { $0.exos.map(\.nom) })).sorted()
        let choisi = noms.contains(exo) ? exo : (noms.first ?? "")
        let points: [Point] = m.d.seances.compactMap { h in
            guard let x = h.exos.first(where: { $0.nom == choisi }), let maxi = x.series.map(\.charge).max(),
                  let date = Temps.date(h.date) else { return nil }
            return Point(id: h.id, date: date, max: maxi, reps: x.series.first { $0.charge == maxi }?.reps ?? 0)
        }
        return Carte {
            HStack {
                Text("Évolution de la charge").font(.title3.bold())
                Spacer()
                if !noms.isEmpty {
                    Picker("Exercice", selection: Binding(get: { choisi }, set: { exo = $0 })) {
                        ForEach(noms, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            }
            if points.isEmpty {
                Text("Termine ta première séance dans l'onglet Sport : la charge de chaque exercice apparaîtra ici, séance après séance.")
                    .foregroundStyle(.secondary)
            } else {
                Chart(points) { p in
                    AreaMark(x: .value("Date", p.date), y: .value("kg", p.max))
                        .foregroundStyle(LinearGradient(colors: [Theme.rose2.opacity(0.3), Theme.rose2.opacity(0)], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Date", p.date), y: .value("kg", p.max))
                        .foregroundStyle(Theme.degradeBarre)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    PointMark(x: .value("Date", p.date), y: .value("kg", p.max))
                        .foregroundStyle(Theme.accent)
                        .symbolSize(p.id == points.last?.id ? 90 : 36)
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) { _ in AxisValueLabel(format: .dateTime.day().month(.twoDigits)) } }
                .frame(height: 190)
                let record = points.max { $0.max < $1.max }!
                let ecart = points.last!.max - points.first!.max
                Text("Record : \(decimal(record.max)) kg × \(Int(record.reps)) le \(Temps.courte(Temps.cle(record.date)))"
                     + (points.count > 1 ? " · depuis le début : \(ecart >= 0 ? "+" : "−")\(decimal(abs(ecart))) kg" : ""))
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    var historique: some View {
        Carte(espacement: 0) {
            Text("Historique muscu").font(.title3.bold()).padding(.bottom, 8)
            if m.d.seances.isEmpty { Text("Aucune séance enregistrée pour l'instant.").foregroundStyle(.secondary) }
            ForEach(Array(m.d.seances.reversed())) { h in
                let nb = h.exos.reduce(0) { $0 + $1.series.count }
                Divider()
                HStack(spacing: 10) {
                    Text(Temps.courte(h.date)).font(.subheadline).foregroundStyle(.secondary).monospacedDigit().frame(width: 46, alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(h.nom).font(.subheadline.weight(.semibold))
                        Text("\(nb) série\(nb > 1 ? "s" : "") · \(h.duree) min").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(entier(h.volume)) kg").font(.subheadline).monospacedDigit()
                    Button { aSupprimer = h } label: { Image(systemName: "trash").foregroundStyle(.red.opacity(0.8)) }
                        .buttonStyle(.plain).accessibilityLabel("Supprimer la séance du \(Temps.courte(h.date))")
                }
                .padding(.vertical, 10)
            }
        }
    }
}
