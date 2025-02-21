import SwiftUI

struct EditPostView: View {
    @Binding var post: CatPost
    @Binding var isEditing: Bool
    var saveChanges: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Cat Name", text: $post.catName)

                // For optional Cat Breed
                TextField("Cat Breed", text: Binding(
                    get: { post.catBreed ?? "" },
                    set: { post.catBreed = $0.isEmpty ? nil : $0 } // Update to nil if empty
                ))

                // For optional Location
                TextField("Location", text: Binding(
                    get: { post.location ?? "" },
                    set: { post.location = $0.isEmpty ? nil : $0 } // Update to nil if empty
                ))

                // For optional Description
                TextField("Description", text: Binding(
                    get: { post.postDescription ?? "" }, // Fallback to empty string if nil
                    set: { post.postDescription = $0.isEmpty ? nil : $0 } // Set nil if empty
                ))

                // For optional Age
                if let age = post.catAge {
                    TextField("Age", value: Binding(
                        get: { age },
                        set: { post.catAge = $0 }
                    ), formatter: NumberFormatter())
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        saveChanges()
                        isEditing = false
                    }
                }
            }
            .navigationTitle("Edit Post")
        }
    }
}
