import SwiftUI
import MapKit

struct ActivityMapView: View {
    let activity: Activity

    @State private var cameraPosition:
        MapCameraPosition

    init(activity: Activity) {
        self.activity = activity

        if let latitude = activity.latitude,
           let longitude = activity.longitude {

            let coordinate = CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            )

            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.015,
                    longitudeDelta: 0.015
                )
            )

            _cameraPosition = State(
                initialValue: .region(region)
            )
        } else {
            _cameraPosition = State(
                initialValue: .automatic
            )
        }
    }

    var body: some View {
        Group {
            if let coordinate {
                Map(position: $cameraPosition) {
                    Marker(
                        activity.name,
                        coordinate: coordinate
                    )
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
            } else {
                ContentUnavailableView(
                    "No Map Location",
                    systemImage: "map",
                    description: Text(
                        "Edit this activity and choose a location."
                    )
                )
            }
        }
        .navigationTitle(activity.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var coordinate:
        CLLocationCoordinate2D? {

        guard let latitude = activity.latitude,
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
