import SwiftUI

/// Convertit « HH:mm » en date du jour, pour les sélecteurs d'heure.
func liaisonHeure(_ b: Binding<String>) -> Binding<Date> {
    Binding(get: {
        let m = Temps.minutes(b.wrappedValue)
        return Temps.calendrier.date(bySettingHour: m / 60 % 24, minute: m % 60, second: 0, of: Date()) ?? Date()
    }, set: { b.wrappedValue = Temps.heure($0) })
}

struct JourneeView: View {
    @EnvironmentObject var m: Magasin
    @State private var demain = false
    @State private var feuille: Feuille?
    @State private var reglesOuvertes = false

    enum Feuille: Identifiable {
        case routine, activite(String, Activite?)
        var id: String { switch self { case .routine: "routine"; case .activite(let c, let a): "act-\(c)-\(a?.id ?? "neuve")" } }
    }

    var cle: String { demain ? Temps.demain(m.maintenant) : Temps.journee(m.maintenant) }

    var body: some View {
        let d = m.d, j = d.jour(cle), t = d.type(j.type), liste = d.activites(cle)
        let actif = demain ? nil : d.indexActif(liste, Temps.maintenant(m.maintenant))
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Jour affiché", selection: $demain) {
                        Text("Aujourd'hui").tag(false)
                        Text("Demain").tag(true)
                    }
                    .pickerStyle(.segmented)

                    choixType(j: j, t: t)

                    if demain { resumeDemain(t: t, liste: liste) } else { heros(j: j, t: t, liste: liste, actif: actif) }

                    HStack(alignment: .firstTextBaseline) {
                        Text(demain ? "Ta journée de demain" : "Ta journée").font(.title2.bold())
                        Spacer()
                        Button("Modifier ma routine") { feuille = .routine }.font(.subheadline.weight(.semibold))
                    }
                    .padding(.top, 4)

                    Carte(espacement: 0) {
                        if liste.isEmpty {
                            Text("Aucune activité. Ajoute-en une ci-dessous.").foregroundStyle(.secondary).padding(.vertical, 8)
                        }
                        ForEach(Array(liste.enumerated()), id: \.element.id) { i, a in
                            if i > 0 { Divider().padding(.leading, 44) }
                            ligne(a, fait: j.faits[a.id] == true, actif: i == actif)
                        }
                    }

