import Foundation

// Contenu de départ : la routine 9h – 0h45, le programme PUSH / PULL / LEGS,
// un plan de repas d'exemple et une liste d'aliments courants.

extension Routine {
    static let defaut: Routine = {
        func communes(_ milieu: Etape) -> [Etape] {
            [Etape(id: "e1", heure: "09:00", titre: "Lever, lumière, petit-déj", note: "Volets ouverts, 10 min dehors, un petit-déj protéiné."),
             Etape(id: "e2", heure: "09:45", titre: "Pixel Designer sans téléphone", note: "Ta tâche la plus importante d'abord, 90 min."),
             milieu,
             Etape(id: "e4", heure: "15:00", titre: "2 candidatures, stop à 18h30", note: "Puis Pixel Designer. À 18h30, tu fermes le travail."),
             Etape(id: "e5", heure: "23:45", titre: "Écrans éteints", note: "Lecture papier, puis au lit à 0h45.")]
        }
        return Routine(
            lever: "09:00", coucher: "00:45",
            types: [
                TypeJour(id: "salle", nom: "Salle", emoji: "🏋️", etapes: communes(
                    Etape(id: "e3s", heure: "12:30", titre: "Séance de muscu", note: "Puis un vrai déjeuner vers 14h.", lien: "seance"))),
                TypeJour(id: "repos", nom: "Repos", emoji: "🌿", etapes: communes(
                    Etape(id: "e3r", heure: "12:30", titre: "Marche dehors, 30 min", note: "Puis un vrai déjeuner vers 14h.", lien: "marche")))
            ],
            regles: [
                Regle(titre: "Lever fixe à 9h", texte: "même le week-end, à une heure près."),
                Regle(titre: "Pas de travail après 18h30.", texte: "Une idée le soir : note-la pour demain."),
                Regle(titre: "Café avant 14h", texte: "sinon l'endormissement recule."),
                Regle(titre: "Repas à heures fixes", texte: ": petit-déj, déjeuner vers 14h, dîner vers 19h30."),
                Regle(titre: "Petits pas", texte: ": si tu te couches encore vers 2h, avance de 15 min tous les 2-3 jours.")
            ])
    }()
}

extension SeanceProgramme {
    static let depart: [SeanceProgramme] = [
        SeanceProgramme(id: "mvpjcb2h29pb", nom: "Séance PUSH", exos: [
            Exercice(nom: "Développé couché haltères", series: "3", reps: "8-10", repos: "120"),
            Exercice(nom: "Ecarté incliné haltères", series: "3", reps: "15", repos: "120"),
            Exercice(nom: "Ecartés poulie vis-à-vis poulie haute", series: "3", reps: "15", repos: "120"),
            Exercice(nom: "Shoulder press machine", series: "3", reps: "10+10", repos: "120"),
            Exercice(nom: "Triceps corde 2 bras", series: "2", reps: "15", repos: "120")]),
        SeanceProgramme(id: "mvpjdanjdyfd", nom: "Séance PULL", exos: [
            Exercice(nom: "Rowing barre pronation", series: "3", reps: "8", repos: "120"),
            Exercice(nom: "Tirage horizontal machine coudes hauts", series: "3", reps: "15", repos: "120"),
            Exercice(nom: "Tirage verticale prise large neutre", series: "3", reps: "8-10", repos: "120"),
            Exercice(nom: "TRX coudes hauts", series: "3", reps: "20 (1\" fin de rep)", repos: "120"),
            Exercice(nom: "Biceps curl haltères prise marteau", series: "3", reps: "10+10", repos: "120")]),
        SeanceProgramme(id: "mvpjdbojumv1", nom: "Séance LEGS", exos: [
            Exercice(nom: "Hack squat machine", series: "3", reps: "8", repos: "180"),
            Exercice(nom: "Leg curl une jambe", series: "3", reps: "10/J", repos: "120"),
            Exercice(nom: "Presse pieds en bas", series: "3", reps: "15", repos: "120"),
            Exercice(nom: "Fentes marchées", series: "3", reps: "10/J", repos: "120")])
    ]
}

