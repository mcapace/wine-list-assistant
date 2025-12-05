import SwiftUI

struct WineDetailSheet: View {
    let recognizedWine: RecognizedWine
    @Environment(\.dismiss) private var dismiss
    @State private var isSaved = false
    @State private var showShareSheet = false

    private var wine: Wine? {
        recognizedWine.matchedWine
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Score Header
                    if let wine = wine {
                        ScoreHeader(wine: wine, confidence: recognizedWine.matchConfidence)
                    }

                    // Wine Info
                    if let wine = wine {
                        WineInfoSection(wine: wine)
                    }

                    // Tasting Note
                    if let wine = wine, !wine.tastingNote.isEmpty {
                        TastingNoteSection(note: wine.tastingNote)
                    }

                    // Price & Value
                    if let wine = wine {
                        PriceValueSection(
                            wine: wine,
                            listPrice: recognizedWine.listPrice,
                            valueRatio: recognizedWine.valueRatio
                        )
                    }

                    // Actions
                    ActionButtonsSection(
                        wine: wine,
                        isSaved: $isSaved,
                        onSave: saveWine,
                        onShare: { showShareSheet = true }
                    )
                }
                .padding()
            }
            .navigationTitle(wine?.displayName ?? "Wine Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
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
        Wine Spectator Score: \(wine.score)

        \(wine.tastingNote)

        Drink: \(wine.drinkWindowDisplay)
        """
    }
}

// MARK: - Score Header

struct ScoreHeader: View {
    let wine: Wine
    let confidence: Double

    var body: some View {
        HStack(spacing: Theme.Spacing.xl) {
            LargeScoreDisplay(
                score: wine.score,
                reviewerInitials: wine.reviewer.initials
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(wine.producer)
                    .font(Theme.Typography.headline)
                    .foregroundColor(.primary)

                Text(wine.name)
                    .font(Theme.Typography.title3)
                    .foregroundColor(.primary)

                if let vintage = wine.vintage {
                    Text("\(vintage)")
                        .font(Theme.Typography.title2)
                        .foregroundColor(.secondary)
                }

                if confidence < 0.85 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Possible match")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }

            Spacer()
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Wine Info Section

struct WineInfoSection: View {
    let wine: Wine

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Details")
                .font(Theme.Typography.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.md) {
                InfoItem(label: "Region", value: wine.region)
                InfoItem(label: "Country", value: wine.country)
                InfoItem(label: "Type", value: wine.color.displayName)
                InfoItem(label: "Drink Window", value: wine.drinkWindowDisplay)
            }

            // Grapes
            if !wine.grapeVarieties.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Grapes")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(wine.grapeVarieties.map(\.name).joined(separator: ", "))
                        .font(.body)
                }
            }

            // Drink Window Status
            DrinkWindowBadge(status: wine.drinkWindowStatus)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
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

// MARK: - Tasting Note Section

struct TastingNoteSection: View {
    let note: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Tasting Note")
                .font(Theme.Typography.headline)

            Text(note)
                .font(.body)
                .lineLimit(isExpanded ? nil : 4)
                .foregroundColor(.primary)

            if note.count > 200 {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Text(isExpanded ? "Show Less" : "Read More")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Price & Value Section

struct PriceValueSection: View {
    let wine: Wine
    let listPrice: Decimal?
    let valueRatio: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Price & Value")
                .font(Theme.Typography.headline)

            HStack(spacing: Theme.Spacing.xl) {
                if let releasePrice = wine.releasePriceDisplay {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Release Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(releasePrice)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }

                if let listPrice = listPrice {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("List Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatPrice(listPrice))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }

                if let ratio = valueRatio {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Markup")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1fx", ratio))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(ratio < 2.5 ? .green : (ratio < 3.5 ? .orange : .red))
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
}

// MARK: - Action Buttons

struct ActionButtonsSection: View {
    let wine: Wine?
    @Binding var isSaved: Bool
    let onSave: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                Button(action: onSave) {
                    Label(
                        isSaved ? "Saved" : "Save",
                        systemImage: isSaved ? "heart.fill" : "heart"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(isSaved ? .red : .accentColor)
                .disabled(isSaved)

                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            // Buy Similar Wine button
            if let wine = wine {
                Button(action: { buySimilarWine(wine) }) {
                    Label("Buy Similar Wine", systemImage: "cart")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }
        }
    }
    
    private func buySimilarWine(_ wine: Wine) {
        // Create search query for similar wines
        let searchQuery = "\(wine.producer) \(wine.name) \(wine.vintage.map { String($0) } ?? "")"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Use Wine-Searcher or general web search
        // Wine-Searcher: https://www.wine-searcher.com/find/
        // For now, use a web search as fallback
        let wineSearcherURL = "https://www.wine-searcher.com/find/\(searchQuery)"
        
        if let url = URL(string: wineSearcherURL) {
            UIApplication.shared.open(url)
        } else if let fallbackURL = URL(string: "https://www.google.com/search?q=\(searchQuery)") {
            UIApplication.shared.open(fallbackURL)
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
