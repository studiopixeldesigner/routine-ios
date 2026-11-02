import Foundation

// Modèle de données de l'appli. Même organisation que l'artefact claude.ai,
// pour pouvoir y reprendre les données. Chaque type se décode avec des valeurs
// par défaut : un fichier écrit par une ancienne version reste lisible.

extension KeyedDecodingContainer {
    /// Lit une valeur si elle est présente et lisible, sinon renvoie la valeur par défaut.
    func v<T: Decodable>(_ cle: Key, _ defaut: @autoclosure () -> T) -> T {
        ((try? decodeIfPresent(T.self, forKey: cle)) ?? nil) ?? defaut()
    }
}

func nouvelId() -> String { UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "").prefix(12).description }

// MARK: - Routine

struct Etape: Codable, Identifiable, Hashable {
    var id: String
    var heure: String          // « HH:mm »
    var titre: String
    var note: String = ""
    var rappel: Bool = true
    var lien: String? = nil    // « seance » ou « marche » : cochée toute seule quand c'est fait
}
extension Etape {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, nouvelId()); heure = c.v(.heure, "09:00"); titre = c.v(.titre, "Activité")
        note = c.v(.note, ""); rappel = c.v(.rappel, true); lien = c.v(.lien, nil)
    }
}

struct TypeJour: Codable, Identifiable, Hashable {
    var id: String
    var nom: String
    var emoji: String
    var etapes: [Etape]
}
extension TypeJour {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, nouvelId()); nom = c.v(.nom, "Jour"); emoji = c.v(.emoji, "📅"); etapes = c.v(.etapes, [])
    }
}

struct Regle: Codable, Identifiable, Hashable {
    var id: String = nouvelId()
    var titre: String
    var texte: String
}
extension Regle {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, nouvelId()); titre = c.v(.titre, ""); texte = c.v(.texte, "")
    }
}

struct Routine: Codable, Hashable {
    var lever: String
    var coucher: String
    var types: [TypeJour]
    var regles: [Regle]
}
extension Routine {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Routine.defaut
        lever = c.v(.lever, d.lever); coucher = c.v(.coucher, d.coucher)
        types = c.v(.types, d.types); regles = c.v(.regles, d.regles)
        if types.isEmpty { types = d.types }
    }
}

struct Jour: Codable, Hashable {
    var date: String
    var type: String? = nil
    var typeChoisi: Bool = false
    var faits: [String: Bool] = [:]
    var ajouts: [Etape] = []
    var retraits: [String] = []
}
extension Jour {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = c.v(.date, ""); type = c.v(.type, nil); typeChoisi = c.v(.typeChoisi, false)
        faits = c.v(.faits, [:]); ajouts = c.v(.ajouts, []); retraits = c.v(.retraits, [])
    }
}

// MARK: - Nutrition

struct Aliment: Codable, Identifiable, Hashable {
    var id: String
    var nom: String
    var emoji: String
    var kcal: Double
    var p: Double
    var g: Double
    var l: Double
    var portion: Double
}
extension Aliment {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, nouvelId()); nom = c.v(.nom, "Aliment"); emoji = c.v(.emoji, "🍽️")
        kcal = c.v(.kcal, 0); p = c.v(.p, 0); g = c.v(.g, 0); l = c.v(.l, 0); portion = c.v(.portion, 100)
    }
}

/// Un aliment et sa quantité en grammes, dans un repas ou un écart.
struct LigneAliment: Codable, Identifiable, Hashable {
    var id: String = nouvelId()
    var a: String
    var q: Double
}
extension LigneAliment {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, nouvelId()); a = c.v(.a, ""); q = c.v(.q, 0)
    }
}

struct Repas: Codable, Identifiable, Hashable {
    var id: String
    var heure: String
    var nom: String
    var aliments: [LigneAliment]
}
extension Repas {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, nouvelId()); heure = c.v(.heure, "12:00"); nom = c.v(.nom, "Repas"); aliments = c.v(.aliments, [])
    }
}

struct ProgrammeRepas: Codable, Identifiable, Hashable {
    var id: String
    var nom: String
    var plans: [String: [Repas]]
}
extension ProgrammeRepas {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, nouvelId()); nom = c.v(.nom, "Programme"); plans = c.v(.plans, [:])
    }
}

struct PlanNutrition: Codable, Hashable {
    var actif: String
    var programmes: [ProgrammeRepas]
}
extension PlanNutrition {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PlanNutrition.defaut
        actif = c.v(.actif, d.actif); programmes = c.v(.programmes, d.programmes)
        if programmes.isEmpty { programmes = d.programmes; actif = d.actif }
    }
}

struct JourNutrition: Codable, Hashable {
    var date: String
    var manges: [String: Bool] = [:]
    var ecarts: [LigneAliment] = []
    var eau: Int = 0
}
extension JourNutrition {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = c.v(.date, ""); manges = c.v(.manges, [:]); ecarts = c.v(.ecarts, []); eau = c.v(.eau, 0)
    }
}

// MARK: - Sport

struct JourMarche: Codable, Hashable {
    var date: String
    var pas: Int = 0
    var minutes: Int = 0
}
extension JourMarche {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = c.v(.date, ""); pas = c.v(.pas, 0); minutes = c.v(.minutes, 0)
    }
}

