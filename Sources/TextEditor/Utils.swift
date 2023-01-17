import Foundation

func clamp(_ value: Int, from: Int = 0, to: Int) -> Int {
    return max(min(value, to), from)
}
