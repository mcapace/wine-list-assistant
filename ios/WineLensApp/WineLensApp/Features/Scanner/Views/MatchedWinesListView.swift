import SwiftUI
import UIKit

/// Beautiful scrollable list view showing all matched wines from the scan
struct MatchedWinesListView: View {
    let matchedWines: [RecognizedWine]
    let onWineTapped: (RecognizedWine) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var sortOption: SortOption = .score
    @State private var expandedCardId: UUID?
    
    enum SortOption: String, CaseIterable {
        case score = "By Score"
        case value = "By Value"
        case price = "By Price"
    }
    
    var sortedWines: [RecognizedWine] {
        let sorted: [RecognizedWine]
        switch sortOption {
        case .score:
            sorted = matchedWines.sorted { ($0.matchedWine?.score ?? 0) > ($1.matchedWine?.score ?? 0) }
        case .value:
            sorted = matchedWines.sorted { 
                let value1 = $0.valueRatio ?? Double.infinity
                let value2 = $1.valueRatio ?? Double.infinity
                return value1 < value2
            }
        case .price:
            sorted = matchedWines.sorted {
                let price1 = $0.listPrice ?? Decimal(0)
                let price2 = $1.listPrice ?? Decimal(0)
                return price1 < price2
            }
        }
        
        // Group by score category
        return sorted
    }
    
    var groupedWines: [(ScoreCategory, [RecognizedWine])] {
        var groups: [ScoreCategory: [RecognizedWine]] = [:]
        
        for wine in sortedWines {
            guard let score = wine.matchedWine?.score else { continue }
            let category = ScoreCategory(score: score)
            groups[category, default: []].append(wine)
        }
        
        // Return in order: Outstanding, Excellent, Very Good, Good, etc.
        let orderedCategories: [ScoreCategory] = [.outstanding, .excellent, .veryGood, .good, .acceptable, .belowAverage]
        return orderedCategories.compactMap { category in
            guard let wines = groups[category], !wines.isEmpty else { return nil }
            return (category, wines)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.95),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if matchedWines.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Header summary
                            SummaryHeaderView(wines: matchedWines)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            // Sort options
                            SortOptionsView(selectedOption: $sortOption)
                                .padding(.horizontal, 20)
                            
                            // Grouped wine cards
                            ForEach(Array(groupedWines.enumerated()), id: \.element.0) { index, group in
                                SectionHeader(category: group.0)
                                    .padding(.horizontal, 20)
                                    .padding(.top, index == 0 ? 0 : 16)
                                
                                ForEach(Array(group.1.enumerated()), id: \.element.id) { cardIndex, recognizedWine in
                                    MatchedWineCard(
                                        recognizedWine: recognizedWine,
                                        isExpanded: expandedCardId == recognizedWine.id,
                                        onTap: {
                                            onWineTapped(recognizedWine)
                                        },
                                        onLongPress: {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                if expandedCardId == recognizedWine.id {
                                                    expandedCardId = nil
                                                } else {
                                                    expandedCardId = recognizedWine.id
                                                }
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 20)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .top)),
                                        removal: .opacity
                                    ))
                                    .animation(
                                        .spring(response: 0.4, dampingFraction: 0.8)
                                        .delay(Double(cardIndex) * 0.05),
                                        value: cardIndex
                                    )
                                }
                            }
                            
                            // Bottom padding
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.vertical, 8)
                    }
                    .refreshable {
                        // Re-sort on pull to refresh
                        withAnimation {
                            // Trigger refresh by changing sort option temporarily
                            let current = sortOption
                            sortOption = current == .score ? .value : .score
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                sortOption = current
                            }
                        }
                    }
                }
            }
            .navigationTitle("Matched Wines")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.secondaryColor)
                }
            }
        }
        .onTapGesture {
            // Collapse expanded card when tapping elsewhere
            if expandedCardId != nil {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    expandedCardId = nil
                }
            }
        }
    }
}

// MARK: - Sort Options View

