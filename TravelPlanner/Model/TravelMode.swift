import Foundation
import MapKit

enum TravelMode: String, CaseIterable, Identifiable {
    case walking
    case driving

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .walking:
            return "Walking"

        case .driving:
            return "Driving"
        }
    }

    var iconName: String {
        switch self {
        case .walking:
            return "figure.walk"

        case .driving:
            return "car.fill"
        }
    }

    var mapKitTransportType: MKDirectionsTransportType {
        switch self {
        case .walking:
            return .walking

        case .driving:
            return .automobile
        }
    }
}
