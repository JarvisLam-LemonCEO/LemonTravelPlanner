import SwiftUI

struct TripDayRowView: View {
    let tripDay: TripDay
    let currencyCode: String

    var body: some View {
        HStack(spacing: 14) {
            VStack {
                Text("DAY")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("\(tripDay.dayNumber)")
                    .font(.title2.bold())
            }
            .frame(width: 50, height: 54)
            .background(.blue.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    tripDay.date.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
                .font(.headline)

                Text(tripDay.city)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(
                    "\(tripDay.activities.count) activities"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(
                tripDay.estimatedTotal,
                format: .currency(code: currencyCode)
            )
            .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 4)
    }
}
