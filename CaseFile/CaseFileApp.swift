import SwiftUI

@main
struct CaseFileApp: App {
    let persistenceController = Persistence.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
