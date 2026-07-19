import Foundation
import SwiftData

@MainActor
final class ItineraryGenerator {
    private let service: any ItineraryService

    init(service: any ItineraryService) {
        self.service = service
    }

    func generate(
        trip: Trip,
        modelContext: ModelContext
    ) async throws {
        let response =
            try await service.generateItinerary(
                for: trip
            )

        removeExistingItinerary(
            from: trip,
            modelContext: modelContext
        )

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(
            identifier: .gregorian
        )
        dateFormatter.locale = Locale(
            identifier: "en_US_POSIX"
        )
        dateFormatter.timeZone = TimeZone(
            secondsFromGMT: 0
        )
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for generatedDay in response.days {
            guard let date = dateFormatter.date(
                from: generatedDay.date
            ) else {
                continue
            }

            let tripDay = TripDay(
                date: date,
                city: generatedDay.city,
                dayNumber: generatedDay.dayNumber,
                hotelCost: generatedDay.hotelCost,
                foodCost: generatedDay.foodCost,
                transportCost: 0,
                admissionCost: 0,
                trip: trip
            )

            modelContext.insert(tripDay)
            trip.days.append(tripDay)

            for (
                index,
                generatedActivity
            ) in generatedDay.activities.enumerated() {
                guard
                    let startTime = combinedDate(
                        date: date,
                        time: generatedActivity.startTime
                    ),
                    let endTime = combinedDate(
                        date: date,
                        time: generatedActivity.endTime
                    )
                else {
                    continue
                }

                let activity = Activity(
                    name: generatedActivity.name,
                    activityDescription:
                        generatedActivity.description,
                    category: normalizedCategory(
                        generatedActivity.category
                    ),
                    startTime: startTime,
                    endTime: endTime,
                    locationName:
                        generatedActivity.locationName,
                    latitude:
                        generatedActivity.latitude,
                    longitude:
                        generatedActivity.longitude,
                    admissionFee:
                        generatedActivity.admissionFee,
                    transportationCost:
                        generatedActivity.transportationCost,
                    isLocked: false,
                    sortOrder: index,
                    tripDay: tripDay
                )

                modelContext.insert(activity)
                tripDay.activities.append(activity)
            }

            tripDay.admissionCost =
                tripDay.activities.reduce(0) {
                    $0 + $1.admissionFee
                }

            tripDay.transportCost =
                tripDay.activities.reduce(0) {
                    $0 + $1.transportationCost
                }
        }

        try modelContext.save()
    }

    private func removeExistingItinerary(
        from trip: Trip,
        modelContext: ModelContext
    ) {
        let existingDays = Array(trip.days)

        for day in existingDays {
            modelContext.delete(day)
        }

        trip.days.removeAll()
    }

    private func combinedDate(
        date: Date,
        time: String
    ) -> Date? {
        let components = time.split(
            separator: ":"
        )

        guard
            components.count == 2,
            let hour = Int(components[0]),
            let minute = Int(components[1]),
            (0...23).contains(hour),
            (0...59).contains(minute)
        else {
            return nil
        }

        return Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: date
        )
    }

    private func normalizedCategory(
        _ value: String
    ) -> String {
        if ActivityCategory(
            rawValue: value
        ) != nil {
            return value
        }

        return ActivityCategory.other.rawValue
    }
}
