import SwiftUI

struct EditPostView: View {
    @Binding var post: CatPost
    @Binding var isEditing: Bool
    var saveChanges: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Cat Name", text: $post.catName)

                TextField("Cat Breed", text: Binding(
                    get: { post.catBreed ?? "" },
                    set: { post.catBreed = $0 }
                ))

                TextField("Location", text: Binding(
                    get: { post.location ?? "" },
                    set: { post.location = $0 }
                ))

                TextField("Description", text: Binding(
                    get: { post.postDescription ?? "" }, // ✅ Fixed issue with optional
                    set: { post.postDescription = $0 }
                ))

                if let age = post.catAge { // ✅ Handle optional age properly
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
                ToolbarItem(placement: .navigationBarTrailing) {
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
