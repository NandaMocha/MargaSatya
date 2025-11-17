//
//  UIConstantsTests.swift
//  MargaSatyaTests
//
//  Unit tests for UIConstants
//

import Testing
import Foundation
@testable import MargaSatya

struct UIConstantsTests {
    // MARK: - Spacing Tests

    @Test("Spacing values are positive and increasing")
    func testSpacingValues() {
        #expect(UIConstants.Spacing.tiny > 0)
        #expect(UIConstants.Spacing.small > UIConstants.Spacing.tiny)
        #expect(UIConstants.Spacing.medium > UIConstants.Spacing.small)
        #expect(UIConstants.Spacing.regular > UIConstants.Spacing.medium)
        #expect(UIConstants.Spacing.large > UIConstants.Spacing.regular)
        #expect(UIConstants.Spacing.extraLarge > UIConstants.Spacing.large)
        #expect(UIConstants.Spacing.huge > UIConstants.Spacing.extraLarge)
        #expect(UIConstants.Spacing.massive > UIConstants.Spacing.huge)
    }

    @Test("Spacing values are reasonable for UI")
    func testSpacingReasonableValues() {
        #expect(UIConstants.Spacing.tiny >= 4)
        #expect(UIConstants.Spacing.tiny <= 8)

        #expect(UIConstants.Spacing.regular >= 12)
        #expect(UIConstants.Spacing.regular <= 20)

        #expect(UIConstants.Spacing.massive >= 32)
        #expect(UIConstants.Spacing.massive <= 50)
    }

    // MARK: - Corner Radius Tests

    @Test("Corner radius values are positive and increasing")
    func testCornerRadiusValues() {
        #expect(UIConstants.CornerRadius.small > 0)
        #expect(UIConstants.CornerRadius.medium > UIConstants.CornerRadius.small)
        #expect(UIConstants.CornerRadius.regular > UIConstants.CornerRadius.medium)
        #expect(UIConstants.CornerRadius.large > UIConstants.CornerRadius.regular)
        #expect(UIConstants.CornerRadius.card > UIConstants.CornerRadius.large)
    }

    @Test("Corner radius values are reasonable for UI")
    func testCornerRadiusReasonableValues() {
        #expect(UIConstants.CornerRadius.small >= 4)
        #expect(UIConstants.CornerRadius.small <= 12)

        #expect(UIConstants.CornerRadius.card >= 20)
        #expect(UIConstants.CornerRadius.card <= 32)
    }

    // MARK: - Shadow Tests

    @Test("Shadow radius is positive")
    func testShadowRadius() {
        #expect(UIConstants.Shadow.radius > 0)
        #expect(UIConstants.Shadow.radius <= 30) // Reasonable maximum
    }

    @Test("Shadow opacity is within valid range")
    func testShadowOpacity() {
        #expect(UIConstants.Shadow.opacity >= 0.0)
        #expect(UIConstants.Shadow.opacity <= 1.0)
    }

    @Test("Shadow Y offset is reasonable")
    func testShadowYOffset() {
        #expect(UIConstants.Shadow.yOffset >= 0)
        #expect(UIConstants.Shadow.yOffset <= 20)
    }

    // MARK: - Animation Tests

    @Test("Animation durations are positive")
    func testAnimationDurations() {
        #expect(UIConstants.Animation.quick > 0)
        #expect(UIConstants.Animation.standard > UIConstants.Animation.quick)
        #expect(UIConstants.Animation.slow > UIConstants.Animation.standard)
    }

    @Test("Animation durations are reasonable")
    func testAnimationReasonableDurations() {
        #expect(UIConstants.Animation.quick <= 0.3)
        #expect(UIConstants.Animation.standard <= 0.5)
        #expect(UIConstants.Animation.slow <= 1.0)
    }

    // MARK: - Icon Size Tests

    @Test("Icon sizes are positive and increasing")
    func testIconSizes() {
        #expect(UIConstants.IconSize.small > 0)
        #expect(UIConstants.IconSize.medium > UIConstants.IconSize.small)
        #expect(UIConstants.IconSize.large > UIConstants.IconSize.medium)
        #expect(UIConstants.IconSize.huge > UIConstants.IconSize.large)
        #expect(UIConstants.IconSize.massive > UIConstants.IconSize.huge)
    }

    @Test("Icon sizes are reasonable for UI")
    func testIconReasonableSizes() {
        #expect(UIConstants.IconSize.small >= 12)
        #expect(UIConstants.IconSize.small <= 20)

        #expect(UIConstants.IconSize.medium >= 20)
        #expect(UIConstants.IconSize.medium <= 32)

        #expect(UIConstants.IconSize.massive >= 60)
        #expect(UIConstants.IconSize.massive <= 100)
    }

    // MARK: - Glass Effect Tests

    @Test("Glass border opacity is within valid range")
    func testGlassBorderOpacity() {
        #expect(UIConstants.Glass.borderOpacity >= 0.0)
        #expect(UIConstants.Glass.borderOpacity <= 1.0)
    }

    @Test("Glass gradient opacities are within valid range")
    func testGlassGradientOpacities() {
        #expect(UIConstants.Glass.gradientTopOpacity >= 0.0)
        #expect(UIConstants.Glass.gradientTopOpacity <= 1.0)

        #expect(UIConstants.Glass.gradientBottomOpacity >= 0.0)
        #expect(UIConstants.Glass.gradientBottomOpacity <= 1.0)

        // Top should be more opaque than bottom
        #expect(UIConstants.Glass.gradientTopOpacity > UIConstants.Glass.gradientBottomOpacity)
    }

    @Test("Glass stroke opacities are within valid range")
    func testGlassStrokeOpacities() {
        #expect(UIConstants.Glass.strokeTopOpacity >= 0.0)
        #expect(UIConstants.Glass.strokeTopOpacity <= 1.0)

        #expect(UIConstants.Glass.strokeBottomOpacity >= 0.0)
        #expect(UIConstants.Glass.strokeBottomOpacity <= 1.0)

        // Top should be more opaque than bottom
        #expect(UIConstants.Glass.strokeTopOpacity > UIConstants.Glass.strokeBottomOpacity)
    }

    // MARK: - Consistency Tests

    @Test("Related values maintain proper ratios")
    func testRelatedValuesRatios() {
        // Small spacing should be half of regular spacing (approximately)
        let ratio = UIConstants.Spacing.regular / UIConstants.Spacing.small
        #expect(ratio >= 1.5)
        #expect(ratio <= 2.5)
    }

    @Test("All constant groups are accessible")
    func testAllConstantGroupsAccessible() {
        // This test ensures all constant groups can be accessed without crashes
        _ = UIConstants.Spacing.regular
        _ = UIConstants.CornerRadius.medium
        _ = UIConstants.Shadow.radius
        _ = UIConstants.Animation.standard
        _ = UIConstants.IconSize.medium
        _ = UIConstants.Glass.borderOpacity

        #expect(true) // If we reach here, all groups are accessible
    }
}
