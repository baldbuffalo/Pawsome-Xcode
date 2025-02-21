import SwiftUI

struct EditPostView: View {
    @Binding var post: CatPost
    @Binding var isEditing: Bool
    var saveChanges: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Cat Name", text: $post.catName)
                TextField("Cat Breed", text: optionalBinding($post).catBreed)
                TextField("Location", text: optionalBinding($post).location)
                TextField("Description", text: optionalBinding($post).postDescription)
                
                // Handling catAge properly
                TextField("Age", value: optionalBinding($post).catAge, formatter: NumberFormatter())
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    isEditing = false
                },
                trailing: Button("Save") {
                    saveChanges()  // Save the changes
                    isEditing = false  // Close the edit view
                }
            )
            .navigationTitle("Edit Post")
        }
    }
    
    // Helper function to provide a safe binding for optional properties
    private func optionalBinding(_ binding: Binding<CatPost>) -> Binding<CatPost> {
        return Binding(
            get: { binding.wrappedValue },
            set: { binding.wrappedValue = $0 }
        )
    }
}
