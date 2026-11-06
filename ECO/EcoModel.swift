import Foundation

enum EcoMood: String, Codable, CaseIterable, Identifiable {
    case calma = "Calma", curiosita = "Curiosità", energia = "Energia", nostalgia = "Nostalgia"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .calma: return "leaf"
        case .curiosita: return "sparkle.magnifyingglass"
        case .energia: return "sun.max"
        case .nostalgia: return "moon.stars"
        }
    }
}

struct EcoCoordinate: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var accuracy: Double
    var measuredAt: Date
    var valid: Bool {
        latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude)
            && accuracy.isFinite && accuracy >= 0
    }
}

struct EcoEntry: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var mood: EcoMood
    var note: String
    var missionID: Int?
    var photo: Data?
    var presenceConfirmed: Bool
}

struct EcoPlace: Codable, Identifiable {
    var id = UUID()
    var name: String
    var createdAt: Date
    var coordinate: EcoCoordinate?
    var seed: Int
    var entries: [EcoEntry]
    var lastVisit: Date { entries.map(\.date).max() ?? createdAt }
    var mood: EcoMood { entries.max(by: { $0.date < $1.date })?.mood ?? .calma }
}

struct EcoArchive: Codable {
    var version = 1
    var places: [EcoPlace] = []
}

struct EcoMission: Identifiable {
    let id: Int
    let title: String
    let prompt: String
    static let all: [EcoMission] = [
        .init(id: 0, title: "Il dettaglio nascosto", prompt: "Da un posto sicuro, osserva un dettaglio che prima non avevi notato e descrivilo."),
        .init(id: 1, title: "Un colore nuovo", prompt: "Scegli un colore presente qui. A quale ricordo lo colleghi?"),
        .init(id: 2, title: "Ascolta un momento", prompt: "Fermati in sicurezza e ascolta per qualche istante. Descrivi un suono, senza registrare altre persone."),
        .init(id: 3, title: "Un’altra prospettiva", prompt: "Osserva il luogo da un altro punto accessibile e sicuro. Che cosa cambia?"),
        .init(id: 4, title: "Tre parole", prompt: "Descrivi questo luogo con tre parole e spiega perché le hai scelte."),
        .init(id: 5, title: "Il tuo segno", prompt: "Dai un nome immaginario a un elemento del paesaggio. Non modificare o lasciare oggetti nel luogo."),
        .init(id: 6, title: "Una storia breve", prompt: "Immagina una piccola storia ambientata qui e scrivine una frase."),
        .init(id: 7, title: "Cosa è cambiato?", prompt: "Confronta il luogo con un tuo ricordo. Se è la prima visita, annota cosa vorresti ricordare."),
        .init(id: 8, title: "Una forma", prompt: "Trova una forma interessante nei dettagli del luogo e descrivila o aggiungi una tua foto."),
        .init(id: 9, title: "Una parola per domani", prompt: "Lascia al tuo io futuro un pensiero legato a questo luogo.")
    ]
}

struct EcoProgress {
    let familiarity: Int
    let curiosity: Int
    let memories: Int
    var score: Int { familiarity + curiosity * 2 + memories }
    var stage: Int { [0, 4, 9, 16, 25].lastIndex(where: { score >= $0 }) ?? 0 }
    var nextThreshold: Int? { stage < 4 ? [0, 4, 9, 16, 25][stage + 1] : nil }
}

enum EcoRules {
    static let stages = ["Seme", "Germoglio", "Custode", "Risonanza", "Legame"]
    static func progress(_ place: EcoPlace, calendar: Calendar = .current) -> EcoProgress {
        let visits = Set(place.entries.map { calendar.startOfDay(for: $0.date) }).count
        let novelty = Set(place.entries.compactMap(\.missionID).filter { (0..<10).contains($0) }).count
        let memories = Set(place.entries.filter {
            !$0.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || $0.photo != nil
        }.map { calendar.startOfDay(for: $0.date) }).count
        return EcoProgress(familiarity: visits, curiosity: novelty, memories: memories)
    }
    static func mission(_ place: EcoPlace, now: Date, calendar: Calendar = .current) -> EcoMission {
        let day = calendar.ordinality(of: .day, in: .era, for: now) ?? 1
        let index = ((day + place.seed) % EcoMission.all.count + EcoMission.all.count) % EcoMission.all.count
        return EcoMission.all[index]
    }
    static func hasVisited(_ place: EcoPlace, now: Date, calendar: Calendar = .current) -> Bool {
        place.entries.contains { calendar.isDate($0.date, inSameDayAs: now) }
    }
    static func canComplete(_ place: EcoPlace, now: Date, calendar: Calendar = .current) -> Bool {
        !place.entries.contains { calendar.isDate($0.date, inSameDayAs: now) && $0.missionID != nil }
    }
    static func sleeping(_ place: EcoPlace, now: Date) -> Bool { now.timeIntervalSince(place.lastVisit) > 7 * 86400 }
    static func story(_ place: EcoPlace, now: Date) -> String {
        if sleeping(place, now: now) { return "La tua eco riposa tra i ricordi. Il legame non è diminuito: puoi risvegliarla quando vuoi." }
        switch progress(place).stage {
        case 0: return "Un piccolo seme ha ascoltato il tuo primo ricordo. Non conosce ancora il luogo, ma riconosce la tua presenza."
        case 1: return "La familiarità ha messo radici. La tua eco cerca le differenze nascoste tra un ritorno e l’altro."
        case 2: return "Ora custodisce dettagli che prima passavano inosservati. Ogni nuova osservazione le dà una voce."
        case 3: return "I tuoi ricordi risuonano insieme. Il luogo è lo stesso, ma il modo in cui lo guardi continua a cambiare."
        default: return "È nato un legame. La creatura non possiede questo luogo: conserva il tuo modo unico di viverlo. La storia può continuare."
        }
    }
}
