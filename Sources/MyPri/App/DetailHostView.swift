import SwiftUI
import MyPriKit

/// NSHostingView sets its `rootView` once at creation, so a `DetailView`
/// hosted directly (as we do for the Mac's detail window) has nothing in
/// its own view tree observing `PriorityStore` — its `Binding<PriorityItem>`
/// writes reach the store fine, but nothing tells SwiftUI to re-render the
/// already-open window afterward, so e.g. the priority picker's highlight
/// only catches up if the window is closed and reopened. Observing `store`
/// here forces DetailView's body to re-run on every store change, so the
/// hosted window always reflects the live value.
struct DetailHostView: View {
    @ObservedObject var store: PriorityStore
    let id: UUID
    let onClose: () -> Void

    var body: some View {
        DetailView(item: store.binding(for: id), knownAssignees: store.allAssigneeNames, onClose: onClose)
    }
}
