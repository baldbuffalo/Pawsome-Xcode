import SwiftUI

#if os(iOS)
import PhotosUI
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ScanView: View {
    @EnvironmentObject var appState: PawsomeApp.AppState
    @Binding var activeHomeFlow: PawsomeApp.HomeFlow?
    var username: String

    // MARK: - State
    @State private var showSourcePicker = false
    @State private var showCameraPicker = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.purple.opacity(0.25), .blue.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {

                // ⬅️ BACK BUTTON
                HStack {
                    Button {
                        // Dismiss any open modals first
                        showSourcePicker = false
                        showCameraPicker = false
                        showPhotoPicker = false
                        showFilePicker = false

                        // Then go back
                        activeHomeFlow = nil
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.headline)
                    }

                    Spacer()
                }
                .padding()

                Spacer()

                // 📸 IMAGE SELECTION CARD
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.blue)

                    Text("Choose an image")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Button {
                        showSourcePicker = true
                    } label: {
                        Text("Choose Image")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)

                Spacer()
            }
        }

        // MARK: - iOS Native Action Sheet
        .confirmationDialog("Select Source",
                            isPresented: $showSourcePicker,
                            titleVisibility: .visible) {
            Button("Photo Library") { showPhotoPicker = true }
            Button("Take Photo or Video") { showCameraPicker = true }
            Button("Choose File") { showFilePicker = true }
            // ⚠️ Remove explicit Cancel button — iOS shows a system Cancel button automatically
        }

        // MARK: - Camera Sheet
        .sheet(isPresented: $showCameraPicker) {
            #if os(iOS)
            ImagePicker(sourceType: .camera) { image in
                guard let image else { return }
                appState.selectedImage = image
                activeHomeFlow = .form
            }
            #elseif os(macOS)
            macOSOpenPanel(useContinuityCamera: true)
            #endif
        }

        // MARK: - Photo Library Sheet
        .sheet(isPresented: $showPhotoPicker) {
            #if os(iOS)
            ImagePicker(sourceType: .photoLibrary) { image in
                guard let image else { return }
                appState.selectedImage = image
                activeHomeFlow = .form
            }
            #elseif os(macOS)
            macOSOpenPanel(useContinuityCamera: false)
            #endif
        }

        // MARK: - File Importer
        #if os(iOS)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result,
               let url = urls.first,
               let image = UIImage(contentsOfFile: url.path) {
                appState.selectedImage = image
                activeHomeFlow = .form
            }
        }
        #elseif os(macOS)
        .onChange(of: showFilePicker) { _, newValue in
            if newValue { openFileMac() }
        }
        #endif
    }

    // MARK: - macOS Helpers
    #if os(macOS)
    private func macOSOpenPanel(useContinuityCamera: Bool) -> some View {
        EmptyView().onAppear {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.image]
            panel.allowsMultipleSelection = false
            panel.message = useContinuityCamera
                ? "Take a photo using Continuity Camera or select an image"
                : "Choose a photo"

            panel.begin { response in
                if response == .OK,
                   let url = panel.urls.first,
                   let image = NSImage(contentsOf: url) {
                    appState.selectedImage = image
                    activeHomeFlow = .form
                }
                showCameraPicker = false
                showPhotoPicker = false
            }
        }
    }

    private func openFileMac() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false

        panel.begin { response in
            if response == .OK,
               let url = panel.urls.first,
               let image = NSImage(contentsOf: url) {
                appState.selectedImage = image
                activeHomeFlow = .form
            }
            showFilePicker = false
        }
    }
    #endif
}
