import SwiftUI
import SwiftData

@main
struct TravelPlannerApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(
            for: [
                Trip.self,
                TripDay.self,
                Activity.self,
                TransportationSegment.self
            ]
        )
    }
}
