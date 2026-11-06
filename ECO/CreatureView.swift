import SwiftUI

extension EcoMood {
    var tint: Color {
        switch self {
        case .calma: return Color(red: 0.46, green: 0.9, blue: 0.72)
        case .curiosita: return Color(red: 0.69, green: 0.64, blue: 1)
        case .energia: return Color(red: 1, green: 0.75, blue: 0.4)
        case .nostalgia: return Color(red: 0.48, green: 0.74, blue: 1)
        }
    }
}

struct CreatureView: View {
    let stage: Int
    var mood: EcoMood = .calma
    var sleeping = false
    var silhouette = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var safeStage: Int { min(4, max(0, stage)) }
    private var spokenDescription: String {
        if silhouette { return "Forma ancora da scoprire" }
        let name: String = EcoRules.stages[safeStage]
        let rest: String = sleeping ? ", a riposo" : ""
        return "La tua eco: \(name), \(mood.rawValue)\(rest)"
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: reduceMotion)) { timeline in
            drawing(at: timeline.date)
        }
        .frame(height: 260)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenDescription)
    }

    private func drawing(at date: Date) -> some View {
        let time: TimeInterval = reduceMotion ? 0.0 : date.timeIntervalSinceReferenceDate
        let color: Color = silhouette ? Color.white.opacity(0.09) : mood.tint
        let renderer = LumeRenderer(stage: safeStage, color: color, sleeping: sleeping, silhouette: silhouette)
        return Canvas { context, size in
            renderer.draw(context: context, size: size, time: time)
        }
    }
}

// Concrete geometry keeps CGFloat calculations out of the SwiftUI view builder.
private struct LumeGeometry {
    let scale: CGFloat
    let center: CGPoint
    let width: CGFloat
    let height: CGFloat
    let canvasHeight: CGFloat

    init(size: CGSize, stage: Int, time: TimeInterval) {
        scale = min(size.width / 320.0, size.height / 260.0)
        let bob: CGFloat = CGFloat(sin(time * 1.5)) * 5.0
        center = CGPoint(x: size.width / 2.0, y: size.height / 2.0 + 18.0 + bob)
        width = CGFloat(58 + stage * 8) * scale
        height = CGFloat(66 + stage * 5) * scale
        canvasHeight = size.height
    }

    func bodyPoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: center.x + width * x, y: center.y + height * y)
    }
    func pixelPoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: center.x + scale * x, y: center.y + scale * y)
    }
}

private struct LumeRenderer {
    let stage: Int
    let color: Color
    let sleeping: Bool
    let silhouette: Bool

    func draw(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        guard size.width > 0, size.height > 0 else { return }
        let g = LumeGeometry(size: size, stage: stage, time: time)
        drawShadow(context, g)
        if stage >= 3 { drawRings(context, g) }
        if stage >= 2 { drawWings(context, g) }
        drawBody(context, g)
        if stage >= 1 { drawLeaf(context, g) }
        if !silhouette { drawFace(context, g) }
        if stage == 4 { drawSparks(context, g) }
    }

    private func drawShadow(_ context: GraphicsContext, _ g: LumeGeometry) {
        let rect = CGRect(x: g.center.x - g.width * 0.85,
                          y: g.canvasHeight * 0.86,
                          width: g.width * 1.7, height: g.scale * 12.0)
        let path = Path(ellipseIn: rect)
        context.fill(path, with: .color(Color.black.opacity(0.22)))
    }

    private func drawRings(_ context: GraphicsContext, _ g: LumeGeometry) {
        let radii: [CGFloat] = [100.0, 113.0]
        for radius in radii {
            let r: CGFloat = radius * g.scale
            let rect = CGRect(x: g.center.x - r, y: g.center.y - r, width: r * 2.0, height: r * 2.0)
            context.stroke(Path(ellipseIn: rect), with: .color(color.opacity(0.15)), lineWidth: 1.0)
        }
    }

