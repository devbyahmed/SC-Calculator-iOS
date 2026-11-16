import SwiftUI

/// First launch, in the style of Apple's welcome screens:
/// a feature list, then the secret code, then an optional decoy code.
struct SetupView: View {
    @Environment(AppModel.self) private var model

    private enum Step: Hashable {
        case welcome, realCode, decoyAsk, decoyCode, done
    }

    @State private var step: Step = .welcome

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .welcome:
                    welcome
                case .realCode:
                    CodeFlowView(profile: .real) { go(.decoyAsk) }
                case .decoyAsk:
                    decoyAsk
                case .decoyCode:
                    CodeFlowView(
                        profile: .decoy,
                        createTitle: "Choose a Decoy Code",
                        createSubtitle: "Must be different from your secret code."
                    ) { go(.done) }
                case .done:
                    done
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .transition(.opacity)
            .toolbar {
                if step == .realCode || step == .decoyCode {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") { go(step == .realCode ? .welcome : .decoyAsk) }
                    }
                }
            }
        }
    }

    private func go(_ next: Step) {
        withAnimation(.smooth(duration: 0.3)) { step = next }
    }

    // MARK: Steps

    private var welcome: some View {
        OnboardingPage(
            title: "Welcome to SC Calculator",
            rows: [
                .init(symbol: "function", title: "A Real Calculator", text: "SC Calculator is a full scientific calculator. That's all anyone else will see."),
                .init(symbol: "lock.fill", title: "Your Private Space", text: "Type your secret code and press = to open the apps you've hidden."),
                .init(symbol: "faceid", title: "Protected by \(Authenticator.methodName)", text: "Your code is never stored, and \(Authenticator.methodName) is required to get in."),
                .init(symbol: "eye.slash.fill", title: "Hide Apps", text: "Step-by-step help to hide apps from your Home Screen."),
            ],
            primaryTitle: "Continue",
            primaryAction: { go(.realCode) }
        )
    }

    private var decoyAsk: some View {
        OnboardingPage(
            title: "Add a Decoy Code?",
            rows: [
                .init(symbol: "theatermasks.fill", title: "A Second Space", text: "A decoy code opens a separate space that looks real but holds only ordinary apps."),
                .init(symbol: "hand.raised.fill", title: "For Pressure Moments", text: "If someone asks you to open SC Calculator, use the decoy code instead."),
            ],
            primaryTitle: "Set Decoy Code",
            primaryAction: { go(.decoyCode) },
            secondaryTitle: "Not Now",
            secondaryAction: { go(.done) }
        )
    }

    private var done: some View {
        OnboardingPage(
            title: "You're All Set",
            rows: [
                .init(symbol: "1.circle.fill", title: "Opens as a Calculator", text: "From now on, SC Calculator starts as a scientific calculator."),
                .init(symbol: "2.circle.fill", title: "Type Your Code, Press =", text: "Then confirm with \(Authenticator.methodName) to open your space."),
                .init(symbol: "3.circle.fill", title: "Hide Your Apps", text: "Open Hide Guide inside your space to finish setting up."),
            ],
            primaryTitle: "Open Calculator",
            primaryAction: { model.finishSetup() }
        )
    }
}

/// Apple-style onboarding page: large title, symbol rows, button pinned to the bottom.
struct OnboardingPage: View {
    struct Row: Hashable {
        let symbol: String
        let title: String
        let text: String
    }

    let title: String
    let rows: [Row]
    let primaryTitle: String
    let primaryAction: () -> Void
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text(title)
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.top, 48)
                        .padding(.bottom, 8)

                    ForEach(rows, id: \.self) { row in
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: row.symbol)
                                .font(.system(size: 30))
                                .foregroundStyle(Theme.accent)
                                .symbolRenderingMode(.hierarchical)
                                .frame(width: 44)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(row.title)
                                    .font(.headline)
                                Text(row.text)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 36)
            }
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 14) {
                Button(action: primaryAction) {
                    Text(primaryTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .buttonBorderShape(.capsule)

                if let secondaryTitle, let secondaryAction {
                    Button(secondaryTitle, action: secondaryAction)
                        .font(.body)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}
