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
        } catch let apiError as WineAPIClient.APIError {
            // Handle unauthorized gracefully (user not logged in)
            if case .unauthorized = apiError {
                // User not authenticated - empty list is fine
                savedWines = []
                #if DEBUG
                print("ℹ️ User not authenticated, showing empty saved wines list")
                #endif
            } else {
                self.error = apiError
                #if DEBUG
                print("Failed to load saved wines: \(apiError)")
                #endif
            }
        } catch {
            self.error = error
            #if DEBUG
            print("Failed to load saved wines: \(error)")
            #endif
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
