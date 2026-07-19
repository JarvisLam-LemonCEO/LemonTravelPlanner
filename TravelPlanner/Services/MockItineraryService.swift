import Foundation

struct MockItineraryService: ItineraryService {
    func generateItinerary(
        for trip: Trip
    ) async throws -> GeneratedItineraryResponse {
        try await Task.sleep(
            for: .seconds(2)
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let calendar = Calendar.current

        let days = (0..<trip.durationInDays).compactMap {
            index -> GeneratedDay? in

            guard let date = calendar.date(
                byAdding: .day,
                value: index,
                to: trip.startDate
            ) else {
                return nil
            }

            return GeneratedDay(
                dayNumber: index + 1,
                date: formatter.string(from: date),
                city: trip.destination,
                hotelCost: 150,
                foodCost: 60,
                activities: sampleActivities(
                    for: date,
                    destination: trip.destination
                )
            )
        }

        return GeneratedItineraryResponse(
            summary:
                "A personalized \(trip.durationInDays)-day itinerary for \(trip.destination).",
            days: days
        )
    }

    private func sampleActivities(
        for date: Date,
        destination: String
    ) -> [GeneratedActivity] {
        [
            GeneratedActivity(
                name: "Historic City Center",
                description:
                    "Explore important landmarks and the surrounding neighborhood.",
                category: "attraction",
                startTime: "09:00",
                endTime: "11:30",
                locationName: destination,
                latitude: nil,
                longitude: nil,
                admissionFee: 20,
                transportationCost: 5
            ),
            GeneratedActivity(
                name: "Local Lunch",
                description:
                    "Try a well-known local restaurant or food market.",
                category: "food",
                startTime: "12:30",
                endTime: "14:00",
                locationName: destination,
                latitude: nil,
                longitude: nil,
                admissionFee: 0,
                transportationCost: 5
            ),
            GeneratedActivity(
                name: "Popular Museum",
                description:
                    "Visit a popular museum suited to the selected interests.",
                category: "museums",
                startTime: "15:00",
                endTime: "17:30",
                locationName: destination,
                latitude: nil,
                longitude: nil,
                admissionFee: 25,
                transportationCost: 5
            )
        ]
    }
}
