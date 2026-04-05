//
//  NexoApp.swift
//  Nexo
//
//  Created by Franciélio Castro on 03/04/26.
//

import SwiftUI
import SwiftData

@main
struct NexoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Subject.self, Term.self])
    }
}
