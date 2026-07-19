import SwiftUI
import MapKit

struct SelectedPlace {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

struct PlaceSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var searchService =
        PlaceSearchService()

    @State private var searchText = ""

    let onPlaceSelected: (SelectedPlace) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search for a Place",
                        systemImage: "magnifyingglass",
                        description: Text(
                            "Search for an attraction, hotel, restaurant, or address."
                        )
                    )
                } else if searchService.isSearching {
                    ProgressView("Searching...")
                } else if searchService.suggestions.isEmpty {
                    ContentUnavailableView.search(
                        text: searchText
                    )
                } else {
                    List(
                        searchService.suggestions,
                        id: \.self
                    ) { suggestion in
                        Button {
                            selectPlace(suggestion)
                        } label: {
                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {
                                Text(suggestion.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: "Search places"
            )
            .onChange(of: searchText) {
                searchService.updateSearchText(
                    searchText
                )
            }
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(
                "Search Error",
                isPresented: Binding(
                    get: {
                        searchService.errorMessage != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            searchService.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    searchService.errorMessage = nil
                }
            } message: {
                Text(
                    searchService.errorMessage
                    ?? "Unable to search for places."
                )
            }
        }
    }

    private func selectPlace(
        _ completion: MKLocalSearchCompletion
    ) {
        Task {
            guard let mapItem =
                await searchService.resolve(completion)
            else {
                return
            }

            let coordinate =
                mapItem.placemark.coordinate

            let address = [
                mapItem.placemark.subThoroughfare,
                mapItem.placemark.thoroughfare,
                mapItem.placemark.locality,
                mapItem.placemark.administrativeArea,
                mapItem.placemark.country
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

            let selectedPlace = SelectedPlace(
                name: mapItem.name
                    ?? completion.title,
                address: address,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

            onPlaceSelected(selectedPlace)
            searchService.clearSuggestions()
            dismiss()
        }
    }
}
