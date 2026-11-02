import Foundation

// MARK: - Heures et jours

/// La journée commence à 5h : ce qui se passe après minuit compte pour la veille.
enum Temps {
    static let calendrier: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "fr_FR")
        c.firstWeekday = 2
        return c
    }()

    static func debutJournee(_ d: Date = .now) -> Date { d.addingTimeInterval(-5 * 3600) }

    static func cle(_ d: Date) -> String {
        let c = calendrier.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }
    static func journee(_ d: Date = .now) -> String { cle(debutJournee(d)) }
    static func demain(_ d: Date = .now) -> String { ajouter(journee(d), jours: 1) }

    static func date(_ cle: String) -> Date? {
        let p = cle.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        return calendrier.date(from: DateComponents(year: p[0], month: p[1], day: p[2], hour: 12))
    }
    static func ajouter(_ cle: String, jours n: Int) -> String {
        guard let d = date(cle), let r = calendrier.date(byAdding: .day, value: n, to: d) else { return cle }
        return Temps.cle(r)
    }
    static func lundi(_ cle: String) -> String {
        guard let d = date(cle) else { return cle }
        let jour = calendrier.component(.weekday, from: d)       // 1 = dimanche
        return ajouter(cle, jours: -((jour + 5) % 7))
    }
    static func semaine(_ cle: String) -> [String] { (0..<7).map { ajouter(lundi(cle), jours: $0) } }

    /// « 09:00 » → 540 minutes
    static func minutes(_ h: String) -> Int {
        let p = h.split(separator: ":").compactMap { Int($0) }
        return (p.first ?? 0) * 60 + (p.count > 1 ? p[1] : 0)
    }
    /// Minutes dans la journée qui commence à 5h : 0h45 vaut 1485
    static func minutesJour(_ h: String) -> Int { let m = minutes(h); return m < 300 ? m + 1440 : m }
    static func maintenant(_ d: Date = .now) -> Int {
        let c = calendrier.dateComponents([.hour, .minute], from: d)
        let m = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        return m < 300 ? m + 1440 : m
    }
    /// « 09:00 » → « 9h00 »
    static func affiche(_ h: String) -> String { let m = minutes(h); return "\(m / 60 % 24)h" + String(format: "%02d", m % 60) }
    static func heure(_ d: Date) -> String {
        let c = calendrier.dateComponents([.hour, .minute], from: d)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }
    /// Date réelle d'une heure « HH:mm » pour un jour donné (après minuit = lendemain civil)
    static func dateReelle(_ cleJour: String, _ h: String) -> Date? {
        guard let d = date(cleJour) else { return nil }
        let m = minutesJour(h)
        let base = calendrier.startOfDay(for: d)
        return base.addingTimeInterval(Double(m) * 60)
    }
    static func courte(_ cle: String) -> String { cle.count >= 10 ? "\(cle.suffix(2))/\(cle.dropFirst(5).prefix(2))" : cle }
    static func longue(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "EEEE d MMMM"
        return f.string(from: d)
    }
}

/// Nombre saisi en français (« 22,5 », « 6 240 »)
func nombre(_ s: String) -> Double {
    Double(s.replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "\u{202F}", with: "").replacingOccurrences(of: "\u{00A0}", with: "")) ?? 0
}
func entier(_ v: Double) -> String {
    let f = NumberFormatter(); f.locale = Locale(identifier: "fr_FR"); f.numberStyle = .decimal; f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: v.rounded())) ?? "\(Int(v))"
}
func decimal(_ v: Double) -> String {
    let f = NumberFormatter(); f.locale = Locale(identifier: "fr_FR"); f.numberStyle = .decimal; f.maximumFractionDigits = 1
    return f.string(from: NSNumber(value: (v * 10).rounded() / 10)) ?? "\(v)"
}

// MARK: - Journée

/// Une activité affichée : une étape de la routine ou un ajout pour ce jour seulement.
struct Activite: Identifiable, Hashable {
    var etape: Etape
    var depuisRoutine: Bool
    var id: String { etape.id }
}

extension Donnees {
    func type(_ id: String?) -> TypeJour { routine.types.first { $0.id == id } ?? routine.types[0] }
    func jour(_ cle: String) -> Jour { jours[cle] ?? Jour(date: cle, type: routine.types.first?.id) }

