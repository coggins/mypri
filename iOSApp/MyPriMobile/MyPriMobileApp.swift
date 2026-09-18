import SwiftUI
import MyPriKit

@main
struct MyPriMobileApp: App {
    @StateObject private var connector = DriveConnector()

    var body: some Scene {
        WindowGroup {
            Group {
                if let store = connector.store {
                    RootView(store: store, fileName: connector.fileName) {
                        connector.disconnect()
                    }
                } else {
                    ConnectView(connector: connector)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
