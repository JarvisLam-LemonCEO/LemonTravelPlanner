import Foundation
import SwiftData

@Model
final class Activity {
    var id: UUID
    var name: String
    var activityDescription: String
    var category: String

    var startTime: Date
    var endTime: Date

    var locationName: String
    var latitude: Double?
    var longitude: Double?

    var admissionFee: Double
    var transportationCost: Double
    var bookingURL: String?

    var isLocked: Bool
    var sortOrder: Int

    var tripDay: TripDay?

    init(
        id: UUID = UUID(),
        name: String,
        activityDescription: String = "",
        category: String = ActivityCategory.attraction.rawValue,
        startTime: Date,
        endTime: Date,
        locationName: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        admissionFee: Double = 0,
        transportationCost: Double = 0,
        bookingURL: String? = nil,
        isLocked: Bool = false,
        sortOrder: Int = 0,
        tripDay: TripDay? = nil
    ) {
        self.id = id
        self.name = name
        self.activityDescription = activityDescription
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.admissionFee = admissionFee
        self.transportationCost = transportationCost
        self.bookingURL = bookingURL
        self.isLocked = isLocked
        self.sortOrder = sortOrder
        self.tripDay = tripDay
    }
}
