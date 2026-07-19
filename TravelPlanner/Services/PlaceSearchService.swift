import Foundation
import MapKit
import Combine

@MainActor
final class PlaceSearchService: NSObject, ObservableObject {
    @Published private(set) var suggestions: [MKLocalSearchCompletion] = []
    @Published private(set) var isSearching = false
    @Published var errorMessage: String?

    private let completer: MKLocalSearchCompleter

    override init() {
        let completer = MKLocalSearchCompleter()
        self.completer = completer

        super.init()

        completer.delegate = self
        completer.resultTypes = [
            .address,
            .pointOfInterest
        ]
    }

    func updateSearchText(_ text: String) {
        let cleanedText = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedText.isEmpty else {
            clearSuggestions()
            return
        }

        completer.queryFragment = cleanedText
    }

    func clearSuggestions() {
        suggestions = []
        completer.queryFragment = ""
    }

    func resolve(
        _ completion: MKLocalSearchCompletion
    ) async -> MKMapItem? {
        isSearching = true
        errorMessage = nil

        defer {
            isSearching = false
        }

        let request = MKLocalSearch.Request(
            completion: completion
        )

        let search = MKLocalSearch(
            request: request
        )

        do {
            let response = try await search.start()

            guard let mapItem = response.mapItems.first else {
                errorMessage = "No matching place was found."
                return nil
            }

            return mapItem
        } catch is CancellationError {
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

extension PlaceSearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(
        _ completer: MKLocalSearchCompleter
    ) {
        let results = completer.results

        Task { @MainActor [weak self] in
            self?.suggestions = results
        }
    }

    nonisolated func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        let message = error.localizedDescription

        Task { @MainActor [weak self] in
            self?.suggestions = []
            self?.errorMessage = message
        }
    }
}
