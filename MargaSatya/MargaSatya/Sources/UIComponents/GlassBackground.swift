//
//  GlassBackground.swift
//  MargaSatya
//
//  Liquid Glass UI Components
//

import SwiftUI

/// Animated liquid glass background
struct GlassBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.45),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.15, green: 0.15, blue: 0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated blobs
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(
                            x: animate ? -geometry.size.width * 0.3 : geometry.size.width * 0.3,
                            y: animate ? -geometry.size.height * 0.2 : geometry.size.height * 0.2
                        )

                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.3),
                                    Color.pink.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(
                            x: animate ? geometry.size.width * 0.4 : -geometry.size.width * 0.2,
                            y: animate ? geometry.size.height * 0.3 : -geometry.size.height * 0.1
                        )

                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.2),
                                    Color.cyan.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 40)
                        .offset(
                            x: animate ? geometry.size.width * 0.2 : -geometry.size.width * 0.4,
                            y: animate ? -geometry.size.height * 0.3 : geometry.size.height * 0.4
                        )
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(
                Animation
                    .easeInOut(duration: 8)
                    .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

#Preview {
    GlassBackground()
}
