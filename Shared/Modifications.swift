import Foundation

// Modifications de la journée et de la routine, partagées par l'appli (et le widget pour les coches).

extension Donnees {
    mutating func basculer(_ cle: String, _ id: String) {
        var j = jour(cle); j.faits[id] = !(j.faits[id] ?? false); jours[cle] = j
    }

    mutating func choisirType(_ cle: String, _ type: String) {
        var j = jour(cle); j.type = type; j.typeChoisi = true; jours[cle] = j
    }

    /// Ajoute ou modifie une activité, pour ce jour seulement ou pour tous les jours du même type.
    mutating func enregistrerActivite(_ cle: String, existante: Activite?, valeur: Etape, pourLaRoutine: Bool) {
        var j = jour(cle)
        let typeId = type(j.type).id
        guard let ti = routine.types.firstIndex(where: { $0.id == typeId }) else { return }
        var v = valeur
        if pourLaRoutine {
            if let ex = existante, ex.depuisRoutine, let ei = routine.types[ti].etapes.firstIndex(where: { $0.id == ex.id }) {
                v.id = ex.id; v.lien = ex.etape.lien
                routine.types[ti].etapes[ei] = v
            } else {
                v.id = nouvelId()
                routine.types[ti].etapes.append(v)
                if let ex = existante {        // un ajout du jour passe dans la routine
                    j.ajouts.removeAll { $0.id == ex.id }
                    if j.faits[ex.id] == true { j.faits[v.id] = true }
                }
            }
        } else if let ex = existante {
            if ex.depuisRoutine {             // on remplace l'étape de la routine par une copie pour ce jour
                v.id = nouvelId(); v.lien = ex.etape.lien
                j.retraits.append(ex.id); j.ajouts.append(v)
                if j.faits[ex.id] == true { j.faits[v.id] = true }
            } else if let ai = j.ajouts.firstIndex(where: { $0.id == ex.id }) {
                v.id = ex.id; v.lien = ex.etape.lien
                j.ajouts[ai] = v
            }
        } else {
            v.id = nouvelId()
            j.ajouts.append(v)
        }
        jours[cle] = j
    }

    mutating func retirerActivite(_ cle: String, _ a: Activite, deLaRoutine: Bool) {
        var j = jour(cle)
        if deLaRoutine && a.depuisRoutine {
            let typeId = type(j.type).id
            if let ti = routine.types.firstIndex(where: { $0.id == typeId }) { routine.types[ti].etapes.removeAll { $0.id == a.id } }
        } else if a.depuisRoutine {
            j.retraits.append(a.id)
        } else {
            j.ajouts.removeAll { $0.id == a.id }
        }
        jours[cle] = j
    }
}

extension Donnees {
    /// Prépare une séance à partir du programme : séries, répétitions et charges prévues.
    func preparerSeance(_ s: SeanceProgramme) -> SeanceEnCours? {
        let exos = s.exos.filter { !$0.nom.trimmingCharacters(in: .whitespaces).isEmpty }.map { x -> ExoEnCours in
            let repos = Int(nombre(x.repos)), n = max(1, Int(nombre(x.series)))
            let reps = String(x.reps.prefix { $0.isNumber })
            let charge = nombre(x.charge) > 0 ? decimal(nombre(x.charge)) : ""
            return ExoEnCours(nom: x.nom.trimmingCharacters(in: .whitespaces), repos: repos > 0 ? repos : 90,
                              series: (0..<n).map { _ in SerieEnCours(reps: reps, charge: charge) })
        }
        guard !exos.isEmpty else { return nil }
        return SeanceEnCours(id: nouvelId(), seanceId: s.id, nom: s.nom, debut: Date(), exos: exos)
    }

    /// Séance d'exemple en plein repos, pour la capture de l'écran « séance en cours ».
    mutating func demarrerDemo() {
        guard let p = programme.first, var s = preparerSeance(p) else { return }
        s.debut = Date().addingTimeInterval(-18 * 60)
        for i in s.exos[0].series.indices.prefix(2) { s.exos[0].series[i].fait = true }
        s.finRepos = Date().addingTimeInterval(75)
        enCours = s
    }

    /// Données d'exemple pour les captures du simulateur.
    mutating func ajouterDemo() {
        guard seances.isEmpty else { return }
        let auj = Temps.journee()
        for i in stride(from: 12, through: 1, by: -2) {
            let k = Temps.ajouter(auj, jours: -i), ts = (Temps.date(k)?.timeIntervalSince1970 ?? 0) * 1000
            let s = programme[(12 - i) / 2 % programme.count]
            seances.append(SeanceFaite(id: nouvelId(), date: k, ts: ts, nom: s.nom, seanceId: s.id, duree: 50 + i, volume: 3200 + Double(12 - i) * 90,
                                       exos: [ExoFait(nom: "Développé couché haltères", series: [SerieFaite(reps: 10, charge: 20 + Double(12 - i))])]))
        }
        for i in 0..<5 { pesees[Temps.ajouter(auj, jours: -i * 4)] = 80 - Double(i) * 0.6 }
        for i in 0..<5 { marche[Temps.ajouter(auj, jours: -i)] = JourMarche(date: Temps.ajouter(auj, jours: -i), pas: [6240, 9100, 7400, 10200, 8800][i], minutes: 20) }
        var j = jour(auj); j.typeChoisi = true; j.faits["e1"] = true; j.faits["e2"] = true; jours[auj] = j
        var n = nutritionDu(auj); n.eau = 5; for r in planDu(auj).prefix(2) { n.manges[r.id] = true }; nutrition[auj] = n
    }
}
