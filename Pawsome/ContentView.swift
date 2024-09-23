import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

struct ContentView: View {
    #if canImport(UIKit)
    @State private var selectedImage: UIImage? = nil
    #elseif canImport(AppKit)
    @State private var selectedImage: NSImage? = nil
    #endif
    
    @State private var showImagePicker = false
    @State private var catImages: [Image] = [] // Array to hold images

    var body: some View {
        VStack {
            // ScrollView to display images as cards
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(catImages.indices, id: \.self) { index in
                        // Display each cat image as a card
                        catImages[index]
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                            .padding(.horizontal, 10)
                    }
                }
            }
            .padding()

            // Button to show image picker
            Button(action: {
                showImagePicker = true
            }) {
                Text("Upload Image")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()

            Spacer() // Pushes content above the bottom bar

            // Bottom Bar with 3 Buttons
            HStack {
                Spacer()
                Button(action: {
                    // Action for Home
                }) {
                    VStack {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                }
                Spacer()
                Button(action: {
                    // Action for Search
                }) {
                    VStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                }
                Spacer()
                Button(action: {
                    // Action for Profile
                }) {
                    VStack {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1)) // Background for the bottom bar
        }
        .sheet(isPresented: $showImagePicker, onDismiss: {
            if let image = selectedImage {
                #if canImport(UIKit)
                catImages.append(Image(uiImage: image))
                #elseif canImport(AppKit)
                catImages.append(Image(nsImage: image))
                #endif
            }
        }) {
            #if canImport(UIKit)
            ImagePicker_iOS(image: $selectedImage)
            #elseif canImport(AppKit)
            ImagePicker_macOS(image: $selectedImage)
            #endif
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 14") // Adjust this for macOS if needed
    }
}
