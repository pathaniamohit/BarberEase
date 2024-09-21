import SwiftUI
import Firebase
import FirebaseAuth

struct LoginPage: View {
    @Binding var showBusiness: Bool
    @Binding var isLoggedIn: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var navigateToHome: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor(red: 1.0, green: 0.97, blue: 0.89, alpha: 1.0))
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Text("Login")
                        .font(.largeTitle)
                        .padding()
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                    if let errorMessage = errorMessage {
                        Text(errorMessage).foregroundColor(.red)
                    }
                    Button(action: loginUser) {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 220, height: 60)
                            .background(Color.blue)
                            .cornerRadius(15.0)
                    }.padding()
                    VStack {
                        NavigationLink(destination: RegisterPage(showBusiness: $showBusiness, isLoggedIn: $isLoggedIn)) {
                            Text("I don't have an account")
                                .foregroundColor(.blue)
                                .padding(.top, 20)
                        }
                        Spacer()
                        NavigationLink(destination: ForgotPasswordPage()) {
                            Text("Forgot Password?")
                                .foregroundColor(.blue)
                                .padding(.top, 20)
                        }
                    }
                    .padding([.leading, .trailing], 40)
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
                NavigationLink("", destination: ContentView(), isActive: $navigateToHome)
            }
        }
    }

    private func loginUser() {
        guard !email.isEmpty, !password.isEmpty else {
            showToastMessage("Please enter both email and password.")
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                showToastMessage("Login failed: \(error.localizedDescription)")
            } else {
                showToastMessage("Login successful!")
                self.isLoggedIn = true // Update the login state
                self.navigateToHome = true
            }
        }
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

struct LoginPage_Previews: PreviewProvider {
    @State static var showBusiness = false
    @State static var isLoggedIn = false
    static var previews: some View {
        LoginPage(showBusiness: $showBusiness, isLoggedIn: $isLoggedIn)
    }
}
