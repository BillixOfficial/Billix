//
//  BillixApp.swift
//  Billix
//
//  Created by Falana on 11/15/25.
//

import SwiftUI
import SwiftData

@main
struct BillixApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StoredBill.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            LoginView()
        }
        .modelContainer(sharedModelContainer)
    }
}