/// Exercice du programme. Séries, répétitions, charge et repos restent du texte
/// comme dans l'artefact (« 8-10 », « 10/J », « 20 (1" fin de rep) »…).
struct Exercice: Codable, Identifiable, Hashable {
    var id: String = nouvelId()
    var nom: String
    var series: String = "3"
    var reps: String = "10"
    var charge: String = ""
    var repos: String = "90"
}
extension Exercice {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, nouvelId()); nom = c.v(.nom, ""); series = c.v(.series, "3"); reps = c.v(.reps, "10")
        charge = c.v(.charge, ""); repos = c.v(.repos, "90")
    }
}

struct SeanceProgramme: Codable, Identifiable, Hashable {
    var id: String
    var nom: String
    var exos: [Exercice]
}
extension SeanceProgramme {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, nouvelId()); nom = c.v(.nom, "Séance"); exos = c.v(.exos, [])
    }
}

struct SerieFaite: Codable, Hashable {
    var reps: Double
    var charge: Double
}
extension SerieFaite {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        reps = c.v(.reps, 0); charge = c.v(.charge, 0)
    }
}

struct ExoFait: Codable, Hashable {
    var nom: String
    var series: [SerieFaite]
}
extension ExoFait {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nom = c.v(.nom, ""); series = c.v(.series, [])
    }
}

struct SeanceFaite: Codable, Identifiable, Hashable {
    var id: String
    var date: String
    var ts: Double             // millisecondes, comme dans l'artefact
    var nom: String
    var seanceId: String
    var duree: Int
    var volume: Double
    var exos: [ExoFait]
}
extension SeanceFaite {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, nouvelId()); date = c.v(.date, ""); ts = c.v(.ts, 0); nom = c.v(.nom, "Séance")
        seanceId = c.v(.seanceId, ""); duree = c.v(.duree, 0); volume = c.v(.volume, 0); exos = c.v(.exos, [])
    }
}

struct SerieEnCours: Codable, Identifiable, Hashable {
    var id: String = nouvelId()
    var reps: String
    var charge: String
    var fait: Bool = false
}

struct ExoEnCours: Codable, Identifiable, Hashable {
    var id: String = nouvelId()
    var nom: String
    var repos: Int
    var series: [SerieEnCours]
}

struct SeanceEnCours: Codable, Hashable {
    var id: String
    var seanceId: String
    var nom: String
    var debut: Date
    var exos: [ExoEnCours]
    var finRepos: Date? = nil
}

struct ChronoMarche: Codable, Hashable {
    var date: String
    var debut: Date?
    var cumul: Double          // secondes déjà marchées avant la dernière pause
    var bip: Bool = false
}

// MARK: - Profil

struct Profil: Codable, Hashable {
    var prenom: String = ""
    var nom: String = ""
    var tel: String = ""
    var naissance: String = ""     // « aaaa-mm-jj »
    var sexe: String = ""          // « h » ou « f »
    var taille: Double = 0         // cm
    var activite: String = "modere"
    var objectif: String = "maintien"
    var poidsCible: Double = 0
    var photo: Data? = nil         // JPEG 512 px
}
extension Profil {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        prenom = c.v(.prenom, ""); nom = c.v(.nom, ""); tel = c.v(.tel, ""); naissance = c.v(.naissance, "")
        sexe = c.v(.sexe, ""); taille = c.v(.taille, 0); activite = c.v(.activite, "modere")
        objectif = c.v(.objectif, "maintien"); poidsCible = c.v(.poidsCible, 0); photo = c.v(.photo, nil)
    }
}

// MARK: - Toutes les données

struct Donnees: Codable {
    var version: Int = 1
    var routine: Routine = .defaut
    var jours: [String: Jour] = [:]
    var plan: PlanNutrition = .defaut
    var alimentsPerso: [Aliment] = []
    var nutrition: [String: JourNutrition] = [:]
    var marche: [String: JourMarche] = [:]
    var objectifPas: Int = 8000
    var programme: [SeanceProgramme] = SeanceProgramme.depart
    var seances: [SeanceFaite] = []
    var enCours: SeanceEnCours? = nil
    var chrono: ChronoMarche? = nil
    var profil: Profil = Profil()
    var pesees: [String: Double] = [:]
    var mensurations: [String: [String: Double]] = [:]
    var importeLe: Date? = nil
}
extension Donnees {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Donnees()
        version = c.v(.version, 1); routine = c.v(.routine, d.routine); jours = c.v(.jours, [:])
        plan = c.v(.plan, d.plan); alimentsPerso = c.v(.alimentsPerso, []); nutrition = c.v(.nutrition, [:])
        marche = c.v(.marche, [:]); objectifPas = c.v(.objectifPas, 8000); programme = c.v(.programme, d.programme)
        seances = c.v(.seances, []); enCours = c.v(.enCours, nil); chrono = c.v(.chrono, nil)
        profil = c.v(.profil, Profil()); pesees = c.v(.pesees, [:]); mensurations = c.v(.mensurations, [:])
        importeLe = c.v(.importeLe, nil)
    }
}
