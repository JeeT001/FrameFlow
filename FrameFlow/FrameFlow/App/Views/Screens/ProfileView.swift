//
//  ProfileView.swift
//  FrameFlow
//

import Supabase
import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var viewModel = ProfileViewModel()
    @State private var showManageSubscriptionAlert = false

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
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Section("Subscription") {
                HStack {
                    Text("Plan")
                    Spacer()
                    if appState.isPro {
                        Text(subscriptionManager.planName)
                            .foregroundStyle(AppColors.textSecondary)
                    } else {
                        subscriptionBadge
                    }
                }

                if appState.isPro {
                    LabeledContent("Renews") {
                        if let renewalDate = subscriptionManager.renewalDate {
                            Text(renewalDate, format: .dateTime.month().day().year())
                                .foregroundStyle(AppColors.textSecondary)
                        } else {
                            Text("—")
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }

                Button("Manage Subscription") {
                    Task { await handleManageSubscription() }
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
        .alert("Manage Subscription", isPresented: $showManageSubscriptionAlert) {
            Button("View Plans") {
                router.navigate(to: .subscription)
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(subscriptionManager.lastError ?? "Subscription management is not available in-app.")
        }
    }

    private func handleManageSubscription() async {
        let opened = await subscriptionManager.showManageSubscriptions()
        if !opened {
            showManageSubscriptionAlert = true
        }
    }

    private var avatarView: some View {
        Circle()
            .fill(AppColors.primary.opacity(0.2))
            .frame(width: 72, height: 72)
            .overlay {
                Text(UserDisplayHelpers.initials(for: appState.currentUser))
                    .font(.title2)
                    .fontWeight(.semibold)
            }
    }

    @ViewBuilder
    private var subscriptionBadge: some View {
        switch appState.subscriptionStatus {
        case .past_due:
            subscriptionStatusBadge("Past Due", tint: .orange)
        case .expired:
            subscriptionStatusBadge("Expired", tint: .orange)
        default:
            if appState.isPro {
                subscriptionStatusBadge("Pro", tint: .accentColor)
            } else {
                subscriptionStatusBadge("Free", tint: AppColors.textSecondary)
            }
        }
    }

    private func subscriptionStatusBadge(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.15), in: Capsule())
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
        .environment(AppRouter())
        .environment(SubscriptionManager.shared)
        .frame(width: 520, height: 640)
}
