import SwiftUI

struct NutritionView: View {
    @EnvironmentObject var m: Magasin
    @State private var editeur = false
    @State private var choixEcart = false
    let verresMax = 8

    var cle: String { Temps.journee(m.maintenant) }

    var body: some View {
        let d = m.d, (prevu, mange) = d.bilan(cle), plan = d.planDu(cle), n = d.nutritionDu(cle)
        let t = d.type(d.jour(cle).type), b = d.besoins
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if d.plan.programmes.count > 1 {
                        Picker("Programme", selection: $m.d.plan.actif) {
                            ForEach(d.plan.programmes) { p in Text(p.nom).tag(p.id) }
                        }
                        .pickerStyle(.segmented)
                    }
                    Carte {
                        HStack {
                            Text("Aujourd'hui · jour \(t.nom.lowercased())").surtitre()
                            Spacer()
                            Text(d.programmeActif?.nom ?? "").font(.footnote).foregroundStyle(.secondary)
                        }
                        GrosChiffre(texte: entier(mange.kcal), unite: "/ \(entier(prevu.kcal)) kcal")
                        Jauge(valeur: prevu.kcal > 0 ? mange.kcal / prevu.kcal : 0)
                        HStack(spacing: 12) {
                            macro("Protéines", mange.p, prevu.p)
                            macro("Glucides", mange.g, prevu.g)
                            macro("Lipides", mange.l, prevu.l)
                        }
                        Text(b.map { "Tes besoins estimés : \(entier($0.kcal)) kcal et \(entier($0.prot)) g de protéines par jour." }
                             ?? "Complète ton profil pour comparer ce plan à tes besoins.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }

                    HStack(alignment: .firstTextBaseline) {
                        Text("Tes repas").font(.title2.bold())
                        Spacer()
                        Text("\(plan.count) repas prévus").font(.footnote).foregroundStyle(.secondary)
                    }
                    if plan.isEmpty {
                        Carte { Text("Aucun repas prévu pour ce type de jour. Touche « Modifier » pour créer le plan.").foregroundStyle(.secondary) }
                    }
                    ForEach(plan) { r in carteRepas(r, mange: n.manges[r.id] == true) }

                    Carte {
                        HStack {
                            Text("Écarts et en-cas").font(.title3.bold())
                            Spacer()
                            let v = d.valeurs(n.ecarts)
                            Text(n.ecarts.isEmpty ? "Rien pour l'instant" : "\(entier(v.kcal)) kcal").font(.footnote).foregroundStyle(.secondary)
                        }
                        ForEach(n.ecarts) { x in
                            HStack(spacing: 10) {
                                ligneAliment(x)
                                Button { retirerEcart(x.id) } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                                    .buttonStyle(.plain).accessibilityLabel("Retirer")
                            }
                        }
                        Button("+ Ajouter un aliment") { choixEcart = true }.buttonStyle(BoutonDoux())
                    }

                    Carte {
                        HStack {
                            Text("Eau").font(.title3.bold())
                            Spacer()
                            Text("\(n.eau) / \(verresMax) verres de 25 cl").font(.footnote).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 0) {
                            ForEach(1...verresMax, id: \.self) { i in
                                Button { boire(i) } label: {
                                    Image(systemName: i <= n.eau ? "drop.fill" : "drop")
                                        .font(.title2)
                                        .foregroundStyle(i <= n.eau ? AnyShapeStyle(Theme.degrade) : AnyShapeStyle(Color(.systemGray3)))
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(i) verre\(i > 1 ? "s" : "")")
                            }
                        }
                        .sensoryFeedback(.increase, trigger: n.eau)
                    }

                    Text("Valeurs moyennes pour 100 g : l'étiquette du produit fait foi. Estimations, pas un avis médical.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nutrition")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Modifier") { editeur = true } } }
            .sheet(isPresented: $editeur) { ProgrammeRepasFeuille().environmentObject(m) }
            .sheet(isPresented: $choixEcart) {
                ChoixAlimentFeuille { ligne in
                    var j = m.d.nutritionDu(cle); j.ecarts.append(ligne); m.d.nutrition[cle] = j
                }
                .environmentObject(m)
            }
        }
    }

    func macro(_ titre: String, _ v: Double, _ max: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titre).surtitre()
            Jauge(valeur: max > 0 ? v / max : 0, hauteur: 6)
            Text("\(entier(v)) / \(entier(max)) g").font(.subheadline.weight(.bold)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func carteRepas(_ r: Repas, mange: Bool) -> some View {
        let v = m.d.valeurs(r.aliments)
        return Carte(espacement: 10) {
            Button { var j = m.d.nutritionDu(cle); j.manges[r.id] = !mange; m.d.nutrition[cle] = j } label: {
                HStack(spacing: 12) {
                    Coche(faite: mange, taille: 32)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(r.nom).font(.title3.bold()).foregroundStyle(mange ? .secondary : .primary)
                        Text("\(Temps.affiche(r.heure)) · \(entier(v.kcal)) kcal · P \(entier(v.p)) g · G \(entier(v.g)) g · L \(entier(v.l)) g")
                            .font(.footnote).foregroundStyle(.secondary).monospacedDigit()
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: mange) { _, n in n }
            ForEach(r.aliments) { x in ligneAliment(x) }
        }
    }

    func ligneAliment(_ x: LigneAliment) -> some View {
        let a = m.d.aliment(x.a)
        return HStack(spacing: 10) {
            TuileEmoji(emoji: a.emoji)
            VStack(alignment: .leading, spacing: 0) {
                Text(a.nom).font(.subheadline)
                Text("\(entier(x.q)) g").font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
            Spacer()
            Text("\(entier(m.d.valeurs([x]).kcal)) kcal").font(.footnote).foregroundStyle(.secondary).monospacedDigit()
        }
    }

    func retirerEcart(_ id: String) { var j = m.d.nutritionDu(cle); j.ecarts.removeAll { $0.id == id }; m.d.nutrition[cle] = j }
    func boire(_ i: Int) { var j = m.d.nutritionDu(cle); j.eau = j.eau == i ? i - 1 : i; m.d.nutrition[cle] = j }
}

struct TuileEmoji: View {
    let emoji: String
    var body: some View {
        Text(emoji).font(.title2).frame(width: 42, height: 42)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

// MARK: - Modifier les programmes de repas

struct ProgrammeRepasFeuille: View {
    @EnvironmentObject var m: Magasin
    @Environment(\.dismiss) var fermer
    @State private var progId = ""
    @State private var typeSel = ""
    @State private var ajoutDans: String?        // repas qui reçoit l'aliment choisi
    @State private var confirmer = false

    var pi: Int? { m.d.plan.programmes.firstIndex { $0.id == progId } }

    var body: some View {
        NavigationStack {
            Form {
                if let pi {
                    Section {
                        Picker("Programme", selection: $progId) {
                            ForEach(m.d.plan.programmes) { p in Text(p.nom).tag(p.id) }
                        }
                        TextField("Nom (Sèche, Prise de masse…)", text: $m.d.plan.programmes[pi].nom)
                        Button("Nouveau programme (copie de celui-ci)") {
                            var n = m.d.plan.programmes[pi]
                            n.id = nouvelId(); n.nom = "Nouveau programme"
                            for k in n.plans.keys { n.plans[k] = n.plans[k]?.map { var r = $0; r.id = nouvelId(); return r } }
                            m.d.plan.programmes.append(n); m.d.plan.actif = n.id; progId = n.id
                        }
                    } footer: { Text("Le programme choisi ici devient celui du jour.") }

                    Section {
                        Picker("Plan pour les jours", selection: $typeSel) {
                            ForEach(m.d.routine.types) { t in Text("\(t.emoji) \(t.nom)").tag(t.id) }
                        }
                        let propre = m.d.plan.programmes[pi].plans[typeSel] ?? []
                        if propre.isEmpty {
                            Text("Pas encore de repas pour ce type de jour : l'appli suit le plan du premier type qui en a.")
                                .font(.footnote).foregroundStyle(.secondary)
                            if !m.d.planParDefaut(m.d.plan.programmes[pi]).isEmpty {
                                Button("Copier ce plan pour le modifier") {
                                    m.d.plan.programmes[pi].plans[typeSel] = m.d.planParDefaut(m.d.plan.programmes[pi]).map { var r = $0; r.id = nouvelId(); return r }
                                }
                            }
                        } else {
                            let v = propre.reduce(Valeurs()) { $0 + m.d.valeurs($1.aliments) }
                            Text("Ce plan : \(entier(v.kcal)) kcal · P \(entier(v.p)) g · G \(entier(v.g)) g · L \(entier(v.l)) g")
                                .font(.subheadline.weight(.semibold))
                            if let b = m.d.besoins {
                                Text("Tes besoins estimés : \(entier(b.kcal)) kcal · P \(entier(b.prot)) g").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }

                    if m.d.plan.programmes[pi].plans[typeSel] != nil {
                        ForEach(liaisonRepas(pi)) { $r in
                            Section {
                                HStack {
                                    DatePicker("Heure", selection: liaisonHeure($r.heure), displayedComponents: .hourAndMinute).labelsHidden()
                                    TextField("Nom du repas", text: $r.nom).font(.headline)
                                }
                                ForEach($r.aliments) { $x in
                                    let a = m.d.aliment(x.a)
                                    HStack(spacing: 10) {
                                        TuileEmoji(emoji: a.emoji)
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text(a.nom).font(.subheadline)
                                            Text("\(entier(m.d.valeurs([x]).kcal)) kcal").font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        TextField("g", value: $x.q, format: .number).keyboardType(.numberPad).champ().frame(width: 72)
                                        Text("g").font(.footnote).foregroundStyle(.secondary)
                                    }
                                }
                                .onDelete { $r.aliments.wrappedValue.remove(atOffsets: $0) }
                                Button("+ Aliment") { ajoutDans = r.id }
                                Button("Supprimer ce repas", role: .destructive) {
                                    m.d.plan.programmes[pi].plans[typeSel]?.removeAll { $0.id == r.id }
                                }
                                .font(.footnote)
                            }
                        }
                    }
                    Section {
                        Button("Ajouter un repas") {
                            var l = m.d.plan.programmes[pi].plans[typeSel] ?? []
                            l.append(Repas(id: nouvelId(), heure: "12:00", nom: "Nouveau repas", aliments: []))
                            m.d.plan.programmes[pi].plans[typeSel] = l
                        }
                        if m.d.plan.programmes.count > 1 {
                            Button("Supprimer ce programme", role: .destructive) { confirmer = true }
                        }
                    }
                }
            }
            .navigationTitle("Programme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Terminé") { fermer() } } }
            .onAppear {
                progId = m.d.programmeActif?.id ?? m.d.plan.programmes[0].id
                typeSel = m.d.jour(Temps.journee()).type ?? m.d.routine.types[0].id
            }
            .onChange(of: progId) { _, v in if !v.isEmpty { m.d.plan.actif = v } }
            .sheet(item: Binding(get: { ajoutDans.map { Ident(id: $0) } }, set: { ajoutDans = $0?.id })) { cible in
                ChoixAlimentFeuille { ligne in
                    guard let pi = pi, let ri = m.d.plan.programmes[pi].plans[typeSel]?.firstIndex(where: { $0.id == cible.id }) else { return }
                    m.d.plan.programmes[pi].plans[typeSel]?[ri].aliments.append(ligne)
                }
                .environmentObject(m)
            }
            .confirmationDialog("Supprimer ce programme ?", isPresented: $confirmer, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    m.d.plan.programmes.removeAll { $0.id == progId }
                    m.d.plan.actif = m.d.plan.programmes[0].id
                    progId = m.d.plan.actif
                }
            }
        }
    }

    struct Ident: Identifiable { let id: String }

    func liaisonRepas(_ pi: Int) -> Binding<[Repas]> {
        Binding(get: { m.d.plan.programmes[safe: pi]?.plans[typeSel] ?? [] },
                set: { m.d.plan.programmes[pi].plans[typeSel] = $0 })
    }
}

// MARK: - Choisir un aliment et sa quantité

struct ChoixAlimentFeuille: View {
    @EnvironmentObject var m: Magasin
    @Environment(\.dismiss) var fermer
    let choisi: (LigneAliment) -> Void
    @State private var recherche = ""
    @State private var chemin = NavigationPath()

    var body: some View {
        NavigationStack(path: $chemin) {
            List {
                let q = recherche.lowercased()
                let perso = m.d.alimentsPerso.filter { q.isEmpty || $0.nom.lowercased().contains(q) }
                let base = Aliment.base.filter { q.isEmpty || $0.nom.lowercased().contains(q) }
                if !perso.isEmpty {
                    Section("Mes aliments") { ForEach(perso) { a in lien(a) } }
                }
                Section("Aliments courants") { ForEach(base) { a in lien(a) } }
                if perso.isEmpty && base.isEmpty {
                    Text("Aucun aliment trouvé. Crée-le avec les valeurs de l'étiquette.").foregroundStyle(.secondary)
                }
            }
            .searchable(text: $recherche, prompt: "Poulet, riz, skyr…")
            .navigationTitle("Choisir un aliment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { fermer() } }
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(value: "creer") { Label("Créer un aliment", systemImage: "plus") }
                }
            }
            .navigationDestination(for: Aliment.self) { a in
                QuantiteVue(aliment: a) { q in choisi(LigneAliment(a: a.id, q: q)); fermer() }
            }
            .navigationDestination(for: String.self) { _ in
                CreerAlimentVue(nomDepart: recherche) { a in
                    m.d.alimentsPerso.insert(a, at: 0)
                    chemin.removeLast()
                    chemin.append(a)
                }
            }
        }
    }

    func lien(_ a: Aliment) -> some View {
        NavigationLink(value: a) {
            HStack(spacing: 10) {
                TuileEmoji(emoji: a.emoji)
                VStack(alignment: .leading, spacing: 1) {
                    Text(a.nom)
                    Text("\(entier(a.kcal)) kcal · P \(decimal(a.p)) g · G \(decimal(a.g)) g · L \(decimal(a.l)) g pour 100 g")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct QuantiteVue: View {
    @EnvironmentObject var m: Magasin
    let aliment: Aliment
    let valider: (Double) -> Void
    @State private var q = 0.0

    var body: some View {
        let v = m.d.valeurs([LigneAliment(a: aliment.id, q: q)])
        Form {
            Section {
                HStack(spacing: 12) {
                    TuileEmoji(emoji: aliment.emoji)
                    VStack(alignment: .leading) {
                        Text(aliment.nom).font(.headline)
                        Text("\(entier(aliment.kcal)) kcal pour 100 g").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Quantité en grammes") {
                TextField("Grammes", value: $q, format: .number).keyboardType(.numberPad).font(.title2.weight(.semibold))
                HStack {
                    ForEach([0.5, 1, 1.5, 2], id: \.self) { k in
                        Button("\(entier(aliment.portion * k)) g") { q = (aliment.portion * k).rounded() }.buttonStyle(BoutonDoux())
                    }
                }
            }
            Section {
                Text("\(entier(v.kcal)) kcal · \(entier(v.p)) g de protéines · G \(entier(v.g)) g · L \(entier(v.l)) g").font(.subheadline)
                Button("Ajouter") { valider(q) }.buttonStyle(BoutonRose()).listRowBackground(Color.clear).disabled(q <= 0)
            }
        }
        .navigationTitle("Quantité")
        .onAppear { if q == 0 { q = aliment.portion } }
    }
}

struct CreerAlimentVue: View {
    let nomDepart: String
    let cree: (Aliment) -> Void
    @State private var a = Aliment(id: "", nom: "", emoji: "🍽️", kcal: 0, p: 0, g: 0, l: 0, portion: 100)
    let emojis = ["🍽️", "🥚", "🍗", "🥩", "🐟", "🥛", "🧀", "🥣", "🍞", "🍚", "🍝", "🥔", "🫘", "🥗", "🥦", "🍎", "🍌", "🥜", "🍫", "🍕", "🥤", "🍪", "🥐", "🌯"]

    var body: some View {
        Form {
            Section {
                TextField("Nom (ex. Yaourt grec)", text: $a.nom)
                Picker("Image", selection: $a.emoji) { ForEach(emojis, id: \.self) { Text($0).tag($0) } }
            }
            Section {
                champ("Calories (kcal)", $a.kcal)
                champ("Protéines (g)", $a.p)
                champ("Glucides (g)", $a.g)
                champ("Lipides (g)", $a.l)
            } header: { Text("Pour 100 g") } footer: { Text("Recopie les valeurs de l'étiquette.") }
            Section { champ("Portion habituelle (g)", $a.portion) }
            Section {
                Button("Créer et choisir") { var x = a; x.id = "perso-" + nouvelId(); x.nom = x.nom.trimmingCharacters(in: .whitespaces); cree(x) }
                    .disabled(a.nom.trimmingCharacters(in: .whitespaces).isEmpty || a.kcal <= 0)
            }
        }
        .navigationTitle("Nouvel aliment")
        .onAppear { if a.nom.isEmpty { a.nom = nomDepart } }
    }

    func champ(_ titre: String, _ b: Binding<Double>) -> some View {
        HStack {
            Text(titre)
            Spacer()
            TextField("0", value: b, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
        }
    }
}
