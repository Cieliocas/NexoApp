//
//  ContentView.swift
//  Nexo
//
//  Created by Franciélio Castro on 03/04/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: [Subject.self, Term.self], inMemory: true)
}
