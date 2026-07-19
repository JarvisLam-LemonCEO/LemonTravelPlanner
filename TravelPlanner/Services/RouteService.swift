import Foundation
import MapKit
import Combine

struct CalculatedRoute: Identifiable {
    let id = UUID()

    let sourceActivity: Activity
    let destinationActivity: Activity
    let route: MKRoute
    let travelMode: TravelMode
    let sortOrder: Int
}

@MainActor
final class RouteService: ObservableObject {
    @Published private(set) var calculatedRoutes: [CalculatedRoute] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var activeDirections: [MKDirections] = []

    func calculateRoutes(
        for activities: [Activity],
        travelMode: TravelMode
    ) async {
        cancel()

        let mappedActivities = activities.filter {
            $0.latitude != nil &&
            $0.longitude != nil
        }

        guard mappedActivities.count >= 2 else {
            calculatedRoutes = []
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
            activeDirections = []
        }

        var results: [CalculatedRoute] = []

        for index in 0..<(mappedActivities.count - 1) {
            let sourceActivity =
                mappedActivities[index]

            let destinationActivity =
                mappedActivities[index + 1]

            guard
                let sourceCoordinate =
                    coordinate(for: sourceActivity),
                let destinationCoordinate =
                    coordinate(for: destinationActivity)
            else {
                continue
            }

            let request = MKDirections.Request()

            request.source = MKMapItem(
                placemark: MKPlacemark(
                    coordinate: sourceCoordinate
                )
            )

            request.destination = MKMapItem(
                placemark: MKPlacemark(
                    coordinate: destinationCoordinate
                )
            )

            request.transportType =
                travelMode.mapKitTransportType

            request.requestsAlternateRoutes = false

            let directions = MKDirections(
                request: request
            )

            activeDirections.append(directions)

            do {
                let response =
                    try await directions.calculate()

                guard let route =
                    response.routes.first
                else {
                    continue
                }

                let calculatedRoute =
                    CalculatedRoute(
                        sourceActivity:
                            sourceActivity,
                        destinationActivity:
                            destinationActivity,
                        route: route,
                        travelMode: travelMode,
                        sortOrder: index
                    )

                results.append(calculatedRoute)
            } catch is CancellationError {
                return
            } catch {
                errorMessage =
                    "Unable to calculate route from \(sourceActivity.name) to \(destinationActivity.name)."
            }
        }

        calculatedRoutes = results
    }

    func cancel() {
        for directions in activeDirections {
            directions.cancel()
        }

        activeDirections = []
        calculatedRoutes = []
        isLoading = false
    }

    private func coordinate(
        for activity: Activity
    ) -> CLLocationCoordinate2D? {
        guard
            let latitude = activity.latitude,
            let longitude = activity.longitude
        else {
            return nil
        }

        return CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }
}
