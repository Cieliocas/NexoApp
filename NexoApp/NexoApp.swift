import SwiftUI
import SwiftData

@main
struct NexoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: [Term.self, GlossaryCategory.self, TermRelationship.self]
        )
    }
}
