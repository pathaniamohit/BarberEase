import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
struct Service: Identifiable, Codable {
    let id: UUID
    var name: String
    var price: String

    init(id: UUID = UUID(), name: String, price: String) {
        self.id = id
        self.name = name
        self.price = price
    }

    init?(dictionary: [String: Any]) {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = dictionary["name"] as? String,
              let price = dictionary["price"] as? String else {
            return nil
        }
        self.id = id
        self.name = name
        self.price = price
    }

    var toDictionary: [String: Any] {
        return ["id": id.uuidString, "name": name, "price": price]
    }
}

struct ServicesPricing: View {
    @State private var services: [Service] = []
    @State private var isLoading = false

    var onSave: (() -> Void)? 
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                } else {
                    List {
                        ForEach($services) { $service in
                            HStack {
                                TextField("Service Name", text: $service.name)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: .infinity)

                                TextField("Price", text: $service.price)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.vertical, 5)
                        }
                        .onDelete(perform: deleteService)
                    }
                    .listStyle(InsetGroupedListStyle())

                    HStack {
                        Button(action: addService) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Service")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                        }
                        .padding(.horizontal)

                        Button(action: saveServices) {
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
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Services and Pricing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditButton()
            }
            .onAppear {
                fetchServices()
            }
        }
    }

    private func addService() {
        services.append(Service(name: "", price: ""))
    }

    private func deleteService(at offsets: IndexSet) {
        services.remove(atOffsets: offsets)
    }

    private func saveServices() {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }

        let ref = Database.database().reference().child("business_accounts").child(user.uid).child("services")

        let servicesDict = services.map { $0.toDictionary }

        ref.setValue(servicesDict) { error, _ in
            if let error = error {
                print("Error saving services: \(error.localizedDescription)")
            } else {
                print("Services saved successfully")
                onSave?() // Call the callback to notify that services are saved
            }
        }
    }

    private func fetchServices() {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }

        isLoading = true
        let ref = Database.database().reference().child("business_accounts").child(user.uid).child("services")

        ref.observeSingleEvent(of: .value) { snapshot in
            isLoading = false
            guard let servicesArray = snapshot.value as? [[String: Any]] else {
                print("No services found")
                return
            }

            self.services = servicesArray.compactMap { Service(dictionary: $0) }
            print("Services fetched successfully")
        }
    }
}
