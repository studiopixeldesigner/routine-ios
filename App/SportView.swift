import Charts
import SwiftUI

struct SportView: View {
    @EnvironmentObject var m: Magasin
    @AppStorage("sousSport") private var sous = 0
    @AppStorage("onglet") private var onglet = 1
    @State private var edition: String?          // id de la séance du programme en cours de modification

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Activité", selection: $sous) {
                        Text("Musculation").tag(0)
                        Text("Marche").tag(1)
                    }
                    .pickerStyle(.segmented)
                    if sous == 1 {
                        MarcheView()
                    } else if m.d.enCours != nil {
                        SeanceEnCoursView { onglet = 3 }
                    } else {
                        programme
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 110)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sport")
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) { MinuteurRepos() }
            .sheet(item: Binding(get: { edition.map { IdSeance(id: $0) } }, set: { edition = $0?.id })) { x in
                SeanceEditeur(id: x.id).environmentObject(m)
            }
        }
    }

    struct IdSeance: Identifiable { let id: String }

    var programme: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let p = m.d.prochaineSeance() {
                Button { lancer(p) } label: {
                    VStack(spacing: 2) {
                        Text("Prochaine séance").font(.caption.weight(.bold)).textCase(.uppercase).opacity(0.9)
                        Text("Lancer « \(p.nom) »")
                    }
                }
                .buttonStyle(BoutonRose())
            }
            Text("Ton programme").font(.title2.bold()).padding(.top, 4)
            ForEach(Array(m.d.programme.enumerated()), id: \.element.id) { i, s in
                carteSeance(s, numero: i + 1)
            }
            Button {
                let n = SeanceProgramme(id: nouvelId(), nom: "Séance \(m.d.programme.count + 1)", exos: [Exercice(nom: "")])
                m.d.programme.append(n); edition = n.id
            } label: {
                Label("Nouvelle séance", systemImage: "plus").frame(maxWidth: .infinity).padding(.vertical, 14)
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])).foregroundStyle(Color(.systemGray3)))
            }
            .font(.headline)
        }
    }

    func carteSeance(_ s: SeanceProgramme, numero: Int) -> some View {
        let exos = s.exos.filter { !$0.nom.trimmingCharacters(in: .whitespaces).isEmpty }
        let der = m.d.derniereSeance(s.id)
        return Carte {
            HStack(spacing: 12) {
                Text("\(numero)").font(.headline.weight(.heavy)).foregroundStyle(.white).frame(width: 32, height: 32).background(Theme.degrade, in: Circle())
                Text(s.nom).font(.title3.bold()).lineLimit(2)
                Spacer()
                Button("Modifier") { edition = s.id }.font(.subheadline.weight(.semibold))
            }
            if exos.isEmpty {
                Text("Aucun exercice. Touche Modifier pour en ajouter.").font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(exos) { x in
                HStack(spacing: 12) {
                    PictoExercice(nom: x.nom, taille: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(x.nom).font(.subheadline.weight(.semibold))
                        Text(Muscles.legende(x.nom)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(x.series) × \(x.reps)" + (nombre(x.charge) > 0 ? " · \(decimal(nombre(x.charge))) kg" : ""))
                        .font(.subheadline).monospacedDigit().foregroundStyle(.secondary)
                }
            }
            HStack {
                Text(der.map { "Dernière fois le \(Temps.courte($0.date)) · \($0.duree) min" } ?? "Pas encore faite")
                    .font(.footnote).foregroundStyle(.secondary)
                Spacer()
                if !exos.isEmpty { Button("Lancer") { lancer(s) }.buttonStyle(BoutonRose(large: false)) }
            }
        }
    }

    func lancer(_ s: SeanceProgramme) {
        guard let seance = m.d.preparerSeance(s) else { return }
        m.d.enCours = seance
        ActiviteDirect.demarrer(seance)
    }
}

/// Silhouette de l'exercice dans un rond rose.
struct PictoExercice: View {
    let nom: String
    var taille: CGFloat = 40
    var body: some View {
        Image(systemName: Muscles.symbole(nom))
            .font(.system(size: taille * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: taille, height: taille)
            .background(Theme.degrade, in: RoundedRectangle(cornerRadius: taille * 0.32, style: .continuous))
    }
}

// MARK: - Séance en cours

struct SeanceEnCoursView: View {
    @EnvironmentObject var m: Magasin
    let terminee: () -> Void
    @State private var confirmerAbandon = false
    @State private var message = ""

    var body: some View {
        if let s = m.d.enCours {
            let total = s.exos.reduce(0) { $0 + $1.series.count }
            let faites = s.exos.reduce(0) { $0 + $1.series.filter(\.fait).count }
            VStack(alignment: .leading, spacing: 14) {
                CarteRose {
                    Text("Séance en cours · depuis \(Temps.affiche(Temps.heure(s.debut)))").font(.caption.weight(.bold)).textCase(.uppercase).opacity(0.92)
                    Text(s.nom).font(.title.bold())
                    HStack { Text("\(faites) / \(total) séries"); Spacer(); Text("\(total > 0 ? faites * 100 / total : 0) %") }
                        .font(.subheadline.weight(.semibold)).monospacedDigit()
                    Jauge(valeur: total > 0 ? Double(faites) / Double(total) : 0, surRose: true)
                }
                ForEach(Array(s.exos.enumerated()), id: \.element.id) { ex, e in
                    Carte(espacement: 10) {
                        HStack(spacing: 12) {
                            PictoExercice(nom: e.nom, taille: 44)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(e.nom).font(.headline)
                                Text("\(Muscles.legende(e.nom)) · repos \(e.repos / 60):\(String(format: "%02d", e.repos % 60))").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        if let der = m.d.derniereFois(e.nom) { Text(der).font(.footnote).foregroundStyle(.secondary) }
                        ForEach(Array(e.series.enumerated()), id: \.element.id) { se, serie in
                            ligneSerie(ex: ex, se: se, serie: serie)
                        }
                        Button("+ Série") {
                            let der = m.d.enCours?.exos[ex].series.last
                            m.d.enCours?.exos[ex].series.append(SerieEnCours(reps: der?.reps ?? "", charge: der?.charge ?? ""))
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
                Button("Terminer et enregistrer") { terminer() }.buttonStyle(BoutonRose())
                if !message.isEmpty { Text(message).font(.footnote).foregroundStyle(.secondary) }
                Button("Abandonner la séance", role: .destructive) { confirmerAbandon = true }
                    .frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .confirmationDialog("Abandonner la séance ?", isPresented: $confirmerAbandon, titleVisibility: .visible) {
                Button("Abandonner", role: .destructive) {
                    m.d.enCours = nil
                    Rappels.annuler("repos")
                    ActiviteDirect.terminer()
                }
            } message: { Text("Les séries validées ne seront pas enregistrées.") }
        }
    }

    func ligneSerie(ex: Int, se: Int, serie: SerieEnCours) -> some View {
        HStack(spacing: 8) {
            Text("S\(se + 1)").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).frame(width: 26, alignment: .leading)
            TextField("reps", text: liaison(ex, se, \.reps)).keyboardType(.numberPad).champ()
            Text("×").foregroundStyle(.secondary)
            TextField("kg", text: liaison(ex, se, \.charge)).keyboardType(.decimalPad).champ()
            Text("kg").font(.footnote).foregroundStyle(.secondary)
            Button { valider(ex, se) } label: { Coche(faite: serie.fait, taille: 40) }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: serie.fait) { _, n in n }
                .accessibilityLabel("Valider la série \(se + 1)")
        }
        .opacity(serie.fait ? 0.75 : 1)
    }

    func liaison(_ ex: Int, _ se: Int, _ k: WritableKeyPath<SerieEnCours, String>) -> Binding<String> {
        Binding(get: { m.d.enCours?.exos[safe: ex]?.series[safe: se]?[keyPath: k] ?? "" },
                set: { v in m.d.enCours?.exos[ex].series[se][keyPath: k] = v })
    }

    func valider(_ ex: Int, _ se: Int) {
        guard var s = m.d.enCours else { return }
        s.exos[ex].series[se].fait.toggle()
        if s.exos[ex].series[se].fait {
            let duree = TimeInterval(s.exos[ex].repos)
            s.finRepos = Date().addingTimeInterval(duree)
            Rappels.programmer("repos", dans: duree, titre: "Repos terminé", texte: "C'est reparti : \(s.exos[ex].nom)")
        }
        m.d.enCours = s
        ActiviteDirect.mettreAJour(s)
    }

    func terminer() {
        guard let s = m.d.enCours else { return }
        let exos = s.exos.map { e in
            ExoFait(nom: e.nom, series: e.series.filter { $0.fait && nombre($0.reps) > 0 }.map { SerieFaite(reps: nombre($0.reps), charge: nombre($0.charge)) })
        }.filter { !$0.series.isEmpty }
        guard !exos.isEmpty else { message = "Valide au moins une série (bouton ✓) avant d'enregistrer."; return }
        let volume = exos.reduce(0.0) { $0 + $1.series.reduce(0.0) { $0 + $1.reps * $1.charge } }
        m.d.seances.append(SeanceFaite(id: s.id, date: Temps.cle(s.debut), ts: s.debut.timeIntervalSince1970 * 1000, nom: s.nom,
                                       seanceId: s.seanceId, duree: Int(Date().timeIntervalSince(s.debut) / 60), volume: volume, exos: exos))
        m.d.enCours = nil
        m.d.cocherLien("seance")
        Rappels.annuler("repos")
        ActiviteDirect.terminer()
        terminee()
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

extension View {
    /// Champ de saisie gris arrondi.
    func champ() -> some View {
        self.multilineTextAlignment(.center).monospacedDigit()
            .padding(.vertical, 9).padding(.horizontal, 6)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

/// Minuteur de repos en bas de l'écran, au-dessus de la barre d'onglets.
struct MinuteurRepos: View {
    @EnvironmentObject var m: Magasin
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            if let fin = m.d.enCours?.finRepos, fin > ctx.date {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Repos").font(.caption.weight(.bold)).textCase(.uppercase).opacity(0.9)
                        Text(timerInterval: ctx.date...fin, countsDown: true).font(.title.weight(.bold)).monospacedDigit()
                    }
                    Spacer()
                    Button("−15") { decaler(-15) }.buttonStyle(PastilleBlanche())
                    Button("+15") { decaler(15) }.buttonStyle(PastilleBlanche())
                    Button("Passer") { decaler(nil) }.buttonStyle(PastilleBlanche())
                }
                .foregroundStyle(.white)
                .padding(.leading, 20).padding(.trailing, 10).padding(.vertical, 10)
                .background(Theme.degrade, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Theme.rose3.opacity(0.35), radius: 14, y: 6)
                .padding(.horizontal, 14).padding(.bottom, 6)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    func decaler(_ s: Double?) {
        guard var x = m.d.enCours, let fin = x.finRepos else { return }
        if let s {
            x.finRepos = fin.addingTimeInterval(s)
            Rappels.programmer("repos", dans: x.finRepos!.timeIntervalSinceNow, titre: "Repos terminé", texte: "C'est reparti !")
        } else {
            x.finRepos = nil
            Rappels.annuler("repos")
        }
        m.d.enCours = x
        ActiviteDirect.mettreAJour(x)
    }
}

struct PastilleBlanche: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.bold)).foregroundStyle(.white)
            .padding(.vertical, 9).padding(.horizontal, 12)
            .background(Color.white.opacity(configuration.isPressed ? 0.35 : 0.22), in: Capsule())
    }
}

// MARK: - Modifier une séance du programme

struct SeanceEditeur: View {
    @EnvironmentObject var m: Magasin
    @Environment(\.dismiss) var fermer
    let id: String
    @State private var confirmer = false

    var body: some View {
        NavigationStack {
            Form {
                if let i = m.d.programme.firstIndex(where: { $0.id == id }) {
                    Section("Nom de la séance") {
                        TextField("Poussée, Tirage, Jambes…", text: $m.d.programme[i].nom)
                    }
                    ForEach($m.d.programme[i].exos) { $x in
                        Section {
                            TextField("Exercice (ex. Développé couché)", text: $x.nom).font(.body.weight(.semibold))
                            HStack(spacing: 8) {
                                petitChamp("Séries", $x.series, .numberPad)
                                petitChamp("Reps", $x.reps, .numbersAndPunctuation)
                                petitChamp("kg", $x.charge, .decimalPad)
                                petitChamp("Repos (s)", $x.repos, .numberPad)
                            }
                            Button("Supprimer cet exercice", role: .destructive) {
                                m.d.programme[i].exos.removeAll { $0.id == x.id }
                            }
                            .font(.footnote)
                        }
                    }
                    Section {
                        Button("Ajouter un exercice") { m.d.programme[i].exos.append(Exercice(nom: "")) }
                        Button("Supprimer la séance", role: .destructive) { confirmer = true }
                    }
                }
            }
            .navigationTitle("Modifier la séance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Terminé") { fermer() } } }
            .confirmationDialog("Supprimer cette séance du programme ?", isPresented: $confirmer, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) { m.d.programme.removeAll { $0.id == id }; fermer() }
            }
        }
    }

    func petitChamp(_ titre: String, _ b: Binding<String>, _ clavier: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(titre).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            TextField(titre, text: b).keyboardType(clavier).champ()
        }
    }
}

// MARK: - Marche

struct MarcheView: View {
    @EnvironmentObject var m: Magasin
    @ObservedObject var sante = Sante.partage
    @State private var objectifOuvert = false
    @State private var objectifTexte = ""
    @State private var pasTexte = ""

    let objectifMinutes = 30.0

    var cle: String { Temps.journee(m.maintenant) }
    var pas: Int {
        if sante.etat == .actif, let p = sante.pasParJour[cle] { return p }
        return m.d.marche[cle]?.pas ?? 0
    }

    var body: some View {
        let obj = max(1, m.d.objectifPas), reste = max(0, obj - pas)
        VStack(alignment: .leading, spacing: 16) {
            Carte {
                HStack {
                    Text("Pas aujourd'hui").surtitre()
                    Spacer()
                    Button("Objectif \(entier(Double(obj)))") { objectifTexte = "\(obj)"; objectifOuvert = true }.font(.subheadline.weight(.semibold))
                }
                GrosChiffre(texte: entier(Double(pas)), unite: "pas")
                Jauge(valeur: Double(pas) / Double(obj))
                Text(pas >= obj ? "Objectif atteint. Bien joué." : "Encore \(entier(Double(reste))) pas, environ \(Int((Double(reste) / 100).rounded(.up))) min de marche.")
                    .font(.subheadline).foregroundStyle(.secondary)
                switch sante.etat {
                case .actif:
                    Label("Repris automatiquement de l'app Santé", systemImage: "heart.fill").font(.footnote).foregroundStyle(Theme.accent)
                case .refuse(let raison):
                    if (m.d.marche[cle]?.pas ?? 0) > 0 {
                        Label("Pas reçus de l'app Raccourcis", systemImage: "figure.walk").font(.footnote).foregroundStyle(Theme.accent)
                    } else {
                        Text("Avec un compte Apple gratuit, l'appli ne peut pas lire Santé elle-même. L'app Raccourcis peut t'envoyer tes pas automatiquement (raccourci « Enregistrer mes pas »), sinon recopie-les ici.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Text("Détail : \(raison)").font(.caption2).foregroundStyle(.tertiary).textSelection(.enabled)
                    saisieManuelle
                case .indisponible:
                    Text("Santé n'est pas disponible sur cet appareil : recopie tes pas ici.").font(.footnote).foregroundStyle(.secondary)
                    saisieManuelle
                default:
                    saisieManuelle
                }
            }
            chronoCarte
            Carte {
                Text("Cette semaine").font(.title3.bold())
                graphiqueSemaine(obj: obj)
                Text("Pointillés : ton objectif de \(entier(Double(obj))) pas.").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .task {
            guard !Capture.actif else { return }       // pas de fenêtre Santé pendant les captures
            if sante.etat == .inconnu { await sante.demander() } else { await sante.lirePas() }
        }
        .onChange(of: sante.pasParJour) { _, valeurs in
            for (k, v) in valeurs where v > 0 && (m.d.marche[k]?.pas ?? 0) != v {
                var j = m.d.marche[k] ?? JourMarche(date: k); j.pas = v; m.d.marche[k] = j
            }
        }
        .alert("Objectif de pas", isPresented: $objectifOuvert) {
            TextField("8000", text: $objectifTexte).keyboardType(.numberPad)
            Button("Annuler", role: .cancel) {}
            Button("Valider") { let v = Int(nombre(objectifTexte)); if v > 0 { m.d.objectifPas = v } }
        }
    }

    var saisieManuelle: some View {
        TextField("Total de pas de ton téléphone", text: Binding(
            get: { (m.d.marche[cle]?.pas ?? 0) > 0 ? "\(m.d.marche[cle]!.pas)" : "" },
            set: { v in var j = m.d.marche[cle] ?? JourMarche(date: cle); j.pas = Int(nombre(v)); m.d.marche[cle] = j }))
            .keyboardType(.numberPad)
            .padding(10).background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
    }

    // Marche de 30 min, qui continue appli fermée
    var chronoCarte: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let secondes = totalSecondes(ctx.date), p = min(1, secondes / (objectifMinutes * 60))
            Carte {
                HStack {
                    Text("Marche de 30 min").font(.title3.bold())
                    Spacer()
                    Text(m.d.activites(cle).contains { $0.etape.lien == "marche" } ? "Au programme" : "En bonus").font(.footnote).foregroundStyle(.secondary)
                }
                ZStack {
                    Anneau(valeur: p, epaisseur: 16, fond: Color(.tertiarySystemFill), trait: AnyShapeStyle(Theme.degrade))
                    VStack(spacing: 2) {
                        Text("\(Int(secondes) / 60):\(String(format: "%02d", Int(secondes) % 60))").font(.system(size: 44, weight: .bold, design: .rounded)).monospacedDigit()
                        Text(p >= 1 ? "Objectif atteint" : (m.d.chrono?.debut != nil ? "En marche · sur 30 min" : (m.d.chrono != nil ? "En pause · sur 30 min" : "sur 30 min")))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 210, height: 210).frame(maxWidth: .infinity)
                HStack(spacing: 10) {
                    if let c = m.d.chrono {
                        if c.debut != nil { Button("Pause") { pause() }.buttonStyle(BoutonDoux()) }
                        else { Button("Reprendre") { reprendre() }.buttonStyle(BoutonRose(large: false)) }
                        Button("Terminer") { terminer() }.buttonStyle(BoutonRose(large: false))
                    } else {
                        Button("Démarrer la marche") { demarrer() }.buttonStyle(BoutonRose(large: false))
                    }
                }
                .frame(maxWidth: .infinity)
                HStack(spacing: 10) {
                    Text("Corriger").font(.footnote).foregroundStyle(.secondary)
                    Button("−5 min") { corriger(-5) }.buttonStyle(BoutonDoux())
                    Button("+5 min") { corriger(5) }.buttonStyle(BoutonDoux())
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    func totalSecondes(_ maintenant: Date) -> Double {
        let deja = Double(m.d.marche[cle]?.minutes ?? 0) * 60
        guard let c = m.d.chrono, c.date == cle else { return deja }
        return deja + c.cumul + (c.debut.map { maintenant.timeIntervalSince($0) } ?? 0)
    }
    func programmerFin() {
        let reste = objectifMinutes * 60 - totalSecondes(Date())
        if reste > 0 { Rappels.programmer("marche", dans: reste, titre: "30 min de marche", texte: "Objectif atteint. Bien joué !") }
    }
    func demarrer() { m.d.chrono = ChronoMarche(date: cle, debut: Date(), cumul: 0); programmerFin() }
    func pause() {
        guard var c = m.d.chrono, let d = c.debut else { return }
        c.cumul += Date().timeIntervalSince(d); c.debut = nil; m.d.chrono = c
        Rappels.annuler("marche")
    }
    func reprendre() { m.d.chrono?.debut = Date(); programmerFin() }
    func terminer() {
        guard let c = m.d.chrono else { return }
        let ecoule = c.cumul + (c.debut.map { Date().timeIntervalSince($0) } ?? 0)
        var j = m.d.marche[cle] ?? JourMarche(date: cle); j.minutes += Int((ecoule / 60).rounded()); m.d.marche[cle] = j
        m.d.chrono = nil
        Rappels.annuler("marche")
        if j.minutes >= Int(objectifMinutes) { m.d.cocherLien("marche") }
    }
    func corriger(_ n: Int) {
        var j = m.d.marche[cle] ?? JourMarche(date: cle); j.minutes = max(0, j.minutes + n); m.d.marche[cle] = j
        if j.minutes >= Int(objectifMinutes) { m.d.cocherLien("marche") }
    }

    func graphiqueSemaine(obj: Int) -> some View {
        let jours = Temps.semaine(cle), lettres = ["L", "M", "M", "J", "V", "S", "D"]
        return Chart {
            ForEach(Array(jours.enumerated()), id: \.offset) { i, k in
                BarMark(x: .value("Jour", "\(lettres[i])\(i)"), y: .value("Pas", m.d.marche[k]?.pas ?? 0))
                    .foregroundStyle(Theme.degradeBarre)
                    .opacity(k == cle ? 1 : 0.5)
                    .cornerRadius(8)
            }
            RuleMark(y: .value("Objectif", obj))
                .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
                .foregroundStyle(Color.primary.opacity(0.45))
        }
        .chartXAxis {
            AxisMarks { v in
                AxisValueLabel { if let s = v.as(String.self) { Text(String(s.prefix(1))) } }
            }
        }
        .frame(height: 180)
    }
}
