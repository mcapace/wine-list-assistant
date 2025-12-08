import SwiftUI
import UIKit

struct WineDetailSheet: View {
    let recognizedWine: RecognizedWine
    @Environment(\.dismiss) private var dismiss
    @State private var isSaved = false
    @State private var showShareSheet = false

    private var wine: Wine? {
        recognizedWine.matchedWine
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Score Header - Premium design
                    if let wine = wine {
                        PremiumScoreHeader(
                            wine: wine,
                            confidence: recognizedWine.matchConfidence
                        )
                        .padding(.bottom, Theme.Spacing.xl)
                    }

                    VStack(spacing: Theme.Spacing.lg) {
                        // Wine Info - Elegant grid layout
                        if let wine = wine {
                            PremiumWineInfoSection(wine: wine)
                        }

                        // Tasting Note - Enhanced typography
                        if let wine = wine, let note = wine.tastingNote, !note.isEmpty {
                            PremiumTastingNoteSection(note: note)
                        }

                        // Price & Value - Premium card
                        if let wine = wine {
                            PremiumPriceValueSection(
                                wine: wine,
                                listPrice: recognizedWine.listPrice,
                                valueRatio: recognizedWine.valueRatio
                            )
                        }

                        // Actions - Elegant buttons
                        PremiumActionButtonsSection(
                            isSaved: $isSaved,
                            onSave: saveWine,
                            onShare: { showShareSheet = true }
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, Theme.Spacing.xl + 20) // Extra padding for safe area
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(wine?.producer ?? "Wine Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let wine = wine {
                ShareSheet(items: [createShareText(wine)])
            }
        }
    }

    private func saveWine() {
        guard let wine = wine else { return }

        Task {
            do {
                _ = try await WineAPIClient.shared.saveWine(wineId: wine.id)
                isSaved = true
            } catch {
                print("Failed to save wine: \(error)")
            }
        }
    }

    private func createShareText(_ wine: Wine) -> String {
        """
        \(wine.fullName)
        Wine Spectator Score: \(wine.score?.description ?? "N/A")

        \(wine.tastingNote ?? "No tasting note available")

        Drink: \(wine.drinkWindowDisplay)
        """
    }
}

// MARK: - Premium Score Header

struct PremiumScoreHeader: View {
    let wine: Wine
    let confidence: Double
    @State private var appear = false

    var body: some View {
        VStack(spacing: 0) {
            // Gradient background
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [
                        Theme.scoreBackgroundColor(for: wine.score),
                        Theme.scoreBackgroundColor(for: wine.score).opacity(0.5),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 280)
                .ignoresSafeArea(edges: .top)

                VStack(spacing: Theme.Spacing.lg) {
                    Spacer()
                        .frame(height: 20)

                    // Large score display
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("\(wine.score)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.scoreColor(for: wine.score))
                            .opacity(appear ? 1.0 : 0.0)
                            .scaleEffect(appear ? 1.0 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appear)

                        if let score = wine.score {
                            ScoreCategoryBadge(score: score)
                        }
                            .opacity(appear ? 1.0 : 0.0)
                            .offset(y: appear ? 0 : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appear)
                    }

                    // Wine name section
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(wine.producer)
                            .font(.system(size: 22, weight: .semibold, design: .default))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text(wine.name)
                            .font(.system(size: 18, weight: .medium, design: .default))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        if let vintage = wine.vintage {
                            Text("\(vintage)")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.secondary.opacity(0.8))
                                .padding(.top, 4)
                        }
                    }
                    .opacity(appear ? 1.0 : 0.0)
                    .offset(y: appear ? 0 : 15)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)

                    // Confidence indicator
                    if confidence < 0.85 {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Possible match")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )
                        .opacity(appear ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: appear)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .onAppear {
            appear = true
        }
    }
}

struct ScoreCategoryBadge: View {
    let score: Int
    
    var body: some View {
        let category = ScoreCategory(score: score)
        Text(category.displayName.uppercased())
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(Theme.scoreColor(for: score))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Theme.scoreColor(for: score).opacity(0.15))
            )
    }
}

// MARK: - Premium Wine Info Section

