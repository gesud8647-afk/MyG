import SwiftUI

@main
struct PocketAIApp: App {
    var body: some Scene {
        WindowGroup { PocketRootView().preferredColorScheme(.dark) }
    }
}

struct PocketRootView: View {
    @StateObject private var chat = ChatModel()
    @StateObject private var browser = PocketBrowser()
    @State private var selected = 0
    @State private var path: [SecurityRoute] = []
    var body: some View {
        TabView(selection: $selected) {
            PocketView(chat: chat, routeCommand: route)
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }.tag(0)
            SecurityHub(path: $path, explain: prepareExplanation)
                .tabItem { Label("Sicurezza", systemImage: "shield.lefthalf.filled") }.tag(1)
            BrowserView(browser: browser, attach: { source in
                guard !chat.busy else { browser.error = "Attendi il termine della risposta prima di allegare una fonte."; return }
                chat.pendingSource = source; selected = 0
            }).tabItem { Label("Web", systemImage: "globe") }.tag(2)
            AssistantActions().tabItem { Label("Azioni", systemImage: "bolt.fill") }.tag(3)
        }.tint(.mint)
    }
    private func route(_ text: String) -> Bool {
        if AssistantActions.recognizes(text) { chat.draft = ""; selected = 3; return true }
        if let query = OnlineTools.browserQuery(text) {
            browser.open(query); chat.draft = ""; selected = 2; return true
        }
        guard let destination = SecurityRoute.parse(text) else { return false }
        chat.draft = ""; path = [destination]; selected = 1
        return true
    }
    private func prepareExplanation(_ text: String) {
        if chat.busy { chat.error = "Attendi il termine dell’operazione o interrompi Qwen prima di preparare la spiegazione." }
        else { chat.draft = text }
        selected = 0
    }
}
