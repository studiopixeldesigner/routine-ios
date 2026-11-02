import SwiftUI

/// Identité de l'appli : un dégradé de roses, des cartes arrondies, des titres très gras.
enum Theme {
    static let rose1 = Color(red: 1.0, green: 0.61, blue: 0.80)     // #FF9CCB
    static let rose2 = Color(red: 1.0, green: 0.37, blue: 0.66)     // #FF5FA8
    static let rose3 = Color(red: 0.89, green: 0.16, blue: 0.48)    // #E3297A
    static let rose4 = Color(red: 0.66, green: 0.07, blue: 0.35)    // #A8115A
    static let degrade = LinearGradient(colors: [Color(red: 0.95, green: 0.27, blue: 0.56), Color(red: 0.87, green: 0.16, blue: 0.47), Color(red: 0.71, green: 0.09, blue: 0.37)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing)
    static let degradeBarre = LinearGradient(colors: [rose1, rose2, rose3], startPoint: .leading, endPoint: .trailing)
    static let accent = Color.accentColor
}

/// Carte blanche (ou gris très sombre) aux coins arrondis.
struct Carte<Contenu: View>: View {
    var espacement: CGFloat = 12
    @ViewBuilder var contenu: Contenu
    var body: some View {
        VStack(alignment: .leading, spacing: espacement) { contenu }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// Grande carte au dégradé rose, texte blanc.
struct CarteRose<Contenu: View>: View {
    @ViewBuilder var contenu: Contenu
    var body: some View {
        VStack(alignment: .leading, spacing: 8) { contenu }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .foregroundStyle(.white)
            .background {
                ZStack {
                    Theme.degrade
                    RadialGradient(colors: [Color.white.opacity(0.35), .clear], center: .topTrailing, startRadius: 0, endRadius: 220)
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .shadow(color: Theme.rose3.opacity(0.3), radius: 16, y: 8)
    }
}

/// Anneau de progression.
struct Anneau: View {
    var valeur: Double          // 0 à 1
    var epaisseur: CGFloat = 11
    var fond: Color = .white.opacity(0.26)
    var trait: AnyShapeStyle = AnyShapeStyle(Color.white)
    var body: some View {
        ZStack {
            Circle().stroke(fond, lineWidth: epaisseur)
            Circle().trim(from: 0, to: max(0.0001, min(1, valeur)))
                .stroke(trait, style: StrokeStyle(lineWidth: epaisseur, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(valeur > 0 ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: valeur)
        }
    }
}

/// Jauge horizontale en dégradé.
struct Jauge: View {
    var valeur: Double
    var hauteur: CGFloat = 9
    var surRose = false
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(surRose ? Color.white.opacity(0.26) : Color(.tertiarySystemFill))
                Capsule().fill(surRose ? AnyShapeStyle(Color.white) : AnyShapeStyle(Theme.degradeBarre))
                    .frame(width: g.size.width * max(0, min(1, valeur)))
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: valeur)
            }
        }
        .frame(height: hauteur)
    }
}

/// Bouton principal : pilule au dégradé rose.
struct BoutonRose: ButtonStyle {
    var large = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, large ? 16 : 10)
            .padding(.horizontal, 18)
            .frame(maxWidth: large ? .infinity : nil)
            .background(Theme.degrade, in: Capsule())
            .shadow(color: Theme.rose3.opacity(0.3), radius: 10, y: 5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Bouton secondaire : pilule grise, texte rose.
struct BoutonDoux: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .padding(.vertical, 10).padding(.horizontal, 16)
            .background(Color(.tertiarySystemFill), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

/// Coche ronde en dégradé.
struct Coche: View {
    var faite: Bool
    var taille: CGFloat = 28
    var body: some View {
        ZStack {
            Circle().strokeBorder(Color(.systemGray3), lineWidth: 2).opacity(faite ? 0 : 1)
            if faite {
                Circle().fill(Theme.degrade)
                Image(systemName: "checkmark").font(.system(size: taille * 0.45, weight: .heavy)).foregroundStyle(.white)
            }
        }
        .frame(width: taille, height: taille)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: faite)
    }
}

extension View {
    /// Petit sous-titre sous le grand titre de l'écran (iOS 26 et plus ; rien avant).
    @ViewBuilder func sousTitre(_ texte: String) -> some View {
        if #available(iOS 26.0, *) { navigationSubtitle(texte) } else { self }
    }

    /// Petit titre de section en majuscules.
    func surtitre() -> some View {
        self.font(.caption.weight(.bold)).textCase(.uppercase).tracking(0.6).foregroundStyle(.secondary)
    }
}

/// Texte de chiffre en dégradé rose.
struct GrosChiffre: View {
    var texte: String
    var unite: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(texte).font(.system(size: 46, weight: .heavy, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [Theme.rose2, Theme.rose3, Theme.rose4], startPoint: .leading, endPoint: .trailing))
                .contentTransition(.numericText())
            Text(unite).font(.headline).foregroundStyle(.secondary)
        }
    }
}
