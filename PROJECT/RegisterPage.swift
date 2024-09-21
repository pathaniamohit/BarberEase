import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct RegisterPage: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var phoneNumber: String = ""
    @State private var errorMessage: String?
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var navigateToHome: Bool = false // State variable for navigation
    @Binding var showBusiness: Bool // Add this binding property
    @Binding var isLoggedIn: Bool // Add this binding property
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor(red: 1.0, green: 0.97, blue: 0.89, alpha: 1.0))
                    .edgesIgnoringSafeArea(.all) // Background color #FFF8E4
                
                VStack {
                    Text("Register")
                        .font(.largeTitle)
                        .padding()

                    TextField("Full Name", text: $fullName)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)

                    TextField("Phone Number", text: $phoneNumber)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                        .keyboardType(.numberPad)

                    if let errorMessage = errorMessage {
                        Text(errorMessage).foregroundColor(.red)
                    }

                    Button(action: registerUser) {
                        Text("Register")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 220, height: 60)
                            .background(Color.blue)
                            .cornerRadius(15.0)
                    }.padding()

                    HStack {
                        NavigationLink(destination: LoginPage(showBusiness: $showBusiness, isLoggedIn: $isLoggedIn)) { // Pass the binding
                            Text("Already have an account? Login")
                                .foregroundColor(.blue)
                                .padding(.top, 20)
                        }
                    }
                }
                .padding()
                
                if showToast {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.75))
                            .cornerRadius(10)
                            .padding(.bottom, 50)
                    }
                    .transition(.opacity)
                }

                NavigationLink("", destination: HomePage(showBusiness: $showBusiness), isActive: $navigateToHome) // NavigationLink to HomePage with binding
            }
        }
    }

    private func registerUser() {
        guard validateInputs() else {
            showToastMessage("Please correct the errors and try again.")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                showToastMessage("Registration failed: \(error.localizedDescription)")
            } else if let user = authResult?.user {
                // Save additional user info to Realtime Database
                saveUserData(userID: user.uid)
                showToastMessage("Registration successful!")
                self.isLoggedIn = true // Update the login state
                self.navigateToHome = true // Navigate to HomePage on successful registration
            }
        }
    }

    private func saveUserData(userID: String) {
        let ref = Database.database(url: "https://project-d017a-default-rtdb.firebaseio.com/").reference()
        let userData = [
            "fullName": fullName,
            "email": email,
            "phoneNumber": phoneNumber
        ]
        ref.child("users").child(userID).setValue(userData) { error, _ in
            if let error = error {
                self.errorMessage = error.localizedDescription
                showToastMessage("Data saving failed: \(error.localizedDescription)")
            } else {
                print("User data saved successfully.")
            }
        }
    }

    private func validateInputs() -> Bool {
        if fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || phoneNumber.isEmpty {
            self.errorMessage = "All fields are required."
            return false
        }
        if !isValidEmail(email) {
            self.errorMessage = "Invalid email address."
            return false
        }
        if password.count < 6 {
            self.errorMessage = "Password must be at least 6 characters."
            return false
        }
        if password != confirmPassword {
            self.errorMessage = "Passwords do not match."
            return false
        }
        if !isValidPhoneNumber(phoneNumber) {
            self.errorMessage = "Invalid phone number."
            return false
        }
        self.errorMessage = nil
        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegEx = "^[0-9]{10,15}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: phoneNumber)
    }
    
    private func showToastMessage(_ message: String) {
        self.toastMessage = message
        withAnimation {
            self.showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.showToast = false
            }
        }
    }
}

struct RegisterPage_Previews: PreviewProvider {
    @State static var showBusiness = false
    @State static var isLoggedIn = false
    static var previews: some View {
        RegisterPage(showBusiness: $showBusiness, isLoggedIn: $isLoggedIn)
    }
}
