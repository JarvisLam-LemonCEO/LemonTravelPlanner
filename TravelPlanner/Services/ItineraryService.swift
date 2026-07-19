import Foundation

protocol ItineraryService {
    func generateItinerary(
        for trip: Trip
    ) async throws -> GeneratedItineraryResponse
}
