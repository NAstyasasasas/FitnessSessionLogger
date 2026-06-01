import SwiftUI

struct WorkoutRowView: View {
    let workout: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.title).font(.headline)
                Spacer()
                Text(workout.type.rawValue).font(.caption).padding(6).background(.thinMaterial).clipShape(Capsule())
            }
            HStack(spacing: 12) {
                Label("\(workout.durationMinutes) мин", systemImage: "clock")
                Label("\(workout.totalSets) подх.", systemImage: "list.bullet")
                Label(String(format: "%.0f кг", workout.totalVolume), systemImage: "scalemass")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
