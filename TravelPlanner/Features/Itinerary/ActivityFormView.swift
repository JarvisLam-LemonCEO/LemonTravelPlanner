import SwiftUI
import SwiftData

struct ActivityFormView: View {
    enum Mode {
        case create
        case edit(Activity)

        var title: String {
            switch self {
            case .create:
                return "Add Activity"

            case .edit:
                return "Edit Activity"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let tripDay: TripDay
    let mode: Mode

    @State private var name: String
    @State private var activityDescription: String
    @State private var category: ActivityCategory
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var locationName: String
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var admissionFee: Double
    @State private var transportationCost: Double
    @State private var bookingURL: String
    @State private var isLocked: Bool

    @State private var isShowingPlaceSearch = false
    @State private var errorMessage: String?

    init(
        tripDay: TripDay,
        mode: Mode = .create
    ) {
        self.tripDay = tripDay
        self.mode = mode

        let calendar = Calendar.current

        let defaultStart = calendar.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: tripDay.date
        ) ?? tripDay.date

        let defaultEnd = calendar.date(
            byAdding: .hour,
            value: 2,
            to: defaultStart
        ) ?? defaultStart

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _activityDescription = State(initialValue: "")
            _category = State(initialValue: .attraction)
            _startTime = State(initialValue: defaultStart)
            _endTime = State(initialValue: defaultEnd)
            _locationName = State(initialValue: "")
            _latitude = State(initialValue: nil)
            _longitude = State(initialValue: nil)
            _admissionFee = State(initialValue: 0)
            _transportationCost = State(initialValue: 0)
            _bookingURL = State(initialValue: "")
            _isLocked = State(initialValue: false)

        case .edit(let activity):
            _name = State(
                initialValue: activity.name
            )

            _activityDescription = State(
                initialValue: activity.activityDescription
            )

            _category = State(
                initialValue:
                    ActivityCategory(
                        rawValue: activity.category
                    ) ?? .other
            )

            _startTime = State(
                initialValue: activity.startTime
            )

            _endTime = State(
                initialValue: activity.endTime
            )

            _locationName = State(
                initialValue: activity.locationName
            )

            _latitude = State(
                initialValue: activity.latitude
            )

            _longitude = State(
                initialValue: activity.longitude
            )

            _admissionFee = State(
                initialValue: activity.admissionFee
            )

            _transportationCost = State(
                initialValue: activity.transportationCost
            )

            _bookingURL = State(
                initialValue: activity.bookingURL ?? ""
            )

            _isLocked = State(
                initialValue: activity.isLocked
            )
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                activitySection
                timeSection
                costSection
                bookingSection
                optionsSection
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Save") {
                        saveActivity()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(
                isPresented: $isShowingPlaceSearch
            ) {
                PlaceSearchView { place in
                    locationName = place.name
                    latitude = place.latitude
                    longitude = place.longitude
                }
            }
            .alert(
                "Unable to Save Activity",
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
    }

    private var activitySection: some View {
        Section("Activity") {
            TextField(
                "Activity name",
                text: $name
            )

            Picker(
                "Category",
                selection: $category
            ) {
                ForEach(
                    ActivityCategory.allCases
                ) { category in
                    Label(
                        category.title,
                        systemImage: category.iconName
                    )
                    .tag(category)
                }
            }

            Button {
                isShowingPlaceSearch = true
            } label: {
                HStack {
                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text("Location")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(
                            locationName.isEmpty
                            ? "Choose a place"
                            : locationName
                        )
                        .foregroundStyle(
                            locationName.isEmpty
                            ? .secondary
                            : .primary
                        )
                    }

                    Spacer()

                    Image(
                        systemName: "magnifyingglass"
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if !locationName.isEmpty {
                HStack {
                    Label(
                        "Location selected",
                        systemImage: "mappin.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button("Clear", role: .destructive) {
                        clearLocation()
                    }
                    .font(.caption)
                }
            }

            TextField(
                "Description",
                text: $activityDescription,
                axis: .vertical
            )
            .lineLimit(3...6)
        }
    }

    private var timeSection: some View {
        Section("Time") {
            DatePicker(
                "Start",
                selection: $startTime,
                displayedComponents: .hourAndMinute
            )

            DatePicker(
                "End",
                selection: $endTime,
                in: startTime...,
                displayedComponents: .hourAndMinute
            )
        }
        .onChange(of: startTime) {
            if endTime <= startTime {
                endTime = Calendar.current.date(
                    byAdding: .hour,
                    value: 1,
                    to: startTime
                ) ?? startTime
            }
        }
    }

    private var costSection: some View {
        Section("Estimated Costs") {
            TextField(
                "Admission fee",
                value: $admissionFee,
                format: .number.precision(
                    .fractionLength(0...2)
                )
            )
            .keyboardType(.decimalPad)

            TextField(
                "Transportation cost",
                value: $transportationCost,
                format: .number.precision(
                    .fractionLength(0...2)
                )
            )
            .keyboardType(.decimalPad)
        }
    }

    private var bookingSection: some View {
        Section("Booking") {
            TextField(
                "Booking URL",
                text: $bookingURL
            )
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
    }

    private var optionsSection: some View {
        Section {
            Toggle(
                "Lock this activity",
                isOn: $isLocked
            )
        } footer: {
            Text(
                "Locked activities will remain unchanged when the itinerary is regenerated."
            )
        }
    }

    private var isFormValid: Bool {
        !cleanedName.isEmpty
        &&
        endTime > startTime
        &&
        admissionFee >= 0
        &&
        transportationCost >= 0
    }

    private func saveActivity() {
        guard isFormValid else {
            errorMessage =
                "Please check the activity details."
            return
        }

        switch mode {
        case .create:
            createActivity()

        case .edit(let activity):
            updateActivity(activity)
        }

        updateDayCosts()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage =
                error.localizedDescription
        }
    }

    private func createActivity() {
        let activity = Activity(
            name: cleanedName,
            activityDescription:
                activityDescription.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            category: category.rawValue,
            startTime: startTime,
            endTime: endTime,
            locationName: cleanedLocationName,
            latitude: latitude,
            longitude: longitude,
            admissionFee: admissionFee,
            transportationCost:
                transportationCost,
            bookingURL: cleanedBookingURL,
            isLocked: isLocked,
            sortOrder:
                nextSortOrder,
            tripDay: tripDay
        )

        tripDay.activities.append(activity)
        modelContext.insert(activity)
    }

    private func updateActivity(
        _ activity: Activity
    ) {
        activity.name = cleanedName

        activity.activityDescription =
            activityDescription.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        activity.category = category.rawValue
        activity.startTime = startTime
        activity.endTime = endTime
        activity.locationName = cleanedLocationName
        activity.latitude = latitude
        activity.longitude = longitude
        activity.admissionFee = admissionFee

        activity.transportationCost =
            transportationCost

        activity.bookingURL =
            cleanedBookingURL

        activity.isLocked =
            isLocked
    }

    private func clearLocation() {
        locationName = ""
        latitude = nil
        longitude = nil
    }

    private func updateDayCosts() {
        tripDay.admissionCost =
            tripDay.activities.reduce(0) {
                $0 + $1.admissionFee
            }

        tripDay.transportCost =
            tripDay.activities.reduce(0) {
                $0 + $1.transportationCost
            }
    }

    private var nextSortOrder: Int {
        let highestSortOrder =
            tripDay.activities
                .map(\.sortOrder)
                .max() ?? -1

        return highestSortOrder + 1
    }

    private var cleanedName: String {
        name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var cleanedLocationName: String {
        locationName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var cleanedBookingURL: String? {
        let value = bookingURL.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return value.isEmpty ? nil : value
    }
}
