import Foundation
import SwiftData

@Model
final class TransportationSegment {
    var id: UUID

    var sourceActivityID: UUID
    var destinationActivityID: UUID

    var sourceName: String
    var destinationName: String

    var travelMode: String
    var distanceMeters: Double
    var durationSeconds: Double
    var estimatedCost: Double

    var sortOrder: Int
    var lastUpdatedAt: Date

    var tripDay: TripDay?

    init(
        id: UUID = UUID(),
        sourceActivityID: UUID,
        destinationActivityID: UUID,
        sourceName: String,
        destinationName: String,
        travelMode: String,
        distanceMeters: Double,
        durationSeconds: Double,
        estimatedCost: Double = 0,
        sortOrder: Int,
        lastUpdatedAt: Date = Date(),
        tripDay: TripDay? = nil
    ) {
        self.id = id
        self.sourceActivityID = sourceActivityID
        self.destinationActivityID = destinationActivityID
        self.sourceName = sourceName
        self.destinationName = destinationName
        self.travelMode = travelMode
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.estimatedCost = estimatedCost
        self.sortOrder = sortOrder
        self.lastUpdatedAt = lastUpdatedAt
        self.tripDay = tripDay
    }

    var formattedDuration: String {
        let totalMinutes = max(
            Int(durationSeconds / 60),
            1
        )

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }

        return "\(minutes) min"
    }

    var formattedDistance: String {
        if distanceMeters >= 1_000 {
            return String(
                format: "%.1f km",
                distanceMeters / 1_000
            )
        }

        return "\(Int(distanceMeters)) m"
    }
}
