import Foundation

enum OnlineTools {
    struct PriceRequest: Equatable {
        let symbol: String
        let currency: String
    }
    struct Quote {
        let amount: String
        let request: PriceRequest
        let received: Date
        let url: URL
        var text: String {
            "1 \(request.symbol) = \(amount) \(request.currency)\nFonte: Coinbase Spot. Ricevuto il \(received.formatted(date: .numeric, time: .standard)).\nÈ la quotazione ricevuta dal servizio, non un prezzo garantito di acquisto/vendita. Può cambiare subito."
        }
    }
    static func asksPrice(_ text: String) -> Bool {
        let lower = text.lowercased()
        let tokens = Set(lower.components(separatedBy: CharacterSet.alphanumerics.inverted))
        return lower.hasPrefix("/prezzo ") || lower.contains("quanto vale") || lower.contains("quanto costa") || tokens.contains("prezzo") || tokens.contains("quotazione") || tokens.contains("price")
    }
    static func priceRequest(_ text: String) -> PriceRequest? {
        let lower = text.lowercased()
        let words = lower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        let tokens = Set(words)
        guard asksPrice(text) else { return nil }
        guard tokens.isDisjoint(with: ["gbp", "sterline", "jpy", "yen", "chf", "franchi"]) else { return nil }
        let euros = tokens.contains("eur") || tokens.contains("euro") || text.contains("€")
        let dollars = tokens.contains("usd") || tokens.contains("dollari") || tokens.contains("dollar") || text.contains("$")
        guard !(euros && dollars) else { return nil }
        let known = [("BTC", ["btc", "bitcoin"]), ("ETH", ["eth", "ethereum"]), ("SOL", ["sol", "solana"]), ("AVAX", ["avax", "avalanche"]), ("DOGE", ["doge", "dogecoin"])]
        let matches = known.filter { !$0.1.allSatisfy { !tokens.contains($0) } }
        guard matches.count == 1 else { return nil }
        let usd = tokens.contains("usd") || tokens.contains("dollari") || tokens.contains("dollar") || text.contains("$")
        return PriceRequest(symbol: matches[0].0, currency: usd ? "USD" : "EUR")
    }
    static func browserQuery(_ text: String) -> String? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        for prefix in ["/cerca ", "cerca online ", "cerca su internet "] where value.lowercased().hasPrefix(prefix) {
            let query = String(value.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return query.isEmpty ? nil : query
        }
        return nil
    }
    static func webURL(_ text: String) -> URL? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 2000 else { return nil }
        if let url = URL(string: value), url.scheme?.lowercased() == "https", url.host != nil, url.user == nil, url.password == nil { return url }
        var search = URLComponents(string: "https://duckduckgo.com/")!
        search.queryItems = [URLQueryItem(name: "q", value: value)]
        return search.url
    }
    static func sourceURL(_ text: String?) -> URL? {
        guard let text = text, let url = URL(string: text), url.scheme?.lowercased() == "https", url.host != nil, url.user == nil, url.password == nil else { return nil }
        return url
    }
    static func price(_ value: PriceRequest) async throws -> Quote {
        let url = URL(string: "https://api.coinbase.com/v2/prices/\(value.symbol)-\(value.currency)/spot")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 20
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count < 100_000,
              http.url?.host == "api.coinbase.com" else { throw ToolError.unavailable }
        struct Body: Decodable { struct Price: Decodable { let amount: String; let currency: String; let base: String? }; let data: Price }
        let result = try JSONDecoder().decode(Body.self, from: data).data
        guard result.currency == value.currency, result.base == nil || result.base == value.symbol,
              result.amount.utf8.count < 64, result.amount.allSatisfy({ "0123456789.".contains($0) }),
              let number = Double(result.amount), number.isFinite, number > 0 else { throw ToolError.unavailable }
        return Quote(amount: result.amount, request: value, received: Date(), url: url)
    }
    enum ToolError: LocalizedError {
        case unavailable
        var errorDescription: String? { "Quotazione non disponibile o risposta del servizio non valida. Non verrà inventato un prezzo: riprova tra poco." }
    }
}
