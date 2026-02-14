import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSeeded = false
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if !hasSeeded {
                Color(.systemBackground)
            } else if showOnboarding {
                OnboardingView {
                    withAnimation {
                        showOnboarding = false
                    }
                }
            } else {
                TaskListView()
            }
        }
        .onAppear {
            SeedDataService.seedIfNeeded(context: modelContext)
            let settings = AppSettings.shared(in: modelContext)
            showOnboarding = !settings.hasCompletedOnboarding
            hasSeeded = true
        }
    }
}
