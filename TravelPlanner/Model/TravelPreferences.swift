import Foundation

enum TravelPace: String, CaseIterable, Identifiable {
    case relaxed
    case moderate
    case busy

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .relaxed:
            return "Relaxed"

        case .moderate:
            return "Moderate"

        case .busy:
            return "Busy"
        }
    }
}

enum ActivityCategory: String, CaseIterable, Identifiable {
    case attraction
    case food
    case hotel
    case transportation
    case shopping
    case relaxation
    case other

    var id: String {
        rawValue
    }

    var title: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {
        case .attraction:
            return "camera.fill"

        case .food:
            return "fork.knife"

        case .hotel:
            return "bed.double.fill"

        case .transportation:
            return "tram.fill"

        case .shopping:
            return "bag.fill"

        case .relaxation:
            return "leaf.fill"

        case .other:
            return "mappin"
        }
    }
}

enum TravelInterest: String, CaseIterable, Identifiable {
    case architecture
    case art
    case beaches
    case culture
    case family
    case food
    case history
    case museums
    case nature
    case nightlife
    case photography
    case shopping

    var id: String {
        rawValue
    }

    var title: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {
        case .architecture:
            return "building.columns"

        case .art:
            return "paintpalette"

        case .beaches:
            return "beach.umbrella"

        case .culture:
            return "theatermasks"

        case .family:
            return "figure.2.and.child.holdinghands"

        case .food:
            return "fork.knife"

        case .history:
            return "books.vertical"

        case .museums:
            return "building.columns.fill"

        case .nature:
            return "leaf"

        case .nightlife:
            return "moon.stars"

        case .photography:
            return "camera"

        case .shopping:
            return "bag"
        }
    }
}
