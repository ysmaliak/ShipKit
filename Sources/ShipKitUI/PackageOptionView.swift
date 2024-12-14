import RevenueCat
import SwiftUI

/// A view that displays a selectable package option for in-app purchases.
///
/// This view presents a package option with:
/// - Package title and description
/// - Optional discount badge
/// - Selection state with animated checkmark
/// - Interactive selection feedback
///
/// Example usage:
/// ```swift
/// PackageOptionView(
///     package: package,
///     isSelected: true,
///     discountPercentage: 20
/// )
/// ```
public struct PackageOptionView: View {
    /// The RevenueCat package to display
    public let package: Package

    /// Whether this package is currently selected
    public let isSelected: Bool

    /// Optional discount percentage to display in the badge
    public let discountPercentage: Double?

    /// Tracks the visual selection state for animation
    @State private var isColorSelected = false

    /// Controls the checkmark visibility
    @State private var isCheckmarkVisible = false

    /// Controls the checkmark scale animation
    @State private var checkmarkScale: CGFloat = 0.5

    /// Tracks the height of the discount badge for layout
    @State private var discountBadgeHeight: CGFloat = 0

    /// Creates a new package option view.
    ///
    /// - Parameters:
    ///   - package: The RevenueCat package to display
    ///   - isSelected: Whether this package is currently selected
    ///   - discountPercentage: Optional discount percentage to show in badge
    public init(
        package: Package,
        isSelected: Bool,
        discountPercentage: Double?
    ) {
        self.package = package
        self.isSelected = isSelected
        self.discountPercentage = discountPercentage
    }

    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(package.storeProduct.localizedTitle)
                    .font(.headline)
                    .foregroundStyle(Color.primary)

                if let description = package.localizedPriceDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if let discount = discountPercentage, discount >= 5 {
                    Text(.localizable(.savePercent(String(Int(round(discount))))))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary)
                        }
                        .background {
                            GeometryReader { geometry in
                                Color.clear.task { discountBadgeHeight = geometry.size.height }
                            }
                        }
                }

                Image(systemSymbol: .checkmarkCircleFill)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color.primary)
                    .opacity(isCheckmarkVisible ? 1 : 0)
                    .scaleEffect(checkmarkScale)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    isColorSelected ? Color.primary : Color.primary.opacity(0.3),
                    lineWidth: isColorSelected ? 3 : 1.5
                )
        }
        .contentShape(.rect)
        .onChange(of: isSelected) { _, newValue in
            withAnimation(.bouncy) {
                isCheckmarkVisible = newValue
                checkmarkScale = newValue ? 1 : 0.5
            }
            withAnimation(.linear) {
                isColorSelected = newValue
            }
        }
        .onAppear {
            isColorSelected = isSelected
            isCheckmarkVisible = isSelected
            checkmarkScale = isSelected ? 1 : 0.5
        }
    }
}
