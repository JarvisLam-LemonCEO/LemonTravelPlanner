import Foundation

struct ItineraryGenerationRequest: Codable {
    let tripTitle: String
    let destination: String
    let startDate: String
    let endDate: String
    let budget: Double
    let currencyCode: String
    let travelPace: String
    let interests: [String]
}

struct GeneratedItineraryResponse: Codable {
    let summary: String
    let days: [GeneratedDay]
}

struct GeneratedDay: Codable, Identifiable {
    let dayNumber: Int
    let date: String
    let city: String
    let hotelCost: Double
    let foodCost: Double
    let activities: [GeneratedActivity]

    var id: Int {
        dayNumber
    }
}

struct GeneratedActivity: Codable, Identifiable {
    let name: String
    let description: String
    let category: String
    let startTime: String
    let endTime: String
    let locationName: String
    let latitude: Double?
    let longitude: Double?
    let admissionFee: Double
    let transportationCost: Double

    var id: String {
        "\(name)-\(startTime)"
    }
}
