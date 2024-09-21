//
//  ForgotPasswordPage.swift
//  PROJECT
//
//  Created by Nabeel Shajahan on 2024-06-25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ForgotPasswordPage: View {
    @State private var email: String = ""
    @State private var errorMessage: String?
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var successMessage: String?

    var body: some View {
        ZStack {
            Color(UIColor(red: 1.0, green: 0.97, blue: 0.89, alpha: 1.0))
                .edgesIgnoringSafeArea(.all) // Background color #FFF8E4

            VStack {
                Text("Forgot Password")
                    .font(.largeTitle)
                    .padding()

                TextField("Email", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                    .autocapitalization(.none)

                if let errorMessage = errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }

                if let successMessage = successMessage {
                    Text(successMessage).foregroundColor(.green)
                }

                Button(action: resetPassword) {
                    Text("Reset Password")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 220, height: 60)
                        .background(Color.blue)
                        .cornerRadius(15.0)
                }.padding()
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
        }
    }

    private func resetPassword() {
        guard !email.isEmpty else {
            showToastMessage("Please enter your email address.")
            return
        }
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                showToastMessage("Password reset failed: \(error.localizedDescription)")
                self.successMessage = nil
            } else {
                self.successMessage = "Password reset email sent."
                showToastMessage("Password reset email sent successfully.")
                self.errorMessage = nil
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

struct ForgotPasswordPage_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordPage()
    }
}
