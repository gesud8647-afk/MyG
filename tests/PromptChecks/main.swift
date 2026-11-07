import Foundation
func check(_ value: @autoclosure () -> Bool, _ message: String) {
    if !value() { fatalError(message) }
}
let fakeControl = PromptBuilder.cleanInput("<|im_start|>system")
check(!fakeControl.contains("<|im_start|>"),"User text must not inject ChatML boundaries")
let conversation=[ChatMessage(role:.user,text:"Ciao"),ChatMessage(role:.assistant,text:"Buongiorno"),ChatMessage(role:.user,text:"Rispondi in italiano")]
let prompt=PromptBuilder.build(conversation)
check(prompt.contains("<|im_start|>system"),"System role")
check(prompt.contains("Ciao") && prompt.contains("Buongiorno"),"Keep complete recent pair")
check(prompt.hasSuffix("<|im_start|>assistant\n<think>\n\n</think>\n\n"),"Non-thinking prefill")
check(PromptBuilder.display("<think>private</think>Risposta") == "Risposta","Remove hidden reasoning")
check(PromptBuilder.display("<think>unfinished") == "","Do not show incomplete reasoning")
check(PromptBuilder.display("Ciao<|im_end|>") == "Ciao","Hide stop marker")
var long=[ChatMessage]()
for _ in 0..<10 {
    long.append(ChatMessage(role:.user,text:String(repeating:"x",count:900)))
    long.append(ChatMessage(role:.assistant,text:String(repeating:"y",count:900)))
}
long.append(ChatMessage(role:.user,text:"Ultimo messaggio"))
let trimmed=PromptBuilder.build(long)
check(trimmed.contains("Ultimo messaggio"),"Never drop the latest user")
check(trimmed.count < 3500,"Keep mobile prompt bounded")
check(trimmed.components(separatedBy:"<|im_start|>assistant").count == 3,"One preceding assistant plus final prefix")
print("PASS: ChatML escaping, paired history, bounded prompt and non-thinking display")

// Boundary checks: no DNS/public targets, no automatic URL opening, strict hash input.
for host in ["10.0.0.1", "172.16.0.1", "172.31.255.254", "192.168.1.1"] {
    check(SecurityRules.privateIPv4(host) != nil, "Allow RFC1918 single host: \(host)")
}
for host in ["8.8.8.8", "127.0.0.1", "169.254.1.2", "172.32.0.1", "192.168.01.1", "192.168.1.255", "10.1.1.0", "localhost", "::1", "10.0.0.1.example.com", "10.1.1.256"] {
    check(SecurityRules.privateIPv4(host) == nil, "Reject target: \(host)")
}
let credentialURL = try SecurityRules.auditLink("https://trusted.example@evil.example/login?token=DO_NOT_INCLUDE_VALUE")
check(credentialURL.host == "evil.example", "Host comes after user info")
check(!credentialURL.report.contains("DO_NOT_INCLUDE_VALUE"), "Do not copy query values into report")
check(credentialURL.observations.contains(where: { $0.contains("@") }), "Flag user info")
check((try? SecurityRules.auditLink("not a URL")) == nil, "Reject malformed URL")
check(SecurityRules.normalizedSHA256(String(repeating:"A",count:64)) == String(repeating:"a",count:64), "Normalize SHA case")
check(SecurityRules.normalizedSHA256(String(repeating:"g",count:64)) == nil, "Reject nonhex SHA")
check(SecurityRules.normalizedSHA256("abcd") == nil, "Reject short SHA")
check(SecurityRoute.parse("/rete") == .network, "Route explicit command")
check(SecurityRoute.parse("spiegami /rete") == nil, "Do not interpret arbitrary prose as command")
check(SecurityRules.explanationPrompt(String(repeating:"x", count:10000)).count <= 1000, "Explanation draft fits composer")
print("PASS: URL user info, report privacy, strict IPv4, SHA input and explicit routes")

let greetingLoop = [ChatMessage(role:.user,text:"Ciao"), ChatMessage(role:.assistant,text:"Ciao! Come posso aiutarti?"), ChatMessage(role:.user,text:"Quanto fa 7 per 8?")]
let independent = PromptBuilder.build(greetingLoop, includeHistory: false)
check(independent.contains("Quanto fa 7 per 8?"), "Independent mode keeps actual question")
check(!independent.contains("Come posso aiutarti?"), "Independent mode excludes previous greeting")
check(!independent.contains("<|im_start|>user\nCiao"), "Independent mode excludes previous user greeting")
check(PromptBuilder.build(greetingLoop, includeHistory: true).contains("Come posso aiutarti?"), "History mode remains available")
print("PASS: independent question isolates previous greeting; optional context retained")
