import Foundation

protocol WorkoutStorage {
    func loadWorkouts() async throws -> [WorkoutSession]
    func saveWorkouts(_ workouts: [WorkoutSession]) async throws
}

actor FileWorkoutStorage: WorkoutStorage {
    private let fileName = "workouts.json"

    func loadWorkouts() async throws -> [WorkoutSession] {
        let url = try fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WorkoutSession].self, from: data)
    }

    func saveWorkouts(_ workouts: [WorkoutSession]) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(workouts)
        try data.write(to: try fileURL(), options: [.atomic])
    }

    private func fileURL() throws -> URL {
        let documents = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return documents.appendingPathComponent(fileName)
    }
}

actor InMemoryWorkoutStorage: WorkoutStorage {
    private var workouts: [WorkoutSession]

    init(workouts: [WorkoutSession] = []) {
        self.workouts = workouts
    }

    func loadWorkouts() async throws -> [WorkoutSession] { workouts }
    func saveWorkouts(_ workouts: [WorkoutSession]) async throws { self.workouts = workouts }
}
