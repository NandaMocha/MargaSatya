//
//  GlassCard.swift
//  MargaSatya
//
//  Liquid Glass UI Components using native SwiftUI
//

import SwiftUI

// MARK: - Glass Card

/// Glassmorphic card component using native SwiftUI materials
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(UIConstants.Spacing.extraLarge)
            .background(glassBackground)
            .shadow(
                color: Color.black.opacity(UIConstants.Shadow.opacity),
                radius: UIConstants.Shadow.radius,
                x: 0,
                y: UIConstants.Shadow.yOffset
            )
    }

    private var glassBackground: some View {
        ZStack {
            // Native material background
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.card, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(gradientOverlay)

            // Border stroke
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.card, style: .continuous)
                .stroke(borderGradient, lineWidth: 1)
        }
    }

    private var gradientOverlay: some View {
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.card, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(UIConstants.Glass.gradientTopOpacity),
                        Color.white.opacity(UIConstants.Glass.gradientBottomOpacity)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(UIConstants.Glass.strokeTopOpacity),
                Color.white.opacity(UIConstants.Glass.strokeBottomOpacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Glass Button

/// Glass button component using native SwiftUI
struct GlassButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, UIConstants.Spacing.regular)
        }
        .background(buttonBackground)
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.regular, style: .continuous))
        .shadow(
            color: Color.blue.opacity(isEnabled ? 0.5 : 0.2),
            radius: 15,
            x: 0,
            y: UIConstants.Shadow.yOffset
        )
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }

    private var buttonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.regular, style: .continuous)
                .fill(buttonGradient)

            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.regular, style: .continuous)
                .stroke(borderGradient, lineWidth: 1)
        }
    }

    private var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.blue.opacity(isEnabled ? 0.6 : 0.3),
                Color.purple.opacity(isEnabled ? 0.6 : 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(UIConstants.Glass.strokeTopOpacity),
                Color.white.opacity(UIConstants.Glass.gradientTopOpacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Glass TextField

/// Glass text field using native TextField
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: UIConstants.Spacing.medium) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.title3)
                    .imageScale(.medium)
            }

            TextField(placeholder, text: $text)
                .foregroundStyle(.white)
                .font(.body)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)
                .tint(.white)
        }
        .padding(UIConstants.Spacing.regular)
        .background(textFieldBackground)
    }

    private var textFieldBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                )

            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium, style: .continuous)
                .stroke(Color.white.opacity(UIConstants.Glass.borderOpacity), lineWidth: 1)
        }
    }
}

// MARK: - Previews

#Preview("Glass Components") {
    ZStack {
        GlassBackground()

        VStack(spacing: UIConstants.Spacing.large) {
            GlassCard {
                VStack(spacing: UIConstants.Spacing.regular) {
                    Text("Glass Card")
                        .foregroundStyle(.white)
                        .font(.title)

                    GlassTextField(
                        placeholder: "Enter code",
                        text: .constant(""),
                        icon: "lock.fill"
                    )

                    GlassButton(title: "Start Exam", action: {})
                }
            }
            .padding()
        }
    }
}
