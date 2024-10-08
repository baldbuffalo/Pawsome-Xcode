import SwiftUI

// Separate FormView in Form.swift
struct Form: View {
    var imageUI: UIImage?
    
    // State variables to hold user input
    @State private var catName: String = ""
    @State private var catBreed: String = ""
    @State private var catAge: String = ""
    @State private var additionalInfo: String = ""
    
    var body: some View {
        VStack {
            if let image = imageUI {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .padding(.bottom, 20)
            } else {
                Text("No image available")
                    .padding(.bottom, 20)
            }

            // Cat Name input field
            TextField("Enter cat's name", text: $catName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)

            // Cat Breed input field
            TextField("Enter cat's breed", text: $catBreed)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)

            // Cat Age input field
            TextField("Enter cat's age", text: $catAge)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)

            // Additional Information input field
            TextField("Any additional info?", text: $additionalInfo)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 20)
            
            Spacer()

            // Submit Button
            Button(action: {
                // Handle form submission
                submitForm()
            }) {
                Text("Submit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Cat Information")
    }
    
    // Function to handle form submission
    private func submitForm() {
        print("Cat Name: \(catName)")
        print("Cat Breed: \(catBreed)")
        print("Cat Age: \(catAge)")
        print("Additional Info: \(additionalInfo)")
        // Add additional logic to save or handle the input data
    }
}
