import SwiftUI

@main
struct CaseFileApp: App {
    let persistenceController = Persistence.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .windowStyle(.hiddenTitleBar)  // タイトルバーを統合
        .defaultPosition(.center)      // ✅ ウィンドウを画面中央に配置
        .defaultSize(width: 1200, height: 800)  // ✅ デフォルトサイズを設定
    }
}
