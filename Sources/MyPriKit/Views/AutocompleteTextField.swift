import SwiftUI

#if os(macOS)
import AppKit

/// A macOS text field that lets Tab be intercepted to accept an inline
/// autocomplete suggestion — returning `true` from `doCommandBy:` tells
/// AppKit "handled, don't do your default thing," which is the only
/// reliable way to stop Tab from also moving focus to the next control.
/// (A SwiftUI `.keyboardShortcut(.tab, ...)` button runs *alongside*
/// default Tab handling rather than replacing it, so it can't do this.)
/// When there's no suggestion to accept, we return `false` and Tab moves
/// focus normally, exactly as expected everywhere else in the window.
struct AutocompleteTextField: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String
    /// Called when Tab is pressed; return `true` if a suggestion was
    /// accepted (suppresses the default focus change), `false` otherwise.
    var acceptSuggestionOnTab: () -> Bool
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = placeholder
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 12)
        field.textColor = NSColor(Color.mpTextPrimary)
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: AutocompleteTextField

        init(_ parent: AutocompleteTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                return parent.acceptSuggestionOnTab()
            }
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}
#endif
