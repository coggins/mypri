import SwiftUI
import MyPriKit

struct RootView: View {
    @ObservedObject var store: PriorityStore
    var fileName: String?
    var onDisconnect: () -> Void

    @State private var path: [UUID] = []
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack(path: $path) {
            MainListView(store: store) { id in
                path.append(id)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if let fileName {
                            Text("Synced file: \(fileName)")
                        }
                        Button("Disconnect File", role: .destructive, action: onDisconnect)
                    } label: {
                        Image(systemName: "icloud.fill")
                            .foregroundStyle(LinearGradient.mpAccent)
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                DetailView(item: store.binding(for: id), knownAssignees: store.allAssigneeNames) {
                    popDetail()
                }
                .navigationTitle(store.items.first(where: { $0.id == id })?.title ?? "Priority")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { popDetail() }
                            .foregroundStyle(LinearGradient.mpAccent)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .tint(Color.mpElectricBlue)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { newPhase in
            // Pull in any changes the Mac app made while we were in the
            // background — the file is shared via Google Drive, so there's
            // no push notification when it changes elsewhere.
            if newPhase == .active {
                store.refresh()
            }
        }
    }

    private func popDetail() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
}