struct SortOptionsView: View {
    @Binding var selectedOption: MatchedWinesListView.SortOption
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(MatchedWinesListView.SortOption.allCases, id: \.self) { option in
                Button(action: {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedOption = option
                    }
                }) {
                    Text(option.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedOption == option ? .black : .white.opacity(0.8))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedOption == option ? Theme.secondaryColor : Color.white.opacity(0.15))
                        )
                }
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let category: ScoreCategory
    
    var body: some View {
        HStack {
            Text(category.displayName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(category.rangeText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            // Accent line
            Rectangle()
                .fill(accentColor)
                .frame(width: 40, height: 2)
        }
        .padding(.vertical, 8)
    }
    
    private var accentColor: Color {
        switch category {
        case .outstanding:
            return Color.yellow.opacity(0.8) // Gold
        case .excellent:
            return Color.gray.opacity(0.6) // Silver
        case .veryGood:
            return Theme.secondaryColor.opacity(0.6)
        default:
            return Theme.secondaryColor.opacity(0.4)
        }
    }
}

extension ScoreCategory {
    var rangeText: String {
        switch self {
        case .outstanding: return "(95+)"
        case .excellent: return "(90-94)"
        case .veryGood: return "(85-89)"
        case .good: return "(80-84)"
        case .acceptable: return "(75-79)"
        case .belowAverage: return "(<75)"
        }
    }
}

// MARK: - Summary Header

struct SummaryHeaderView: View {
    let wines: [RecognizedWine]

    private var count: Int { wines.count }

    private var outstandingCount: Int {
        wines.filter { ($0.matchedWine?.score ?? 0) >= 95 }.count
    }

    private var excellentCount: Int {
        wines.filter {
            let score = $0.matchedWine?.score ?? 0
            return score >= 90 && score < 95
        }.count
    }

    private var bestValueCount: Int {
        wines.filter { $0.isBestValue }.count
    }

    private var avgScore: Int {
        let scores = wines.compactMap { $0.matchedWine?.score }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / scores.count
    }

    var body: some View {
        VStack(spacing: 16) {
            // Main title row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(count) wine\(count == 1 ? "" : "s") found")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Tap any wine for details")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Average score badge
                if avgScore > 0 {
                    VStack(spacing: 2) {
                        Text("\(avgScore)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.scoreColor(for: avgScore))
                        Text("avg")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(Theme.scoreColor(for: avgScore).opacity(0.2))
                            .overlay(
                                Circle()
                                    .stroke(Theme.scoreColor(for: avgScore).opacity(0.4), lineWidth: 2)
                            )
                    )
                }
            }

            // Stats row
            if outstandingCount > 0 || excellentCount > 0 || bestValueCount > 0 {
                HStack(spacing: 12) {
                    if outstandingCount > 0 {
                        StatBadge(
                            count: outstandingCount,
                            label: "Outstanding",
                            color: .yellow,
                            icon: "star.fill"
                        )
                    }

                    if excellentCount > 0 {
                        StatBadge(
                            count: excellentCount,
                            label: "Excellent",
                            color: .gray,
                            icon: "medal.fill"
                        )
                    }

                    if bestValueCount > 0 {
                        StatBadge(
                            count: bestValueCount,
                            label: "Best Value",
                            color: .green,
                            icon: "tag.fill"
                        )
                    }

                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.secondaryColor.opacity(0.2),
                            Theme.secondaryColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.secondaryColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text("\(count)")
                .font(.system(size: 13, weight: .bold))
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Matched Wine Card

struct MatchedWineCard: View {
    let recognizedWine: RecognizedWine
    let isExpanded: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    
    private var wine: Wine? {
        recognizedWine.matchedWine
    }
    
    private var tastingNotePreview: String {
        guard let note = wine?.tastingNote, !note.isEmpty else { return "" }
        if note.count <= 100 {
            return note
        }
        let index = note.index(note.startIndex, offsetBy: 100)
        return String(note[..<index]) + "..."
    }
    
    @ViewBuilder
    private var scoreBadge: some View {
        if let wine = wine, let score = wine.score {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.scoreColor(for: score).opacity(0.25),
                                Theme.scoreColor(for: score).opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Theme.scoreColor(for: score).opacity(0.4), lineWidth: 2)
                    )
                
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.scoreColor(for: score))
                    
                    if let reviewer = wine.reviewer {
                        Text(reviewer.initials)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.scoreColor(for: score).opacity(0.8))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var wineInfoSection: some View {
        if let wine = wine {
            VStack(alignment: .leading, spacing: 8) {
                // Producer
                Text(wine.producer)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                // Wine name
                Text(wine.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Vintage and region
                HStack(spacing: 12) {
                    if let vintage = wine.vintage {
                        Label(String(vintage), systemImage: "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    if let region = wine.region {
                        Label(region, systemImage: "mappin.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                
                // Tasting note preview (2 lines max)
                if !isExpanded && !tastingNotePreview.isEmpty {
                    Text(tastingNotePreview)
                        .font(.system(size: 14))
                        .italic()
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(2)
                        .padding(.top, 4)
                }
                
                // Price and value indicators
                HStack(spacing: 12) {
                    if let listPrice = recognizedWine.listPrice {
                        Text(formatPrice(listPrice))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.secondaryColor)
                    }

                    if recognizedWine.isBestValue {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                            Text("Best Value")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.8))
                        )
                    }

                    if let ratio = recognizedWine.valueRatio {
                        ValueIndicatorBadge(ratio: ratio)
                    }

                    // Show drink window status if available
                    if wine.drinkWindowStatus != .ready {
                        DrinkStatusBadge(status: wine.drinkWindowStatus)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    @ViewBuilder
    private var confidenceIndicator: some View {
        VStack(spacing: 8) {
            if recognizedWine.hasLowConfidence {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
    }
    
    @ViewBuilder
    private var expandedContent: some View {
        if isExpanded, let wine = wine {
            VStack(alignment: .leading, spacing: 16) {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Full tasting note
                if let note = wine.tastingNote, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tasting Notes")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(note)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Drink window
                if wine.drinkWindowStart != nil || wine.drinkWindowEnd != nil {
                    HStack(spacing: 8) {
                        Image(systemName: wine.drinkWindowStatus.iconName)
                            .font(.system(size: 14))
                        Text("Drink Window: \(wine.drinkWindowDisplay)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                // Grape varieties
                if !wine.grapeVarieties.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Grape Varieties")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack {
                            ForEach(wine.grapeVarieties, id: \.name) { variety in
                                Text(variety.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    var body: some View {
        Group {
            if let wine = wine {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 16) {
                        scoreBadge
                        wineInfoSection
                        Spacer()
                        confidenceIndicator
                    }
                    .padding(20)
                    
                    expandedContent
                }
                .background(cardBackground)
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                .shadow(color: Theme.secondaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
            }
        }
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
                onTap()
            }
        }
        .onLongPressGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onLongPress()
        }
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
}

// MARK: - Value Indicator Badge

struct ValueIndicatorBadge: View {
    let ratio: Double
    
    var body: some View {
        let (color, text) = valueIndicator(for: ratio)
        
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.8))
        )
    }
    
    private func valueIndicator(for ratio: Double) -> (Color, String) {
        switch ratio {
        case ..<2.0:
            return (.green, "Great Value")
        case 2.0..<2.5:
            return (.blue, "Good Value")
        case 2.5..<3.5:
            return (.orange, "Fair")
        default:
            return (.red, "Premium")
        }
    }
}

// MARK: - Drink Status Badge

struct DrinkStatusBadge: View {
    let status: DrinkWindowStatus

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
        .background(
            Capsule()
                .fill(statusColor.opacity(0.8))
        )
    }

    private var statusColor: Color {
        switch status {
        case .tooYoung:
            return .purple
        case .peaking:
            return .orange
        case .pastPrime:
            return .red
        case .ready:
            return .green
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wineglass")
                .font(.system(size: 64))
                .foregroundColor(Theme.secondaryColor.opacity(0.5))
            
            Text("No wines matched yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                Text("Keep scanning to find wines from your list")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 8) {
                    TipRow(icon: "hand.raised.fill", text: "Hold steady")
                    TipRow(icon: "lightbulb.fill", text: "Ensure good lighting")
                    TipRow(icon: "arrow.down", text: "Move closer to text")
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.secondaryColor.opacity(0.7))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    MatchedWinesListView(
        matchedWines: [
            RecognizedWine.preview,
            RecognizedWine.previewLowConfidence
        ],
        onWineTapped: { _ in }
    )
}
#endif

