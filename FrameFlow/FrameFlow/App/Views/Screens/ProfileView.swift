//
//  ProfileView.swift
//  FrameFlow
//

import Supabase
import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    avatarView
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Account") {
                TextField("Display name", text: $viewModel.displayName)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save") {
                        Task { await viewModel.saveDisplayName(appState: appState) }
                    }
                    .disabled(viewModel.isSaving)

                    if viewModel.isSaving {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                LabeledContent("Email") {
                    Text(appState.currentUser?.email ?? "—")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Subscription") {
                HStack {
                    Text("Plan")
                    Spacer()
                    subscriptionBadge
                }

                if appState.isPro {
                    LabeledContent("Renews") {
                        Text("—")
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Manage Subscription") {
                    router.navigate(to: .subscription)
                }
            }

            Section("Security") {
                Button("Change Password") {
                    Task {
                        await viewModel.sendPasswordReset(email: appState.currentUser?.email)
                    }
                }
                .disabled(viewModel.isSendingPasswordReset)

                if viewModel.isSendingPasswordReset {
                    ProgressView("Sending reset email…")
                }
            }

            Section {
                Button("Log Out", role: .destructive) {
                    Task {
                        await appState.signOut()
                        router.navigate(to: .login)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Profile")
        .onAppear {
            viewModel.syncDisplayName(from: appState.currentUser)
        }
        .onChange(of: appState.currentUser?.id) { _, _ in
            viewModel.syncDisplayName(from: appState.currentUser)
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var avatarView: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.2))
            .frame(width: 72, height: 72)
            .overlay {
                Text(UserDisplayHelpers.initials(for: appState.currentUser))
                    .font(.title2)
                    .fontWeight(.semibold)
            }
    }

    @ViewBuilder
    private var subscriptionBadge: some View {
        if appState.isPro {
            Text("Pro")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.15), in: Capsule())
        } else {
            Text("Free")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.15), in: Capsule())
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
        .environment(AppRouter())
        .frame(width: 520, height: 640)
}
