import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage

struct BusinessAccountPage: View {
    @State private var coverImage: UIImage? = nil
    @State private var isImagePickerPresented: Bool = false
    @State private var coverImageUrl: String = ""
    @State private var services: [String] = []
    @State private var upcomingAppointments: [String] = []
    @State private var completedAppointments: [String] = []

    private let storage = Storage.storage().reference()

    var body: some View {
        NavigationStack {
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
                        Text(upcomingAppointments.isEmpty ? "None" : upcomingAppointments.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(upcomingAppointments.isEmpty ? .gray : .black)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)

                    VStack(alignment: .center, spacing: 5) {
                        Text("Completed Appointments")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.primary)
                        Text(completedAppointments.isEmpty ? "None" : completedAppointments.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(completedAppointments.isEmpty ? .gray : .black)
                            .frame(maxWidth: .infinity, alignment: .center)
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
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("Business Account")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
            })
            .onAppear {
                fetchCoverImage()
                fetchServices()
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
