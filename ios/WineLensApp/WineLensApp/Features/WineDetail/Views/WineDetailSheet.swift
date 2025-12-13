import SwiftUI
import UIKit

struct WineDetailSheet: View {
    let recognizedWine: RecognizedWine
    @Environment(\.dismiss) private var dismiss
    @State private var isSaved = false
    @State private var showShareSheet = false
    @State private var selectedTab: DetailTab = .details
    @State private var saveError: String?
    @State private var showSaveError = false
    @State private var isSaving = false

    enum DetailTab: String, CaseIterable {
        case details = "Details"
        case tastingNote = "Tasting Note"
    }

    private var wine: Wine? {
        recognizedWine.matchedWine
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let wine = wine {
                        // Hero Section with wine-type colored header
                        WineHeroHeader(
                            wine: wine,
                            confidence: recognizedWine.matchConfidence
                        )

                        // Quick Info Bar (Score | Price | Region)
                        QuickInfoBar(wine: wine, listPrice: recognizedWine.listPrice)
                            .padding(.horizontal)
                            .padding(.top, -20)
                            .zIndex(1)

                        // Tabbed Content
                        VStack(spacing: 0) {
                            // Tab Picker
                            TabPicker(selectedTab: $selectedTab)
                                .padding(.top, Theme.Spacing.lg)
                                .padding(.horizontal)

                            // Tab Content
                            TabContent(
                                selectedTab: selectedTab,
                                wine: wine,
                                listPrice: recognizedWine.listPrice,
                                valueRatio: recognizedWine.valueRatio
                            )
                            .padding(.horizontal)
                            .padding(.top, Theme.Spacing.md)
                        }

                        // Action Buttons
                        ActionButtons(
                            isSaved: $isSaved,
                            isSaving: isSaving,
                            onSave: saveWine,
                            onShare: { showShareSheet = true }
                        )
                        .padding(.horizontal)
                        .padding(.top, Theme.Spacing.lg)

                        // Brand Footer
                        BrandFooter()
                            .padding(.top, Theme.Spacing.lg)
                            .padding(.bottom, Theme.Spacing.xl + 20)
                    }
                }
            }
            .background(Color(.systemGray6).opacity(0.5))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let wine = wine {
                ShareSheet(items: [createShareText(wine)])
            }
        }
        .alert("Error Saving Wine", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveError ?? "An unknown error occurred. Please try again.")
        }
    }

    private func saveWine() {
        guard let wine = wine else { return }
        guard !isSaving else { return } // Prevent multiple saves
        
        isSaving = true
        saveError = nil
        
        Task {
            do {
                _ = try await WineAPIClient.shared.saveWine(wineId: wine.id)
                await MainActor.run {
                    withAnimation { 
                        isSaved = true
                        isSaving = false
                    }
                }
            } catch let error as WineAPIClient.APIError {
                await MainActor.run {
                    isSaving = false
                    saveError = error.errorDescription
                    showSaveError = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    if let apiError = error as? WineAPIClient.APIError {
                        saveError = apiError.errorDescription
                    } else {
                        saveError = "Failed to save wine. Please check your connection and try again."
                    }
                    showSaveError = true
                }
                print("Failed to save wine: \(error)")
            }
        }
    }

    private func createShareText(_ wine: Wine) -> String {
        """
        \(wine.fullName)
        Wine Spectator Score: \(wine.score?.description ?? "N/A")

        \(wine.tastingNote ?? "")

        Drink: \(wine.drinkWindowDisplay)
        """
    }
}

// MARK: - Wine Hero Header

struct WineHeroHeader: View {
    let wine: Wine
    let confidence: Double
    @State private var appear = false

