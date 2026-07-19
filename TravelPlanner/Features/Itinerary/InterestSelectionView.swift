import SwiftUI

struct InterestSelectionView: View {
    @Binding var selectedInterests: Set<TravelInterest>

    var body: some View {
        List {
            Section {
                ForEach(TravelInterest.allCases) { interest in
                    Button {
                        toggle(interest)
                    } label: {
                        HStack {
                            Label(
                                interest.title,
                                systemImage: interest.iconName
                            )

                            Spacer()

                            if selectedInterests.contains(interest) {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text(
                    "Your interests will be used to personalize the itinerary."
                )
            }
        }
        .navigationTitle("Interests")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ interest: TravelInterest) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
}
