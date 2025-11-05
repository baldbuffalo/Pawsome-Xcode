import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImageURL: String?
    var onPostCreated: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Top bar
            HStack {
                Text("Welcome, \(currentUsername)")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if let urlString = profileImageURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Feed placeholder
            ScrollView {
                VStack(spacing: 20) {
                    Text("🐾 Your Feed")
                        .font(.headline)
                        .padding(.top, 10)

                    Text("No posts yet 👀")
                        .foregroundColor(.gray)
                        .font(.subheadline)

                    Button(action: onPostCreated) {
                        Label("Create a new post", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding()
            }
        }
    }
}
