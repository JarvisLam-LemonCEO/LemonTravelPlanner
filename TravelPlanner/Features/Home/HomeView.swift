import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        sort: \Trip.startDate,
        order: .forward
    )
    private var trips: [Trip]

    @State private var isShowingCreateTrip = false

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    emptyState
                } else {
                    tripList
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingCreateTrip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create Trip")
                }
            }
            .sheet(isPresented: $isShowingCreateTrip) {
                CreateTripView()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                "No Trips Yet",
                systemImage: "airplane.departure"
            )
        } description: {
            Text("Create your first trip and start planning your itinerary.")
        } actions: {
            Button("Create Trip") {
                isShowingCreateTrip = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var tripList: some View {
        List {
            ForEach(trips) { trip in
                NavigationLink {
                    TripDetailView(trip: trip)
                } label: {
                    TripRowView(trip: trip)
                }
            }
            .onDelete(perform: deleteTrips)
        }
    }

    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(trips[index])
        }

        do {
            try modelContext.save()
        } catch {
            print("Unable to delete trip: \(error)")
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Trip.self, inMemory: true)
}
