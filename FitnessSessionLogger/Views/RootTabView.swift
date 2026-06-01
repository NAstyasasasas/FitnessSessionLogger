import SwiftUI

struct RootTabView: View {
    @Bindable var viewModel: WorkoutsViewModel

    var body: some View {
        TabView {
            WorkoutsListView(viewModel: viewModel)
                .tabItem { Label("Тренировки", systemImage: "dumbbell") }

            StatsView(viewModel: viewModel)
                .tabItem { Label("Календарь", systemImage: "calendar") }

            WorkoutTimerView()
                .tabItem { Label("Таймер", systemImage: "timer") }
        }
        .task { await viewModel.load() }
    }
}
