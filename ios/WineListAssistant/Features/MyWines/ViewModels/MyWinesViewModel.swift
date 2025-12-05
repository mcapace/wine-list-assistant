import Foundation
import Combine

@MainActor
final class MyWinesViewModel: ObservableObject {
    @Published var savedWines: [SavedWine] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let apiClient = WineAPIClient.shared

    func loadSavedWines() async {
        isLoading = true
        error = nil

        do {
            savedWines = try await apiClient.getSavedWines()
        } catch {
            self.error = error
            print("Failed to load saved wines: \(error)")
        }

        isLoading = false
    }

    func deleteWine(_ savedWine: SavedWine) async {
        do {
            try await apiClient.deleteSavedWine(savedId: savedWine.id)
            savedWines.removeAll { $0.id == savedWine.id }
        } catch {
            self.error = error
            print("Failed to delete wine: \(error)")
        }
    }
}
