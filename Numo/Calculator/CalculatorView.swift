import SwiftUI

/// The disguise: a full scientific calculator that evaluates whole expressions.
/// Typing a secret code and pressing "=" calls `onCode`.
struct CalculatorView: View {
    var onCode: (String) -> Void

    @State private var engine = CalculatorEngine()
    @State private var showHistory = false
    @State private var tapCount = 0

    private enum Key: Hashable {
        case second, angle
        case trig(CalcFunction, CalcFunction)
        case square, power, root, ln, log
        case open, close, percent, factorial, pi
        case digit(String)
        case backspace, clear
        case op(BinaryOp)
        case exp10, ans, equals
    }

    private enum Kind {
        case function, number, operation, destructive, equals, toggle
    }

    private let functionRows: [[Key]] = [
        [.second, .angle, .trig(.sin, .asin), .trig(.cos, .acos), .trig(.tan, .atan)],
        [.square, .power, .root, .ln, .log],
        [.open, .close, .percent, .factorial, .pi],
    ]

    private let mainRows: [[Key]] = [
        [.digit("7"), .digit("8"), .digit("9"), .backspace, .clear],
        [.digit("4"), .digit("5"), .digit("6"), .op(.multiply), .op(.divide)],
        [.digit("1"), .digit("2"), .digit("3"), .op(.add), .op(.subtract)],
        [.digit("0"), .digit("."), .exp10, .ans, .equals],
    ]

    private let spacing: CGFloat = 9

