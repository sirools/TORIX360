import SwiftUI

/// En-tête : personnage, lieu, coordonnées, aide-mémoire des commandes.
struct HUDHeaderView: View {
    let world: VillageWorld

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color(uiColor: Palette.mauve))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sirools").font(.title3).bold()
                    Text("Clairière de Bruyère  [\(Int(world.mapPosition.x.rounded())), \(Int((-world.mapPosition.y).rounded()))]")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Text("ZQSD / flèches : marcher · Maj : courir · ← → : pivoter · 1–6 : sorts · I : inventaire · M : carte · pincer le sol : portail")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 520, alignment: .leading)
        }
        .padding(16)
        .glassBackgroundEffect()
    }
}

/// Barre de sorts : 6 emplacements, recharge visible.
struct SpellBarView: View {
    let world: VillageWorld

    var body: some View {
        HStack(spacing: 10) {
            ForEach(world.spells) { spell in
                let remaining = world.cooldowns[spell.id] ?? 0
                let progress = spell.cooldown > 0 ? remaining / spell.cooldown : 0
                ZStack(alignment: .topLeading) {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: spell.color).opacity(0.25))
                        Image(systemName: spell.symbol)
                            .font(.title2)
                            .foregroundStyle(Color(uiColor: spell.color))
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.black.opacity(0.55), style: StrokeStyle(lineWidth: 26))
                            .rotationEffect(.degrees(-90))
                            .padding(13)
                    }
                    .frame(width: 64, height: 64)
                    Text("\(spell.id + 1)")
                        .font(.caption.bold())
                        .padding(4)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .help(spell.name)
            }
        }
        .padding(12)
        .glassBackgroundEffect()
    }
}

/// Inventaire (touche I).
struct InventoryView: View {
    let world: VillageWorld

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Inventaire", systemImage: "bag.fill").font(.title3).bold()
            if world.inventory.isEmpty {
                Text("Rien pour l'instant. Approche-toi des objets qui flottent pour les ramasser.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                    ForEach(world.inventory) { item in
                        VStack(spacing: 6) {
                            Image(systemName: item.symbol).font(.title)
                            Text(item.name).font(.caption).multilineTextAlignment(.center).lineLimit(2)
                            Text("×\(item.count)").font(.caption.bold()).foregroundStyle(.secondary)
                        }
                        .frame(width: 110, height: 100)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            Divider()
            Label("Hérissons touchés : \(world.hits)", systemImage: "scope").font(.callout)
        }
        .padding(20)
        .frame(width: 400)
        .glassBackgroundEffect()
    }
}

/// Carte du village vue de dessus (touche M).
struct VillageMapView: View {
    let world: VillageWorld

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Clairière de Bruyère", systemImage: "map.fill").font(.title3).bold()
            Canvas { context, size in
                let scale = Float(size.width) / (world.layout.walkableRadius * 2 + 4)
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                func point(_ p: SIMD2<Float>) -> CGPoint {
                    CGPoint(x: center.x + CGFloat(p.x * scale), y: center.y + CGFloat(p.y * scale))
                }

                let radius = CGFloat(world.layout.walkableRadius * scale)
                context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                             with: .color(Color(uiColor: VillageBuilder.grass)))
                for (start, end) in world.layout.paths {
                    var path = Path()
                    path.move(to: point(start))
                    path.addLine(to: point(end))
                    context.stroke(path, with: .color(Color(uiColor: VillageBuilder.dirt)), lineWidth: CGFloat(1.6 * scale))
                }
                let plaza = point(world.layout.plaza)
                let plazaRadius = CGFloat(4.6 * scale)
                context.fill(Path(ellipseIn: CGRect(x: plaza.x - plazaRadius, y: plaza.y - plazaRadius, width: plazaRadius * 2, height: plazaRadius * 2)),
                             with: .color(Color(uiColor: VillageBuilder.stone)))
                for tree in world.layout.trees {
                    let p = point(tree)
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)),
                                 with: .color(Color(uiColor: VillageBuilder.grassDark)))
                }
                for house in world.layout.houses {
                    let p = point(house)
                    let side = CGFloat(2.6 * scale)
                    context.fill(Path(CGRect(x: p.x - side / 2, y: p.y - side / 2, width: side, height: side)),
                                 with: .color(Color(uiColor: VillageBuilder.roof)))
                }
                let portal = point(world.layout.portal)
                context.fill(Path(ellipseIn: CGRect(x: portal.x - 5, y: portal.y - 5, width: 10, height: 10)),
                             with: .color(Color(uiColor: Palette.spellCyan)))
                for creature in world.creaturePositions {
                    let p = point(creature)
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 3.5, y: p.y - 3.5, width: 7, height: 7)), with: .color(.red))
                }

                // Joueur : flèche orientée dans la direction du regard.
                let player = point(world.mapPosition)
                var arrow = Path()
                arrow.move(to: CGPoint(x: 0, y: -10))
                arrow.addLine(to: CGPoint(x: 7, y: 8))
                arrow.addLine(to: CGPoint(x: 0, y: 4))
                arrow.addLine(to: CGPoint(x: -7, y: 8))
                arrow.closeSubpath()
                let transform = CGAffineTransform(translationX: player.x, y: player.y).rotated(by: CGFloat(world.mapHeading))
                context.fill(arrow.applying(transform), with: .color(Color(uiColor: Palette.mauve)))
            }
            .frame(width: 340, height: 340)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(20)
        .glassBackgroundEffect()
    }
}

/// Message éphémère (objet ramassé, sort réussi…).
struct ToastView: View {
    let world: VillageWorld

    var body: some View {
        Text(world.toast ?? " ")
            .font(.title3.bold())
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .glassBackgroundEffect()
            .opacity(world.toast == nil ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: world.toast)
    }
}
