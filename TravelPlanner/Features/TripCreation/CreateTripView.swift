import SwiftUI
import SwiftData

struct CreateTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var tripTitle = ""
    @State private var destination = ""

    @State private var startDate = Date()

    @State private var endDate =
        Calendar.current.date(
            byAdding: .day,
            value: 3,
            to: Date()
        ) ?? Date()

    @State private var budget = 1_000.0
    @State private var currencyCode = "USD"
    @State private var travelPace = TravelPace.moderate

    @State private var selectedInterests: Set<TravelInterest> = []

    @State private var errorMessage: String?

    private let currencyCodes = [
        "USD",
        "EUR",
        "GBP",
        "JPY",
        "CAD",
        "AUD"
    ]

    var body: some View {
        NavigationStack {
            Form {
                tripInformationSection
                datesSection
                budgetSection
                preferencesSection
            }
            .navigationTitle("Create Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTrip()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert(
                "Unable to Save Trip",
                isPresented: Binding(
                    get: { errorMessage != nil },
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
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }

    private var tripInformationSection: some View {
        Section("Trip Information") {
            TextField(
                "Trip name",
                text: $tripTitle
            )

            TextField(
                "Destination",
                text: $destination
            )
            .textContentType(.addressCity)
        }
    }

    private var datesSection: some View {
        Section("Dates") {
            DatePicker(
                "Start date",
                selection: $startDate,
                in: Date()...,
                displayedComponents: .date
            )

            DatePicker(
                "End date",
                selection: $endDate,
                in: startDate...,
                displayedComponents: .date
            )

            LabeledContent(
                "Duration",
                value: "\(durationInDays) days"
            )
        }
        .onChange(of: startDate) { _, newStartDate in
            if endDate < newStartDate {
                endDate = newStartDate
            }
        }
    }

    private var budgetSection: some View {
        Section("Budget") {
            TextField(
                "Total budget",
                value: $budget,
                format: .number.precision(.fractionLength(0...2))
            )
            .keyboardType(.decimalPad)

            Picker(
                "Currency",
                selection: $currencyCode
            ) {
                ForEach(currencyCodes, id: \.self) { code in
                    Text(code).tag(code)
                }
            }
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Picker(
                "Travel pace",
                selection: $travelPace
            ) {
                ForEach(TravelPace.allCases) { pace in
                    Text(pace.title)
                        .tag(pace)
                }
            }

            NavigationLink {
                InterestSelectionView(
                    selectedInterests: $selectedInterests
                )
            } label: {
                LabeledContent(
                    "Interests",
                    value: interestSummary
                )
            }
        }
    }

    private var isFormValid: Bool {
        !tripTitle.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        &&
        !destination.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        &&
        endDate >= startDate
        &&
        budget > 0
    }

    private var durationInDays: Int {
        let calendar = Calendar.current

        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        let difference = calendar.dateComponents(
            [.day],
            from: start,
            to: end
        ).day ?? 0

        return max(difference + 1, 1)
    }

    private var interestSummary: String {
        if selectedInterests.isEmpty {
            return "None"
        }

        return "\(selectedInterests.count) selected"
    }

    private func saveTrip() {
        guard isFormValid else {
            errorMessage = "Please complete all required fields."
            return
        }

        let trip = Trip(
            title: tripTitle.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            destination: destination.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            startDate: startDate,
            endDate: endDate,
            budget: budget,
            currencyCode: currencyCode,
            travelPace: travelPace.rawValue,
            interests: selectedInterests
                .map(\.rawValue)
                .sorted()
        )

        modelContext.insert(trip)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.delete(trip)
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CreateTripView()
        .modelContainer(for: Trip.self, inMemory: true)
}
