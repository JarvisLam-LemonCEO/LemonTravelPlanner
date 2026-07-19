import SwiftUI
import SwiftData

struct TripDayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode

    let trip: Trip
    let tripDay: TripDay

    @State private var isShowingAddActivity = false
    @State private var activityToEdit: Activity?
    @State private var activityToShowOnMap: Activity?

    @State private var isShowingDayMap = false
    @State private var showNoLocationsAlert = false

    @State private var errorMessage: String?

    var body: some View {
        List {
            activitySection
            transportationSection
            dailyEstimateSection
        }
        .navigationTitle(
            "Day \(tripDay.dayNumber)"
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(
                placement: .topBarTrailing
            ) {
                Button {
                    openDayMap()
                } label: {
                    Image(systemName: "map")
                }
                .accessibilityLabel(
                    "View Day Map"
                )

                EditButton()

                Button {
                    isShowingAddActivity = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(
                    "Add Activity"
                )
            }
        }
        .navigationDestination(
            isPresented: $isShowingDayMap
        ) {
            TripDayMapView(
                tripDay: tripDay
            )
        }
        .sheet(
            isPresented: $isShowingAddActivity
        ) {
            ActivityFormView(
                tripDay: tripDay,
                mode: .create
            )
        }
        .sheet(
            item: $activityToEdit
        ) { activity in
            ActivityFormView(
                tripDay: tripDay,
                mode: .edit(activity)
            )
        }
        .sheet(
            item: $activityToShowOnMap
        ) { activity in
            NavigationStack {
                ActivityMapView(
                    activity: activity
                )
                .toolbar {
                    ToolbarItem(
                        placement: .cancellationAction
                    ) {
                        Button("Done") {
                            activityToShowOnMap = nil
                        }
                    }
                }
            }
        }
        .alert(
            "No Map Locations",
            isPresented: $showNoLocationsAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "Add a real map location to at least one activity before opening the day map."
            )
        }
        .alert(
            "Unable to Update Itinerary",
            isPresented: Binding(
                get: {
                    errorMessage != nil
                },
                set: { isPresented in
                    if !isPresented {
                        errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(
                errorMessage
                ?? "An unknown error occurred."
            )
        }
    }

    // MARK: - Activity locations

    private var mappedActivities: [Activity] {
        tripDay.sortedActivities.filter {
            hasMapLocation($0)
        }
    }

    // MARK: - Activity section

    private var activitySection: some View {
        Section {
            if tripDay.sortedActivities.isEmpty {
                ContentUnavailableView {
                    Label(
                        "No Activities",
                        systemImage:
                            "calendar.badge.plus"
                    )
                } description: {
                    Text(
                        "Add the first activity for this day."
                    )
                } actions: {
                    Button("Add Activity") {
                        isShowingAddActivity = true
                    }
                    .buttonStyle(
                        .borderedProminent
                    )
                }
            } else {
                ForEach(
                    tripDay.sortedActivities
                ) { activity in
                    activityRow(
                        for: activity
                    )
                }
                .onDelete(
                    perform: deleteActivities
                )
                .onMove(
                    perform: moveActivities
                )
            }
        } header: {
            Text(tripDay.city)
        } footer: {
            if !tripDay.activities.isEmpty {
                Text(
                    "Tap an activity to edit it. Use Edit to delete or reorder activities."
                )
            }
        }
    }

    private func activityRow(
        for activity: Activity
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Button {
                guard editMode?.wrappedValue
                    != .active
                else {
                    return
                }

                activityToEdit = activity
            } label: {
                ActivityRowView(
                    activity: activity,
                    currencyCode:
                        trip.currencyCode
                )
            }
            .buttonStyle(.plain)

            if hasMapLocation(activity) {
                Button {
                    guard editMode?.wrappedValue
                        != .active
                    else {
                        return
                    }

                    activityToShowOnMap =
                        activity
                } label: {
                    Label(
                        "View on Map",
                        systemImage: "map"
                    )
                    .font(
                        .caption.weight(
                            .semibold
                        )
                    )
                }
                .buttonStyle(.borderless)
            } else {
                Label(
                    "No map location",
                    systemImage: "mappin.slash"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Transportation section

    @ViewBuilder
    private var transportationSection: some View {
        if !tripDay
            .sortedTransportationSegments
            .isEmpty {

            Section {
                ForEach(
                    tripDay
                        .sortedTransportationSegments
                ) { segment in
                    transportationRow(
                        for: segment
                    )
                }

                Button(
                    role: .destructive
                ) {
                    deleteSavedTransportation()
                } label: {
                    Label(
                        "Delete Saved Transportation",
                        systemImage: "trash"
                    )
                }
            } header: {
                Text("Transportation")
            } footer: {
                Text(
                    "Routes are calculated using MapKit and may change when activities are reordered."
                )
            }
        }
    }

    private func transportationRow(
        for segment: TransportationSegment
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            HStack(
                alignment: .top,
                spacing: 10
            ) {
                Image(
                    systemName:
                        travelModeIcon(
                            segment.travelMode
                        )
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
                    spacing: 4
                ) {
                    Text(segment.sourceName)
                        .font(
                            .subheadline.weight(
                                .semibold
                            )
                        )

                    Label(
                        segment.destinationName,
                        systemImage:
                            "arrow.down"
                    )
                    .font(.subheadline)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Label(
                    segment.formattedDuration,
                    systemImage: "clock"
                )

                Text("•")

                Label(
                    segment.formattedDistance,
                    systemImage: "ruler"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Text(
                    travelModeTitle(
                        segment.travelMode
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                Text(
                    segment.estimatedCost,
                    format: .currency(
                        code: trip.currencyCode
                    )
                )
                .font(
                    .subheadline.weight(
                        .semibold
                    )
                )
            }
        }
        .padding(.vertical, 5)
    }

    // MARK: - Daily estimate section

    private var dailyEstimateSection:
        some View {

        Section("Daily Estimate") {
            costRow(
                title: "Hotel",
                value: tripDay.hotelCost
            )

            costRow(
                title: "Food",
                value: tripDay.foodCost
            )

            costRow(
                title: "Transportation",
                value: tripDay.transportCost
            )

            costRow(
                title: "Admission",
                value: tripDay.admissionCost
            )

            LabeledContent {
                Text(
                    tripDay.estimatedTotal,
                    format: .currency(
                        code:
                            trip.currencyCode
                    )
                )
                .fontWeight(.bold)
            } label: {
                Text("Daily total")
                    .fontWeight(.bold)
            }
        }
    }

    private func costRow(
        title: String,
        value: Double
    ) -> some View {
        LabeledContent {
            Text(
                value,
                format: .currency(
                    code: trip.currencyCode
                )
            )
        } label: {
            Text(title)
        }
    }

    // MARK: - Map actions

    private func openDayMap() {
        guard !mappedActivities.isEmpty else {
            showNoLocationsAlert = true
            return
        }

        isShowingDayMap = true
    }

    private func hasMapLocation(
        _ activity: Activity
    ) -> Bool {
        guard
            let latitude = activity.latitude,
            let longitude = activity.longitude
        else {
            return false
        }

        return latitude >= -90
            && latitude <= 90
            && longitude >= -180
            && longitude <= 180
    }

    // MARK: - Activity editing

    private func deleteActivities(
        at offsets: IndexSet
    ) {
        let orderedActivities =
            tripDay.sortedActivities

        for index in offsets {
            guard orderedActivities.indices
                .contains(index)
            else {
                continue
            }

            let activity =
                orderedActivities[index]

            if let relationshipIndex =
                tripDay.activities.firstIndex(
                    where: {
                        $0.id == activity.id
                    }
                ) {
                tripDay.activities.remove(
                    at: relationshipIndex
                )
            }

            modelContext.delete(activity)
        }

        /*
         Saved routes may now refer to activities
         that no longer exist.
        */
        invalidateSavedTransportation()
        normalizeSortOrder()
        updateDayCosts()
        saveChanges()
    }

    private func moveActivities(
        from source: IndexSet,
        to destination: Int
    ) {
        var reorderedActivities =
            tripDay.sortedActivities

        reorderedActivities.move(
            fromOffsets: source,
            toOffset: destination
        )

        for (
            index,
            activity
        ) in reorderedActivities.enumerated() {
            activity.sortOrder = index
        }

        /*
         Route order is now outdated, so the user
         should calculate and save it again.
        */
        invalidateSavedTransportation()
        updateDayCosts()
        saveChanges()
    }

    private func normalizeSortOrder() {
        for (
            index,
            activity
        ) in tripDay
            .sortedActivities
            .enumerated() {

            activity.sortOrder = index
        }
    }

    // MARK: - Transportation actions

    private func deleteSavedTransportation() {
        invalidateSavedTransportation()
        updateDayCosts()
        saveChanges()
    }

    private func invalidateSavedTransportation() {
        let existingSegments =
            Array(
                tripDay.transportationSegments
            )

        for segment in existingSegments {
            modelContext.delete(segment)
        }

        tripDay
            .transportationSegments
            .removeAll()
    }

    // MARK: - Costs

    private func updateDayCosts() {
        tripDay.admissionCost =
            tripDay.activities.reduce(0) {
                $0 + $1.admissionFee
            }

        if tripDay
            .transportationSegments
            .isEmpty {

            tripDay.transportCost =
                tripDay.activities.reduce(0) {
                    $0
                    + $1.transportationCost
                }
        } else {
            tripDay.transportCost =
                tripDay
                    .transportationSegments
                    .reduce(0) {
                        $0
                        + $1.estimatedCost
                    }
        }
    }

    // MARK: - Transportation formatting

    private func travelModeIcon(
        _ rawValue: String
    ) -> String {
        let mode =
            TravelMode(
                rawValue: rawValue
            ) ?? .walking

        return mode.iconName
    }

    private func travelModeTitle(
        _ rawValue: String
    ) -> String {
        let mode =
            TravelMode(
                rawValue: rawValue
            ) ?? .walking

        return mode.title
    }

    // MARK: - Persistence

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            errorMessage =
                error.localizedDescription
        }
    }
}
