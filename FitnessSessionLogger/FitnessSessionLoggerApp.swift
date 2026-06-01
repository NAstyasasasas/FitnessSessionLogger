import SwiftUI

@main
struct FitnessSessionLoggerApp: App {
    @State private var viewModel = WorkoutsViewModel(
        storage: FileWorkoutStorage(),
        exerciseService: MockExerciseService()
    )

    var body: some Scene {
        WindowGroup {
            RootTabView(viewModel: viewModel)
        }
    }
}