    var body: some View {
        GeometryReader { geo in
            let keyWidth = (geo.size.width - 32 - spacing * 4) / 5
            let mainHeight = min(keyWidth * 0.84, 64)
            VStack(spacing: 0) {
                topBar
                display
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 18)
                VStack(spacing: spacing) {
                    ForEach(functionRows, id: \.self) { row in
                        keyRow(row, height: 40)
                    }
                    Color.clear.frame(height: 4)
                    ForEach(mainRows, id: \.self) { row in
                        keyRow(row, height: mainHeight)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .background(Color.black.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: tapCount)
        .sheet(isPresented: $showHistory) {
            HistorySheet(engine: engine)
        }
    }

    // MARK: Top bar and display

    private var topBar: some View {
        HStack {
            Button { showHistory = true } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Theme.secondaryFill, in: Circle())
            }
            .accessibilityLabel("History")

            Spacer()

            HStack(spacing: 6) {
                indicator(engine.angle.rawValue, isOn: true)
                indicator("2nd", isOn: engine.isSecond)
            }

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.top, 4)
    }

    private func indicator(_ text: String, isOn: Bool) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(isOn ? Color.white.opacity(0.85) : Color.white.opacity(0.25))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.fill, in: Capsule())
    }

    private var display: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(engine.expressionText.isEmpty ? " " : engine.expressionText)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(engine.isShowingResult ? Color.secondary : Color.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.trailing)

            Group {
                if engine.isShowingResult || engine.tokens.isEmpty {
                    Text(engine.resultText)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.white)
                } else {
                    Text(engine.preview ?? " ")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.secondary)
                }
            }
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.2), value: engine.resultText)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 24).onEnded { value in
                if abs(value.translation.width) > 40 {
                    tapCount += 1
                    engine.backspace()
                }
            }
        )
    }

    // MARK: Keys

    private func keyRow(_ row: [Key], height: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(row, id: \.self) { key in
                keyButton(key, height: height)
            }
        }
    }

    private func keyButton(_ key: Key, height: CGFloat) -> some View {
        let kind = self.kind(of: key)
        let (background, foreground) = colors(for: kind)
        return Button {
            tapCount += 1
            press(key)
        } label: {
            label(for: key, kind: kind, color: foreground)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(background, in: RoundedRectangle(cornerRadius: min(height * 0.36, 18), style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(KeyPressStyle())
    }

    @ViewBuilder
    private func label(for key: Key, kind: Kind, color: Color) -> some View {
        if key == .backspace {
            Image(systemName: "delete.left")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(color)
        } else {
            let pair = self.titles(for: key)
            let showAlternate = engine.isSecond && pair.1 != nil
            Text(showAlternate ? (pair.1 ?? pair.0) : pair.0)
                .font(font(for: kind))
                .foregroundStyle(showAlternate ? Theme.accent : color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func titles(for key: Key) -> (String, String?) {
        switch key {
        case .second: return ("2nd", nil)
        case .angle: return (engine.angle == .degrees ? "Deg" : "Rad", nil)
        case .trig(let normal, let inverse): return (normal.rawValue, inverse.rawValue)
        case .square: return ("x²", "x³")
        case .power: return ("xʸ", "ʸ√x")
        case .root: return ("√x", "∛x")
        case .ln: return ("ln", "eˣ")
        case .log: return ("log", "10ˣ")
        case .open: return ("(", nil)
        case .close: return (")", nil)
        case .percent: return ("%", nil)
        case .factorial: return ("x!", "1/x")
        case .pi: return ("π", "e")
        case .digit(let d): return (d, nil)
        case .backspace: return ("", nil)
        case .clear: return ("AC", nil)
        case .op(let op): return (op.rawValue, nil)
        case .exp10: return ("EE", nil)
        case .ans: return ("Ans", nil)
        case .equals: return ("=", nil)
        }
    }

    private func kind(of key: Key) -> Kind {
        switch key {
        case .second: return engine.isSecond ? .toggle : .function
        case .digit: return .number
        case .op: return .operation
        case .clear, .backspace: return .destructive
        case .equals: return .equals
        case .exp10, .ans: return .number
        default: return .function
        }
    }

    private func colors(for kind: Kind) -> (Color, Color) {
        switch kind {
        case .function: return (Color(white: 0.11), Color.white.opacity(0.88))
        case .number: return (Color(white: 0.2), .white)
        case .operation: return (Theme.accent.opacity(0.28), Color(red: 0.72, green: 0.71, blue: 1.0))
        case .destructive: return (Color(white: 0.2), Color(red: 1.0, green: 0.55, blue: 0.5))
        case .equals: return (Theme.accent, .white)
        case .toggle: return (Theme.accent, .white)
        }
    }

    private func font(for kind: Kind) -> Font {
        switch kind {
        case .function, .toggle: return .system(size: 16, weight: .medium)
        case .number: return .system(size: 26, weight: .regular)
        case .operation: return .system(size: 26, weight: .medium)
        case .destructive: return .system(size: 19, weight: .semibold)
        case .equals: return .system(size: 30, weight: .medium)
        }
    }

    private func press(_ key: Key) {
        let second = engine.isSecond
        switch key {
        case .second: engine.isSecond.toggle()
        case .angle: engine.toggleAngle()
        case .trig(let normal, let inverse): engine.input(.function(second ? inverse : normal))
        case .square: engine.input(.postfix(second ? .cube : .square))
        case .power: engine.input(.binary(second ? .root : .power))
        case .root: engine.input(.function(second ? .cbrt : .sqrt))
        case .ln: engine.input(.function(second ? .exp : .ln))
        case .log: engine.input(.function(second ? .pow10 : .log))
        case .open: engine.input(.open)
        case .close: engine.input(.close)
        case .percent: engine.input(.postfix(.percent))
        case .factorial: engine.input(.postfix(second ? .reciprocal : .factorial))
        case .pi: engine.input(.constant(second ? .e : .pi))
        case .digit(let d): engine.input(.digit(d))
        case .backspace: engine.backspace()
        case .clear: engine.clear()
        case .op(let op): engine.input(.binary(op))
        case .exp10: engine.input(.binary(.exp10))
        case .ans: engine.input(.constant(.ans))
        case .equals:
            if let code = engine.equals() { onCode(code) }
        }
    }
}

private struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .animation(.easeOut(duration: configuration.isPressed ? 0.02 : 0.25), value: configuration.isPressed)
    }
}

/// Past calculations. Tap one to reuse its result.
private struct HistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let engine: CalculatorEngine

    var body: some View {
        NavigationStack {
            List {
                ForEach(engine.history) { entry in
                    Button {
                        engine.reuse(entry)
                        dismiss()
                    } label: {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(entry.expression)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(entry.result)
                                .font(.title2)
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .overlay {
                if engine.history.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("Your calculations will appear here.")
                    )
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear", role: .destructive) { engine.clearHistory() }
                        .disabled(engine.history.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    CalculatorView { _ in }
        .preferredColorScheme(.dark)
}
