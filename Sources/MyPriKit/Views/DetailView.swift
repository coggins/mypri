import SwiftUI

public struct DetailView: View {
    @Binding var item: PriorityItem
    var onClose: () -> Void

    @State private var newPersonName: String = ""
    @State private var newLinkTitle: String = ""
    @State private var newLinkURL: String = ""

    public init(item: Binding<PriorityItem>, onClose: @escaping () -> Void) {
        self._item = item
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            MPPanelBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    titleSection
                    prioritySection
                    assigneesSection
                    notesSection
                    linksSection
                    timestampFooter
                }
                .padding(24)
            }

            // Invisible button so pressing Escape always saves & closes,
            // even while a text field or editor has focus. Only relevant on
            // macOS (or iPad with a hardware keyboard) — harmless elsewhere.
            Button("") { onClose() }
                .keyboardShortcut(.cancelAction)
                .opacity(0)
                .frame(width: 0, height: 0)
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 560)
        #endif
    }

    private var titleSection: some View {
        TextField("Priority title", text: $item.title)
            .textFieldStyle(.plain)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.mpTextPrimary)
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Priority")
            HStack(spacing: 8) {
                ForEach(PriorityLevel.allCases) { level in
                    Button {
                        item.priority = level
                    } label: {
                        HStack(spacing: 6) {
                            Circle().fill(level.color).frame(width: 8, height: 8)
                            Text("\(level.label) · \(level.description)")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(item.priority == level ? Color.mpSurfaceElevated : Color.mpSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(item.priority == level ? level.color : Color.mpBorder, lineWidth: item.priority == level ? 1.5 : 1)
                        )
                        .foregroundColor(.mpTextPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var assigneesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Assigned To")

            if !item.assignees.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(item.assignees, id: \.self) { name in
                        TagChipView(name: name) {
                            item.assignees.removeAll { $0 == name }
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Add a person and press Return", text: $newPersonName)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.mpSurface))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mpBorder, lineWidth: 1))
                    .font(.system(size: 12))
                    .foregroundColor(.mpTextPrimary)
                    .onSubmit(addPerson)

                Button(action: addPerson) {
                    Image(systemName: "plus")
                        .foregroundStyle(LinearGradient.mpAccent)
                }
                .buttonStyle(.plain)
                .disabled(newPersonName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Notes")
            TextEditor(text: $item.notes)
                .scrollContentBackground(.hidden)
                .font(.system(size: 13))
                .foregroundColor(.mpTextPrimary)
                .frame(minHeight: 140)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.mpSurface))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mpBorder, lineWidth: 1))
        }
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Links")

            ForEach(item.links) { link in
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 11))
                        .foregroundColor(.mpElectricBlue)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(link.displayTitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.mpTextPrimary)
                        if let url = link.normalizedURL {
                            Link(url.absoluteString, destination: url)
                                .font(.system(size: 10))
                                .foregroundColor(.mpTextSecondary)
                        }
                    }

                    Spacer()

                    Button {
                        item.links.removeAll { $0.id == link.id }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.mpTextTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.mpSurface))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mpBorder, lineWidth: 1))
            }

            HStack(spacing: 8) {
                TextField("Title", text: $newLinkTitle)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.mpSurface))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mpBorder, lineWidth: 1))
                    .font(.system(size: 12))
                    .foregroundColor(.mpTextPrimary)
                    .frame(maxWidth: 140)

                TextField("https://…", text: $newLinkURL)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.mpSurface))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mpBorder, lineWidth: 1))
                    .font(.system(size: 12))
                    .foregroundColor(.mpTextPrimary)
                    .onSubmit(addLink)

                Button(action: addLink) {
                    Image(systemName: "plus")
                        .foregroundStyle(LinearGradient.mpAccent)
                }
                .buttonStyle(.plain)
                .disabled(newLinkURL.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var timestampFooter: some View {
        HStack {
            Text("Created \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
            Spacer()
            Text("Updated \(item.updatedAt.formatted(date: .abbreviated, time: .shortened))")
        }
        .font(.system(size: 10))
        .foregroundColor(.mpTextTertiary)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundColor(.mpTextTertiary)
    }

    private func addPerson() {
        let name = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !item.assignees.contains(name) else { newPersonName = ""; return }
        item.assignees.append(name)
        newPersonName = ""
    }

    private func addLink() {
        let urlString = newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty else { return }
        let title = newLinkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        item.links.append(LinkItem(title: title, urlString: urlString))
        newLinkTitle = ""
        newLinkURL = ""
    }
}
