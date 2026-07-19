import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let trip: Trip

    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var isShowingRegenerateConfirmation = false

    private let itineraryGenerator:
        ItineraryGenerator

    init(trip: Trip) {

        self.trip = trip

        switch AppConfiguration.provider {

        case .mock:

            itineraryGenerator =
                ItineraryGenerator(
                    service: MockItineraryService()
                )

        case .lmStudio:

            itineraryGenerator =
                ItineraryGenerator(
                    service: LMStudioItineraryService(
                        baseURL:
                            AppConfiguration
                                .lmStudioBaseURL,
                        modelIdentifier:
                            AppConfiguration
                                .lmStudioModel
                    )
                )

        case .openAI:

            itineraryGenerator =
                ItineraryGenerator(
                    service: RemoteItineraryService(
                        baseURL:
                            AppConfiguration
                                .backendURL
                    )
                )
        }
    }
    
    var body: some View {
        List {
            tripSummarySection

            if trip.sortedDays.isEmpty {
                emptyItinerarySection
            } else {
                regenerateSection
                itinerarySection
                budgetSection
            }
        }
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Regenerate Itinerary?",
            isPresented: $isShowingRegenerateConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Regenerate Itinerary",
                role: .destructive
            ) {
                generateAIItinerary()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This will replace the current itinerary, including its days and activities."
            )
        }
        .alert(
            "Unable to Generate Itinerary",
            isPresented: Binding(
                get: {
                    generationError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        generationError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                generationError = nil
            }
        } message: {
            Text(
                generationError
                ?? "An unknown error occurred."
            )
        }
        .overlay {
            if isGenerating {
                generationOverlay
            }
        }
    }

    // MARK: - Trip summary

    private var tripSummarySection: some View {
        Section("Trip") {
            LabeledContent(
                "Destination",
                value: trip.destination
            )

            LabeledContent(
                "Dates",
                value: dateDescription
            )

            LabeledContent(
                "Duration",
                value: "\(trip.durationInDays) days"
            )

            LabeledContent(
                "Travel pace",
                value: trip.travelPace.capitalized
            )

            LabeledContent(
                "Budget"
            ) {
                Text(
                    trip.budget,
                    format: .currency(
                        code: trip.currencyCode
                    )
                )
            }

            if !trip.interests.isEmpty {
                LabeledContent(
                    "Interests",
                    value: interestsDescription
                )
            }
        }
    }

    // MARK: - Empty itinerary

    private var emptyItinerarySection: some View {
        Section {
            VStack(spacing: 28) {

                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                VStack(spacing: 10) {
                    Text("No Itinerary Yet")
                        .font(.title2.bold())

                    Text("""
    Generate a personalized itinerary based on your destination, travel dates, budget, and interests.
    """)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    generateAIItinerary()
                } label: {

                    HStack(spacing: 10) {

                        if isGenerating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }

                        Text(
                            isGenerating
                            ? "Generating..."
                            : "Generate AI Itinerary"
                        )
                        .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.blue)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                }
                .disabled(isGenerating)

            }
            .padding(.vertical, 40)
            .padding(.horizontal)
        }
    }

    // MARK: - Regeneration

    private var regenerateSection: some View {
        Section {
            Button {
                isShowingRegenerateConfirmation = true
            } label: {
                generationButtonLabel(
                    normalTitle: "Regenerate AI Itinerary",
                    loadingTitle: "Regenerating..."
                )
            }
            .disabled(isGenerating)
        } footer: {
            Text(
                "Regenerating replaces the current itinerary. Locked activities are not preserved by the current mock generator."
            )
        }
    }

    @ViewBuilder
    private func generationButtonLabel(
        normalTitle: String,
        loadingTitle: String
    ) -> some View {
        if isGenerating {
            HStack(spacing: 10) {
                ProgressView()

                Text(loadingTitle)
            }
            .frame(maxWidth: .infinity)
        } else {
            Label(
                normalTitle,
                systemImage: "sparkles"
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Itinerary

    private var itinerarySection: some View {
        Section("Itinerary") {
            ForEach(trip.sortedDays) { day in
                NavigationLink {
                    TripDayDetailView(
                        trip: trip,
                        tripDay: day
                    )
                } label: {
                    TripDayRowView(
                        tripDay: day,
                        currencyCode: trip.currencyCode
                    )
                }
            }
        }
    }

    // MARK: - Budget

    private var budgetSection: some View {
        Section("Estimated Budget") {
            LabeledContent {
                Text(
                    trip.estimatedTotal,
                    format: .currency(
                        code: trip.currencyCode
                    )
                )
            } label: {
                Text("Itinerary estimate")
            }

            LabeledContent {
                Text(
                    trip.budget,
                    format: .currency(
                        code: trip.currencyCode
                    )
                )
            } label: {
                Text("User budget")
            }

            LabeledContent {
                Text(
                    budgetDifferenceMagnitude,
                    format: .currency(
                        code: trip.currencyCode
                    )
                )
                .foregroundStyle(
                    isOverBudget
                    ? .red
                    : .green
                )
            } label: {
                Text(
                    isOverBudget
                    ? "Over budget"
                    : "Remaining budget"
                )
            }
        }
    }

    // MARK: - Loading overlay

    private var generationOverlay: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)

                Text("Creating your itinerary")
                    .font(.headline)

                Text(
                    "This may take a few moments."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )
            .shadow(radius: 10)
        }
    }

    // MARK: - Generation

    private func generateAIItinerary() {
        guard !isGenerating else {
            return
        }

        isGenerating = true
        generationError = nil

        Task {
            do {
                try await itineraryGenerator.generate(
                    trip: trip,
                    modelContext: modelContext
                )
            } catch is CancellationError {
                // No alert is necessary for cancellation.
            } catch {
                generationError =
                    error.localizedDescription
            }

            isGenerating = false
        }
    }

    // MARK: - Formatting

    private var dateDescription: String {
        let start = trip.startDate.formatted(
            date: .abbreviated,
            time: .omitted
        )

        let end = trip.endDate.formatted(
            date: .abbreviated,
            time: .omitted
        )

        return "\(start) – \(end)"
    }

    private var interestsDescription: String {
        trip.interests
            .map {
                $0.capitalized
            }
            .joined(separator: ", ")
    }

    private var isOverBudget: Bool {
        trip.estimatedTotal > trip.budget
    }

    private var budgetDifferenceMagnitude: Double {
        abs(
            trip.budget
            - trip.estimatedTotal
        )
    }
}
