//
//  UIConstants.swift
//  MargaSatya
//
//  UI constants for consistent design
//

import SwiftUI

/// UI Constants
enum UIConstants {
    /// Spacing constants
    enum Spacing {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let regular: CGFloat = 16
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 24
        static let huge: CGFloat = 32
        static let massive: CGFloat = 40
    }

    /// Corner radius constants
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let regular: CGFloat = 16
        static let large: CGFloat = 20
        static let card: CGFloat = 24
    }

    /// Shadow constants
    enum Shadow {
        static let radius: CGFloat = 20
        static let opacity: Double = 0.2
        static let yOffset: CGFloat = 10
    }

    /// Animation constants
    enum Animation {
        static let quick: Double = 0.2
        static let standard: Double = 0.3
        static let slow: Double = 0.5
        static let spring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.6)
    }

    /// Icon sizes
    enum IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 24
        static let large: CGFloat = 32
        static let huge: CGFloat = 50
        static let massive: CGFloat = 70
    }

    /// Glass effect constants
    enum Glass {
        static let borderOpacity: Double = 0.3
        static let gradientTopOpacity: Double = 0.2
        static let gradientBottomOpacity: Double = 0.05
        static let strokeTopOpacity: Double = 0.5
        static let strokeBottomOpacity: Double = 0.1
    }
}
