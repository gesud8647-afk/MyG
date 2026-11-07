import SwiftUI
import WebKit

struct BrowserSource: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
    var text: String
    let readAt: Date
}

final class PocketBrowser: NSObject, ObservableObject, WKNavigationDelegate {
    let web: WKWebView
    @Published var address = ""
    @Published var title = "Browser"
    @Published var source: BrowserSource?
    @Published var error: String?
    override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        web = WKWebView(frame: .zero, configuration: config)
        super.init(); web.navigationDelegate = self
    }
    func open(_ input: String) {
        guard let url = OnlineTools.webURL(input) else { error = "Inserisci una ricerca o un URL HTTPS."; return }
        address = input; source = nil; web.load(URLRequest(url: url))
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title ?? "Pagina"; address = webView.url?.absoluteString ?? address
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError failure: Error) { error = failure.localizedDescription }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError failure: Error) { error = failure.localizedDescription }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, OnlineTools.sourceURL(url.absoluteString) != nil else { decisionHandler(.cancel); return }
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request); decisionHandler(.cancel) }
        else { decisionHandler(.allow) }
    }
    func extract() {
        guard let url = web.url, OnlineTools.sourceURL(url.absoluteString) != nil else { error = "Apri prima una pagina HTTPS."; return }
        let title = web.title ?? url.host ?? "Pagina"
        // Selected text preferred; otherwise visible document text. Nothing executes from the page in the model.
        web.evaluateJavaScript("String(window.getSelection()?.toString() || document.body?.innerText || '').slice(0, 8000)") { value, failure in
            guard self.web.url == url else { self.error = "La pagina è cambiata: ripeti la lettura."; return }
            if let failure = failure { self.error = failure.localizedDescription; return }
            guard let text = value as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { self.error = "Testo non leggibile. Alcuni siti bloccano l’estrazione."; return }
            self.source = BrowserSource(title: title, url: url, text: String(text.prefix(1200)), readAt: Date())
        }
    }
}
private struct BrowserSurface: UIViewRepresentable {
    let browser: PocketBrowser
    func makeUIView(context: Context) -> WKWebView { browser.web }
    func updateUIView(_ view: WKWebView, context: Context) {}
}
struct BrowserView: View {
    @ObservedObject var browser: PocketBrowser
    let attach: (BrowserSource) -> Void
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack {
                    TextField("Cerca o incolla URL HTTPS", text: $browser.address).textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                        .onSubmit { browser.open(browser.address) }
                    Button("Vai") { browser.open(browser.address) }.buttonStyle(.borderedProminent)
                }.padding(.horizontal)
                HStack {
                    Button { browser.web.goBack() } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Pagina precedente")
                    Button { browser.web.goForward() } label: { Image(systemName: "chevron.right") }.accessibilityLabel("Pagina successiva")
                    Button { browser.web.reload() } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Ricarica")
                    Spacer()
                    Button("Leggi testo per Qwen") { browser.extract() }.buttonStyle(.bordered)
                }.padding(.horizontal)
                Text("La ricerca va a DuckDuckGo. I siti visitati ricevono le normali richieste del browser. Qwen legge solo l’estratto che confermi.").font(.caption2).foregroundStyle(.secondary).padding(.horizontal)
                BrowserSurface(browser: browser)
            }.navigationTitle("Web").navigationBarTitleDisplayMode(.inline)
                .sheet(item: $browser.source) { source in
                    SourcePreview(source: source) { edited in attach(edited); browser.source = nil }
                }
                .alert("Browser", isPresented: Binding(get: { browser.error != nil }, set: { if !$0 { browser.error = nil } })) {
                    Button("OK") { browser.error = nil }
                } message: { Text(browser.error ?? "") }
        }.tint(.mint)
    }
}
private struct SourcePreview: View {
    let source: BrowserSource
    let attach: (BrowserSource) -> Void
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text(source.title).font(.headline)
                Text(source.url.absoluteString).font(.caption).textSelection(.enabled)
                Text("Rivedi l’estratto, togli dati privati e parti irrilevanti. Massimo 1200 caratteri: seleziona il passaggio nella pagina per scegliere cosa leggere.").font(.footnote)
                TextEditor(text: $text).font(.body).onChange(of: text) { if $0.count > 1200 { text = String($0.prefix(1200)) } }
                Button("Allega alla prossima domanda") {
                    var edited = source; edited.text = text; attach(edited)
                }.buttonStyle(.borderedProminent).disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Text("È una fonte scelta da te, non una verifica indipendente. Il contenuto della pagina può essere errato o malevolo.").font(.caption).foregroundStyle(.secondary)
            }.padding().navigationTitle("Testo per Qwen")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } } }
                .onAppear { text = source.text }
        }
    }
}
