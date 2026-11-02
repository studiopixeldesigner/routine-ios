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