    private var headerColor: Color {
        switch wine.color {
        case .red: return Theme.primaryColor
        case .white: return Color(red: 0.85, green: 0.75, blue: 0.45)
        case .rose: return Color(red: 0.9, green: 0.5, blue: 0.55)
        case .sparkling: return Color(red: 0.75, green: 0.7, blue: 0.55)
        case .dessert: return Color(red: 0.8, green: 0.6, blue: 0.3)
        case .fortified: return Color(red: 0.6, green: 0.3, blue: 0.25)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Gradient background based on wine type
            LinearGradient(
                colors: [
                    headerColor.opacity(0.95),
                    headerColor.opacity(0.8),
                    headerColor.opacity(0.4)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 380)

            VStack(spacing: Theme.Spacing.md) {
                // Top 100 Badge
                if let rank = wine.top100Rank, let year = wine.top100Year {
                    Top100RankBadge(rank: rank, year: year)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : -10)
                }

                // Wine Label Image
                WineLabelDisplay(wine: wine)
                    .frame(height: 200)
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.9)

                // Wine Name
                VStack(spacing: 4) {
                    Text(wine.producer)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                    if wine.name.lowercased() != wine.producer.lowercased() {
                        Text(wine.name)
                            .font(.system(size: 17, weight: .medium, design: .serif))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    if let vintage = wine.vintage {
                        Text(String(vintage))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)

                // Confidence warning
                if confidence < 0.85 {
                    ConfidenceWarning()
                        .opacity(appear ? 1 : 0)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appear = true
            }
        }
    }
}

// MARK: - Wine Label Display

struct WineLabelDisplay: View {
    let wine: Wine

    var body: some View {
        Group {
            if let urlString = wine.labelUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        WineBottlePlaceholder(wineColor: wine.color)
                            .overlay(ProgressView().tint(.white))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                    case .failure:
                        WineBottlePlaceholder(wineColor: wine.color)
                    @unknown default:
                        WineBottlePlaceholder(wineColor: wine.color)
                    }
                }
            } else {
                WineBottlePlaceholder(wineColor: wine.color)
            }
        }
    }
}

// MARK: - Wine Bottle Placeholder

struct WineBottlePlaceholder: View {
    let wineColor: WineColor

    private var iconName: String {
        switch wineColor {
        case .sparkling: return "bubbles.and.sparkles"
        default: return "wineglass.fill"
        }
    }

    private var iconColor: Color {
        switch wineColor {
        case .red: return Color(red: 0.4, green: 0.1, blue: 0.15)
        case .white: return Color(red: 0.9, green: 0.85, blue: 0.6)
        case .rose: return Color(red: 0.95, green: 0.6, blue: 0.65)
        case .sparkling: return Color(red: 0.9, green: 0.85, blue: 0.6)
        case .dessert: return Color(red: 0.85, green: 0.65, blue: 0.3)
        case .fortified: return Color(red: 0.5, green: 0.2, blue: 0.15)
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.2))
            .frame(width: 120, height: 180)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: iconName)
                        .font(.system(size: 50))
                        .foregroundColor(iconColor)
                    Text(wineColor.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            )
            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Top 100 Rank Badge

struct Top100RankBadge: View {
    let rank: Int
    let year: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 12))
            Text("#\(rank) • Top 100 of \(year)")
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(Theme.secondaryColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
                .overlay(Capsule().strokeBorder(Theme.secondaryColor.opacity(0.5), lineWidth: 1))
        )
    }
}

// MARK: - Confidence Warning

struct ConfidenceWarning: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("Possible match")
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.orange.opacity(0.2)))
    }
}

// MARK: - Quick Info Bar

struct QuickInfoBar: View {
    let wine: Wine
    let listPrice: Decimal?

