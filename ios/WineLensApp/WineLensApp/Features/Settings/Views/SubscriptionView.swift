import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    SubscriptionHeader()

                    // Features
                    FeaturesSection()

                    // Products
                    if subscriptionService.isLoading {
                        ProgressView()
                            .padding()
                    } else if subscriptionService.products.isEmpty {
                        Text("Unable to load subscription options")
                            .foregroundColor(.secondary)
                    } else {
                        ProductsSection(
                            products: subscriptionService.products,
                            selectedProduct: $selectedProduct
                        )
                    }

                    // Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // Purchase Button
                    if let product = selectedProduct {
                        Button(action: { purchase(product) }) {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Subscribe for \(product.displayPrice)/\(periodName(product))")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .disabled(isPurchasing)
                        .padding(.horizontal)
                    }

                    // Legal
                    LegalSection()
                }
                .padding()
            }
            .navigationTitle("Go Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await subscriptionService.loadProducts()
                // Select yearly by default
                selectedProduct = subscriptionService.products.first { $0.id.contains("yearly") }
                    ?? subscriptionService.products.first
            }
        }
    }

    private func purchase(_ product: Product) {
        isPurchasing = true
        errorMessage = nil

        Task {
            do {
                let success = try await subscriptionService.purchase(product)
                if success {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }

    private func periodName(_ product: Product) -> String {
        if product.id.contains("yearly") {
            return "year"
        }
        return "month"
    }
}

// MARK: - Header

struct SubscriptionHeader: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)

            Text("Wine List Assistant Premium")
                .font(.title2)
                .fontWeight(.bold)

            Text("Unlock the full power of Wine Spectator's 450,000+ expert reviews")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Features

struct FeaturesSection: View {
    let features = [
        ("camera.viewfinder", "Unlimited Scans", "Scan as many wine lists as you want"),
        ("doc.text", "Full Tasting Notes", "Access complete critic reviews"),
        ("slider.horizontal.3", "Advanced Filters", "Filter by score, drink window, value"),
        ("heart.fill", "Save Unlimited Wines", "Build your personal wine collection"),
        ("rectangle.stack.badge.minus", "No Ads", "Enjoy an ad-free experience")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            ForEach(features, id: \.0) { icon, title, subtitle in
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(Theme.primary)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(Theme.CornerRadius.large)
    }
}

// MARK: - Products

struct ProductsSection: View {
    let products: [Product]
    @Binding var selectedProduct: Product?

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(products, id: \.id) { product in
                ProductCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    onSelect: { selectedProduct = product }
                )
            }
        }
    }
}

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    private var isYearly: Bool {
        product.id.contains("yearly")
    }

    private var savingsText: String? {
        // Calculate savings vs monthly
        if isYearly {
            return "Save 33%"
        }
        return nil
    }

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.headline)

                        if let savings = savingsText {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }

                    if isYearly {
                        Text("Best Value")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("per \(isYearly ? "year" : "month")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(isSelected ? Theme.primary : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(isSelected ? Theme.primary.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legal

struct LegalSection: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Link("Terms of Service", destination: URL(string: "https://winespectator.com/terms")!)
                Text("•")
                Link("Privacy Policy", destination: URL(string: "https://winespectator.com/privacy")!)
            }
            .font(.caption2)
            .foregroundColor(.accentColor)
        }
        .padding(.top)
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(SubscriptionService.shared)
}
