import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AddWorkoutViewModel {
    var title = ""
    var type: WorkoutType = .glutes
    var date = Date()
    var durationMinutes = 60
    var note = ""
    var photoData: Data?
    var selectedExercises: [LoggedExercise] = []

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedExercises.isEmpty
    }

    func addExercise(_ exercise: Exercise) {
        let logged = LoggedExercise(
            exercise: exercise,
            sets: [
                ExerciseSet(reps: 10, weight: 0, note: ""),
                ExerciseSet(reps: 10, weight: 0, note: ""),
                ExerciseSet(reps: 10, weight: 0, note: "")
            ]
        )
        selectedExercises.append(logged)
    }

    func addSet(to exerciseID: UUID) {
        guard let index = selectedExercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        let previous = selectedExercises[index].sets.last ?? ExerciseSet(reps: 10, weight: 0, note: "")
        selectedExercises[index].sets.append(ExerciseSet(reps: previous.reps, weight: previous.weight, note: ""))
    }

    func removeExercise(at offsets: IndexSet) {
        selectedExercises.remove(atOffsets: offsets)
    }

    func removeSet(exerciseID: UUID, setID: UUID) {
        guard let exerciseIndex = selectedExercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        selectedExercises[exerciseIndex].sets.removeAll { $0.id == setID }
    }

    func buildWorkout() -> WorkoutSession {
        WorkoutSession(title: title, type: type, date: date, durationMinutes: durationMinutes, exercises: selectedExercises, note: note, photoData: photoData)
    }
}