    var body: some View {
        HStack(spacing: 0) {
            // Score with Arc
            ScoreArcView(score: wine.score)
                .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 50)

            // Price
            VStack(spacing: 2) {
                Text("Price")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                if let price = wine.releasePriceDisplay {
                    Text(price)
                        .font(.system(size: 18, weight: .bold))
                } else if let listPrice = listPrice {
                    Text(formatPrice(listPrice))
                        .font(.system(size: 18, weight: .bold))
                } else {
                    Text("N/A")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 50)

            // Region
            VStack(spacing: 2) {
                Text("Region")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(wine.region ?? wine.country ?? "Unknown")
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }

    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
}

// MARK: - Score Arc View

struct ScoreArcView: View {
    let score: Int?

    private var scoreColor: Color {
        guard let score = score else { return .gray }
        switch score {
        case 95...100: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case 90...94: return Color(red: 0.4, green: 0.75, blue: 0.3)
        case 85...89: return Color(red: 0.9, green: 0.7, blue: 0.2)
        case 80...84: return Color(red: 0.95, green: 0.5, blue: 0.2)
        default: return Color(red: 0.9, green: 0.3, blue: 0.25)
        }
    }

    private var progress: Double {
        guard let score = score else { return 0 }
        return Double(score - 50) / 50.0 // 50-100 range
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0.0, to: 0.75)
                    .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(135))
                    .frame(width: 60, height: 60)

                // Progress arc
                Circle()
                    .trim(from: 0.0, to: progress * 0.75)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(135))
                    .frame(width: 60, height: 60)

                // Score text
                VStack(spacing: -2) {
                    Text(score.map { "\($0)" } ?? "N/A")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    if score != nil {
                        Text("pts")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Tab Picker

struct TabPicker: View {
    @Binding var selectedTab: WineDetailSheet.DetailTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(WineDetailSheet.DetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? Theme.primaryColor : .secondary)

                        Rectangle()
                            .fill(selectedTab == tab ? Theme.primaryColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 1)
            }
        )
    }
}

// MARK: - Tab Content

struct TabContent: View {
    let selectedTab: WineDetailSheet.DetailTab
    let wine: Wine
    let listPrice: Decimal?
    let valueRatio: Double?

    var body: some View {
        switch selectedTab {
        case .details:
            DetailsTabContent(wine: wine, listPrice: listPrice, valueRatio: valueRatio)
        case .tastingNote:
            TastingNoteTabContent(wine: wine)
        }
    }
}

// MARK: - Details Tab Content

struct DetailsTabContent: View {
    let wine: Wine
    let listPrice: Decimal?
    let valueRatio: Double?

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Wine Info Card
            InfoCard(wine: wine)

            // Value Card (if applicable)
            if let ratio = valueRatio {
                ValueCard(ratio: ratio, listPrice: listPrice, releasePrice: wine.releasePrice)
            }

            // Grape Varieties
            if !wine.grapeVarieties.isEmpty {
                GrapeVarietiesCard(grapes: wine.grapeVarieties)
            }
        }
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let wine: Wine

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Type & Country Row
            HStack {
                InfoPill(icon: "drop.fill", text: wine.color.displayName, color: Theme.primaryColor)
                InfoPill(icon: "globe", text: wine.country ?? "Unknown", color: .blue)
                Spacer()
            }

            // Drink Window
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(.purple)
                Text("Drink")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text(wine.drinkWindowDisplay)
                    .font(.system(size: 14, weight: .semibold))

                if wine.drinkWindowStatus != .ready {
                    DrinkWindowStatusBadge(status: wine.drinkWindowStatus)
                }
            }

            // Alcohol if available
            if let alcohol = wine.alcohol {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "percent")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    Text("Alcohol")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", alcohol))
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Info Pill

struct InfoPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Drink Window Status Badge

struct DrinkWindowStatusBadge: View {
    let status: DrinkWindowStatus

    private var color: Color {
        switch status {
        case .tooYoung: return .orange
        case .ready: return .green
        case .peaking: return .green
        case .pastPrime: return .red
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.system(size: 10))
            Text(status.displayText)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(color))
    }
}

// MARK: - Value Card

struct ValueCard: View {
    let ratio: Double
    let listPrice: Decimal?
    let releasePrice: Decimal?

    private var valueColor: Color {
        ratio < 2.0 ? .green : (ratio < 3.0 ? .orange : .red)
    }

    private var valueText: String {
        ratio < 2.0 ? "Great Value" : (ratio < 3.0 ? "Fair Value" : "High Markup")
    }