                    Button { feuille = .activite(cle, nil) } label: {
                        Label(demain ? "Ajouter une activité demain" : "Ajouter une activité aujourd'hui", systemImage: "plus")
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])).foregroundStyle(Color(.systemGray3)))
                    }
                    .font(.headline)

                    Carte {
                        DisclosureGroup(isExpanded: $reglesOuvertes) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(d.routine.regles.filter { !$0.titre.isEmpty || !$0.texte.isEmpty }) { r in
                                    (Text(r.titre).bold().foregroundColor(.primary) + Text(" " + r.texte).foregroundColor(.secondary)).font(.subheadline)
                                }
                            }
                            .padding(.top, 8)
                        } label: {
                            Text("Les règles qui font tenir la routine").font(.headline).foregroundStyle(.primary)
                        }
                    }

                    Text("Conseils généraux, pas un avis médical. Si les difficultés à dormir durent, parles-en à un médecin.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(demain ? "Demain" : "Aujourd'hui")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(d.type(d.jour(Temps.journee(m.maintenant)).type).emoji) Jour \(d.type(d.jour(Temps.journee(m.maintenant)).type).nom.lowercased())")
                        .font(.caption.weight(.bold)).foregroundStyle(Theme.accent)
                }
            }
            .sheet(item: $feuille) { f in
                switch f {
                case .routine: RoutineFeuille().environmentObject(m)
                case .activite(let c, let a): ActiviteFeuille(cle: c, existante: a).environmentObject(m)
                }
            }
        }
    }

    // MARK: Morceaux

    func choixType(j: Jour, t: TypeJour) -> some View {
        Carte {
            Text(demain ? "Demain, c'est…" : (j.typeChoisi ? "Type de journée" : "Aujourd'hui, c'est salle ou repos ?")).font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(m.d.routine.types) { x in
                    let choisi = x.id == t.id
                    Button { m.d.choisirType(cle, x.id) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(x.emoji).font(.largeTitle)
                            Text(x.nom).font(.title3.bold())
                            Text(m.d.resume(x)).font(.caption).foregroundStyle(choisi ? .white.opacity(0.9) : .secondary).lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .foregroundStyle(choisi ? .white : .primary)
                        .background {
                            if choisi { RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.degrade) }
                            else { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color(.separator), lineWidth: 1) }
                        }
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: choisi)
                }
            }
        }
        .overlay {
            if !demain && !j.typeChoisi { RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.rose2, lineWidth: 1.5) }
        }
    }

    func heros(j: Jour, t: TypeJour, liste: [Activite], actif: Int?) -> some View {
        let n = liste.filter { j.faits[$0.id] == true }.count
        let suite: String = {
            if !liste.isEmpty && n == liste.count { return "Journée complète. Bravo." }
            let depuis = actif ?? 0
            if let k = liste.indices.first(where: { $0 >= depuis && j.faits[liste[$0].id] != true }) {
                return (k == actif ? "Maintenant" : "Ensuite à \(Temps.affiche(liste[k].etape.heure))") + " : \(liste[k].etape.titre)"
            }
            return "Coche ce que tu as fait plus tôt."
        }()
        return CarteRose {
            HStack(spacing: 18) {
                Anneau(valeur: liste.isEmpty ? 0 : Double(n) / Double(liste.count)).frame(width: 84, height: 84)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Jour \(t.nom.lowercased())").font(.caption.weight(.bold)).textCase(.uppercase).opacity(0.92)
                    Text("\(n) sur \(liste.count)").font(.system(size: 34, weight: .heavy, design: .rounded)).contentTransition(.numericText())
                    Text(suite).font(.subheadline.weight(.medium))
                }
            }
            HStack(spacing: 8) {
                ForEach(["Lever \(Temps.affiche(m.d.routine.lever))", "Coucher \(Temps.affiche(m.d.routine.coucher))"], id: \.self) { s in
                    Text(s).font(.caption.weight(.bold)).monospacedDigit()
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Color.white.opacity(0.2), in: Capsule())
                }
            }
            .padding(.top, 6)
        }
    }

    func resumeDemain(t: TypeJour, liste: [Activite]) -> some View {
        let rappels = liste.filter(\.etape.rappel).count
        return CarteRose {
            Text("Demain · \(Temps.courte(cle))").font(.caption.weight(.bold)).textCase(.uppercase).opacity(0.92)
            Text("\(t.emoji) Jour \(t.nom.lowercased())").font(.title.bold())
            Text("\(liste.count) activité\(liste.count > 1 ? "s" : "") · \(rappels) rappel\(rappels > 1 ? "s" : "") · lever \(Temps.affiche(m.d.routine.lever))")
                .font(.subheadline.weight(.medium))
        }
    }

    func ligne(_ a: Activite, fait: Bool, actif: Bool) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button {
                guard !demain else { return }
                m.d.basculer(cle, a.id)
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    if demain {
                        Image(systemName: a.etape.rappel ? "bell.fill" : "circle.fill")
                            .font(.system(size: a.etape.rappel ? 13 : 6)).foregroundStyle(Theme.accent)
                            .frame(width: 28, height: 28).background(Color(.tertiarySystemFill), in: Circle())
                    } else {
                        Coche(faite: fait)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.etape.titre).font(.body.weight(.semibold))
                            .strikethrough(fait, color: .secondary).foregroundStyle(fait ? .secondary : .primary)
                        if !a.etape.note.isEmpty { Text(a.etape.note).font(.subheadline).foregroundStyle(.secondary) }
                    }
                    Spacer(minLength: 4)
                    HStack(spacing: 3) {
                        if a.etape.rappel { Image(systemName: "bell").font(.caption2) }
                        Text(actif ? "Maintenant" : Temps.affiche(a.etape.heure)).monospacedDigit()
                    }
                    .font(.footnote.weight(actif ? .bold : .regular))
                    .foregroundStyle(actif ? .white : .secondary)
                    .padding(.horizontal, actif ? 8 : 0).padding(.vertical, actif ? 3 : 0)
                    .background { if actif { Capsule().fill(Theme.degrade) } }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: fait) { _, nouveau in nouveau }

            Button { feuille = .activite(cle, a) } label: {
                Image(systemName: "pencil").foregroundStyle(.secondary).frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Modifier \(a.etape.titre)")
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Ajouter ou modifier une activité

struct ActiviteFeuille: View {
    @EnvironmentObject var m: Magasin
    @Environment(\.dismiss) var fermer
    let cle: String
    let existante: Activite?
    @State private var e = Etape(id: "", heure: "12:00", titre: "")
    @State private var pourLaRoutine = false
    @State private var confirmer = false

    var body: some View {
        let t = m.d.type(m.d.jour(cle).type)
        let aujourdhui = cle == Temps.journee()
        NavigationStack {
            Form {
                Section {
                    TextField("Appeler le garage, cardio, courses…", text: $e.titre)
                    DatePicker("Heure", selection: liaisonHeure($e.heure), displayedComponents: .hourAndMinute)
                    Toggle("Me prévenir à l'heure", isOn: $e.rappel).tint(Theme.accent)
                    TextField("Note (facultatif)", text: $e.note)
                } footer: {
                    Text("\(aujourdhui ? "Aujourd'hui" : "Demain") · jour \(t.nom.lowercased()). Le rappel arrive même appli fermée, avec le son de l'appli.")
                }
                Section(existante == nil ? "Ajouter à" : "Appliquer à") {
                    Picker("Portée", selection: $pourLaRoutine) {
                        Text(aujourdhui ? "Aujourd'hui seulement" : "Demain seulement").tag(false)
                        Text("Tous les jours \(t.nom.lowercased())").tag(true)
                    }
                    .pickerStyle(.inline).labelsHidden()
                }
                if let ex = existante {
                    Section {
                        Button(role: .destructive) { confirmer = true } label: {
                            Text(pourLaRoutine && ex.depuisRoutine ? "Supprimer de ma routine" : (aujourdhui ? "Retirer d'aujourd'hui" : "Retirer de demain"))
                        }
                    }
                }
            }
            .navigationTitle(existante == nil ? "Nouvelle activité" : "Modifier l'activité")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { fermer() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existante == nil ? "Ajouter" : "Enregistrer") {
                        var v = e; v.titre = v.titre.trimmingCharacters(in: .whitespaces); v.note = v.note.trimmingCharacters(in: .whitespaces)
                        m.d.enregistrerActivite(cle, existante: existante, valeur: v, pourLaRoutine: pourLaRoutine)
                        fermer()
                    }
                    .disabled(e.titre.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Retirer cette activité ?", isPresented: $confirmer, titleVisibility: .visible) {
                Button("Retirer", role: .destructive) {
                    if let ex = existante { m.d.retirerActivite(cle, ex, deLaRoutine: pourLaRoutine) }
                    fermer()
                }
            }
            .onAppear {
                if let ex = existante { e = ex.etape }
                else {
                    let mn = min(1439, ((Temps.maintenant() + 30) % 1440 + 14) / 15 * 15)
                    e = Etape(id: "", heure: String(format: "%02d:%02d", mn / 60 % 24, mn % 60), titre: "")
                    if !aujourdhui { e.heure = m.d.routine.lever }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Ma routine

struct RoutineFeuille: View {
    @EnvironmentObject var m: Magasin
    @Environment(\.dismiss) var fermer
    @State private var typeSel = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Horaires") {
                    DatePicker("Lever", selection: liaisonHeure($m.d.routine.lever), displayedComponents: .hourAndMinute)
                    DatePicker("Coucher", selection: liaisonHeure($m.d.routine.coucher), displayedComponents: .hourAndMinute)
                }
                Section {
                    ForEach($m.d.routine.types) { $t in
                        HStack {
                            TextField("😀", text: $t.emoji).frame(width: 44).multilineTextAlignment(.center)
                            TextField("Nom du type", text: $t.nom)
                        }
                    }
                    .onDelete { i in
                        guard m.d.routine.types.count - i.count >= 1 else { return }
                        m.d.routine.types.remove(atOffsets: i)
                    }
                    Button("Nouveau type de jour") {
                        let base = m.d.routine.types.first { $0.id == typeSel } ?? m.d.routine.types[0]
                        let n = TypeJour(id: nouvelId(), nom: "Nouveau type", emoji: "📅", etapes: base.etapes.map { var e = $0; e.id = nouvelId(); return e })
                        m.d.routine.types.append(n); typeSel = n.id
                    }
                } header: { Text("Types de jour") } footer: {
                    Text("Glisse vers la gauche pour supprimer un type. Un nouveau type reprend les activités du type sélectionné plus bas.")
                }
                Section {
                    Picker("Type", selection: $typeSel) {
                        ForEach(m.d.routine.types) { t in Text("\(t.emoji) \(t.nom)").tag(t.id) }
                    }
                    if let ti = m.d.routine.types.firstIndex(where: { $0.id == typeSel }) {
                        ForEach($m.d.routine.types[ti].etapes) { $e in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    DatePicker("Heure", selection: liaisonHeure($e.heure), displayedComponents: .hourAndMinute).labelsHidden()
                                    TextField("Activité", text: $e.titre).font(.body.weight(.semibold))
                                    Toggle("Rappel", isOn: $e.rappel).labelsHidden().tint(Theme.accent)
                                }
                                TextField("Note", text: $e.note).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { m.d.routine.types[ti].etapes.remove(atOffsets: $0) }
                        Button("Ajouter une activité") {
                            m.d.routine.types[ti].etapes.append(Etape(id: nouvelId(), heure: "18:00", titre: "Nouvelle activité"))
                        }
                    }
                } header: { Text("Activités de chaque type") } footer: {
                    Text("L'interrupteur active le rappel à l'heure de l'activité.")
                }
                Section("Règles") {
                    ForEach($m.d.routine.regles) { $r in
                        VStack(alignment: .leading) {
                            TextField("La règle", text: $r.titre).font(.body.weight(.semibold))
                            TextField("Le détail", text: $r.texte).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { m.d.routine.regles.remove(atOffsets: $0) }
                    Button("Ajouter une règle") { m.d.routine.regles.append(Regle(titre: "", texte: "")) }
                }
            }
            .navigationTitle("Ma routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") {
                        for i in m.d.routine.types.indices {
                            m.d.routine.types[i].etapes.sort { Temps.minutesJour($0.heure) < Temps.minutesJour($1.heure) }
                        }
                        fermer()
                    }
                }
            }
            .onAppear { typeSel = m.d.jour(Temps.journee()).type ?? m.d.routine.types[0].id }
        }
    }
}
