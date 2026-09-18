import SwiftUI
import MyPriKit

/// Shown until the user has pointed the app at a priorities.json file.
/// That file can live anywhere the Files app can reach — most usefully in
/// Google Drive, so the same file the Mac app writes to stays in sync here.
struct ConnectView: View {
    @ObservedObject var connector: DriveConnector

    @State private var showOpenPicker = false
    @State private var showExportPicker = false
    @State private var tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("priorities.json")

    var body: some View {
        ZStack {
            MPPanelBackground()

            VStack(spacing: 22) {
                Spacer()

                ZStack {
                    Circle().fill(LinearGradient.mpAccent).frame(width: 64, height: 64)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black.opacity(0.75))
                }

                Text("MyPri")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.mpTextPrimary)

                Text("Connect the same priorities.json your Mac uses. Put it in Google Drive (or any Files-integrated location) so both devices stay in sync.")
                    .font(.system(size: 13))
                    .foregroundColor(.mpTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                VStack(spacing: 12) {
                    Button {
                        showOpenPicker = true
                    } label: {
                        Text("Choose Existing File")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .background(Capsule().fill(LinearGradient.mpAccent))
                    .foregroundColor(.black.opacity(0.85))

                    Button {
                        createAndExportNewFile()
                    } label: {
                        Text("Create New File…")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .background(Capsule().strokeBorder(LinearGradient.mpAccent, lineWidth: 1.4))
                    .foregroundColor(.mpTextPrimary)
                }
                .padding(.horizontal, 36)

                Spacer()
                Spacer()
            }
        }
        .sheet(isPresented: $showOpenPicker) {
            DocumentPicker(mode: .open) { url in
                connector.connect(to: url)
                showOpenPicker = false
            }
        }
        .sheet(isPresented: $showExportPicker) {
            DocumentPicker(mode: .exportNew(tempURL: tempFileURL)) { url in
                connector.connect(to: url)
                showExportPicker = false
            }
        }
    }

    private func createAndExportNewFile() {
        try? "[]".data(using: .utf8)?.write(to: tempFileURL, options: .atomic)
        showExportPicker = true
    }
}
