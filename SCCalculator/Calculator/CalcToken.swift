import Foundation

/// One key press in the expression. The expression is a list of these,
/// so editing and parsing never has to guess what a piece of text meant.
enum CalcToken: Hashable {
    case digit(String)            // "0"..."9" or "."
    case binary(BinaryOp)
    case function(CalcFunction)   // also opens a parenthesis, e.g. "sin("
    case open
    case close
    case constant(CalcConstant)
    case postfix(PostfixOp)

    var text: String {
        switch self {
        case .digit(let d): return d
        case .binary(let op): return op.display
        case .function(let f): return f.display + "("
        case .open: return "("
        case .close: return ")"
        case .constant(let c): return c.rawValue
        case .postfix(let p): return p.rawValue
        }
    }

    var isDigit: Bool {
        if case .digit = self { return true }
        return false
    }
}

enum BinaryOp: String, Hashable {
    case add = "+", subtract = "−", multiply = "×", divide = "÷"
    case power = "^", root = "ˣ√", exp10 = "E"

    var display: String {
        switch self {
        case .add, .subtract, .multiply, .divide: return " \(rawValue) "
        default: return rawValue
        }
    }
}

enum CalcFunction: String, Hashable {
    case sin, cos, tan
    case asin = "sin⁻¹", acos = "cos⁻¹", atan = "tan⁻¹"
    case ln, log
    case sqrt = "√", cbrt = "∛"
    case exp = "e^", pow10 = "10^"

    var display: String { rawValue }
}

enum CalcConstant: String, Hashable {
    case pi = "π", e = "e", ans = "Ans"
}

enum PostfixOp: String, Hashable {
    case square = "²", cube = "³", factorial = "!", percent = "%", reciprocal = "⁻¹"
}

enum AngleMode: String {
    case degrees = "DEG", radians = "RAD"
}
