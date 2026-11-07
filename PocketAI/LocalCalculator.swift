import Foundation

// Explicit arithmetic only: no JavaScript, NSExpression or code execution.
enum LocalCalculator {
    static func expression(_ text: String) -> String? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        for prefix in ["/calcola ", "calcola ", "quanto fa "] where value.lowercased().hasPrefix(prefix) {
            let expression = String(value.dropFirst(prefix.count)).trimmingCharacters(in: CharacterSet(charactersIn: " ?=\n"))
            return expression.isEmpty ? nil : expression
        }
        return nil
    }
    static func evaluate(_ text: String) throws -> Double {
        guard !text.isEmpty, text.count <= 160 else { throw MathError.invalid }
        var parser = Parser(chars: Array(text.replacingOccurrences(of: ",", with: ".").filter { !$0.isWhitespace }))
        let value = try parser.sum()
        guard parser.index == parser.chars.count, value.isFinite else { throw MathError.invalid }
        return value
    }
    static func report(_ expression: String) throws -> String {
        let value = try evaluate(expression)
        return "\(expression) = \(String(format: "%.12g", locale: Locale(identifier: "en_US_POSIX"), value))\nCalcolo locale, senza modello AI. Precisione numerica finita; usa parentesi esplicite."
    }
    private struct Parser {
        let chars: [Character]
        var index = 0
        mutating func take(_ char: Character) -> Bool {
            guard index < chars.count, chars[index] == char else { return false }
            index += 1; return true
        }
        mutating func sum() throws -> Double {
            var value = try product()
            while index < chars.count {
                if take("+") { value += try product() }
                else if take("-") { value -= try product() }
                else { break }
            }
            return value
        }
        mutating func product() throws -> Double {
            var value = try unary()
            while index < chars.count {
                if take("*") || take("×") { value *= try unary() }
                else if take("/") || take("÷") {
                    let divisor = try unary(); guard divisor != 0 else { throw MathError.zero }
                    value /= divisor
                } else { break }
            }
            return value
        }
        mutating func unary() throws -> Double {
            if take("+") { return try unary() }
            if take("-") { return -(try unary()) }
            return try power()
        }
        mutating func power() throws -> Double {
            let value = try atom()
            if take("^") { return pow(value, try unary()) }
            return value
        }
        mutating func atom() throws -> Double {
            if take("(") {
                let value = try sum(); guard take(")") else { throw MathError.invalid }; return value
            }
            let start = index
            while index < chars.count, "0123456789.".contains(chars[index]) { index += 1 }
            guard index > start, let value = Double(String(chars[start..<index])), value.isFinite else { throw MathError.invalid }
            return value
        }
    }
    enum MathError: LocalizedError, Equatable {
        case invalid, zero
        var errorDescription: String? {
            self == .zero ? "Non posso dividere per zero." : "Scrivi un’espressione numerica: +, -, *, /, ^ e parentesi. Esempio: /calcola 10000*(1+0,06)^30. Massimo 160 caratteri."
        }
    }
}
