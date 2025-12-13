import SwiftUI

struct MyWinesView: View {
    @StateObject private var viewModel = MyWinesViewModel()
    @State private var searchText = ""
    @State private var selectedWine: SavedWine?

    var filteredWines: [SavedWine] {
        if searchText.isEmpty {
            return viewModel.savedWines
        }
        return viewModel.savedWines.filter { saved in
            saved.wine.fullName.localizedCaseInsensitiveContains(searchText) ||
            (saved.wine.region?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.savedWines.isEmpty {
                    ProgressView("Loading wines...")
                } else if viewModel.savedWines.isEmpty {
                    EmptyWinesView()
                } else {
                    wineList
                }
            }
            .navigationTitle("My Wines")
            .searchable(text: $searchText, prompt: "Search wines")
            .refreshable {
                await viewModel.loadSavedWines()
            }
        }
        .task {
            await viewModel.loadSavedWines()
        }
        .sheet(item: $selectedWine) { saved in
            SavedWineDetailView(savedWine: saved, onDelete: {
                Task {
                    await viewModel.deleteWine(saved)
                }
            })
        }
    }

    private var wineList: some View {
        List {
            ForEach(filteredWines) { saved in
                SavedWineRow(savedWine: saved)
                    .onTapGesture {
                        selectedWine = saved
                    }
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await viewModel.deleteWine(filteredWines[index])
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Empty State

struct EmptyWinesView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Saved Wines")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Wines you save while scanning will appear here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Wine Row

struct SavedWineRow: View {
    let savedWine: SavedWine

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Score badge
            ScoreBadge(score: savedWine.wine.score, size: .medium)

            // Wine info
            VStack(alignment: .leading, spacing: 4) {
                Text(savedWine.wine.producer)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(savedWine.wine.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let vintage = savedWine.wine.vintage {
                        Text(String(vintage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(savedWine.wine.region ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Context info
            VStack(alignment: .trailing, spacing: 4) {
                if let restaurant = savedWine.context?.restaurant {
                    Text(restaurant)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text(savedWine.addedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Saved Wine Detail

struct SavedWineDetailView: View {
    let savedWine: SavedWine
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Score Header
                    PremiumScoreHeader(
                        wine: savedWine.wine,
                        confidence: 1.0
                    )

                    // Wine Info
                    PremiumWineInfoSection(wine: savedWine.wine)

                    // Tasting Note
                    if let note = savedWine.wine.tastingNote, !note.isEmpty {
                        PremiumTastingNoteSection(note: note)
                    }

                    // User Notes
                    if let notes = savedWine.notes, !notes.isEmpty {
                        UserNotesSection(notes: notes)
                    }

                    // Context
                    if let context = savedWine.context {
                        ContextSection(context: context)
                    }

                    // Delete button
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Remove from My Wines", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Wine Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Remove this wine?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

struct UserNotesSection: View {
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("My Notes")
                .font(Theme.Typography.headline)

            Text(notes)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct ContextSection: View {
    let context: SavedWine.SaveContext

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Where I Had It")
                .font(Theme.Typography.headline)

            if let restaurant = context.restaurant {
                InfoItem(label: "Restaurant", value: restaurant)
            }

            if let price = context.pricePaidDisplay {
                InfoItem(label: "Price Paid", value: price)
            }

            if let date = context.date {
                InfoItem(label: "Date", value: date.formatted(date: .long, time: .omitted))
            }

            if let rating = context.rating {
                HStack {
                    Text("My Rating")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Info Item

struct InfoItem: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Premium Score Header (for saved wine detail)

struct PremiumScoreHeader: View {
    let wine: Wine
    let confidence: Double

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
        VStack(spacing: Theme.Spacing.md) {
            // Score
            if let score = wine.score {
                ZStack {
                    Circle()
                        .fill(headerColor)
                        .frame(width: 80, height: 80)
                    VStack(spacing: -2) {
                        Text("\(score)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("pts")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }

            // Wine Name
            VStack(spacing: 4) {
                Text(wine.producer)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)

                if wine.name.lowercased() != wine.producer.lowercased() {
                    Text(wine.name)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let vintage = wine.vintage {
                    Text(String(vintage))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

// MARK: - Premium Wine Info Section

struct PremiumWineInfoSection: View {
    let wine: Wine

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Wine Details")
                .font(Theme.Typography.headline)

            InfoItem(label: "Type", value: wine.color.displayName)

            if let region = wine.region {
                InfoItem(label: "Region", value: region)
            }

            if let country = wine.country {
                InfoItem(label: "Country", value: country)
            }

            if let alcohol = wine.alcohol {
                InfoItem(label: "Alcohol", value: String(format: "%.1f%%", alcohol))
            }

            InfoItem(label: "Drink Window", value: wine.drinkWindowDisplay)

            if let price = wine.releasePriceDisplay {
                InfoItem(label: "Release Price", value: price)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Premium Tasting Note Section

struct PremiumTastingNoteSection: View {
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Tasting Note")
                .font(Theme.Typography.headline)

            Text(note)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Preview

#Preview {
    MyWinesView()
}
