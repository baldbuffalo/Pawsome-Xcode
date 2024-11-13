import SwiftUI

struct EditPostView: View {
    @Binding var post: CatPost
    @Binding var isEditing: Bool
    var saveChanges: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Cat Name", text: $post.catName)
                TextField("Cat Breed", text: Binding($post.catBreed, default: ""))
                TextField("Age", value: $post.catAge, formatter: NumberFormatter())
                TextField("Location", text: Binding($post.location, default: ""))
                TextField("Description", text: Binding($post.postDescription, default: ""))
                
                // You can add more fields as needed (image picker, etc.)
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
}
