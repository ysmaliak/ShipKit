import Inject
import RevenueCat
import SwiftUI

public struct PackageOptionView: View {
    public let package: Package
    public let isSelected: Bool
    public let discountPercentage: Double?

    @State private var isColorSelected = false
    @State private var isCheckmarkVisible = false
    @State private var checkmarkScale: CGFloat = 0.5
    @State private var discountBadgeHeight: CGFloat = 0

    @ObserveInjection private var inject

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
                    Text(String(localizable: .savePercent(String(Int(round(discount))))))
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
                .strokeBorder(isColorSelected ? Color.primary : Color.primary.opacity(0.3), lineWidth: isColorSelected ? 3 : 1.5)
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
        .enableInjection()
    }
}
