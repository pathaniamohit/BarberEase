import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct BusinessAccountPage: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    @State private var barberName: String = "Barber Business"
    @State private var userId: String = Auth.auth().currentUser?.uid ?? ""

    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 10) {
                    Text(barberName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)

                    Text("Manage your business settings and services")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding()

                TabView(selection: $selectedTab) {
                    HomeView(userId: userId)
                        .tabItem {
                            Text("HOME")
                        }
                        .tag(0)

                    ServicesView(userId: userId)
                        .tabItem {
                            Text("SERVICES")
                        }
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Business Account")
            .navigationBarItems(leading: Button("Cancel") {
                self.presentationMode.wrappedValue.dismiss()
            })
            .onAppear(perform: fetchProfile)
        }
    }

    private func fetchProfile() {
        // Fetch profile logic, using placeholder for now
        self.barberName = "Barber Business"
    }
}

struct HomeView: View {
    var userId: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                NavigationLink(destination: AddressHoursView(userId: userId)) {
                    Text("Address & Hours")
                        .font(.headline)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(8)
                }

                NavigationLink(destination: InfoView(userId: userId)) {
                    Text("Info")
                        .font(.headline)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(8)
                }

                Text("Today's Schedule: No appointments yet")
                    .foregroundColor(.white)
                    .padding(.top, 20)
            }
            .padding()
        }
    }
}

struct ServicesView: View {
    var userId: String
    @State private var name: String = ""
    @State private var price: String = ""
    @State private var duration: String = ""
    @State private var description: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Service Information")) {
                    TextField("Name", text: $name)
                    TextField("Price", text: $price)
                    TextField("Duration", text: $duration)
                    TextField("Description", text: $description)
                }

                Button(action: saveService) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("Services")
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Information"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveService() {
        guard !userId.isEmpty else {
            alertMessage = "User ID is not available."
            showingAlert = true
            return
        }

        let db = Firestore.firestore()
        let ref = db.collection("business_accounts").document(userId).collection("services").document()
        let serviceInfo: [String: Any] = [
            "name": name,
            "price": price,
            "duration": duration,
            "description": description
        ]

        ref.setData(serviceInfo) { error in
            if let error = error {
                alertMessage = "Error saving service: \(error.localizedDescription)"
                showingAlert = true
            } else {
                alertMessage = "Service saved successfully!"
                showingAlert = true
            }
        }
    }
}

struct AddressHoursView: View {
    var userId: String
    @State private var locationType: String = ""
    @State private var barbershopName: String = ""
    @State private var streetAddress: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var country: String = "Canada"
    @State private var hours: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Address")) {
                    TextField("Location Type", text: $locationType)
                    TextField("Barbershop Name", text: $barbershopName)
                    TextField("Street Address", text: $streetAddress)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("Zip Code", text: $zipCode)
                    TextField("Country", text: $country)
                }

                Section(header: Text("Hours")) {
                    TextField("Hours", text: $hours)
                }

                Button(action: saveAddressAndHours) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("Address & Hours")
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Information"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveAddressAndHours() {
        guard !userId.isEmpty else {
            alertMessage = "User ID is not available."
            showingAlert = true
            return
        }

        let db = Firestore.firestore()
        let ref = db.collection("business_accounts").document(userId).collection("address").document("details")
        let addressInfo: [String: Any] = [
            "locationType": locationType,
            "barbershopName": barbershopName,
            "streetAddress": streetAddress,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "country": country,
            "hours": hours
        ]

        ref.setData(addressInfo) { error in
            if let error = error {
                alertMessage = "Error saving address and hours: \(error.localizedDescription)"
                showingAlert = true
            } else {
                alertMessage = "Address and hours saved successfully!"
                showingAlert = true
            }
        }
    }
}

struct InfoView: View {
    var userId: String
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var phoneNumber: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Name")) {
                    TextField("Enter your name", text: $name)
                }
                Section(header: Text("Bio")) {
                    TextField("Enter a short bio", text: $bio)
                }
                Section(header: Text("Phone Number")) {
                    TextField("Enter your phone number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Button(action: saveInfo) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("Business Info")
            .onAppear(perform: fetchInfo)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Information"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func fetchInfo() {
        guard !userId.isEmpty else {
            alertMessage = "User ID is not available."
            showingAlert = true
            return
        }

        let db = Firestore.firestore()
        let ref = db.collection("business_accounts").document(userId)
        ref.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                self.name = data?["name"] as? String ?? ""
                self.bio = data?["bio"] as? String ?? ""
                self.phoneNumber = data?["phoneNumber"] as? String ?? ""
            } else {
                self.alertMessage = "Failed to fetch user information."
                self.showingAlert = true
            }
        }
    }

    private func saveInfo() {
        guard !userId.isEmpty else {
            alertMessage = "User ID is not available."
            showingAlert = true
            return
        }

        let db = Firestore.firestore()
        let ref = db.collection("business_accounts").document(userId)
        let userInfo: [String: Any] = [
            "name": name,
            "bio": bio,
            "phoneNumber": phoneNumber
        ]

        ref.setData(userInfo) { error in
            if let error = error {
                alertMessage = "Error saving data: \(error.localizedDescription)"
                showingAlert = true
            } else {
                alertMessage = "Information saved successfully!"
                showingAlert = true
            }
        }
    }
}

struct BusinessAccountPage_Previews: PreviewProvider {
    static var previews: some View {
        BusinessAccountPage()
    }
}
