import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}
let now = Date(timeIntervalSince1970: 1000)
check(SignalFilter.distance(rssi: -59, reference: -59, exponent: 2) == 1, "Reference must be 1 m")
let near = SignalFilter.distance(rssi: -65, reference: -59, exponent: 2)!
let far = SignalFilter.distance(rssi: -85, reference: -59, exponent: 2)!
check(far > near, "Weaker signal must imply larger model distance")
check(SignalFilter.distance(rssi: .nan, reference: -59, exponent: 2) == nil, "NaN must not produce a circle")
check(SignalFilter.distance(rssi: 127, reference: -59, exponent: 2) == nil, "Unavailable RSSI sentinel must be rejected")
check(SignalFilter.distance(rssi: -60, reference: -59, exponent: 0) == nil, "Zero environment exponent must be rejected")
var filter = SignalFilter()
check(!filter.add(127, at: now), "Invalid read must not create a sample")
check(filter.value == nil, "Invalid read must leave distance unavailable")
check(filter.add(-80, at: now), "Initial read")
check(!filter.add(-20, at: now.addingTimeInterval(0.1)), "Duplicate bursts must not bias smoothing")
check(filter.value == -80, "Ignored burst must not change value")
for i in 1 ... 12 { _ = filter.add(-50, at: now.addingTimeInterval(Double(i))) }
check(filter.trend.contains("forte"), "Sustained stronger reads should show approaching tendency")
_ = filter.add(-90, at: now.addingTimeInterval(40))
check(filter.value == -90 && filter.history.count == 1, "After signal loss, reset historical smoothing")
check(filter.trend.contains("Raccolta"), "Do not compare movement across signal loss")
var stable = SignalFilter()
for i in 0 ... 12 { _ = stable.add(-60, at: now.addingTimeInterval(Double(i))) }
check(stable.trend == "Segnale stabile", "Stable RSSI should not indicate movement")
print("PASS: distance validity, smoothing, burst rejection, trends and stale reset")