    private func drawWings(_ context: GraphicsContext, _ g: LumeGeometry) {
        let sides: [CGFloat] = [-1.0, 1.0]
        for side in sides {
            var path = Path()
            path.move(to: g.bodyPoint(side * 0.75, 0.0))
            path.addQuadCurve(to: g.bodyPoint(side * 1.5, -0.48), control: g.bodyPoint(side * 1.6, -0.8))
            path.addQuadCurve(to: g.bodyPoint(side * 0.75, 0.3), control: g.bodyPoint(side * 1.6, 0.4))
            path.closeSubpath()
            context.fill(path, with: .color(color.opacity(0.65)))
        }
    }

    private func drawBody(_ context: GraphicsContext, _ g: LumeGeometry) {
        var path = Path()
        path.move(to: g.bodyPoint(0.0, -1.0))
        path.addCurve(to: g.bodyPoint(1.0, 0.35), control1: g.bodyPoint(0.75, -1.06), control2: g.bodyPoint(1.22, -0.1))
        path.addCurve(to: g.bodyPoint(0.0, 1.0), control1: g.bodyPoint(0.9, 0.95), control2: g.bodyPoint(0.5, 1.0))
        path.addCurve(to: g.bodyPoint(-1.0, 0.35), control1: g.bodyPoint(-0.5, 1.0), control2: g.bodyPoint(-0.9, 0.95))
        path.addCurve(to: g.bodyPoint(0.0, -1.0), control1: g.bodyPoint(-1.22, -0.1), control2: g.bodyPoint(-0.75, -1.06))
        path.closeSubpath()
        let gradient = Gradient(colors: [color, color.opacity(0.5)])
        let shading: GraphicsContext.Shading = .linearGradient(gradient, startPoint: g.bodyPoint(-1.0, -1.0), endPoint: g.bodyPoint(1.0, 1.0))
        context.fill(path, with: shading)
    }

    private func drawLeaf(_ context: GraphicsContext, _ g: LumeGeometry) {
        let top: CGFloat = -g.height / g.scale
        var path = Path()
        path.move(to: g.pixelPoint(0.0, top + 4.0))
        path.addQuadCurve(to: g.pixelPoint(35.0, top - 37.0), control: g.pixelPoint(-4.0, top - 40.0))
        path.addQuadCurve(to: g.pixelPoint(0.0, top + 4.0), control: g.pixelPoint(40.0, top + 4.0))
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    private func drawFace(_ context: GraphicsContext, _ g: LumeGeometry) {
        let offsets: [CGFloat] = [-20.0, 20.0]
        let eyeHeight: CGFloat = (sleeping ? 2.0 : 12.0) * g.scale
        let eyeColor = Color(red: 0.04, green: 0.1, blue: 0.15)
        for offset in offsets {
            let origin = g.pixelPoint(offset - 4.0, -6.0)
            let rect = CGRect(origin: origin, size: CGSize(width: g.scale * 8.0, height: eyeHeight))
            let eye = Path(roundedRect: rect, cornerRadius: g.scale * 4.0)
            context.fill(eye, with: .color(eyeColor))
        }
        var smile = Path()
        smile.move(to: g.pixelPoint(-7.0, 18.0))
        smile.addQuadCurve(to: g.pixelPoint(7.0, 18.0), control: g.pixelPoint(0.0, 24.0))
        context.stroke(smile, with: .color(Color.black.opacity(0.6)), lineWidth: g.scale * 2.0)
    }

    private func drawSparks(_ context: GraphicsContext, _ g: LumeGeometry) {
        for index in 0..<5 {
            let angle: Double = Double(index) * 1.256 - Double.pi / 2.0
            let x: CGFloat = CGFloat(cos(angle)) * 105.0
            let y: CGFloat = CGFloat(sin(angle)) * 105.0
            let origin = g.pixelPoint(x - 3.0, y - 3.0)
            let rect = CGRect(origin: origin, size: CGSize(width: g.scale * 6.0, height: g.scale * 6.0))
            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }
}
