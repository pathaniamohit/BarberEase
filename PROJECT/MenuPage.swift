import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage

struct MenuPage: View {
    @Binding var showBusiness: Bool
    @Binding var isLoggedIn: Bool
    @State private var userProfile: UserProfile = UserProfile(name: "", email: "", phoneNumber: "")
    @State private var isProfileImagePickerPresented: Bool = false
    
    private let storage = Storage.storage().reference()

    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 16) {
                    // Profile Image
                    Button(action: {
                        self.isProfileImagePickerPresented.toggle()
                    }) {
                        if let profileImage = userProfile.image {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                                .shadow(radius: 5)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                                .shadow(radius: 5)
                        }
                    }
                    .sheet(isPresented: $isProfileImagePickerPresented) {
                        CustomProfileImagePicker(image: $userProfile.image)
                            .onDisappear {
                                if let image = userProfile.image {
                                    uploadProfileImage(image) // Upload image after it's selected
                                }
                            }
                    }
                    
                    // User Information
                    Text(userProfile.email)
                        .font(.headline)
                        .padding(.top, 4)
                    Text(userProfile.name)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(userProfile.phoneNumber)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                
                // List with enhanced styling
                List {
                    Section(header: HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                        Text("Account")
                            .font(.headline)
                    }
                    .padding(.vertical, 10)
                    .background(Color.clear)) {
                        NavigationLink(destination: EditProfilePage(userProfile: $userProfile)) {
                            MenuRow(iconName: "square.and.pencil", title: "Edit Profile")
                        }
                        Toggle(isOn: $showBusiness) {
                            MenuRow(iconName: "briefcase.fill", title: "Enable Business Account")
                        }
                        .padding(.vertical, 5)
                        Button(action: logoutUser) {
                            MenuRow(iconName: "arrowshape.turn.up.left.fill", title: "Logout")
                                .foregroundColor(.red)
                        }
                    }
                    .listRowBackground(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .listStyle(InsetGroupedListStyle())
                .padding(.horizontal, 20)
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray6), Color(.white)]), startPoint: .top, endPoint: .bottom)
            )
            .navigationBarTitle("Menu", displayMode: .inline)
            .onAppear {
                createUserProfileIfNotExists() // Ensure user profile exists in Firestore
                fetchUserProfile() // Fetch user profile data
            }
        }
    }

    // Function to upload the profile image to Firebase Storage
    private func uploadProfileImage(_ image: UIImage) {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }
        
        // Convert the image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            print("Failed to convert image to JPEG data")
            return
        }
        
        // Define the file path in Firebase Storage based on user ID and filename
        let fileName = "profile.jpg"
        let imageRef = storage.child("profile_pictures/\(user.uid)/\(fileName)")
        
        // Start the upload task
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload profile image: \(error.localizedDescription)")
                return
            }
            
            // Get the download URL of the uploaded file
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    return
                }
                
                if let url = url {
                    print("Image URL: \(url.absoluteString)") // Debugging output
                    saveProfileImageUrl(url.absoluteString)
                }
            }
        }
    }

    // Function to save the image URL to Firestore with transaction to handle missing document
    private func saveProfileImageUrl(_ url: String) {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }
        
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(user.uid)
        
        // Use a transaction to check for document existence and update or create it
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                // Check if document exists
                let document = try transaction.getDocument(userDocRef)
                
                if document.exists {
                    // Update the profileImageUrl field if the document exists
                    transaction.updateData(["profileImageUrl": url], forDocument: userDocRef)
                } else {
                    // Create a new document with profileImageUrl field if it doesn't exist
                    transaction.setData([
                        "profileImageUrl": url,
                        "name": self.userProfile.name, // Include other necessary fields
                        "email": self.userProfile.email,
                        "phoneNumber": self.userProfile.phoneNumber
                    ], forDocument: userDocRef)
                }
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        }) { (result, error) in
            if let error = error {
                print("Failed to update or create profile image URL: \(error.localizedDescription)")
            } else {
                print("Profile image URL updated successfully")
                // Fetch the image again to refresh the display
                downloadProfileImage(from: url)
            }
        }
    }

    // Function to create user profile document in Firestore if it does not exist
    private func createUserProfileIfNotExists() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(user.uid)
        
        userDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                print("User profile already exists")
            } else {
                // Create a new document with default fields
                userDocRef.setData([
                    "name": user.displayName ?? "",
                    "email": user.email ?? "",
                    "phoneNumber": "" // or user.phoneNumber if available
                ]) { error in
                    if let error = error {
                        print("Failed to create user profile: \(error.localizedDescription)")
                    } else {
                        print("User profile created successfully")
                    }
                }
            }
        }
    }

    private func fetchUserProfile() {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }
        
        let db = Firestore.firestore()
        let userId = user.uid
        
        db.collection("users").document(userId).getDocument { (document, error) in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("User profile does not exist")
                return
            }
            
            DispatchQueue.main.async {
                self.userProfile.email = user.email ?? ""
                self.userProfile.name = data["name"] as? String ?? ""
                self.userProfile.phoneNumber = data["phoneNumber"] as? String ?? ""
                if let profileImageUrl = data["profileImageUrl"] as? String {
                    print("Profile image URL: \(profileImageUrl)") // Debugging output
                    downloadProfileImage(from: profileImageUrl)
                }
            }
        }
    }
    
    private func downloadProfileImage(from urlString: String) {
        print("Downloading image from URL: \(urlString)") // Debugging output
        guard let url = URL(string: urlString) else {
            print("Invalid URL") // Debugging output
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error downloading profile image: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    print("Profile image downloaded successfully") // Debugging output
                    self.userProfile.image = image
                }
            } else {
                print("Failed to decode image data") // Debugging output
            }
        }.resume()
    }

    private func logoutUser() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false // Update the login state
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct MenuRow: View {
    var iconName: String
    var title: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
                .padding(.trailing, 10)
            Text(title)
                .font(.body)
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

struct UserProfile {
    var name: String
    var email: String
    var phoneNumber: String
    var image: UIImage? = nil
}

struct MenuPage_Previews: PreviewProvider {
    @State static var showBusiness = false
    @State static var isLoggedIn = true
    static var previews: some View {
        MenuPage(showBusiness: $showBusiness, isLoggedIn: $isLoggedIn)
    }
}