    var body: some View {
        HStack {
            // Value Gauge
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14))
                        .foregroundColor(valueColor)
                    Text(valueText)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(valueColor)
                }
                Text(String(format: "%.1fx markup from release", ratio))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Mini gauge
            ValueGauge(ratio: ratio)
                .frame(width: 60, height: 30)
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(valueColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(valueColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Value Gauge

struct ValueGauge: View {
    let ratio: Double

    private var color: Color {
        ratio < 2.0 ? .green : (ratio < 3.0 ? .orange : .red)
    }

    private var needlePosition: Double {
        min(1.0, max(0.0, (ratio - 1.0) / 4.0)) // 1x to 5x range
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background arc
                Path { path in
                    path.addArc(center: CGPoint(x: geo.size.width / 2, y: geo.size.height),
                               radius: geo.size.width / 2 - 4,
                               startAngle: .degrees(180),
                               endAngle: .degrees(0),
                               clockwise: false)
                }
                .stroke(
                    LinearGradient(colors: [.green, .yellow, .orange, .red],
                                  startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )

                // Needle
                let angle = 180 - (needlePosition * 180)
                let needleLength = geo.size.width / 2 - 8
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height)
                let needleEnd = CGPoint(
                    x: center.x + needleLength * cos(angle * .pi / 180),
                    y: center.y - needleLength * sin(angle * .pi / 180)
                )

                Path { path in
                    path.move(to: center)
                    path.addLine(to: needleEnd)
                }
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))

                Circle()
                    .fill(Color.primary)
                    .frame(width: 6, height: 6)
                    .position(center)
            }
        }
    }
}

// MARK: - Grape Varieties Card

struct GrapeVarietiesCard: View {
    let grapes: [GrapeVariety]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                Text("Grape Varieties")
                    .font(.system(size: 15, weight: .semibold))
            }

            FlowLayout(spacing: 8) {
                ForEach(grapes, id: \.name) { grape in
                    GrapeChip(grape: grape)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Grape Chip

struct GrapeChip: View {
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
        .background(Capsule().fill(Color(.systemGray6)))
    }
}

// MARK: - Tasting Note Tab Content

struct TastingNoteTabContent: View {
    let wine: Wine
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            if let note = wine.tastingNote, !note.isEmpty {
                // Tasting Note Card
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    // Quote icon
                    Image(systemName: "quote.opening")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.secondaryColor.opacity(0.5))

                    // Note text
                    Text(note)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .lineSpacing(8)
                        .lineLimit(isExpanded ? nil : 6)
                        .foregroundColor(.primary)

                    // Read more
                    if note.count > 250 {
                        Button(action: { withAnimation { isExpanded.toggle() } }) {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "Show Less" : "Read More")
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.primaryColor)
                        }
                    }

                    // Reviewer attribution
                    if let reviewer = wine.reviewer {
                        HStack(spacing: Theme.Spacing.sm) {
                            // Reviewer initials avatar
                            Text(reviewer.initials)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Theme.primaryColor))

                            VStack(alignment: .leading, spacing: 2) {
                                if let name = reviewer.name {
                                    Text(name)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                if let date = wine.issueDate {
                                    Text(formatDate(date))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, Theme.Spacing.sm)
                    }
                }
                .padding(Theme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )
            } else {
                // No tasting note
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No tasting note available")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xxl)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Action Buttons

struct ActionButtons: View {
    @Binding var isSaved: Bool
    var isSaving: Bool = false
    let onSave: () -> Void
    let onShare: () -> Void

    var body: some View {
        Button(action: {
            guard !isSaving && !isSaved else { return }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onSave()
        }) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.primaryColor))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(isSaving ? "Saving..." : (isSaved ? "Saved to My Wines" : "Save to My Wines"))
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(isSaved ? .white : Theme.primaryColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSaved ? Theme.primaryColor : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Theme.primaryColor, lineWidth: isSaved ? 0 : 2)
                    )
            )
        }
        .disabled(isSaved || isSaving)
    }
}

// MARK: - Brand Footer

struct BrandFooter: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                WineSpectatorLogo(variant: .black, height: 18)
            }
            Text("Expert ratings & reviews")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Theme.Spacing.md)
    }
}

// MARK: - Flow Layout

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
