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
                    // Hero section with label image
                    if let wine = wine {
                        WineHeroSection(
                            wine: wine,
                            confidence: recognizedWine.matchConfidence
                        )
                    }

                    VStack(spacing: Theme.Spacing.lg) {
                        // Wine Info Section
                        if let wine = wine {
                            WineInfoCard(wine: wine)
                        }

                        // Tasting Note Section
                        if let wine = wine, let note = wine.tastingNote, !note.isEmpty {
                            TastingNoteCard(note: note, reviewer: wine.reviewer)
                        }

                        // Price & Value Section
                        if let wine = wine {
                            PriceValueCard(
                                wine: wine,
                                listPrice: recognizedWine.listPrice,
                                valueRatio: recognizedWine.valueRatio
                            )
                        }

                        // Action Buttons
                        ActionButtonsCard(
                            isSaved: $isSaved,
                            onSave: saveWine,
                            onShare: { showShareSheet = true }
                        )

                        // Wine Spectator Badge
                        WineSpectatorBrandFooter()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, Theme.Spacing.xl + 20)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary, Color(.systemGray5))
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

// MARK: - Wine Hero Section

struct WineHeroSection: View {
    let wine: Wine
    let confidence: Double
    @State private var appear = false

    var body: some View {
        ZStack(alignment: .top) {
            // Background gradient
            LinearGradient(
                colors: [
                    Theme.primaryColor.opacity(0.95),
                    Theme.primaryColor.opacity(0.7),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 420)
            .ignoresSafeArea(edges: .top)

            VStack(spacing: Theme.Spacing.md) {
                // Top 100 Badge (if applicable)
                if let rank = wine.top100Rank, let year = wine.top100Year {
                    Top100Badge(rank: rank, year: year)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : -10)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appear)
                }

                // Wine Label Image or Placeholder
                WineLabelImage(wine: wine)
                    .frame(height: 180)
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appear)

                // Score Badge
                ScoreBadge(score: wine.score)
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.15), value: appear)

                // Wine Name & Details
                VStack(spacing: Theme.Spacing.xs) {
                    Text(wine.producer)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    if wine.name.lowercased() != wine.producer.lowercased() {
                        Text(wine.name)
                            .font(.system(size: 18, weight: .medium, design: .serif))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    if let vintage = wine.vintage {
                        Text(String(vintage))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.secondaryColor)
                            .padding(.top, 2)
                    }

                    // Region
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                        Text([wine.region, wine.country].compactMap { $0 }.joined(separator: ", "))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 4)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 15)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)

                // Confidence warning
                if confidence < 0.85 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Possible match")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appear)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal)
        }
        .onAppear { appear = true }
    }
}

// MARK: - Wine Label Image

struct WineLabelImage: View {
    let wine: Wine

    var body: some View {
        Group {
            if let urlString = wine.labelUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        WineLabelPlaceholder(wine: wine)
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    case .failure:
                        WineLabelPlaceholder(wine: wine)
                    @unknown default:
                        WineLabelPlaceholder(wine: wine)
                    }
                }
            } else {
                WineLabelPlaceholder(wine: wine)
            }
        }
    }
}

// MARK: - Wine Label Placeholder

struct WineLabelPlaceholder: View {
    let wine: Wine

    var body: some View {
        ZStack {
            // Wine bottle silhouette
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.3), Color.black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 100, height: 160)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: wineIcon)
                            .font(.system(size: 40))
                            .foregroundColor(wineIconColor)

                        Text(wine.color.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                )
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
        }
    }

    private var wineIcon: String {
        switch wine.color {
        case .red: return "wineglass.fill"
        case .white: return "wineglass"
        case .rose: return "wineglass.fill"
        case .sparkling: return "bubbles.and.sparkles"
        case .dessert: return "drop.fill"
        case .fortified: return "wineglass.fill"
        }
    }

    private var wineIconColor: Color {
        switch wine.color {
        case .red: return Color(red: 0.5, green: 0.1, blue: 0.15)
        case .white: return Color(red: 0.95, green: 0.9, blue: 0.7)
        case .rose: return Color(red: 0.95, green: 0.6, blue: 0.65)
        case .sparkling: return Color(red: 0.95, green: 0.9, blue: 0.7)
        case .dessert: return Color(red: 0.8, green: 0.6, blue: 0.2)
        case .fortified: return Color(red: 0.6, green: 0.2, blue: 0.1)
        }
    }
}

// MARK: - Top 100 Badge

