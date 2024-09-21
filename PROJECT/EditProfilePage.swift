import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

struct EditProfilePage: View {
    @Binding var userProfile: UserProfile
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showPasswordDialog = false // Show password update dialog
    @State private var showToast = false // State for toast visibility
    
    // State variables for password update
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("Full Name")) {
                        TextField("Full Name", text: $name)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                    Section(header: Text("Email")) {
                        Text(email)  // Display email as uneditable text
                    }
                    Section(header: Text("Phone Number")) {
                        Text(phoneNumber)  // Display phone number as uneditable text
                    }
                    
                    // Section for action buttons
                    Section {
                        Button(action: {
                            showPasswordDialog = true
                        }) {
                            Text("Update Password")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: 44)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        
                        Button(action: {
                            if validateFields() {
                                updateProfile()
                            }
                        }) {
                            Text("Save Changes")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: 44)
                                .background(Color.green)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                    }
                }
                
                // Toast message with enhanced design
                if showToast {
                    VStack {
                        Spacer()
                        Text("Full name has been updated")
                            .font(.headline)
                            .padding()
                            .background(BlurView(style: .systemMaterialDark)) // Custom blur effect
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                            .shadow(radius: 5)
                            .transition(.opacity)
                            .animation(.easeInOut)
                    }
                }
                
                // Password Update Dialog
                if showPasswordDialog {
                    PasswordUpdateDialog(
                        currentPassword: $currentPassword,
                        newPassword: $newPassword,
                        confirmPassword: $confirmPassword,
                        showDialog: $showPasswordDialog,
                        onUpdatePassword: updatePassword
                    )
                }
            }
            .navigationTitle("Edit Profile")
            .onAppear {
                fetchUserData()
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }

        // Fetch email and phone number from Auth
        self.email = user.email ?? "No Email"

        // Fetch additional data (fullName and phoneNumber) from Realtime Database
        let dbRef = Database.database().reference()
        let userId = user.uid

        dbRef.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
            if let data = snapshot.value as? [String: Any],
               let fetchedName = data["fullName"] as? String,
               let fetchedPhoneNumber = data["phoneNumber"] as? String {
                self.name = fetchedName
                self.phoneNumber = fetchedPhoneNumber
                self.userProfile.name = fetchedName
                self.userProfile.phoneNumber = fetchedPhoneNumber
            }
        }
    }

    private func validateFields() -> Bool {
        if name.isEmpty {
            alertMessage = "Name cannot be empty"
            showingAlert = true
            return false
        }
        return true
    }

    private func updateProfile() {
        updateProfileData()
    }

    private func updateProfileData() {
        let dbRef = Database.database().reference() // Reference to the Realtime Database
        let userId = Auth.auth().currentUser?.uid ?? ""

        if userProfile.name != name {
            dbRef.child("users").child(userId).child("fullName").setValue(name) { error, _ in
                if let error = error {
                    alertMessage = "Error updating profile: \(error.localizedDescription)"
                    showingAlert = true
                } else {
                    self.userProfile.name = self.name
                    showToastMessage() // Show toast message
                }
            }
        } else {
            alertMessage = "No changes to update"
            showingAlert = true
        }
    }

    private func showToastMessage() {
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }

    private func updatePassword() {
        // Check that new password and confirm password match
        guard newPassword == confirmPassword else {
            alertMessage = "New password and confirm password must match"
            showingAlert = true
            return
        }
        
        // Check if email is valid
        guard let userEmail = Auth.auth().currentUser?.email else {
            alertMessage = "No email found for the authenticated user."
            showingAlert = true
            return
        }
        
        // Reauthenticate user
        let credential = EmailAuthProvider.credential(withEmail: userEmail, password: currentPassword)
        
        Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
            if let error = error {
                alertMessage = "Current password is incorrect: \(error.localizedDescription)"
                showingAlert = true
            } else {
                Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
                    if let error = error {
                        alertMessage = "Failed to update password: \(error.localizedDescription)"
                        showingAlert = true
                    } else {
                        alertMessage = "Password updated successfully"
                        showingAlert = true
                        showPasswordDialog = false // Dismiss dialog
                        // Clear password fields
                        currentPassword = ""
                        newPassword = ""
                        confirmPassword = ""
                    }
                }
            }
        }
    }
}

struct PasswordUpdateDialog: View {
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var showDialog: Bool
    @State private var showCurrentPassword: Bool = false
    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    var onUpdatePassword: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Update Password")
                .font(.headline)
            
            HStack {
                if showCurrentPassword {
                    TextField("Current Password", text: $currentPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    SecureField("Current Password", text: $currentPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Button(action: {
                    showCurrentPassword.toggle()
                }) {
                    Image(systemName: showCurrentPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }

            HStack {
                if showNewPassword {
                    TextField("New Password", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    SecureField("New Password", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Button(action: {
                    showNewPassword.toggle()
                }) {
                    Image(systemName: showNewPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }

            HStack {
                if showConfirmPassword {
                    TextField("Confirm New Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Button(action: {
                    showConfirmPassword.toggle()
                }) {
                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Button(action: {
                    showDialog = false
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                
                Button(action: {
                    onUpdatePassword()
                }) {
                    Text("Update")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
        }
        .padding()
        .background(BlurView(style: .systemMaterial))
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding(40)
    }
}

// Custom BlurView for more appealing background effects
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct EditProfilePage_Previews: PreviewProvider {
    @State static var userProfile = UserProfile(name: "John Doe", email: "johndoe@example.com", phoneNumber: "123-456-7890")
    
    static var previews: some View {
        EditProfilePage(userProfile: $userProfile)
    }
}
