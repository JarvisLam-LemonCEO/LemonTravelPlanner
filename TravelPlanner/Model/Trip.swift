import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var title: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var budget: Double
    var currencyCode: String
    var travelPace: String
    var interests: [String]
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade)
    var days: [TripDay]

    init(
        id: UUID = UUID(),
        title: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        budget: Double,
        currencyCode: String = "USD",
        travelPace: String = "Moderate",
        interests: [String] = [],
        createdAt: Date = Date(),
        days: [TripDay] = []
    ) {
        self.id = id
        self.title = title
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.budget = budget
        self.currencyCode = currencyCode
        self.travelPace = travelPace
        self.interests = interests
        self.createdAt = createdAt
        self.days = days
    }
    
    var sortedDays: [TripDay] {
        days.sorted {
            $0.dayNumber < $1.dayNumber
        }
    }

    var estimatedTotal: Double {
        days.reduce(0) {
            $0 + $1.estimatedTotal
        }
    }

    var durationInDays: Int {
        let calendar = Calendar.current

        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        let difference = calendar.dateComponents(
            [.day],
            from: start,
            to: end
        ).day ?? 0

        return max(difference + 1, 1)
    }
}
