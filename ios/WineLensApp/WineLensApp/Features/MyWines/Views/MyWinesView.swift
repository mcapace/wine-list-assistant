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
            saved.wine.region.localizedCaseInsensitiveContains(searchText)
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

// MARK: - Preview

#Preview {
    MyWinesView()
}
