import SwiftUI
import Firebase
import FirebaseFirestore

// MARK: - Firestore Model
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var age: Int
}

// MARK: - Firestore ViewModel
class FirestoreViewModel: ObservableObject {
    @Published var users: [User] = []
    private var db = Firestore.firestore()

    // 🔥 Fetch Users from Firestore
    func fetchUsers() {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }

            self.users = snapshot?.documents.compactMap { doc in
                try? doc.data(as: User.self)
            } ?? []
        }
    }

    // 🔥 Add User to Firestore
    func addUser(name: String, age: Int) {
        let newUser = User(name: name, age: age)
        do {
            _ = try db.collection("users").addDocument(from: newUser)
        } catch {
            print("Error adding user: \(error)")
        }
    }
}

// MARK: - SwiftUI View
struct ContentView: View {
    @StateObject var viewModel = FirestoreViewModel()
    @State private var name = ""
    @State private var age = ""

    var body: some View {
        NavigationView {
            VStack {
                // 🔹 Input Fields
                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Age", text: $age)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // 🔹 Add User Button
                Button("Add User") {
                    if let ageInt = Int(age) {
                        viewModel.addUser(name: name, age: ageInt)
                        name = ""
                        age = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()

                // 🔹 List of Users
                List(viewModel.users) { user in
                    VStack(alignment: .leading) {
                        Text(user.name).font(.headline)
                        Text("Age: \(user.age)").font(.subheadline)
                    }
                }
            }
            .navigationTitle("Firestore Users")
            .onAppear {
                viewModel.fetchUsers()
            }
        }
    }
}

// MARK: - Firebase Setup
@main
struct FirestoreApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
