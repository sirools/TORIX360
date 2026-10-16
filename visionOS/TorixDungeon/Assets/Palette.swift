import UIKit

/// Palette « inspirée » : tons chauds, pierre sombre, touches d'ocre et de mauve.
/// Aucune couleur officielle reprise : à ajuster librement.
enum Palette {
    // Pierre et sol
    static let stoneDark = UIColor(hex: 0x24211E)
    static let stoneMid = UIColor(hex: 0x332E2A)
    static let stoneLight = UIColor(hex: 0x433C35)
    static let floorDark = UIColor(hex: 0x1B1917)
    static let floorMid = UIColor(hex: 0x26221F)
    static let ceiling = UIColor(hex: 0x121110)

    // Feu
    static let flame = UIColor(hex: 0xFF8A2A)
    static let flameCore = UIColor(hex: 0xFFD27A)
    static let torchLight = UIColor(hex: 0xFF9A4A)

    // Éléments
    static let ochre = UIColor(hex: 0xC98A2E)
    static let ochreDark = UIColor(hex: 0x8E5E1C)
    static let mauve = UIColor(hex: 0x9A6FB0)
    static let mauveDark = UIColor(hex: 0x5E3F72)
    static let spellCyan = UIColor(hex: 0x5FE3D6)
    static let gold = UIColor(hex: 0xD9A93E)
    static let wood = UIColor(hex: 0x4E321E)
    static let woodDark = UIColor(hex: 0x33200F)
    static let iron = UIColor(hex: 0x3D3D42)
    static let wax = UIColor(hex: 0xEDE3CC)
    static let parchment = UIColor(hex: 0xE3D3A8)
    static let leather = UIColor(hex: 0x5B2140)
    static let hedgehogBody = UIColor(hex: 0x9A7A58)
    static let hedgehogSpikes = UIColor(hex: 0x3B2A1E)
    static let hedgehogSnout = UIColor(hex: 0xDCC4A4)
    static let black = UIColor(hex: 0x0B0A0A)
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }

    /// Variante légèrement plus claire ou plus sombre (facteur 0.8 = 20 % plus sombre).
    func scaled(_ factor: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: min(r * factor, 1), green: min(g * factor, 1),
                       blue: min(b * factor, 1), alpha: a)
    }
}