struct Top100Badge: View {
    let rank: Int
    let year: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 14))
            Text("#\(rank) Top 100 of \(year)")
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundColor(Theme.secondaryColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Theme.secondaryColor.opacity(0.2))
                .overlay(
                    Capsule()
                        .strokeBorder(Theme.secondaryColor.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Score Badge

struct ScoreBadge: View {
    let score: Int?

    var body: some View {
        VStack(spacing: 2) {
            Text(score.map { "\($0)" } ?? "N/A")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if let score = score {
                Text(ScoreCategory(score: score).displayName.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.secondaryColor)
                    .tracking(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.secondaryColor.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Wine Info Card

struct WineInfoCard: View {
    let wine: Wine

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Section header with icon
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.primaryColor)
                Text("Details")
                    .font(.system(size: 18, weight: .bold))
            }

            // Info Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.md),
                GridItem(.flexible(), spacing: Theme.Spacing.md)
            ], spacing: Theme.Spacing.md) {
                InfoTile(icon: "drop.fill", label: "Type", value: wine.color.displayName, color: Theme.primaryColor)
                InfoTile(icon: "calendar", label: "Drink", value: wine.drinkWindowDisplay, color: .purple)

                if let alcohol = wine.alcohol {
                    InfoTile(icon: "percent", label: "Alcohol", value: String(format: "%.1f%%", alcohol), color: .orange)
                }

                if let price = wine.releasePriceDisplay {
                    InfoTile(icon: "tag.fill", label: "Release", value: price, color: .green)
                }
            }

            // Grape Varieties
            if !wine.grapeVarieties.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text("Grape Varieties")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    FlowLayout(spacing: 8) {
                        ForEach(wine.grapeVarieties, id: \.name) { grape in
                            GrapeTag(grape: grape)
                        }
                    }
                }
            }

            // Drink Window Status
            if wine.drinkWindowStatus != .ready {
                DrinkStatusBadge(status: wine.drinkWindowStatus)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Info Tile

struct InfoTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Grape Tag

struct GrapeTag: View {
    let grape: GrapeVariety

    var body: some View {
        HStack(spacing: 4) {
            Text(grape.name)
                .font(.system(size: 13, weight: .medium))
            if let pct = grape.percentage {
                Text("\(pct)%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Flow Layout (for grape tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Drink Status Badge

struct DrinkStatusBadge: View {
    let status: DrinkWindowStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.iconName)
            Text(status.displayText)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Theme.drinkWindowColor(for: status))
        )
    }
}

// MARK: - Tasting Note Card

struct TastingNoteCard: View {
    let note: String
    let reviewer: Reviewer?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.secondaryColor)
                Text("Tasting Note")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                if let reviewer = reviewer {
                    Text(reviewer.initials)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Theme.primaryColor))
                }
            }

            // Note text
            Text(note)
                .font(.system(size: 16, weight: .regular, design: .serif))
                .lineSpacing(6)
                .lineLimit(isExpanded ? nil : 5)
                .foregroundColor(.primary)

            // Read more button
            if note.count > 200 {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show Less" : "Read More")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.primaryColor)
                }
            }

            // Reviewer name
            if let name = reviewer?.name {
                Text("— \(name)")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Price Value Card

struct PriceValueCard: View {
    let wine: Wine
    let listPrice: Decimal?
    let valueRatio: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
                Text("Price & Value")
                    .font(.system(size: 18, weight: .bold))
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.md),
                GridItem(.flexible(), spacing: Theme.Spacing.md)
            ], spacing: Theme.Spacing.md) {
                if let price = wine.releasePriceDisplay {
                    PriceTile(icon: "tag.fill", label: "Release Price", value: price, color: .blue)
                }

                if let listPrice = listPrice {
                    PriceTile(icon: "list.clipboard.fill", label: "List Price", value: formatPrice(listPrice), color: .purple)
                }

                if let ratio = valueRatio {
                    ValueRatioTile(ratio: ratio)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
}

// MARK: - Price Tile

struct PriceTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Value Ratio Tile

struct ValueRatioTile: View {
    let ratio: Double

    private var ratioColor: Color {
        ratio < 2.5 ? .green : (ratio < 3.5 ? .orange : .red)
    }

    private var valueText: String {
        ratio < 2.5 ? "Great Value" : (ratio < 3.5 ? "Fair Value" : "High Markup")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 12))
                    .foregroundColor(ratioColor)
                Text("Value")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%.1fx", ratio))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ratioColor)
                Text(valueText)
                    .font(.system(size: 12, weight: .medium))
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

// MARK: - Action Buttons Card

struct ActionButtonsCard: View {
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
                HStack(spacing: 8) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isSaved ? "Saved" : "Save")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(isSaved ? .white : Theme.primaryColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
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
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Share")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.primaryColor)
                )
            }
        }
    }
}

// MARK: - Wine Spectator Brand Footer

struct WineSpectatorBrandFooter: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                WineSpectatorLogo(variant: .black, height: 20)
                Text("×")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.secondary)
                WineLensBadge(style: .dark, showText: true)
            }

            Text("Expert ratings from Wine Spectator")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Theme.Spacing.lg)
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

#if DEBUG
#Preview {
    WineDetailSheet(recognizedWine: RecognizedWine.preview)
}
#endif
