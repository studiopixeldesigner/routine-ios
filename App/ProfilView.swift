import AVFoundation
import Charts
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct ProfilView: View {
    @EnvironmentObject var m: Magasin
    @ObservedObject var sante = Sante.partage
    @State private var photoChoisie: PhotosPickerItem?
    @State private var poidsTexte = ""
    @State private var mesures: [String: String] = [:]
    @State private var importer = false
    @State private var aImporter: Donnees?
    @State private var message = ""

    let mensurations = [("taille", "Tour de taille"), ("poitrine", "Poitrine"), ("bras", "Bras"), ("cuisses", "Cuisses"), ("hanches", "Hanches")]
    let objectifs = [("perte", "Perdre"), ("maintien", "Maintenir"), ("prise", "Prendre")]

    var body: some View {
        NavigationStack {
            Form {
                entete
                Section("Identité") {
                    TextField("Prénom", text: $m.d.profil.prenom).textContentType(.givenName)
                    TextField("Nom", text: $m.d.profil.nom).textContentType(.familyName)
                    TextField("Numéro de téléphone", text: $m.d.profil.tel).keyboardType(.phonePad).textContentType(.telephoneNumber)
                }
                Section("Ton corps et ton objectif") {
                    Picker("Sexe", selection: $m.d.profil.sexe) { Text("Homme").tag("h"); Text("Femme").tag("f") }.pickerStyle(.segmented)
                    DatePicker("Date de naissance", selection: Binding(
                        get: { Temps.date(m.d.profil.naissance) ?? Temps.calendrier.date(from: DateComponents(year: 2000, month: 1, day: 1))! },
                        set: { m.d.profil.naissance = Temps.cle($0) }), in: ...Date(), displayedComponents: .date)
                    champNombre("Taille (cm)", $m.d.profil.taille)
                    Picker("Activité", selection: $m.d.profil.activite) {
                        ForEach(Activites.liste, id: \.id) { a in Text("\(a.nom) : \(a.texte)").tag(a.id) }
                    }
                    Picker("Objectif", selection: $m.d.profil.objectif) { ForEach(objectifs, id: \.0) { Text($0.1).tag($0.0) } }.pickerStyle(.segmented)
                    champNombre("Poids visé (kg)", $m.d.profil.poidsCible)
                }
                besoins
                poids
                sectionMensurations
                Section("Son des rappels") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("« Velours »").font(.headline)
                            Text("Deux accords graves et ronds, composés pour l'appli.").font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Écouter") { Son.jouer() }.buttonStyle(BoutonDoux())
                    }
                }
                Section {
                    Button("Importer mes données de l'artefact (fichier .json)") { importer = true }
                    ShareLink(item: Sauvegarde.fichier(m.d), preview: SharePreview("Sauvegarde Ma routine")) {
                        Label("Exporter une sauvegarde", systemImage: "square.and.arrow.up")
                    }
                    if !message.isEmpty { Text(message).font(.footnote).foregroundStyle(.secondary) }
                } header: { Text("Tes données") } footer: {
                    Text(Stockage.groupeDisponible ? "Tes données sont sur ce téléphone et partagées avec le widget."
                         : "Tes données sont sur ce téléphone. Le widget n'y a pas accès avec cette installation : il affiche la routine de base.")
                }
                Section {
                    LabeledContent("App Santé", value: sante.etat == .actif ? "Connectée" : sante.etat == .inconnu ? "Pas encore demandée" : "Non disponible")
                    LabeledContent("Version", value: "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"))")
                } footer: {
                    Text("Besoins et IMC sont des estimations générales, pas un avis médical.")
                }
            }
            .navigationTitle("Profil")
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: photoChoisie) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                        m.d.profil.photo = Photo.carre(img, cote: 512)
                    }
                }
            }
            .fileImporter(isPresented: $importer, allowedContentTypes: [.json]) { r in
                guard case .success(let url) = r else { return }
                let acces = url.startAccessingSecurityScopedResource()
                defer { if acces { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url), let d = try? Stockage.decodeur.decode(Donnees.self, from: data) { aImporter = d }
                else { message = "Ce fichier n'est pas une sauvegarde de Ma routine." }
            }
            .confirmationDialog("Remplacer les données de ce téléphone par celles du fichier ?", isPresented: Binding(get: { aImporter != nil }, set: { if !$0 { aImporter = nil } }), titleVisibility: .visible) {
                Button("Remplacer", role: .destructive) {
                    if var d = aImporter { d.importeLe = Date(); m.d = d; message = "Données importées." }
                }
            } message: { Text("Programme, séances, journées, repas, profil et photo seront repris du fichier.") }
        }
    }

    var entete: some View {
        Section {
            HStack(spacing: 16) {
                PhotosPicker(selection: $photoChoisie, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            if let p = m.d.profil.photo, let img = UIImage(data: p) { Image(uiImage: img).resizable().scaledToFill() }
                            else {
                                Text(initiales).font(.system(size: 32, weight: .heavy, design: .rounded)).foregroundStyle(Theme.accent)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.tertiarySystemFill))
                            }
                        }
                        .frame(width: 84, height: 84).clipShape(Circle())
                        .padding(3).background(Theme.degrade, in: Circle())
                        Image(systemName: "camera.fill").font(.caption).foregroundStyle(Theme.accent)
                            .frame(width: 28, height: 28).background(Color(.secondarySystemGroupedBackground), in: Circle())
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Changer la photo de profil")
                VStack(alignment: .leading, spacing: 4) {
                    Text([m.d.profil.prenom, m.d.profil.nom].filter { !$0.isEmpty }.joined(separator: " ").ifEmpty("Ton profil"))
                        .font(.title2.weight(.heavy))
                    Text(sousTitre).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    var initiales: String {
        let p = m.d.profil.prenom.first.map(String.init) ?? "R", n = m.d.profil.nom.first.map(String.init) ?? ""
        return (p + n).uppercased()
    }
    var sousTitre: String {
        let o = objectifs.first { $0.0 == m.d.profil.objectif }.map { $0.0 == "perte" ? "Perdre du gras" : $0.0 == "prise" ? "Prendre du muscle" : "Rester stable" }
        return [o, m.d.age > 0 ? "\(m.d.age) ans" : nil, m.d.poidsActuel > 0 ? "\(decimal(m.d.poidsActuel)) kg" : nil]
            .compactMap { $0 }.joined(separator: " · ").ifEmpty("Touche la photo pour en ajouter une")
    }

    var besoins: some View {
        Section("Tes besoins") {
            if let b = m.d.besoins {
                HStack(alignment: .firstTextBaseline) {
                    GrosChiffre(texte: entier(b.kcal), unite: "kcal par jour")
                    Spacer()
                    Text("IMC \(decimal(b.imc))").font(.footnote).foregroundStyle(.secondary)
                }
                HStack(spacing: 10) {
                    chiffre("\(entier(b.prot)) g", "protéines")
                    chiffre("\(entier(b.glu)) g", "glucides")
                    chiffre("\(entier(b.lip)) g", "lipides")
                }
                Text("Métabolisme de base \(entier(b.bmr)) kcal · maintien \(entier(b.maintien)) kcal"
                     + (m.d.profil.objectif == "perte" ? " · −15 % pour perdre du gras" : m.d.profil.objectif == "prise" ? " · +10 % pour prendre du muscle" : "") + ".")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                Text("Indique ton sexe, ta date de naissance, ta taille et note ton poids : l'appli calculera tes besoins en calories et en protéines, repris dans la nutrition.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    func chiffre(_ v: String, _ l: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(v).font(.headline.weight(.heavy)).monospacedDigit()
            Text(l).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10).background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14))
    }

    var poids: some View {
        let liste = m.d.pesees.sorted { $0.key < $1.key }, cible = m.d.profil.poidsCible, actuel = m.d.poidsActuel
        return Section {
            HStack {
                TextField(actuel > 0 ? decimal(actuel) : "Poids du jour (kg)", text: $poidsTexte).keyboardType(.decimalPad)
                Button("Noter") {
                    let v = nombre(poidsTexte)
                    guard (25...350).contains(v) else { message = "Entre ton poids en kilos, par exemple 76,5."; return }
                    m.d.pesees[Temps.journee()] = (v * 10).rounded() / 10
                    poidsTexte = ""
                }
                .buttonStyle(BoutonRose(large: false))
            }
            if liste.isEmpty {
                Text("Pèse-toi le matin, à jeun, pour comparer d'un jour à l'autre.").font(.footnote).foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(liste.suffix(30), id: \.key) { k, v in
                        if let d = Temps.date(k) {
                            LineMark(x: .value("Date", d), y: .value("kg", v)).foregroundStyle(Theme.degradeBarre).lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                            PointMark(x: .value("Date", d), y: .value("kg", v)).foregroundStyle(Theme.accent).symbolSize(30)
                        }
                    }
                    if cible > 0 { RuleMark(y: .value("Visé", cible)).lineStyle(StrokeStyle(lineWidth: 1.2, dash: [3, 4])).foregroundStyle(Color.primary.opacity(0.45)) }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 170)
                ForEach(Array(liste.suffix(5).reversed()), id: \.key) { k, v in
                    HStack {
                        Text(Temps.courte(k)).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(decimal(v)) kg").bold().monospacedDigit()
                    }
                    .swipeActions { Button("Supprimer", role: .destructive) { m.d.pesees[k] = nil } }
                }
            }
        } header: {
            HStack {
                Text("Poids")
                Spacer()
                if actuel > 0 && cible > 0 {
                    let r = actuel - cible
                    Text(abs(r) < 0.05 ? "Poids visé atteint" : "\(decimal(abs(r))) kg \(r > 0 ? "à perdre" : "à prendre")").textCase(nil)
                }
            }
        } footer: {
            if !liste.isEmpty { Text("Glisse une pesée vers la gauche pour la supprimer." + (cible > 0 ? " Pointillés : ton poids visé." : "")) }
        }
    }

    var sectionMensurations: some View {
        let dates = m.d.mensurations.keys.sorted(), der = dates.last.flatMap { m.d.mensurations[$0] }
        let avant = dates.count > 1 ? m.d.mensurations[dates[dates.count - 2]] : nil
        return Section {
            ForEach(mensurations, id: \.0) { k, l in
                HStack {
                    Text(l)
                    Spacer()
                    TextField(der?[k].map { decimal($0) } ?? "cm", text: Binding(get: { mesures[k] ?? "" }, set: { mesures[k] = $0 }))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    if let v = der?[k], let a = avant?[k] {
                        let e = v - a
                        Text("\(e > 0 ? "+" : e < 0 ? "−" : "")\(decimal(abs(e)))").font(.caption).foregroundStyle(.secondary).frame(width: 40, alignment: .trailing)
                    }
                }
            }
            Button("Enregistrer les mesures") {
                var x: [String: Double] = m.d.mensurations[Temps.journee()] ?? [:]
                for (k, v) in mesures where nombre(v) > 0 { x[k] = (nombre(v) * 10).rounded() / 10 }
                guard !x.isEmpty else { return }
                m.d.mensurations[Temps.journee()] = x
                mesures = [:]
            }
        } header: { Text("Mensurations (cm)") } footer: {
            if let k = dates.last { Text("Dernières mesures le \(Temps.courte(k)) ; l'écart avec les précédentes s'affiche à droite.") }
        }
    }

    func champNombre(_ titre: String, _ b: Binding<Double>) -> some View {
        HStack {
            Text(titre)
            Spacer()
            TextField("0", value: b, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
        }
    }
}

extension String {
    func ifEmpty(_ s: String) -> String { isEmpty ? s : self }
}

enum Photo {
    /// Recadre au centre en carré et réduit, en JPEG.
    static func carre(_ img: UIImage, cote: CGFloat) -> Data? {
        let c = min(img.size.width, img.size.height)
        let rendu = UIGraphicsImageRenderer(size: CGSize(width: cote, height: cote))
        let resultat = rendu.image { _ in
            let echelle = cote / c
            let w = img.size.width * echelle, h = img.size.height * echelle
            img.draw(in: CGRect(x: (cote - w) / 2, y: (cote - h) / 2, width: w, height: h))
        }
        return resultat.jpegData(compressionQuality: 0.85)
    }
}

enum Son {
    static var lecteur: AVAudioPlayer?
    static func jouer() {
        guard let url = Bundle.main.url(forResource: "velours", withExtension: "wav") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        lecteur = try? AVAudioPlayer(contentsOf: url)
        lecteur?.play()
    }
}

enum Sauvegarde {
    static func fichier(_ d: Donnees) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ma-routine-\(Temps.journee()).json")
        if let data = try? Stockage.encodeur.encode(d) { try? data.write(to: url, options: .atomic) }
        return url
    }
}
