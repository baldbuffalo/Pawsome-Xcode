import SwiftUI

#if os(iOS)
import PhotosUI
import UIKit
#elseif os(macOS)
import AppKit
import AVFoundation
#endif

struct ScanView: View {
    @EnvironmentObject var appState: PawsomeApp.AppState
    @Binding var activeHomeFlow: PawsomeApp.HomeFlow?
    var username: String

    // MARK: - State
    @State private var showSourcePicker = false
    @State private var showCameraPicker = false
    @State private var showPhotoPicker = false

    #if os(macOS)
    @State private var isConnectingContinuityCamera = false
    @State private var waitingForPicture = false
    @State private var continuityCameraDeviceName: String = "iPhone"
    @State private var overlayScale: CGFloat = 0.9
    @State private var overlayOpacity: Double = 0

    // Instant Capture
    @State private var isShowingLivePreview = false
    @State private var capturedImage: NSImage?
    private let cameraController = MacContinuityCameraController()
    #endif

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.purple.opacity(0.25), .blue.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {

                // ⬅️ Back
                HStack {
                    Button {
                        showSourcePicker = false
                        showCameraPicker = false
                        showPhotoPicker = false
                        activeHomeFlow = nil

                        #if os(macOS)
                        cameraController.stopSession()
                        #endif
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                // 📸 Image selection card
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

            // MARK: - macOS Overlays
            #if os(macOS)
            if isConnectingContinuityCamera || waitingForPicture {
                VStack(spacing: 14) {
                    ProgressView()
                        .scaleEffect(1.1)

                    if isConnectingContinuityCamera {
                        Text("Preparing iPhone Camera…")
                            .font(.headline)
                        Text("Unlock your iPhone and keep it nearby")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Waiting for picture…")
                            .font(.headline)
                        Text("Take a photo on your iPhone")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
                .frame(width: 320)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(radius: 12)
                .scaleEffect(overlayScale)
                .opacity(overlayOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        overlayScale = 1
                        overlayOpacity = 1
                    }
                }
            }

            if isShowingLivePreview {
                VStack {
                    MacCameraPreviewView(session: cameraController.session)
                        .frame(width: 400, height: 300)
                        .cornerRadius(16)
                        .shadow(radius: 8)

                    HStack {
                        Button("Capture") {
                            cameraController.capturePhoto { image in
                                if let image = image {
                                    capturedImage = image
                                    appState.selectedImage = image
                                    activeHomeFlow = .form
                                }
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)

                        Button("Cancel") {
                            cameraController.stopSession()
                            isShowingLivePreview = false
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            #endif
        }

        // MARK: - Source Picker
        .confirmationDialog("Select Source", isPresented: $showSourcePicker) {
            Button("Photo Library") { showPhotoPicker = true }

            Button {
                showCameraPicker = true
            } label: {
                #if os(macOS)
                Text("Capture from iPhone")
                #else
                Text("Take Photo")
                #endif
            }

            Button("Cancel", role: .cancel) {}
        }

        // MARK: - iOS Camera & Photo Library
        #if os(iOS)
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera) { image in
                guard let image else { return }
                appState.selectedImage = image
                activeHomeFlow = .form
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                guard let image else { return }
                appState.selectedImage = image
                activeHomeFlow = .form
            }
        }
        #endif

        // MARK: - macOS Triggers
        #if os(macOS)
        .onChange(of: showCameraPicker) { _, newValue in
            if newValue { startContinuityCameraFlow() }
        }

        .onChange(of: showPhotoPicker) { _, newValue in
            if newValue { openFileMac() }
        }
        #endif
    }

    // MARK: - macOS Helpers
    #if os(macOS)
    private func startContinuityCameraFlow() {
        isConnectingContinuityCamera = true
        waitingForPicture = false
        overlayScale = 0.9
        overlayOpacity = 0

        cameraController.startSession()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isConnectingContinuityCamera = false
                waitingForPicture = true
                isShowingLivePreview = true
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

            showPhotoPicker = false
        }
    }
    #endif
}
