import SwiftUI

/// Code entry modeled on the iOS passcode screen: outlined dots, round keys, "Delete" in the corner.
struct PinEntryView: View {
    let title: String
    let subtitle: String
    var errorText: String?
    /// Increase this to clear the entry and shake (e.g. after a wrong code).
    var errorToken = 0
    var buttonTitle = "Continue"
    var onComplete: (String) -> Void

    @State private var code = ""
    @State private var shake = 0

    private let maxLength = 8
    private let minLength = 4

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(errorText ?? subtitle)
                    .font(.subheadline)
                    .foregroundStyle(errorText == nil ? Color.secondary : Color.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            dots
                .padding(.top, 28)
                .modifier(ShakeEffect(shakes: CGFloat(shake)))

            Spacer(minLength: 24)

            keypad

            Spacer(minLength: 24)

            Button {
                onComplete(code)
            } label: {
                Text(buttonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .buttonBorderShape(.capsule)
            .disabled(code.count < minLength)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .padding(.top, 24)
        .onChange(of: errorToken) { _, _ in
            code = ""
            withAnimation(.default) { shake += 1 }
        }
        .sensoryFeedback(.selection, trigger: code)
        .sensoryFeedback(.error, trigger: errorToken)
    }

    private var dots: some View {
        HStack(spacing: 18) {
            ForEach(0..<max(minLength, min(maxLength, code.count + 1)), id: \.self) { index in
                Circle()
                    .strokeBorder(Color.primary, lineWidth: 1.2)
                    .background(Circle().fill(index < code.count ? Color.primary : Color.clear))
                    .frame(width: 13, height: 13)
            }
        }
        .animation(.snappy(duration: 0.2), value: code.count)
    }

    private var keypad: some View {
        let rows = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "⌫"]]
        return VStack(spacing: 16) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 26) {
                    ForEach(row, id: \.self) { key in
                        keyView(key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyView(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: 78, height: 78)
        } else if key == "⌫" {
            Button("Delete") {
                if !code.isEmpty { code.removeLast() }
            }
            .font(.body)
            .foregroundStyle(.primary)
            .frame(width: 78, height: 78)
            .opacity(code.isEmpty ? 0 : 1)
        } else {
            Button {
                if code.count < maxLength { code += key }
            } label: {
                Text(key)
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(.primary)
                    .frame(width: 78, height: 78)
                    .background(Theme.secondaryFill, in: Circle())
            }
            .buttonStyle(PasscodeKeyStyle())
        }
    }
}

private struct PasscodeKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? 0.3 : 0)
            .animation(.easeOut(duration: configuration.isPressed ? 0.02 : 0.3), value: configuration.isPressed)
    }
}

/// Horizontal shake used when a code is wrong.
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(shakes * .pi * 4), y: 0))
    }
}
