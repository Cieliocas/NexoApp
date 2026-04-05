import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [GlossaryCategory]
    @StateObject private var viewModel = GlossaryViewModel()

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home",       systemImage: "house.fill") }

            CategoriesView()
                .tabItem { Label("Categories", systemImage: "folder.fill") }

            SearchView()
                .tabItem { Label("Search",     systemImage: "magnifyingglass") }
        }
        .environmentObject(viewModel)
        .onAppear {
            viewModel.insertDefaultCategoriesIfNeeded(
                modelContext: modelContext,
                existing: categories
            )
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Term.self, GlossaryCategory.self, TermRelationship.self],
                        inMemory: true)
}
