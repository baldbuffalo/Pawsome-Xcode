import SwiftUI

struct FormView: View {
    var imageUI: UIImage?

    @State private var catName: String = ""
    @State private var catBreed: String = ""
    @State private var catColor: String = ""
    @State private var catAge: Int = 0
    @State private var additionalNotes: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Display the captured image at the top of the form
                if let image = imageUI {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .padding(.bottom, 20)
                } else {
                    Text("No image captured.")
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }

                // Form fields for inputting cat information
                Group {
                    Text("Cat Information")
                        .font(.title2)
                        .padding(.bottom, 10)

                    TextField("Cat Name", text: $catName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 10)

                    TextField("Cat Breed", text: $catBreed)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 10)

                    TextField("Cat Color", text: $catColor)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 10)

                    Stepper(value: $catAge, in: 0...25) {
                        Text("Cat Age: \(catAge)")
                    }
                    .padding(.bottom, 10)

                    TextField("Additional Notes", text: $additionalNotes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 10)
                }

                // Submit button
                Button(action: {
                    submitForm()
                }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Cat Information Form")
    }

    // Function to handle form submission
    func submitForm() {
        // Process the form data (e.g., save it, upload it, etc.)
        print("Form submitted:")
        print("Cat Name: \(catName)")
        print("Cat Breed: \(catBreed)")
        print("Cat Color: \(catColor)")
        print("Cat Age: \(catAge)")
        print("Additional Notes: \(additionalNotes)")
    }
}
