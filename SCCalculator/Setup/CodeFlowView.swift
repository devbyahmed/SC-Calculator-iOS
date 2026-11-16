import SwiftUI

/// Choose a code, confirm it, and save it for a profile.
/// Used by first-run setup and by Settings ("Change code", "Decoy code").
struct CodeFlowView: View {
    let profile: Profile
    var createTitle = "Choose a Secret Code"
    var createSubtitle = "4–8 digits. You'll type it on the calculator, then press =."
    var onSaved: () -> Void

    @State private var firstEntry: String?
    @State private var errorText: String?
    @State private var errorToken = 0

    var body: some View {
        Group {
            if let first = firstEntry {
                PinEntryView(
                    title: "Confirm Your Code",
                    subtitle: "Type the same code again.",
                    errorText: errorText,
                    errorToken: errorToken,
                    buttonTitle: "Save Code"
                ) { second in
                    if second == first {
                        SecretStore.shared.setCode(second, for: profile)
                        onSaved()
                    } else {
                        errorText = "Codes didn't match. Start again."
                        firstEntry = nil
                    }
                }
                .id("confirm")
            } else {
                PinEntryView(
                    title: createTitle,
                    subtitle: createSubtitle,
                    errorText: errorText,
                    errorToken: errorToken
                ) { code in
                    if let owner = SecretStore.shared.match(code), owner != profile {
                        errorText = "That code is already used. Pick another one."
                        errorToken += 1
                    } else {
                        errorText = nil
                        firstEntry = code
                    }
                }
                .id("create")
            }
        }
        .transition(.push(from: .trailing))
        .animation(.easeInOut(duration: 0.25), value: firstEntry)
    }
}
