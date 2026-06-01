import Foundation
import Observation

@MainActor
@Observable
final class WorkoutsViewModel {
    private let storage: WorkoutStorage
    private let exerciseService: ExerciseService

    var workouts: [WorkoutSession] = []
    var exercises: [Exercise] = []
    var state: ViewState = .loading
    var selectedFilter: WorkoutType?
    var searchText: String = ""

    init(storage: WorkoutStorage, exerciseService: ExerciseService) {
        self.storage = storage
        self.exerciseService = exerciseService
    }

    var filteredWorkouts: [WorkoutSession] {
        workouts
            .filter { selectedFilter == nil || $0.type == selectedFilter }
            .filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.date > $1.date }
    }

    var totalWorkouts: Int { workouts.count }
    var totalVolume: Double { workouts.reduce(0) { $0 + $1.totalVolume } }
    var totalSets: Int { workouts.reduce(0) { $0 + $1.totalSets } }
    var averageDuration: Int {
        guard !workouts.isEmpty else { return 0 }
        return workouts.reduce(0) { $0 + $1.durationMinutes } / workouts.count
    }

    func load() async {
        state = .loading
        do {
            async let savedWorkouts = storage.loadWorkouts()
            async let fetchedExercises = exerciseService.fetchExercises(type: nil)
            workouts = try await savedWorkouts
            exercises = try await fetchedExercises
            state = workouts.isEmpty ? .empty : .content
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func addWorkout(_ workout: WorkoutSession) async {
        workouts.append(workout)
        await persist()
    }

    func updateWorkout(_ workout: WorkoutSession) async {
        guard let index = workouts.firstIndex(where: { $0.id == workout.id }) else { return }
        workouts[index] = workout
        await persist()
    }

    func deleteWorkout(at offsets: IndexSet) async {
        let idsToDelete = offsets.map { filteredWorkouts[$0].id }
        workouts.removeAll { idsToDelete.contains($0.id) }
        await persist()
    }

    func setFilter(_ type: WorkoutType?) {
        selectedFilter = type
    }

    private func persist() async {
        do {
            try await storage.saveWorkouts(workouts)
            state = workouts.isEmpty ? .empty : .content
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
