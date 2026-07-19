import SwiftUI
import SwiftData
import MapKit

struct TripDayMapView: View {
    @Environment(\.modelContext) private var modelContext

    let tripDay: TripDay

    @StateObject private var routeService =
        RouteService()

    @State private var cameraPosition:
        MapCameraPosition = .automatic

    @State private var selectedActivityID: UUID?
    @State private var travelMode = TravelMode.walking

    @State private var showRoutesSavedAlert = false
    @State private var saveErrorMessage: String?

    private var mappedActivities: [Activity] {
        tripDay.sortedActivities.filter {
            hasValidCoordinate($0)
        }
    }

    private var selectedActivity: Activity? {
        guard let selectedActivityID else {
            return nil
        }

        return mappedActivities.first {
            $0.id == selectedActivityID
        }
    }

    var body: some View {
        Group {
            if mappedActivities.isEmpty {
                emptyState
            } else {
                mapContent
            }
        }
        .navigationTitle(
            "Day \(tripDay.dayNumber) Map"
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(
                placement: .topBarTrailing
            ) {
                travelModeMenu

                Button {
                    saveCalculatedRoutes()
                } label: {
                    Image(
                        systemName:
                            "square.and.arrow.down"
                    )
                }
                .accessibilityLabel(
                    "Save Transportation Routes"
                )
                .disabled(
                    routeService
                        .calculatedRoutes
                        .isEmpty
                    ||
                    routeService.isLoading
                )
            }
        }
        .task {
            await calculateRoutes()
        }
        .onChange(of: travelMode) {
            selectedActivityID = nil

            Task {
                await calculateRoutes()
            }
        }
        .onDisappear {
            routeService.cancel()
        }
        .alert(
            "Route Error",
            isPresented: Binding(
                get: {
                    routeService.errorMessage != nil
                },
                set: { isPresented in
                    if !isPresented {
                        routeService.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                routeService.errorMessage = nil
            }
        } message: {
            Text(
                routeService.errorMessage
                ?? "Unable to calculate routes."
            )
        }
        .alert(
            "Routes Saved",
            isPresented: $showRoutesSavedAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "The transportation distance, duration, mode, and estimated cost were saved."
            )
        }
        .alert(
            "Unable to Save Routes",
            isPresented: Binding(
                get: {
                    saveErrorMessage != nil
                },
                set: { isPresented in
                    if !isPresented {
                        saveErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(
                saveErrorMessage
                ?? "An unknown error occurred."
            )
        }
    }

    private var travelModeMenu: some View {
        Menu {
            Picker(
                "Travel Mode",
                selection: $travelMode
            ) {
                ForEach(
                    TravelMode.allCases
                ) { mode in
                    Label(
                        mode.title,
                        systemImage:
                            mode.iconName
                    )
                    .tag(mode)
                }
            }
        } label: {
            Label(
                travelMode.title,
                systemImage:
                    travelMode.iconName
            )
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Locations",
            systemImage: "map",
            description: Text(
                "Add map locations to at least two activities to calculate routes."
            )
        )
    }

    private var mapContent: some View {
        ZStack(alignment: .bottom) {
            Map(
                position: $cameraPosition,
                selection: $selectedActivityID
            ) {
                routePolylines
                activityAnnotations
            }
            .mapControls {
                MapCompass()
                MapScaleView()
                MapUserLocationButton()
            }
            .onAppear {
                cameraPosition = .automatic
            }

            VStack(spacing: 10) {
                if routeService.isLoading {
                    loadingView
                }

                if let selectedActivity {
                    activityCard(
                        for: selectedActivity
                    )
                } else if !routeService
                    .calculatedRoutes
                    .isEmpty {
                    routeSummaryCard
                } else if mappedActivities.count == 1 {
                    singleLocationCard
                }
            }
            .padding()
        }
    }

    @MapContentBuilder
    private var routePolylines: some MapContent {
        ForEach(
            routeService.calculatedRoutes
        ) { calculatedRoute in
            MapPolyline(
                calculatedRoute.route
            )
            .stroke(
                .blue,
                lineWidth: 5
            )
        }
    }

    @MapContentBuilder
    private var activityAnnotations: some MapContent {
        ForEach(
            Array(
                mappedActivities.enumerated()
            ),
            id: \.element.id
        ) { index, activity in
            if let coordinate =
                coordinate(for: activity) {

                Annotation(
                    activity.name,
                    coordinate: coordinate
                ) {
                    markerView(
                        activity: activity,
                        number: index + 1
                    )
                }
                .tag(activity.id)
            }
        }
    }

    private var loadingView: some View {
        ProgressView(
            "Calculating routes..."
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(Capsule())
    }

    private var singleLocationCard: some View {
        Label(
            "Add another activity location to calculate a route.",
            systemImage: "point.topleft.down.to.point.bottomright.curvepath"
        )
        .font(.subheadline)
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    private var routeSummaryCard: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            HStack {
                Label(
                    travelMode.title,
                    systemImage:
                        travelMode.iconName
                )
                .font(.headline)

                Spacer()

                Text(
                    formattedTravelTime(
                        totalTravelTime
                    )
                )
                .fontWeight(.semibold)
            }

            HStack {
                Label(
                    "\(routeService.calculatedRoutes.count) segments",
                    systemImage: "point.3.connected.trianglepath.dotted"
                )

                Spacer()

                Text(
                    formattedDistance(
                        totalDistance
                    )
                )
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Divider()

            HStack {
                Text("Estimated cost")

                Spacer()

                Text(
                    totalEstimatedCost,
                    format: .currency(
                        code: currencyCode
                    )
                )
                .fontWeight(.semibold)
            }
            .font(.subheadline)

            Button {
                saveCalculatedRoutes()
            } label: {
                Label(
                    "Save Transportation",
                    systemImage:
                        "square.and.arrow.down"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .shadow(radius: 6)
    }

    private func markerView(
        activity: Activity,
        number: Int
    ) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(.blue)
                    .frame(
                        width: 38,
                        height: 38
                    )

                Text("\(number)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }

            Image(
                systemName:
                    category(for: activity)
                    .iconName
            )
            .font(.caption)
            .foregroundStyle(.blue)
            .padding(5)
            .background(.regularMaterial)
            .clipShape(Circle())
        }
        .shadow(radius: 3)
        .accessibilityLabel(
            "Stop \(number), \(activity.name)"
        )
    }

    private func activityCard(
        for activity: Activity
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            HStack {
                Image(
                    systemName:
                        category(for: activity)
                        .iconName
                )
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    .blue.opacity(0.12)
                )
                .clipShape(Circle())

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text(activity.name)
                        .font(.headline)

                    Text(
                        timeDescription(
                            for: activity
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    selectedActivityID = nil
                } label: {
                    Image(
                        systemName:
                            "xmark.circle.fill"
                    )
                    .foregroundStyle(.secondary)
                }
                .accessibilityLabel(
                    "Close activity details"
                )
            }

            if !activity.locationName.isEmpty {
                Label(
                    activity.locationName,
                    systemImage:
                        "mappin.and.ellipse"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            if !activity.activityDescription.isEmpty {
                Text(
                    activity.activityDescription
                )
                .font(.subheadline)
                .lineLimit(2)
            }

            if let stopNumber =
                stopNumber(for: activity) {
                Text("Stop \(stopNumber)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .shadow(radius: 8)
    }

    private var totalTravelTime: TimeInterval {
        routeService.calculatedRoutes.reduce(0) {
            $0 + $1.route.expectedTravelTime
        }
    }

    private var totalDistance: CLLocationDistance {
        routeService.calculatedRoutes.reduce(0) {
            $0 + $1.route.distance
        }
    }

    private var totalEstimatedCost: Double {
        routeService.calculatedRoutes.reduce(0) {
            $0 + estimatedCost(for: $1)
        }
    }

    private var currencyCode: String {
        tripDay.trip?.currencyCode ?? "USD"
    }

    private func calculateRoutes() async {
        guard mappedActivities.count >= 2 else {
            routeService.cancel()
            return
        }

        await routeService.calculateRoutes(
            for: mappedActivities,
            travelMode: travelMode
        )

        cameraPosition = .automatic
    }

    private func saveCalculatedRoutes() {
        guard !routeService
            .calculatedRoutes
            .isEmpty
        else {
            saveErrorMessage =
                "There are no calculated routes to save."
            return
        }

        let oldSegments =
            Array(
                tripDay.transportationSegments
            )

        for segment in oldSegments {
            modelContext.delete(segment)
        }

        tripDay.transportationSegments.removeAll()

        for calculatedRoute in
            routeService.calculatedRoutes {

            let segment =
                TransportationSegment(
                    sourceActivityID:
                        calculatedRoute
                        .sourceActivity
                        .id,
                    destinationActivityID:
                        calculatedRoute
                        .destinationActivity
                        .id,
                    sourceName:
                        calculatedRoute
                        .sourceActivity
                        .name,
                    destinationName:
                        calculatedRoute
                        .destinationActivity
                        .name,
                    travelMode:
                        calculatedRoute
                        .travelMode
                        .rawValue,
                    distanceMeters:
                        calculatedRoute
                        .route
                        .distance,
                    durationSeconds:
                        calculatedRoute
                        .route
                        .expectedTravelTime,
                    estimatedCost:
                        estimatedCost(
                            for: calculatedRoute
                        ),
                    sortOrder:
                        calculatedRoute
                        .sortOrder,
                    tripDay: tripDay
                )

            tripDay
                .transportationSegments
                .append(segment)

            modelContext.insert(segment)
        }

        tripDay.transportCost =
            tripDay
                .transportationSegments
                .reduce(0) {
                    $0 + $1.estimatedCost
                }

        do {
            try modelContext.save()
            showRoutesSavedAlert = true
        } catch {
            saveErrorMessage =
                error.localizedDescription
        }
    }

    private func estimatedCost(
        for calculatedRoute: CalculatedRoute
    ) -> Double {
        let kilometers =
            calculatedRoute.route.distance
            / 1_000

        switch calculatedRoute.travelMode {
        case .walking:
            return 0

        case .driving:
            return max(
                5,
                kilometers * 1.5
            )
        }
    }

    private func hasValidCoordinate(
        _ activity: Activity
    ) -> Bool {
        guard
            let latitude = activity.latitude,
            let longitude = activity.longitude
        else {
            return false
        }

        return latitude >= -90 &&
            latitude <= 90 &&
            longitude >= -180 &&
            longitude <= 180
    }

    private func coordinate(
        for activity: Activity
    ) -> CLLocationCoordinate2D? {
        guard hasValidCoordinate(activity),
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

    private func category(
        for activity: Activity
    ) -> ActivityCategory {
        ActivityCategory(
            rawValue: activity.category
        ) ?? .other
    }

    private func stopNumber(
        for activity: Activity
    ) -> Int? {
        guard let index =
            mappedActivities.firstIndex(
                where: {
                    $0.id == activity.id
                }
            )
        else {
            return nil
        }

        return index + 1
    }

    private func timeDescription(
        for activity: Activity
    ) -> String {
        let start =
            activity.startTime.formatted(
                date: .omitted,
                time: .shortened
            )

        let end =
            activity.endTime.formatted(
                date: .omitted,
                time: .shortened
            )

        return "\(start) – \(end)"
    }

    private func formattedTravelTime(
        _ interval: TimeInterval
    ) -> String {
        let totalMinutes =
            max(
                Int(interval / 60),
                1
            )

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }

        return "\(minutes) min"
    }

    private func formattedDistance(
        _ distance: CLLocationDistance
    ) -> String {
        if distance >= 1_000 {
            return String(
                format: "%.1f km",
                distance / 1_000
            )
        }

        return "\(Int(distance)) m"
    }
}
