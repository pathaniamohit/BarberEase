import SwiftUI
import Firebase
import FirebaseAuth

struct SplashScreen: View {
    @State private var isActive = false
    @State private var isLoggedIn = false
    @State private var showBusiness = false

    var body: some View {
        ZStack {
            Color(UIColor(red: 1.0, green: 0.97, blue: 0.89, alpha: 1.0))
                .edgesIgnoringSafeArea(.all)

            VStack {
                if isActive {
                    if isLoggedIn {
                        ContentView()
                    } else {
                        LoginPage(showBusiness: $showBusiness, isLoggedIn: $isLoggedIn)
                    }
                } else {
                    VStack {
                        Spacer()
                        Image("pixelcut-export")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .padding(.bottom, 20)
                        Text("Welcome to BarberEase")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding()
                        Text("Your perfect grooming partner")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    }
                    .onAppear {
                        checkAuthState()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func checkAuthState() {
        if let _ = Auth.auth().currentUser {
            self.isLoggedIn = true
        } else {
            self.isLoggedIn = false
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
