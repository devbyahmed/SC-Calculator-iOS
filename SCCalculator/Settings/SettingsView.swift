import SwiftUI

/// Settings for the current space, laid out like the iOS Settings app.
/// In the decoy space, "Change Code" changes the decoy code, and decoy/erase options are hidden,
/// so nothing hints that a real space exists.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var model
    let store: VaultStore

    @AppStorage(AppModel.requireAuthKey) private var requireAuth = true
    @State private var currentIcon: AppIconChoice = .calculator
    @State private var iconError: String?
    @State private var newGroup = ""
    @State private var confirmErase = false
    @State private var hasDecoy = SecretStore.shared.hasCode(for: .decoy)

    private var isReal: Bool { store.profile == .real }

    var body: some View {
        NavigationStack {
            Form {
                iconSection
                securitySection
                groupsSection
                if isReal { eraseSection }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                currentIcon = AppIconChoice.current
                hasDecoy = SecretStore.shared.hasCode(for: .decoy)
            }
            .confirmationDialog("Erase Everything?", isPresented: $confirmErase, titleVisibility: .visible) {
                Button("Erase Codes, Apps and Groups", role: .destructive) {
                    dismiss()
                    model.eraseEverything()
                }
            } message: {
                Text("This can't be undone. Apps you've hidden stay hidden in iOS.")
            }
        }
    }

    // MARK: Sections

    private var iconSection: some View {
        Section {
            HStack(spacing: 0) {
                ForEach(AppIconChoice.allCases) { choice in
                    Button {
                        Task { await setIcon(choice) }
                    } label: {
                        VStack(spacing: 8) {
                            Image(choice.previewImageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 58, height: 58)
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                                )
                            Text(choice.title)
                                .font(.caption)
                                .foregroundStyle(.primary)
                            Image(systemName: currentIcon == choice ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(currentIcon == choice ? Theme.accent : Color.secondary.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(currentIcon == choice ? .isSelected : [])
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("App Icon")
        } footer: {
            Text(iconError ?? "iOS shows a short notice when the icon changes. The name under the icon stays \"SC Calculator\".")
        }
    }

    private var securitySection: some View {
        Section("Security") {
            Toggle(isOn: $requireAuth) {
                Label {
                    Text("Require \(Authenticator.methodName)")
                } icon: {
                    SettingsIcon(symbol: "faceid", tint: .green)
                }
            }
            NavigationLink {
                CodeScreen(profile: store.profile, title: "New Secret Code") { refreshDecoy() }
            } label: {
                Label {
                    Text("Change Secret Code")
                } icon: {
                    SettingsIcon(symbol: "lock.fill", tint: .gray)
                }
            }
            if isReal {
                NavigationLink {
                    decoyScreen
                } label: {
                    LabeledContent {
                        Text(hasDecoy ? "On" : "Off")
                    } label: {
                        Label {
                            Text("Decoy Code")
                        } icon: {
                            SettingsIcon(symbol: "theatermasks.fill", tint: .orange)
                        }
                    }
                }
            }
        }
    }

    private var groupsSection: some View {
        Section {
            ForEach(store.groups, id: \.self) { group in
                LabeledContent(group, value: "\(store.items(in: group).count)")
            }
            .onDelete { offsets in
                for name in offsets.map({ store.groups[$0] }) { store.removeGroup(name) }
            }
            TextField("Add Group", text: $newGroup)
                .onSubmit(addGroup)
                .submitLabel(.done)
        } header: {
            Text("Groups")
        } footer: {
            Text("Swipe left to delete a group. Its apps stay, without a group.")
        }
    }

    private var eraseSection: some View {
        Section {
            Button("Erase Everything", role: .destructive) { confirmErase = true }
        } footer: {
            Text("SC Calculator \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
        }
    }

    // MARK: Decoy

    private var decoyScreen: some View {
        Form {
            Section {
                NavigationLink(hasDecoy ? "Change Decoy Code" : "Set Up Decoy Code") {
                    CodeScreen(profile: .decoy, title: "Decoy Code") { refreshDecoy() }
                }
                if hasDecoy {
                    Button("Turn Off Decoy Code", role: .destructive) {
                        SecretStore.shared.removeCode(for: .decoy)
                        hasDecoy = false
                    }
                }
            } footer: {
                Text("The decoy code opens a separate space with its own apps. Open it once with the decoy code and add a few ordinary apps so it looks real.")
            }
        }
        .navigationTitle("Decoy Code")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Actions

    private func refreshDecoy() {
        hasDecoy = SecretStore.shared.hasCode(for: .decoy)
    }

    private func addGroup() {
        store.addGroup(newGroup)
        newGroup = ""
    }

    private func setIcon(_ choice: AppIconChoice) async {
        do {
            try await choice.apply()
            currentIcon = choice
            iconError = nil
        } catch {
            iconError = "Couldn't change the icon: \(error.localizedDescription)"
        }
    }
}

/// Pushed screen that runs the choose + confirm flow and pops when saved.
private struct CodeScreen: View {
    @Environment(\.dismiss) private var dismiss
    let profile: Profile
    let title: String
    var onSaved: () -> Void

    var body: some View {
        CodeFlowView(
            profile: profile,
            createTitle: title,
            createSubtitle: "4–8 digits. Type it on the calculator, then press =."
        ) {
            onSaved()
            dismiss()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}
