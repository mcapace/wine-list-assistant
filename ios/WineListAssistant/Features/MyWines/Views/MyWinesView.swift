import SwiftUI

struct MyWinesView: View {
    @StateObject private var viewModel = MyWinesViewModel()
    @State private var searchText = ""
    @State private var selectedWine: SavedWine?
    @State private var selectedFilter: WineListFilter = .all

    enum WineListFilter: String, CaseIterable {
        case all = "All"
        case top = "95+"
        case recent = "Recent"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .top: return "star.fill"
            case .recent: return "clock"
            }
        }
    }

    var filteredWines: [SavedWine] {
        var wines = viewModel.savedWines

        // Apply text search
        if !searchText.isEmpty {
            wines = wines.filter { saved in
                saved.wine.fullName.localizedCaseInsensitiveContains(searchText) ||
                saved.wine.region.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .top:
            wines = wines.filter { $0.wine.score >= 95 }
        case .recent:
            wines = wines.sorted { $0.addedAt > $1.addedAt }
        }

        return wines
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with branding
                    MyWinesHeader()

                    // Filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(WineListFilter.allCases, id: \.self) { filter in
                                FilterPill(
                                    title: filter.rawValue,
                                    icon: filter.icon,
                                    isSelected: selectedFilter == filter
                                ) {
                                    withAnimation { selectedFilter = filter }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemBackground))

                    // Content
                    Group {
                        if viewModel.isLoading && viewModel.savedWines.isEmpty {
                            LoadingWinesView()
                        } else if viewModel.savedWines.isEmpty {
                            EmptyWinesView()
                        } else if filteredWines.isEmpty {
                            NoResultsView(searchText: searchText)
                        } else {
                            wineList
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .searchable(text: $searchText, prompt: "Search your wines")
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
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredWines) { saved in
                    SavedWineCard(savedWine: saved)
                        .onTapGesture {
                            selectedWine = saved
                        }
                }
            }
            .padding()
        }
    }
}

// MARK: - Header

struct MyWinesHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Wines")
                    .font(.system(size: 28, weight: .bold))
                Text("Your personal collection")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Wine Lens badge
            WineLensBadge(style: .dark)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.primaryColor : Color(.systemGray6))
            )
        }
    }
}

// MARK: - Wine Card

struct SavedWineCard: View {
    let savedWine: SavedWine

    var body: some View {
        HStack(spacing: 14) {
            // Score badge
            ZStack {
                Circle()
                    .fill(Theme.scoreColor(for: savedWine.wine.score).opacity(0.15))
                    .frame(width: 56, height: 56)

                Text("\(savedWine.wine.score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.scoreColor(for: savedWine.wine.score))
            }

            // Wine info
            VStack(alignment: .leading, spacing: 4) {
                Text(savedWine.wine.producer)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(savedWine.wine.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let vintage = savedWine.wine.vintage {
                        Label("\(vintage)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Label(savedWine.wine.region, systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Empty State

struct EmptyWinesView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.primaryColor.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "heart")
                    .font(.system(size: 44))
                    .foregroundColor(Theme.primaryColor)
            }

            Text("No Saved Wines Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("When you scan a wine list, tap the heart\nto save your favorite bottles here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Hint
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Theme.secondaryColor)
                Text("Tip: Go to Scan tab to find wines")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(40)
    }
}

// MARK: - Loading State

struct LoadingWinesView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading your wines...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - No Results

struct NoResultsView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No wines match \"\(searchText)\"")
                .font(.headline)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        Text("\(vintage)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(savedWine.wine.region)
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
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Score Header
                    ScoreHeader(
                        wine: savedWine.wine,
                        confidence: 1.0
                    )

                    // Wine Info
                    WineInfoSection(wine: savedWine.wine)

                    // Tasting Note
                    if !savedWine.wine.tastingNote.isEmpty {
                        TastingNoteSection(note: savedWine.wine.tastingNote)
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

// MARK: - Preview

#Preview {
    MyWinesView()
}
