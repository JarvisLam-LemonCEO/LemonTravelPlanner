import SwiftUI

struct TripRowView: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "airplane")
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(.headline)

                Text(trip.destination)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(dateDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(trip.durationInDays)d")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.secondary.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

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
}
