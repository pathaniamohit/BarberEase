import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

struct BarberAppointment: Identifiable {
    let id: String
    let userId: String
    let username: String
    let date: Date
    let time: String
    let services: [String]
}

struct BusinessAccountPage: View {
    @State private var coverImage: UIImage? = nil
    @State private var isImagePickerPresented: Bool = false
    @State private var coverImageUrl: String = ""
    @State private var services: [String] = []
    @State private var upcomingAppointments: [BarberAppointment] = []
    @State private var completedAppointments: [BarberAppointment] = []

    private let storage = Storage.storage().reference()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let coverImage = coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .onTapGesture(count: 2) {
                                isImagePickerPresented = true
                            }
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .background(Color.gray.opacity(0.3))
                            .overlay(
                                Text("Your Business Cover")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .shadow(radius: 5)
                                    .padding(),
                                alignment: .bottom
                            )
                            .onTapGesture(count: 2) {
                                isImagePickerPresented = true
                            }
                    }

                    VStack(spacing: 15) {
                        VStack(alignment: .center, spacing: 5) {
                            HStack {
                                Spacer()
                                Text("Services and Pricing")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                
                                NavigationLink(
                                    destination: ServicesPricing(onSave: fetchServices)) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                        .padding()
                                        .background(Color.yellow.opacity(0.8))
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            Text(services.isEmpty ? "None" : services.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(services.isEmpty ? .gray : .black)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)

                        VStack(alignment: .center, spacing: 5) {
                            Text("Upcoming Appointments")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.primary)
                            
                            if upcomingAppointments.isEmpty {
                                Text("None")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(upcomingAppointments) { appointment in
                                    BarberAppointmentCardView(appointment: appointment)
                                        .padding(.vertical, 5)
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)

                        VStack(alignment: .center, spacing: 5) {
                            Text("Completed Appointments")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if completedAppointments.isEmpty {
                                Text("None")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(completedAppointments) { appointment in
                                    BarberAppointmentCardView(appointment: appointment)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)

                    Spacer()

                    NavigationLink(destination: BusinessProfile()) {
                        Text("Edit Business Profile")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top, 16)
                .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            }
            .navigationTitle("Business Account")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchCoverImage()
                fetchServices()
                fetchAppointments()
            }
            .sheet(isPresented: $isImagePickerPresented) {
                CustomProfileImagePicker(image: $coverImage)
                    .onDisappear {
                        if let image = coverImage {
                            uploadCoverImage(image)
                        }
                    }
            }
        }
    }

    private func fetchAppointments() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }

        let db = Database.database().reference().child("appointments")
        db.observeSingleEvent(of: .value) { snapshot in
            var fetchedUpcomingAppointments: [BarberAppointment] = []
            var fetchedCompletedAppointments: [BarberAppointment] = []

            let group = DispatchGroup()

            for child in snapshot.children {
                if let snap = child as? DataSnapshot,
                   let data = snap.value as? [String: Any],
                   let userId = data["userId"] as? String,
                   let time = data["time"] as? String,
                   let serviceIds = data["services"] as? [String],
                   let barberId = data["barberId"] as? String,
                   barberId == currentUserId {

                    var appointmentDate: Date?
                    if let timestamp = data["date"] as? Double {
                        appointmentDate = Date(timeIntervalSince1970: timestamp)
                    } else if let dateString = data["date"] as? String,
                              let timestamp = Double(dateString) {
                        appointmentDate = Date(timeIntervalSince1970: timestamp)
                    }

                    guard let validDate = appointmentDate else {
                        print("Invalid date format for appointment: \(snap.key)")
                        continue
                    }

                    group.enter()

                    fetchUserName(userId: userId) { username in
                        self.fetchServiceNames(barberId: barberId, serviceIds: serviceIds) { serviceNames in
                            let appointment = BarberAppointment(
                                id: snap.key,
                                userId: userId,
                                username: username,
                                date: validDate,
                                time: time,
                                services: serviceNames
                            )

                            if validDate > Date() {
                                fetchedUpcomingAppointments.append(appointment)
                            } else {
                                fetchedCompletedAppointments.append(appointment)
                            }

                            group.leave()
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.upcomingAppointments = fetchedUpcomingAppointments
                self.completedAppointments = fetchedCompletedAppointments
            }
        }
    }

    private func fetchUserName(userId: String, completion: @escaping (String) -> Void) {
        let db = Database.database().reference().child("users").child(userId)
        db.observeSingleEvent(of: .value) { snapshot in
            if let data = snapshot.value as? [String: Any],
               let username = data["username"] as? String {
                completion(username)
            } else {
                completion("Unknown User")
            }
        }
    }

    private func fetchServiceNames(barberId: String, serviceIds: [String], completion: @escaping ([String]) -> Void) {
        let db = Database.database().reference().child("business_accounts").child(barberId).child("services")
        var serviceNames: [String] = []

        let group = DispatchGroup()

        for serviceId in serviceIds {
            group.enter()
            db.queryOrdered(byChild: "id").queryEqual(toValue: serviceId).observeSingleEvent(of: .value) { snapshot in
                for child in snapshot.children {
                    if let snap = child as? DataSnapshot,
                       let data = snap.value as? [String: Any],
                       let serviceName = data["name"] as? String {
                        serviceNames.append(serviceName)
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(serviceNames)
        }
    }

    private func fetchCoverImage() {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }
        
        let ref = Database.database().reference().child("business_accounts").child(user.uid)
        
        ref.child("coverImageUrl").observeSingleEvent(of: .value) { snapshot in
            if let urlString = snapshot.value as? String {
                loadImageFromUrl(urlString: urlString)
            }
        }
    }

    private func loadImageFromUrl(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error downloading cover image: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.coverImage = image
                }
            } else {
                print("Failed to decode image data")
            }
        }.resume()
    }

    private func uploadCoverImage(_ image: UIImage) {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            print("Failed to convert image to JPEG data")
            return
        }
        
        let fileName = "cover.jpg"
        let imageRef = storage.child("cover_photos/\(user.uid)/\(fileName)")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload cover image: \(error.localizedDescription)")
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    return
                }
                
                if let url = url {
                    print("Cover Image URL: \(url.absoluteString)")
                    saveCoverImageUrlToRealtimeDatabase(url.absoluteString)
                }
            }
        }
    }

    private func saveCoverImageUrlToRealtimeDatabase(_ url: String) {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }
        
        let ref = Database.database().reference().child("business_accounts").child(user.uid)
        
        ref.updateChildValues(["coverImageUrl": url]) { error, _ in
            if let error = error {
                print("Error saving cover image URL to Realtime Database: \(error.localizedDescription)")
            } else {
                print("Cover image URL saved successfully in Realtime Database")
            }
        }
    }

    private func fetchServices() {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }

        let ref = Database.database().reference().child("business_accounts").child(user.uid).child("services")

        ref.observeSingleEvent(of: .value) { snapshot in
            guard let servicesArray = snapshot.value as? [[String: Any]] else {
                print("No services found")
                services = []
                return
            }

            services = servicesArray.compactMap { dict in
                guard let name = dict["name"] as? String, let price = dict["price"] as? String else { return nil }
                return "\(name): \(price)"
            }
        }
    }
}

struct BarberAppointmentCardView: View {
    let appointment: BarberAppointment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("User: \(appointment.username)")
                .font(.headline)
            Text("Date: \(formattedDate(appointment.date))")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Time: \(appointment.time)")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Services: \(appointment.services.joined(separator: ", "))")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
