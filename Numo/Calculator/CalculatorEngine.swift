import Foundation
import Observation

/// A scientific calculator that works on whole expressions, like a desk calculator:
/// type "2 × sin(30) + π", press "=", and the result becomes "Ans".
/// Pressing "=" on a plain number (e.g. "2580") also hands that number back so it can be
/// checked against the secret codes.
@Observable
final class CalculatorEngine {
    struct HistoryEntry: Identifiable, Hashable {
        let id = UUID()
        let expression: String
        let result: String
    }

    private(set) var tokens: [CalcToken] = []
    private(set) var resultText = "0"
    private(set) var isShowingResult = false
    private(set) var history: [HistoryEntry] = []
    var angle: AngleMode = .degrees
    var isSecond = false

    private var ans: Double = 0
    private let maxTokens = 80

    // MARK: Display

    var expressionText: String {
        tokens.map(\.text).joined().trimmingCharacters(in: .whitespaces)
    }

    /// Live answer shown under the expression while typing (nil if it isn't complete yet).
    var preview: String? {
        guard !isShowingResult, tokens.contains(where: { !$0.isDigit }) else { return nil }
        var evaluator = ExpressionEvaluator(angle: angle, ans: ans)
        guard let value = try? evaluator.evaluate(tokens) else { return nil }
        return Self.format(value)
    }

    // MARK: Input

    func input(_ token: CalcToken) {
        if isShowingResult {
            isShowingResult = false
            switch token {
            case .binary, .postfix:
                // Carry on from the last answer: "Ans × 2".
                tokens = [.constant(.ans)]
            default:
                tokens = []
            }
        }
        guard tokens.count < maxTokens else { return }
        tokens.append(token)
        isSecond = false
    }

    func backspace() {
        if isShowingResult {
            isShowingResult = false
            return
        }
        if !tokens.isEmpty { tokens.removeLast() }
    }

    func clear() {
        tokens = []
        resultText = "0"
        isShowingResult = false
        isSecond = false
    }

    func toggleAngle() {
        angle = angle == .degrees ? .radians : .degrees
    }

    /// Evaluates the expression. Returns the typed digits if the expression was a plain
    /// whole number of 4–8 digits (a possible secret code); otherwise nil.
    func equals() -> String? {
        guard !tokens.isEmpty, !isShowingResult else { return nil }

        let isPlainNumber = tokens.allSatisfy { $0.isDigit && $0 != .digit(".") }
        let code = isPlainNumber && (4...8).contains(tokens.count)
            ? tokens.map(\.text).joined()
            : nil

        var evaluator = ExpressionEvaluator(angle: angle, ans: ans)
        do {
            let value = try evaluator.evaluate(tokens)
            ans = value
            resultText = Self.format(value)
            // Plain numbers aren't calculations, and must never leave a code in the history.
            if !isPlainNumber {
                history.insert(HistoryEntry(expression: expressionText, result: resultText), at: 0)
                if history.count > 50 { history.removeLast() }
            }
        } catch ExpressionEvaluator.EvalError.math {
            resultText = "Math Error"
        } catch {
            resultText = "Syntax Error"
        }
        isShowingResult = true
        isSecond = false
        return code
    }

    /// Puts a past result back into the expression.
    func reuse(_ entry: HistoryEntry) {
        if isShowingResult { tokens = []; isShowingResult = false }
        let digits = entry.result.replacingOccurrences(of: ",", with: "")
        guard !digits.contains("e"), !digits.contains("Error") else { return }
        for char in digits {
            if char == "-" {
                tokens.append(.binary(.subtract))
            } else {
                tokens.append(.digit(String(char)))
            }
        }
    }

    func clearHistory() {
        history.removeAll()
    }

    // MARK: Formatting

    /// Up to 12 significant digits with thousands separators; scientific notation when huge or tiny.
    static func format(_ value: Double) -> String {
        if value == 0 { return "0" }
        let plain = String(format: "%.12g", value)
        // %g switches to exponent form below 1e-4 or from 1e12 up.
        guard plain.contains("e") else { return grouped(plain) }
        let parts = String(format: "%.6e", value).split(separator: "e")
        var mantissa = String(parts[0])
        while mantissa.contains(".") && (mantissa.hasSuffix("0") || mantissa.hasSuffix(".")) {
            mantissa.removeLast()
        }
        let exponent = Int(parts[1]) ?? 0
        return "\(mantissa)e\(exponent)"
    }

    /// 1234567.5 -> 1,234,567.5
    static func grouped(_ raw: String) -> String {
        var body = raw
        var sign = ""
        if body.hasPrefix("-") {
            sign = "-"
            body.removeFirst()
        }
        let parts = body.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integer = String(parts.first ?? "0")
        var out = ""
        for (index, char) in integer.reversed().enumerated() {
            if index > 0 && index % 3 == 0 { out.append(",") }
            out.append(char)
        }
        var result = sign + String(out.reversed())
        if parts.count > 1 { result += "." + parts[1] }
        return result
    }
}
