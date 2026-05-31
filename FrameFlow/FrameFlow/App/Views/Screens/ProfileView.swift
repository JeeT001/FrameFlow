//
//  ProfileView.swift
//  FrameFlow
//

import AppKit
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
                profileHeader
                    .listRowBackground(Color.clear)
            }

            Section("Account") {
                TextField("Display name", text: $viewModel.displayName)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 12) {
                    Button("Save") {
                        Task { await viewModel.saveDisplayName(appState: appState) }
                    }
                    .disabled(viewModel.isSaving || !viewModel.canSaveDisplayName)

                    if viewModel.isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else if viewModel.showSaveSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppColors.successGreen)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.showSaveSuccess)

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

                Button("Delete Account", role: .destructive) {
                    viewModel.showDeleteConfirmation = true
                }
                .disabled(viewModel.isDeletingAccount)

                if viewModel.isDeletingAccount {
                    ProgressView("Deleting account…")
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
        .alert("Delete your account?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Delete Account", role: .destructive) {
                Task { await viewModel.deleteAccount(appState: appState, router: router) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone. Your account and subscription data will be permanently removed.")
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

    private var profileHeader: some View {
        VStack(spacing: 12) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            }

            Text("FrameFlow")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)

            Text("Version \(ProfileViewModel.appVersionString)")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)

            avatarView
                .padding(.top, 4)

            Text(UserDisplayHelpers.displayName(for: appState.currentUser))
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
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
            .frame(width: 56, height: 56)
            .overlay {
                Text(UserDisplayHelpers.initials(for: appState.currentUser))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
            }
    }

    @ViewBuilder
    private var subscriptionBadge: some View {
        switch appState.subscriptionStatus {
        case .past_due:
            subscriptionStatusBadge("Past Due", tint: AppColors.proGold)
        case .expired:
            subscriptionStatusBadge("Expired", tint: AppColors.proGold)
        default:
            if appState.isPro {
                subscriptionStatusBadge("Pro", tint: AppColors.primary)
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
            .foregroundStyle(tint)
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
        .environment(AppRouter())
        .environment(SubscriptionManager.shared)
        .frame(width: 520, height: 720)
}
