//
//  AuthTextField.swift
//  FrameFlow
//

import SwiftUI

struct AuthTextField: View {
    let label: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var isDisabled: Bool = false

    @State private var isVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 20)

                Group {
                    if isSecure, !isVisible {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .textFieldStyle(.plain)
                .focused($isFocused)

                if isSecure {
                    Button {
                        isVisible.toggle()
                    } label: {
                        Image(systemName: isVisible ? "eye.slash" : "eye")
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help(isVisible ? "Hide password" : "Show password")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(AppColors.background.opacity(0.6))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isFocused ? AppColors.primary : AppColors.border,
                        lineWidth: isFocused ? 1.5 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.65 : 1)
    }
}

extension AuthTextField {
    func textContentType(_ type: NSTextContentType?) -> some View {
        modifier(AuthTextContentTypeModifier(type: type))
    }
}

private struct AuthTextContentTypeModifier: ViewModifier {
    let type: NSTextContentType?

    func body(content: Content) -> some View {
        if let type {
            content.textContentType(type)
        } else {
            content
        }
    }
}
