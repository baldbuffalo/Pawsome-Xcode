import Firebase
import FirebaseFirestore

struct UserRegistration {
    static func registerUser(username: String, profilePicture: String) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "username": username,
            "profilePicture": profilePicture,
            "joinDate": Timestamp(date: Date())
        ]
        
        // Create a new document in the "Users" collection with the user's username as the document ID
        db.collection("Users").document(username).setData(userData) { error in
            if let error = error {
                print("Error adding user: \(error)")
            } else {
                print("User added successfully!")
            }
        }
    }
    
    static func createUserWithAuth(email: String, password: String, profilePicture: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
                return
            }
            
            // Get the user's unique ID
            guard let userId = authResult?.user.uid else { return }
            
            // Call the registerUser function
            registerUser(username: userId, profilePicture: profilePicture)
        }
    }
}
