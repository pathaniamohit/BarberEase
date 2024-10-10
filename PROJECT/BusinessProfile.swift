import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

struct BusinessProfile: View {
    @State private var shopName: String = ""
    @State private var address: String = ""
    @State private var openingHours: [String: (String, String)] = [
        "Monday": ("", ""),
        "Tuesday": ("", ""),
        "Wednesday": ("", ""),
        "Thursday": ("", ""),
        "Friday": ("", ""),
        "Saturday": ("", ""),
        "Sunday": ("", "")
    ]
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                } else {
                    Form {
                        Section(header: Text("Shop Information")) {
                            TextField("Shop Name", text: $shopName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Address", text: $address)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Section(header: Text("Opening Hours")) {
                            ForEach(openingHours.keys.sorted(), id: \.self) { day in
                                VStack(alignment: .leading) {
                                    Text(day)
                                        .font(.headline)
                                    
                                    HStack {
                                        TextField("Opening Time", text: Binding(
                                            get: { openingHours[day]?.0 ?? "" },
                                            set: { openingHours[day]?.0 = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.default)
                                        
                                        TextField("Closing Time", text: Binding(
                                            get: { openingHours[day]?.1 ?? "" },
                                            set: { openingHours[day]?.1 = $0 }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.default)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        
                        Button(action: saveBusinessProfile) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Business Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchBusinessProfile()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // Function to validate the input fields
    private func validateInputs() -> Bool {
        if shopName.isEmpty {
            showAlertMessage("Shop Name is required")
            return false
        }
        
        if address.isEmpty {
            showAlertMessage("Address is required")
            return false
        }
        
        for (day, times) in openingHours {
            if times.0.isEmpty || times.1.isEmpty {
                showAlertMessage("\(day) Opening and Closing times are required")
                return false
            }
        }
        
        return true
    }

    // Function to save the business profile to Firebase
    private func saveBusinessProfile() {
        guard let user = Auth.auth().currentUser else {
            showAlertMessage("No user logged in")
            return
        }
        
        // Validate inputs before saving
        guard validateInputs() else {
            return
        }
        
        isLoading = true
        
        let ref = Database.database().reference().child("business_accounts").child(user.uid)
        let openingHoursDict = openingHours.mapValues { ["opening": $0.0, "closing": $0.1] }
        let businessInfo: [String: Any] = [
            "shopName": shopName,
            "address": address,
            "openingHours": openingHoursDict
        ]
        
        ref.updateChildValues(businessInfo) { error, _ in
            isLoading = false
            if let error = error {
                showAlertMessage("Error saving business profile: \(error.localizedDescription)")
            } else {
                showAlertMessage("Business profile saved successfully")
            }
        }
    }

    // Function to fetch the business profile from Firebase
    private func fetchBusinessProfile() {
        guard let user = Auth.auth().currentUser else {
            showAlertMessage("No user logged in")
            return
        }
        
        isLoading = true
        
        let ref = Database.database().reference().child("business_accounts").child(user.uid)
        ref.observeSingleEvent(of: .value) { snapshot in
            isLoading = false
            if let data = snapshot.value as? [String: Any] {
                self.shopName = data["shopName"] as? String ?? ""
                self.address = data["address"] as? String ?? ""
                
                if let hours = data["openingHours"] as? [String: [String: String]] {
                    for (day, times) in hours {
                        self.openingHours[day] = (times["opening"] ?? "", times["closing"] ?? "")
                    }
                }
            } else {
                showAlertMessage("Failed to fetch business profile")
            }
        }
    }

    // Function to show alert messages
    private func showAlertMessage(_ message: String) {
        self.alertMessage = message
        self.showAlert = true
    }
}

struct BusinessProfile_Previews: PreviewProvider {
    static var previews: some View {
        BusinessProfile()
    }
}