struct PremiumWineInfoSection: View {
    let wine: Wine

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.primaryColor)
                Text("Details")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.bottom, Theme.Spacing.xs)

            // Grid layout - elegant spacing
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.md),
                GridItem(.flexible(), spacing: Theme.Spacing.md)
            ], spacing: Theme.Spacing.lg) {
                PremiumInfoItem(
                    icon: "mappin.circle.fill",
                    label: "Region",
                    value: wine.region,
                    iconColor: .blue
                )
                PremiumInfoItem(
                    icon: "globe",
                    label: "Country",
                    value: wine.country,
                    iconColor: .green
                )
                PremiumInfoItem(
                    icon: "drop.fill",
                    label: "Type",
                    value: wine.color.displayName,
                    iconColor: Theme.primaryColor
                )
                PremiumInfoItem(
                    icon: "calendar",
                    label: "Drink Window",
                    value: wine.drinkWindowDisplay,
                    iconColor: .purple
                )
            }

            // Divider
            Divider()
                .padding(.vertical, Theme.Spacing.xs)

            // Grapes - elegant display
            if !wine.grapeVarieties.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text("Grape Varieties")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(wine.grapeVarieties, id: \.name) { grape in
                                Text(grape.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemGray6))
                                    )
                            }
                        }
                    }
                }
            }

            // Drink Window Status - premium badge
            if wine.drinkWindowStatus != .ready {
                HStack {
                    DrinkWindowBadge(status: wine.drinkWindowStatus)
                    Spacer()
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct PremiumInfoItem: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

struct InfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DrinkWindowBadge: View {
    let status: DrinkWindowStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.iconName)
            Text(status.displayText)
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Theme.drinkWindowColor(for: status))
        )
    }
}

// MARK: - Premium Tasting Note Section

struct PremiumTastingNoteSection: View {
    let note: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.secondaryColor)
                Text("Tasting Note")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }

            // Note text with elegant typography
            Text(note)
                .font(.system(size: 17, weight: .regular, design: .default))
                .lineSpacing(6)
                .lineLimit(isExpanded ? nil : 5)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Read more/less button
            if note.count > 250 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show Less" : "Read More")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Theme.primaryColor)
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Premium Price & Value Section

struct PremiumPriceValueSection: View {
    let wine: Wine
    let listPrice: Decimal?
    let valueRatio: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                Text("Price & Value")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }

            // Price grid - elegant layout
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.md),
                GridItem(.flexible(), spacing: Theme.Spacing.md)
            ], spacing: Theme.Spacing.md) {
                if let releasePrice = wine.releasePriceDisplay {
                    PremiumPriceItem(
                        icon: "tag.fill",
                        label: "Release Price",
                        value: releasePrice,
                        iconColor: .blue
                    )
                }

                if let listPrice = listPrice {
                    PremiumPriceItem(
                        icon: "list.bullet",
                        label: "List Price",
                        value: formatPrice(listPrice),
                        iconColor: .purple
                    )
                }

                if let ratio = valueRatio {
                    ValueRatioItem(ratio: ratio)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
}

struct PremiumPriceItem: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

struct ValueRatioItem: View {
    let ratio: Double
    
    private var ratioColor: Color {
        ratio < 2.5 ? .green : (ratio < 3.5 ? .orange : .red)
    }
    
    private var valueText: String {
        ratio < 2.5 ? "Great Value" : (ratio < 3.5 ? "Fair Value" : "High Markup")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundColor(ratioColor)
                Text("Value")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%.1fx", ratio))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ratioColor)
                Text(valueText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ratioColor.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ratioColor.opacity(0.1))
        )
    }
}

// MARK: - Premium Action Buttons

struct PremiumActionButtonsSection: View {
    @Binding var isSaved: Bool
    let onSave: () -> Void
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Save button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onSave()
            }) {
                HStack {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isSaved ? "Saved" : "Save")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(isSaved ? .white : Theme.primaryColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSaved ? Color.red : Color(.systemGray6))
                )
            }
            .disabled(isSaved)

            // Share button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onShare()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Share")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.primaryColor)
                )
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    WineDetailSheet(recognizedWine: RecognizedWine.preview)
}