extension Aliment {
    /// Valeurs moyennes pour 100 g ; l'étiquette du produit fait foi.
    static let base: [Aliment] = {
        typealias L = (String, String, String, Double, Double, Double, Double, Double)
        let lignes: [L] = [
        ("oeuf", "Œufs", "🥚", 145, 12.5, 0.7, 10, 60), ("poulet", "Blanc de poulet cuit", "🍗", 150, 30, 0, 3, 150),
        ("dinde", "Escalope de dinde cuite", "🦃", 135, 29, 0, 2, 150), ("steak", "Steak haché 5 % cuit", "🥩", 160, 27, 0, 6, 125),
        ("jambon", "Jambon blanc", "🍖", 115, 21, 1, 3, 40), ("thon", "Thon au naturel", "🐟", 115, 26, 0, 1, 100),
        ("saumon", "Saumon cuit", "🍣", 200, 25, 0, 11, 130), ("cabillaud", "Cabillaud cuit", "🐠", 100, 22, 0, 1, 150),
        ("crevettes", "Crevettes cuites", "🍤", 100, 22, 0, 1, 100), ("skyr", "Skyr nature", "🥛", 63, 11, 4, 0.2, 150),
        ("fromage-blanc", "Fromage blanc 0 %", "🥛", 48, 7.5, 4, 0.2, 200), ("cottage", "Cottage cheese", "🧀", 100, 11, 3.5, 4.5, 150),
        ("lait", "Lait demi-écrémé", "🥛", 46, 3.3, 4.8, 1.6, 250), ("whey", "Whey (poudre)", "🥤", 380, 78, 6, 5, 30),
        ("emmental", "Emmental", "🧀", 380, 28, 0, 29, 30), ("mozza", "Mozzarella", "🧀", 250, 18, 1, 19, 60),
        ("avoine", "Flocons d'avoine", "🥣", 370, 13, 59, 7, 60), ("granola", "Granola", "🥣", 450, 9, 64, 16, 50),
        ("pain-complet", "Pain complet", "🍞", 240, 9, 43, 2.5, 60), ("baguette", "Baguette", "🥖", 270, 9, 55, 1.3, 60),
        ("croissant", "Croissant", "🥐", 410, 8, 45, 21, 60), ("riz", "Riz cuit", "🍚", 130, 2.7, 28, 0.3, 200),
        ("pates", "Pâtes cuites", "🍝", 150, 5.5, 30, 0.9, 200), ("pdt", "Pommes de terre cuites", "🥔", 85, 2, 18, 0.1, 200),
        ("patate-douce", "Patate douce cuite", "🍠", 90, 2, 20, 0.2, 200), ("lentilles", "Lentilles cuites", "🫘", 115, 9, 17, 0.5, 200),
        ("pois-chiches", "Pois chiches cuits", "🫘", 140, 8, 20, 2.5, 150), ("wrap", "Tortilla de blé", "🌯", 300, 8, 50, 7, 60),
        ("legumes", "Légumes variés", "🥗", 30, 1.5, 4.5, 0.3, 200), ("brocoli", "Brocoli cuit", "🥦", 35, 2.8, 4, 0.4, 200),
        ("haricots", "Haricots verts cuits", "🫛", 30, 2, 4.5, 0.2, 200), ("salade", "Salade verte", "🥬", 15, 1.3, 1.5, 0.2, 80),
        ("tomate", "Tomate", "🍅", 20, 0.9, 3.5, 0.2, 120), ("avocat", "Avocat", "🥑", 160, 2, 2, 15, 80),
        ("banane", "Banane", "🍌", 90, 1.1, 21, 0.3, 120), ("pomme", "Pomme", "🍎", 54, 0.3, 12, 0.2, 150),
        ("fruits-rouges", "Fruits rouges", "🫐", 45, 1, 8, 0.4, 100), ("orange", "Orange", "🍊", 47, 0.9, 9, 0.1, 150),
        ("amandes", "Amandes", "🌰", 620, 25, 7, 53, 20), ("beurre-cacahuete", "Beurre de cacahuète", "🥜", 600, 25, 14, 50, 15),
        ("huile-olive", "Huile d'olive", "🫒", 900, 0, 0, 100, 10), ("chocolat", "Chocolat noir 70 %", "🍫", 580, 8, 33, 43, 20),
        ("miel", "Miel", "🍯", 320, 0.4, 80, 0, 10), ("jus-orange", "Jus d'orange", "🧃", 45, 0.7, 10, 0.2, 200),
        ("pizza", "Pizza", "🍕", 260, 11, 30, 10, 300), ("burger", "Burger", "🍔", 250, 13, 24, 11, 220),
        ("frites", "Frites", "🍟", 300, 3.5, 38, 15, 150), ("soda", "Soda", "🥫", 42, 0, 10.6, 0, 330),
        ("biere", "Bière", "🍺", 43, 0.4, 3.6, 0, 330)
        ]
        return lignes.map { Aliment(id: $0.0, nom: $0.1, emoji: $0.2, kcal: $0.3, p: $0.4, g: $0.5, l: $0.6, portion: $0.7) }
    }()
}

extension PlanNutrition {
    static let defaut: PlanNutrition = {
        func repas(_ id: String, _ heure: String, _ nom: String, _ a: [(String, Double)]) -> Repas {
            Repas(id: id, heure: heure, nom: nom, aliments: a.map { LigneAliment(a: $0.0, q: $0.1) })
        }
        return PlanNutrition(actif: "p1", programmes: [ProgrammeRepas(id: "p1", nom: "Équilibre", plans: [
            "salle": [repas("r1", "09:15", "Petit-déj", [("avoine", 60), ("skyr", 150), ("banane", 120), ("oeuf", 120)]),
                      repas("r2", "14:00", "Déjeuner", [("poulet", 150), ("riz", 200), ("legumes", 200), ("huile-olive", 10)]),
                      repas("r3", "17:00", "Collation", [("fromage-blanc", 200), ("fruits-rouges", 100), ("amandes", 20)]),
                      repas("r4", "19:30", "Dîner", [("saumon", 130), ("pdt", 250), ("haricots", 200)])],
            "repos": [repas("q1", "09:15", "Petit-déj", [("avoine", 50), ("skyr", 150), ("fruits-rouges", 100), ("oeuf", 120)]),
                      repas("q2", "14:00", "Déjeuner", [("poulet", 150), ("riz", 120), ("legumes", 250), ("huile-olive", 10)]),
                      repas("q3", "17:00", "Collation", [("fromage-blanc", 200), ("pomme", 150)]),
                      repas("q4", "19:30", "Dîner", [("saumon", 130), ("pdt", 150), ("haricots", 200)])]
        ])])
    }()
}
