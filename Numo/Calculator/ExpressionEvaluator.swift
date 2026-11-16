import Foundation

/// Evaluates a token list with normal maths rules:
/// brackets, powers (right to left), ×/÷ before +/−, implicit multiplication (2π, 3sin(30)),
/// unary minus (−2² = −4), and auto-closing of any brackets left open.
struct ExpressionEvaluator {
    enum EvalError: Error { case syntax, math }

    private enum Lexeme {
        case number(Double)
        case binary(BinaryOp)
        case function(CalcFunction)
        case open, close
        case constant(CalcConstant)
        case postfix(PostfixOp)
        case end
    }

    private var lexemes: [Lexeme] = []
    private var index = 0
    private let angle: AngleMode
    private let ans: Double

    init(angle: AngleMode, ans: Double) {
        self.angle = angle
        self.ans = ans
    }

    mutating func evaluate(_ tokens: [CalcToken]) throws -> Double {
        lexemes = try Self.lex(tokens)
        index = 0
        guard !lexemes.isEmpty else { throw EvalError.syntax }
        let value = try parseExpression()
        guard case .end = peek else { throw EvalError.syntax }
        guard value.isFinite else { throw EvalError.math }
        return value
    }

    // MARK: Lexing

    private static func lex(_ tokens: [CalcToken]) throws -> [Lexeme] {
        var out: [Lexeme] = []
        var buffer = ""

        func flush() throws {
            guard !buffer.isEmpty else { return }
            guard buffer.filter({ $0 == "." }).count <= 1 else { throw EvalError.syntax }
            var text = buffer
            if text.hasPrefix(".") { text = "0" + text }
            if text.hasSuffix(".") { text += "0" }
            guard let value = Double(text) else { throw EvalError.syntax }
            out.append(.number(value))
            buffer = ""
        }

        for token in tokens {
            if case .digit(let d) = token {
                buffer += d
                continue
            }
            try flush()
            switch token {
            case .digit: break
            case .binary(let op): out.append(.binary(op))
            case .function(let f): out.append(.function(f))
            case .open: out.append(.open)
            case .close: out.append(.close)
            case .constant(let c): out.append(.constant(c))
            case .postfix(let p): out.append(.postfix(p))
            }
        }
        try flush()
        return out
    }

    // MARK: Parsing

    private var peek: Lexeme {
        index < lexemes.count ? lexemes[index] : .end
    }

    private mutating func advance() -> Lexeme {
        let current = peek
        index += 1
        return current
    }

    /// expression := term (("+" | "−") term)*
    private mutating func parseExpression() throws -> Double {
        var value = try parseTerm()
        while true {
            switch peek {
            case .binary(.add):
                index += 1
                value += try parseTerm()
            case .binary(.subtract):
                index += 1
                value -= try parseTerm()
            default:
                return value
            }
        }
    }

    /// term := unary (("×" | "÷") unary | implicit-multiplication unary)*
    private mutating func parseTerm() throws -> Double {
        var value = try parseUnary()
        while true {
            switch peek {
            case .binary(.multiply):
                index += 1
                value *= try parseUnary()
            case .binary(.divide):
                index += 1
                let divisor = try parseUnary()
                guard divisor != 0 else { throw EvalError.math }
                value /= divisor
            case .number, .constant, .open, .function:
                value *= try parseUnary()
            default:
                return value
            }
        }
    }

    /// unary := ("−" | "+") unary | power
    private mutating func parseUnary() throws -> Double {
        switch peek {
        case .binary(.subtract):
            index += 1
            return -(try parseUnary())
        case .binary(.add):
            index += 1
            return try parseUnary()
        default:
            return try parsePower()
        }
    }

    /// power := postfix (("^" | "ˣ√" | "E") unary)?   (right-associative)
    private mutating func parsePower() throws -> Double {
        let base = try parsePostfix()
        switch peek {
        case .binary(.power):
            index += 1
            return pow(base, try parseUnary())
        case .binary(.exp10):
            index += 1
            return base * pow(10, try parseUnary())
        case .binary(.root):
            index += 1
            return try Self.nthRoot(of: try parseUnary(), degree: base)
        default:
            return base
        }
    }

    /// postfix := primary ("²" | "³" | "!" | "%" | "⁻¹")*
    private mutating func parsePostfix() throws -> Double {
        var value = try parsePrimary()
        while case .postfix(let op) = peek {
            index += 1
            value = try apply(op, to: value)
        }
        return value
    }

    /// primary := number | constant | "(" expression ")" | function expression ")"
    private mutating func parsePrimary() throws -> Double {
        switch advance() {
        case .number(let value):
            return value
        case .constant(let constant):
            switch constant {
            case .pi: return .pi
            case .e: return exp(1.0)
            case .ans: return ans
            }
        case .open:
            let value = try parseExpression()
            try closeBracket()
            return value
        case .function(let function):
            let value = try parseExpression()
            try closeBracket()
            return try apply(function, to: value)
        default:
            throw EvalError.syntax
        }
    }

    /// Accepts ")" or the end of input (brackets close themselves at the end).
    private mutating func closeBracket() throws {
        switch peek {
        case .close: index += 1
        case .end: break
        default: throw EvalError.syntax
        }
    }

    // MARK: Maths

    private func apply(_ op: PostfixOp, to x: Double) throws -> Double {
        switch op {
        case .square: return x * x
        case .cube: return x * x * x
        case .percent: return x / 100
        case .reciprocal:
            guard x != 0 else { throw EvalError.math }
            return 1 / x
        case .factorial:
            guard x >= 0, x <= 170 else { throw EvalError.math }
            if x == x.rounded() {
                var result = 1.0
                var n = 2.0
                while n <= x {
                    result *= n
                    n += 1
                }
                return result
            }
            return tgamma(x + 1)
        }
    }

    private func apply(_ function: CalcFunction, to x: Double) throws -> Double {
        let toRadians = angle == .degrees ? Double.pi / 180 : 1
        let fromRadians = angle == .degrees ? 180 / Double.pi : 1
        switch function {
        case .sin: return Self.clean(sin(x * toRadians))
        case .cos: return Self.clean(cos(x * toRadians))
        case .tan:
            if angle == .degrees, (x - 90).truncatingRemainder(dividingBy: 180) == 0 { throw EvalError.math }
            return Self.clean(tan(x * toRadians))
        case .asin:
            guard (-1...1).contains(x) else { throw EvalError.math }
            return asin(x) * fromRadians
        case .acos:
            guard (-1...1).contains(x) else { throw EvalError.math }
            return acos(x) * fromRadians
        case .atan:
            return atan(x) * fromRadians
        case .ln:
            guard x > 0 else { throw EvalError.math }
            return log(x)
        case .log:
            guard x > 0 else { throw EvalError.math }
            return log10(x)
        case .sqrt:
            guard x >= 0 else { throw EvalError.math }
            return x.squareRoot()
        case .cbrt:
            return cbrt(x)
        case .exp:
            return exp(x)
        case .pow10:
            return pow(10, x)
        }
    }

    private static func nthRoot(of x: Double, degree n: Double) throws -> Double {
        guard n != 0 else { throw EvalError.math }
        if x < 0 {
            // Odd whole-number roots of negatives are real: ³√−8 = −2.
            guard n == n.rounded(), Int(n) % 2 != 0 else { throw EvalError.math }
            return -pow(-x, 1 / n)
        }
        return pow(x, 1 / n)
    }

    /// Removes floating-point noise such as sin(180°) = 1.2e-16.
    private static func clean(_ value: Double) -> Double {
        abs(value) < 1e-12 ? 0 : value
    }
}
