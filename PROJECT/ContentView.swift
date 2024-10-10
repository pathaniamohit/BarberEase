import SwiftUI
import Firebase
import FirebaseAuth

struct ContentView: View {
    @State private var showBusiness = false
    @State private var isActive = false
    @State private var isLoggedIn = false
    @State private var selectedView: SelectedView = .home

    var body: some View {
        VStack {
            if isActive {
                if isLoggedIn {
                    contentView
                } else {
                    LoginPage(showBusiness: $showBusiness, isLoggedIn: $isLoggedIn)
                }
            } else {
                SplashScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                self.isActive = true
                                self.checkAuthState()
                            }
                        }
                    }
            }
        }
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            switch selectedView {
            case .home:
                HomePage(showBusiness: $showBusiness)
            case .appointments:
                AppointmentsPage()
            case .menu:
                MenuPage(showBusiness: $showBusiness, isLoggedIn: $isLoggedIn)
            case .business:
                if showBusiness {
                    BusinessAccountPage()
                } else {
                    HomePage(showBusiness: $showBusiness) // Default to Home if business is not enabled
                }
            }
            Spacer()
            bottomNavigationBar
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
    }

    private var bottomNavigationBar: some View {
        HStack {
            Button(action: { selectedView = .home }) {
                Image(systemName: "house.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding()
            }
            Spacer()
            Button(action: { selectedView = .appointments }) {
                Image(systemName: "calendar")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding()
            }
            Spacer()
            Button(action: { selectedView = .menu }) {
                Image(systemName: "line.horizontal.3")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding()
            }
            Spacer()
            if showBusiness {
                Button(action: { selectedView = .business }) {
                    Image(systemName: "briefcase.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding()
                }
            }
        }
        .padding([.leading, .trailing, .bottom])
        .background(Color.white.shadow(radius: 2))
    }

    private func checkAuthState() {
        if let _ = Auth.auth().currentUser {
            self.isLoggedIn = true
        } else {
            self.isLoggedIn = false
        }
    }

    enum SelectedView {
        case home, appointments, menu, business
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
