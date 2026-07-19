import Foundation
import SwiftData

@Model
final class TripDay {
    var id: UUID
    var date: Date
    var city: String
    var dayNumber: Int
    var notes: String

    var hotelCost: Double
    var foodCost: Double
    var transportCost: Double
    var admissionCost: Double

    var trip: Trip?

    @Relationship(deleteRule: .cascade)
    var activities: [Activity]

    @Relationship(deleteRule: .cascade)
    var transportationSegments: [TransportationSegment]

    init(
        id: UUID = UUID(),
        date: Date,
        city: String,
        dayNumber: Int,
        notes: String = "",
        hotelCost: Double = 0,
        foodCost: Double = 0,
        transportCost: Double = 0,
        admissionCost: Double = 0,
        trip: Trip? = nil,
        activities: [Activity] = [],
        transportationSegments: [TransportationSegment] = []
    ) {
        self.id = id
        self.date = date
        self.city = city
        self.dayNumber = dayNumber
        self.notes = notes
        self.hotelCost = hotelCost
        self.foodCost = foodCost
        self.transportCost = transportCost
        self.admissionCost = admissionCost
        self.trip = trip
        self.activities = activities
        self.transportationSegments = transportationSegments
    }

    var estimatedTotal: Double {
        hotelCost
        + foodCost
        + transportCost
        + admissionCost
    }

    var sortedActivities: [Activity] {
        activities.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.startTime < $1.startTime
            }

            return $0.sortOrder < $1.sortOrder
        }
    }

    var sortedTransportationSegments: [TransportationSegment] {
        transportationSegments.sorted {
            $0.sortOrder < $1.sortOrder
        }
    }
}
