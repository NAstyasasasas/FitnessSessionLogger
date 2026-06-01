import XCTest
@testable import FitnessSessionLogger

@MainActor
final class WorkoutsViewModelTests: XCTestCase {
    func testLoadEmptyState() async {
        let vm = WorkoutsViewModel(storage: InMemoryWorkoutStorage(), exerciseService: MockExerciseService())
        await vm.load()
        XCTAssertEqual(vm.state, .empty)
        XCTAssertEqual(vm.workouts.count, 0)
        XCTAssertFalse(vm.exercises.isEmpty)
    }

    func testAddWorkout() async {
        let storage = InMemoryWorkoutStorage()
        let vm = WorkoutsViewModel(storage: storage, exerciseService: MockExerciseService())
        await vm.load()
        await vm.addWorkout(.mock)
        XCTAssertEqual(vm.workouts.count, 1)
        XCTAssertEqual(vm.state, .content)
    }

    func testFilteringByType() async {
        let vm = WorkoutsViewModel(storage: InMemoryWorkoutStorage(workouts: [.mock, .upperMock]), exerciseService: MockExerciseService())
        await vm.load()
        vm.setFilter(.glutes)
        XCTAssertEqual(vm.filteredWorkouts.count, 1)
        XCTAssertEqual(vm.filteredWorkouts.first?.type, .glutes)
    }

    func testSearch() async {
        let vm = WorkoutsViewModel(storage: InMemoryWorkoutStorage(workouts: [.mock, .upperMock]), exerciseService: MockExerciseService())
        await vm.load()
        vm.searchText = "upper"
        XCTAssertEqual(vm.filteredWorkouts.count, 1)
    }

    func testStorageRestore() async throws {
        let storage = InMemoryWorkoutStorage()
        try await storage.saveWorkouts([.mock])
        let restored = try await storage.loadWorkouts()
        XCTAssertEqual(restored.count, 1)
    }
}

extension WorkoutSession {
    static let mock = WorkoutSession(
        title: "Glute day",
        type: .glutes,
        date: Date(),
        durationMinutes: 70,
        exercises: [LoggedExercise(exercise: Exercise.mockExercises[0], sets: [ExerciseSet(reps: 10, weight: 100, note: "")])],
        note: "Good session"
    )

    static let upperMock = WorkoutSession(
        title: "Upper body",
        type: .upperBody,
        date: Date(),
        durationMinutes: 50,
        exercises: [LoggedExercise(exercise: Exercise.mockExercises[4], sets: [ExerciseSet(reps: 12, weight: 30, note: "")])],
        note: ""
    )
}
