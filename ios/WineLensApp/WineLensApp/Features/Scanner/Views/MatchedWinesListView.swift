import SwiftUI

/// Beautiful scrollable list view showing all matched wines from the scan
struct MatchedWinesListView: View {
    let matchedWines: [RecognizedWine]
    let onWineTapped: (RecognizedWine) -> Void
    @Environment(\.dismiss) private var dismiss
    
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
                            SummaryHeaderView(count: matchedWines.count)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            // Wine cards
                            ForEach(matchedWines) { recognizedWine in
                                MatchedWineCard(recognizedWine: recognizedWine)
                                    .padding(.horizontal, 20)
                                    .onTapGesture {
                                        onWineTapped(recognizedWine)
                                    }
                            }
                            
                            // Bottom padding
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.vertical, 8)
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
    }
}

// MARK: - Summary Header

struct SummaryHeaderView: View {
    let count: Int
    
    var body: some View {
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
            
            // Decorative icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(Theme.secondaryColor.opacity(0.8))
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

// MARK: - Matched Wine Card

struct MatchedWineCard: View {
    let recognizedWine: RecognizedWine
    @State private var isPressed = false
    
    private var wine: Wine? {
        recognizedWine.matchedWine
    }
    
    var body: some View {
        Group {
            if let wine = wine {
                HStack(spacing: 16) {
                    // Score badge - prominent
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.scoreColor(for: wine.score).opacity(0.25),
                                        Theme.scoreColor(for: wine.score).opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Theme.scoreColor(for: wine.score).opacity(0.4), lineWidth: 2)
                            )
                        
                        VStack(spacing: 2) {
                            Text("\(wine.score)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.scoreColor(for: wine.score))
                            
                            Text(wine.reviewer.initials)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Theme.scoreColor(for: wine.score).opacity(0.8))
                        }
                    }
                    
                    // Wine information
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
                                Label("\(vintage)", systemImage: "calendar")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Label(wine.region, systemImage: "mappin.circle.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
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
                        }
                    }
                    
                    Spacer()
                    
                    // Confidence indicator and chevron
                    VStack(spacing: 8) {
                        if recognizedWine.hasLowConfidence {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(20)
                .background(
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
                )
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                .shadow(color: Theme.secondaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
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

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wineglass")
                .font(.system(size: 64))
                .foregroundColor(Theme.secondaryColor.opacity(0.5))
            
            Text("No Matches Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Keep scanning to find wines from your list")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Preview

#Preview {
    MatchedWinesListView(
        matchedWines: [
            RecognizedWine.preview,
            RecognizedWine.previewLowConfidence
        ],
        onWineTapped: { _ in }
    )
}

