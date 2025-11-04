import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImageURL: String?
    var onPostCreated: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Welcome, \(currentUsername)")
                    .font(.title2)
                Spacer()
                if let urlString = profileImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Image(systemName: "person.crop.circle")
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                }
            }
            .padding()

            Text("Home content goes here...")
            Spacer()
        }
    }
}