    func activites(_ cle: String) -> [Activite] {
        let j = jour(cle), t = type(j.type)
        let liste = t.etapes.filter { !j.retraits.contains($0.id) }.map { Activite(etape: $0, depuisRoutine: true) }
            + j.ajouts.map { Activite(etape: $0, depuisRoutine: false) }
        return liste.sorted { Temps.minutesJour($0.etape.heure) < Temps.minutesJour($1.etape.heure) }
    }

    /// Index de l'activité en cours (la dernière dont l'heure est passée)
    func indexActif(_ liste: [Activite], _ m: Int = Temps.maintenant()) -> Int? {
        liste.lastIndex { Temps.minutesJour($0.etape.heure) <= m }
    }

    func resume(_ t: TypeJour) -> String {
        if let s = t.etapes.first(where: { $0.lien == "seance" }) { return "Séance à \(Temps.affiche(s.heure))" }
        if let m = t.etapes.first(where: { $0.lien == "marche" }) { return "\(m.titre) à \(Temps.affiche(m.heure))" }
        return "\(t.etapes.count) activité\(t.etapes.count > 1 ? "s" : "")"
    }

    /// Coche l'activité liée (séance ou marche) quand elle est faite dans l'onglet Sport.
    mutating func cocherLien(_ lien: String) {
        let cle = Temps.journee()
        guard let a = activites(cle).first(where: { $0.etape.lien == lien }) else { return }
        var j = jour(cle); j.faits[a.id] = true; jours[cle] = j
    }
}

// MARK: - Nutrition

struct Valeurs: Hashable {
    var kcal = 0.0, p = 0.0, g = 0.0, l = 0.0
    static func + (a: Valeurs, b: Valeurs) -> Valeurs { Valeurs(kcal: a.kcal + b.kcal, p: a.p + b.p, g: a.g + b.g, l: a.l + b.l) }
}

extension Donnees {
    var tousAliments: [Aliment] { alimentsPerso + Aliment.base }
    func aliment(_ id: String) -> Aliment {
        tousAliments.first { $0.id == id } ?? Aliment(id: id, nom: "Aliment supprimé", emoji: "❔", kcal: 0, p: 0, g: 0, l: 0, portion: 100)
    }
    func valeurs(_ lignes: [LigneAliment]) -> Valeurs {
        lignes.reduce(Valeurs()) { t, x in
            let a = aliment(x.a), f = x.q / 100
            return t + Valeurs(kcal: a.kcal * f, p: a.p * f, g: a.g * f, l: a.l * f)
        }
    }
    var programmeActif: ProgrammeRepas? { plan.programmes.first { $0.id == plan.actif } ?? plan.programmes.first }

    /// Le plan du premier type de jour qui a des repas sert aux types qui n'en ont pas encore.
    func planParDefaut(_ p: ProgrammeRepas) -> [Repas] {
        for t in routine.types { if let r = p.plans[t.id], !r.isEmpty { return r } }
        return p.plans.values.first { !$0.isEmpty } ?? []
    }
    func planDu(_ cle: String) -> [Repas] {
        guard let p = programmeActif else { return [] }
        let t = jour(cle).type ?? routine.types[0].id
        let propre = p.plans[t] ?? []
        return (propre.isEmpty ? planParDefaut(p) : propre).sorted { Temps.minutesJour($0.heure) < Temps.minutesJour($1.heure) }
    }
    func nutritionDu(_ cle: String) -> JourNutrition { nutrition[cle] ?? JourNutrition(date: cle) }
    func bilan(_ cle: String) -> (prevu: Valeurs, mange: Valeurs) {
        let n = nutritionDu(cle), plan = planDu(cle)
        let prevu = plan.reduce(Valeurs()) { $0 + valeurs($1.aliments) }
        let mange = plan.filter { n.manges[$0.id] == true }.reduce(Valeurs()) { $0 + valeurs($1.aliments) } + valeurs(n.ecarts)
        return (prevu, mange)
    }
}

// MARK: - Profil et besoins

struct Besoins { var bmr, maintien, kcal, prot, glu, lip, imc: Double }

enum Activites {
    static let liste: [(id: String, facteur: Double, nom: String, texte: String)] = [
        ("sedentaire", 1.2, "Sédentaire", "peu de marche, pas de sport"),
        ("leger", 1.375, "Léger", "1 à 3 séances par semaine"),
        ("modere", 1.55, "Modéré", "3 à 5 séances par semaine"),
        ("actif", 1.725, "Très actif", "6 à 7 séances par semaine")]
    static func facteur(_ id: String) -> Double { liste.first { $0.id == id }?.facteur ?? 1.55 }
}

