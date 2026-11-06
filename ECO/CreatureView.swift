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
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let scale = min(size.width / 320, size.height / 260)
                let cx = size.width / 2
                let cy = size.height / 2 + 18 + (reduceMotion ? 0 : sin(time * 1.5) * 5)
                let width = CGFloat(58 + stage * 8) * scale
                let height = CGFloat(66 + stage * 5) * scale
                let color = silhouette ? Color.white.opacity(0.09) : mood.tint
                let shadow = CGRect(x: cx-width*0.85, y: size.height*0.86, width: width*1.7, height: 12*scale)
                context.fill(Path(ellipseIn: shadow), with: .color(.black.opacity(0.22)))
                if stage >= 3 {
                    for r in [100.0, 113.0] {
                        let rect = CGRect(x: cx-r*scale, y: cy-r*scale, width: r*2*scale, height: r*2*scale)
                        context.stroke(Path(ellipseIn: rect), with: .color(color.opacity(0.15)), lineWidth: 1)
                    }
                }
                if stage >= 2 {
                    for side in [-1.0, 1.0] {
                        var wing = Path()
                        wing.move(to: CGPoint(x: cx+side*width*0.75,y: cy))
                        wing.addQuadCurve(to: CGPoint(x: cx+side*width*1.5, y: cy-height*0.48),
                                          control: CGPoint(x: cx+side*width*1.6, y: cy-height*0.8))
                        wing.addQuadCurve(to: CGPoint(x: cx+side*width*0.75,y: cy+height*0.3),
                                          control: CGPoint(x: cx+side*width*1.6,y: cy+height*0.4))
                        context.fill(wing, with: .color(color.opacity(0.65)))
                    }
                }
                var body = Path()
                body.move(to: CGPoint(x: cx,y:cy-height))
                body.addCurve(to: CGPoint(x:cx+width,y:cy+height*0.35), control1: CGPoint(x:cx+width*0.75,y:cy-height*1.06), control2: CGPoint(x:cx+width*1.22,y:cy-height*0.1))
                body.addCurve(to: CGPoint(x:cx,y:cy+height), control1: CGPoint(x:cx+width*0.9,y:cy+height*0.95), control2: CGPoint(x:cx+width*0.5,y:cy+height))
                body.addCurve(to: CGPoint(x:cx-width,y:cy+height*0.35), control1: CGPoint(x:cx-width*0.5,y:cy+height), control2: CGPoint(x:cx-width*0.9,y:cy+height*0.95))
                body.addCurve(to: CGPoint(x:cx,y:cy-height), control1: CGPoint(x:cx-width*1.22,y:cy-height*0.1), control2: CGPoint(x:cx-width*0.75,y:cy-height*1.06))
                context.fill(body, with: .linearGradient(Gradient(colors:[color, color.opacity(0.5)]),
                    startPoint: CGPoint(x:cx-width,y:cy-height), endPoint: CGPoint(x:cx+width,y:cy+height)))
                if stage >= 1 {
                    var leaf = Path()
                    leaf.move(to:CGPoint(x:cx,y:cy-height+4*scale))
                    leaf.addQuadCurve(to:CGPoint(x:cx+35*scale,y:cy-height-37*scale),control:CGPoint(x:cx-4*scale,y:cy-height-40*scale))
                    leaf.addQuadCurve(to:CGPoint(x:cx,y:cy-height+4*scale),control:CGPoint(x:cx+40*scale,y:cy-height+4*scale))
                    context.fill(leaf, with:.color(color))
                }
                if !silhouette {
                    for x in [-20.0,20.0] {
                        let eye = CGRect(x:cx+x*scale-4*scale,y:cy-6*scale,width:8*scale,height:(sleeping ? 2 : 12)*scale)
                        context.fill(Path(roundedRect:eye,cornerRadius:4*scale),with:.color(Color(red:0.04,green:0.1,blue:0.15)))
                    }
                    var smile = Path()
                    smile.move(to:CGPoint(x:cx-7*scale,y:cy+18*scale))
                    smile.addQuadCurve(to:CGPoint(x:cx+7*scale,y:cy+18*scale),control:CGPoint(x:cx,y:cy+24*scale))
                    context.stroke(smile,with:.color(.black.opacity(0.6)),lineWidth:2*scale)
                }
                if stage == 4 {
                    for i in 0..<5 {
                        let angle = Double(i) * 1.256 - .pi/2
                        let point = CGPoint(x:cx+cos(angle)*105*scale,y:cy+sin(angle)*105*scale)
                        context.fill(Path(ellipseIn:CGRect(x:point.x-3*scale,y:point.y-3*scale,width:6*scale,height:6*scale)),with:.color(color))
                    }
                }
            }
        }.frame(height: 260)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(silhouette ? "Forma ancora da scoprire" : "La tua eco: \(EcoRules.stages[stage]), \(mood.rawValue)\(sleeping ? ", a riposo" : "")")
    }
}
