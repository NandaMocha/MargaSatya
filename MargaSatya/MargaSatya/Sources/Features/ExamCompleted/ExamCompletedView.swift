//
//  ExamCompletedView.swift
//  MargaSatya
//
//  Exam Completed Screen
//

import SwiftUI

struct ExamCompletedView: View {
    @Binding var shouldReturnHome: Bool
    @State private var showCheckmark = false
    @State private var scale: CGFloat = 0.5

    var body: some View {
        ZStack {
            GlassBackground()

            VStack(spacing: 40) {
                Spacer()

                // Success Animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)
                        .scaleEffect(showCheckmark ? 1.2 : 0.8)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)

                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                        .opacity(showCheckmark ? 1 : 0)
                }
                .shadow(color: .green.opacity(0.5), radius: 30)

                // Message Card
                GlassCard {
                    VStack(spacing: 20) {
                        Text("Exam Completed")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Thank you for completing the exam. Your responses have been submitted successfully.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)

                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.vertical, 8)

                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Responses saved")
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                            }

                            HStack {
                                Image(systemName: "lock.open.fill")
                                    .foregroundColor(.blue)
                                Text("Device unlocked")
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                            }

                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .foregroundColor(.purple)
                                Text("Ready for next exam")
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                            }
                        }
                        .font(.subheadline)

                        GlassButton(title: "Return to Home", action: {
                            shouldReturnHome = true
                        })
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .onAppear {
            // Animate checkmark
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
            }

            withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
                showCheckmark = true
            }

            withAnimation(
                Animation
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
            ) {
                showCheckmark = true
            }
        }
    }
}

#Preview {
    ExamCompletedView(shouldReturnHome: .constant(false))
}
