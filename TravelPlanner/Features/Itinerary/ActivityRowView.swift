import SwiftUI

struct ActivityRowView: View {
    let activity: Activity
    let currencyCode: String

    private var category: ActivityCategory {
        ActivityCategory(
            rawValue: activity.category
        ) ?? .other
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: category.iconName)
                .font(.headline)
                .frame(width: 40, height: 40)
                .background(.blue.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(activity.name)
                        .font(.headline)

                    if activity.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Locked activity")
                    }
                }

                Text(timeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !activity.locationName.isEmpty {
                    Label(
                        activity.locationName,
                        systemImage: "mappin.and.ellipse"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if !activity.activityDescription.isEmpty {
                    Text(activity.activityDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                if activity.admissionFee > 0 ||
                    activity.transportationCost > 0 {
                    HStack(spacing: 12) {
                        if activity.admissionFee > 0 {
                            Label {
                                Text(
                                    activity.admissionFee,
                                    format: .currency(
                                        code: currencyCode
                                    )
                                )
                            } icon: {
                                Image(systemName: "ticket")
                            }
                        }

                        if activity.transportationCost > 0 {
                            Label {
                                Text(
                                    activity.transportationCost,
                                    format: .currency(
                                        code: currencyCode
                                    )
                                )
                            } icon: {
                                Image(systemName: "tram")
                            }
                        }
                    }
                    .font(.caption.weight(.semibold))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }

    private var timeDescription: String {
        let start = activity.startTime.formatted(
            date: .omitted,
            time: .shortened
        )

        let end = activity.endTime.formatted(
            date: .omitted,
            time: .shortened
        )

        return "\(start) – \(end)"
    }
}
