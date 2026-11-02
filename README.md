# Ma routine (iPhone)

Appli iPhone de la routine 9h – 0h45 : journée, sport (muscu et marche), nutrition, progrès, profil.

## Installer

Avec un compte Apple gratuit, de deux façons :

- **iloader (depuis un PC)** : brancher l'iPhone, ouvrir [iloader](https://iloader.app), se connecter,
  « Importer IPA » et choisir `MaRoutine.ipa`
  (https://github.com/studiopixeldesigner/routine-ios/releases/latest/download/MaRoutine.ipa).
  Refaire la même chose tous les 7 jours : les données sont gardées.
- **SideStore (depuis l'iPhone)** : ouvrir le lien de l'IPA, puis SideStore → My Apps → « + ».
  Renouveler dans SideStore tous les 7 jours.

Au premier lancement, accepter les notifications (rappels) et l'accès à Santé (pas).
Le widget « Ma journée » s'ajoute comme n'importe quel widget (écran d'accueil ou écran verrouillé).

## Ce que fait l'appli

- **Journée** : type de jour (Salle, Repos, ou tes propres types), activités d'aujourd'hui et de demain,
  rappels à l'heure avec le son « Velours », routine entièrement modifiable.
- **Sport** : programme de musculation, séance en cours avec minuteur de repos (Dynamic Island et écran
  verrouillé), marche avec les pas de l'app Santé et un minuteur de 30 minutes.
- **Nutrition** : programmes de repas par type de jour, calories et macros, écarts, eau, aliments perso.
- **Progrès** : semaine en un coup d'œil, courbe de charge par exercice, historique.
- **Profil** : photo, besoins estimés, poids, mensurations, import et sauvegarde des données.

## Fabrication

Pas besoin de Mac : à chaque envoi sur `main`, GitHub Actions

- `compiler.yml` génère le projet avec XcodeGen (`project.yml`), compile l'appli et son widget sans
  signature, ajoute les autorisations avec `ldid`, puis publie `MaRoutine.ipa` dans la release « derniere » ;
- `captures.yml` installe l'appli sur un iPhone simulé, prend une capture de chaque onglet en clair et en
  sombre, et les publie dans la release « captures ».
