# Ma routine (iPhone)

Appli iPhone de la routine 9h – 0h45 : journée, sport (muscu et marche), nutrition, progrès, profil.

## Installer

1. Sur l'iPhone, ouvrir https://github.com/studiopixeldesigner/routine-ios/releases/latest/download/MaRoutine.ipa
2. Ouvrir le fichier téléchargé avec **SideStore**.
3. Renouveler l'appli dans SideStore tous les 7 jours (compte Apple gratuit).

## Fabrication

Pas besoin de Mac : à chaque envoi sur `main`, GitHub Actions (`.github/workflows/compiler.yml`)
génère le projet avec XcodeGen (`project.yml`), compile l'appli et son widget sans signature,
ajoute les autorisations avec `ldid`, puis publie `MaRoutine.ipa` dans la release « derniere ».