extension Donnees {
    var poidsActuel: Double {
        guard let cle = pesees.keys.max() else { return 0 }
        return pesees[cle] ?? 0
    }
    var age: Int {
        guard let n = Temps.date(profil.naissance) else { return 0 }
        let a = Temps.calendrier.dateComponents([.year], from: n, to: .now).year ?? 0
        return (1..<120).contains(a) ? a : 0
    }
    /// Besoins estimés : métabolisme de base (Mifflin-St Jeor) × activité, ajusté à l'objectif.
    var besoins: Besoins? {
        let poids = poidsActuel, taille = profil.taille, age = self.age
        guard poids > 0, taille > 0, age > 0, !profil.sexe.isEmpty else { return nil }
        let bmr = 10 * poids + 6.25 * taille - 5 * Double(age) + (profil.sexe == "f" ? -161 : 5)
        let maintien = bmr * Activites.facteur(profil.activite)
        let o = profil.objectif
        let kcal = maintien * (o == "perte" ? 0.85 : o == "prise" ? 1.1 : 1)
        let prot = poids * (o == "perte" ? 2 : o == "prise" ? 1.8 : 1.6), lip = poids * 0.9
        return Besoins(bmr: bmr, maintien: maintien, kcal: kcal, prot: prot,
                       glu: max(0, (kcal - prot * 4 - lip * 9) / 4), lip: lip, imc: poids / pow(taille / 100, 2))
    }
}

// MARK: - Musculation

enum Muscles {
    static let regles: [(String, [String])] = [
        ("ischios", ["leg curl", "jambes tendues", "roumain", "rdl"]), ("mollets", ["mollet"]),
        ("fessiers", ["hip thrust", "fessier", "kickback"]), ("jambes", ["squat", "presse", "fente", "leg ext", "hack", "cuisse"]),
        ("triceps", ["triceps", "barre au front", "dips"]), ("biceps", ["biceps", "curl", "marteau"]),
        ("epaules", ["shoulder", "épaule", "epaule", "militaire", "élévation", "elevation", "oiseau", "face pull", "arnold"]),
        ("pecs", ["couché", "couche", "écart", "ecart", "pec", "pompe", "butterfly", "chest", "vis-à-vis", "développé", "developpe"]),
        ("dos", ["rowing", "tirage", "traction", "trx", "pull", "lat", "row", "dos"]),
        ("abdos", ["abdo", "gainage", "crunch", "planche", "relevé de jambes"])]
    static let noms = ["pecs": "Pectoraux", "dos": "Dos", "epaules": "Épaules", "biceps": "Biceps", "triceps": "Triceps",
                       "jambes": "Quadriceps", "ischios": "Ischio-jambiers", "fessiers": "Fessiers", "mollets": "Mollets", "abdos": "Abdos"]
    static func de(_ nom: String) -> String? {
        let n = nom.lowercased()
        return regles.first { $0.1.contains { n.contains($0) } }?.0
    }
    static func legende(_ nom: String) -> String { de(nom).flatMap { noms[$0] } ?? "Exercice" }
    /// Symbole Apple qui montre le mouvement
    static func symbole(_ nom: String) -> String {
        switch de(nom) {
        case "jambes", "ischios", "fessiers", "mollets": return "figure.strengthtraining.functional"
        case "abdos": return "figure.core.training"
        case "dos": return "figure.rower"
        default: return "figure.strengthtraining.traditional"
        }
    }
}

extension Donnees {
    func derniereSeance(_ id: String) -> SeanceFaite? { seances.last { $0.seanceId == id } }
    func prochaineSeance() -> SeanceProgramme? {
        let ss = programme.filter { $0.exos.contains { !$0.nom.trimmingCharacters(in: .whitespaces).isEmpty } }
        guard !ss.isEmpty else { return nil }
        for h in seances.reversed() {
            if let k = ss.firstIndex(where: { $0.id == h.seanceId }) { return ss[(k + 1) % ss.count] }
        }
        return ss[0]
    }
    func derniereFois(_ nom: String) -> String? {
        for h in seances.reversed() {
            if let e = h.exos.first(where: { $0.nom.lowercased() == nom.lowercased() }) {
                return "Dernière fois (\(Temps.courte(h.date))) : " + e.series.map { "\(Int($0.reps))×\(decimal($0.charge))" }.joined(separator: " · ")
            }
        }
        return nil
    }
}
