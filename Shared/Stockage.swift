import Foundation

/// Lecture et écriture des données dans un fichier JSON.
/// Le fichier est rangé dans le groupe d'apps partagé avec le widget quand SideStore l'autorise ;
/// sinon, dans les documents de l'appli (le widget affiche alors seulement la routine par défaut).
enum Stockage {
    static let groupe = "group.com.pixeldesigner.maroutine"

    /// Dossier utilisable : le groupe d'apps s'il accepte réellement une écriture, sinon les documents.
    /// SideStore renomme le groupe d'apps en y ajoutant l'identifiant d'équipe de ton compte Apple,
    /// et note le vrai nom dans la clé « ALTAppGroups » de l'Info.plist : on essaie chaque possibilité.
    private static var groupesPossibles: [String] {
        var l = (Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String]) ?? []
        l.append(groupe)
        if let id = Bundle.main.bundleIdentifier,
           let equipe = id.split(separator: ".").last.map(String.init),
           equipe.count == 10, equipe == equipe.uppercased() {
            l.append("\(groupe).\(equipe)")
        }
        return l
    }

    private static let emplacement: (url: URL, groupe: Bool) = {
        let fm = FileManager.default
        for nom in groupesPossibles {
            guard let g = fm.containerURL(forSecurityApplicationGroupIdentifier: nom) else { continue }
            let sonde = g.appendingPathComponent(".sonde")
            if (try? Data("ok".utf8).write(to: sonde, options: .atomic)) != nil {
                try? fm.removeItem(at: sonde)
                return (g, true)
            }
        }
        return (fm.urls(for: .documentDirectory, in: .userDomainMask)[0], false)
    }()
    static var dossier: URL { emplacement.url }
    static var groupeDisponible: Bool { emplacement.groupe }
    static var fichier: URL { dossier.appendingPathComponent("donnees.json") }

    static let encodeur: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }()
    static let decodeur: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()

    static func charger() -> Donnees {
        let fm = FileManager.default
        guard let data = try? Data(contentsOf: fichier) else { return Donnees() }
        if let d = try? decodeur.decode(Donnees.self, from: data) { return d }
        // Fichier illisible : on le met de côté au lieu de l'écraser
        let copie = dossier.appendingPathComponent("donnees-illisibles-\(Int(Date().timeIntervalSince1970)).json")
        try? fm.copyItem(at: fichier, to: copie)
        return Donnees()
    }

    @discardableResult
    static func sauver(_ d: Donnees) -> Bool {
        guard let data = try? encodeur.encode(d) else { return false }
        return (try? data.write(to: fichier, options: .atomic)) != nil
    }
}
