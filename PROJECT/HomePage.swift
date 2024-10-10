import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseStorage 

struct Barber: Identifiable {
    let id: String
    let shopName: String
    let address: String
    let coverPhotoURL: String
    let openingHours: [String: [String: String]]
    let services: [BarberService]
}

struct BarberService: Identifiable {
    let id: String
    let name: String
    let price: String
}

struct HomePage: View {
    @Binding var showBusiness: Bool
    @State private var searchText: String = ""
    @State private var barbers: [Barber] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search", text: $searchText)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                }
                .padding([.leading, .trailing, .top])
                .padding(.top, getTopSafeArea())

                Text("Recommended Barbers")
                    .font(.headline)
                    .padding(.top, 10)
                    .padding([.leading, .trailing])
                
                ForEach(barbers.filter { barber in
                    searchText.isEmpty ? true : barber.shopName.lowercased().contains(searchText.lowercased())
                }) { barber in
                    BarberCardView(barber: barber)
                        .padding([.leading, .trailing, .top])
                }
            }
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            fetchBarbers()
        }
    }
    
    private func getTopSafeArea() -> CGFloat {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }
    
    private func fetchBarbers() {
        let db = Database.database().reference().child("business_accounts")
        db.observe(.childAdded) { snapshot, previousKey in
            guard let barberData = snapshot.value as? [String: Any],
                  let shopName = barberData["shopName"] as? String,
                  let address = barberData["address"] as? String,
                  let coverPhotoURL = barberData["coverImageUrl"] as? String,
                  let openingHoursDict = barberData["openingHours"] as? [String: [String: String]],
                  let servicesArray = barberData["services"] as? [[String: Any]] else {
                print("Error parsing barber data")
                return
            }
            
            let services = servicesArray.compactMap { serviceDict -> BarberService? in
                guard let id = serviceDict["id"] as? String,
                      let name = serviceDict["name"] as? String,
                      let price = serviceDict["price"] as? String else {
                    return nil
                }
                return BarberService(id: id, name: name, price: price)
            }
            
            let barber = Barber(id: snapshot.key, shopName: shopName, address: address, coverPhotoURL: coverPhotoURL, openingHours: openingHoursDict, services: services)
            self.barbers.append(barber)
        }
    }
}

struct BarberCardView: View {
    let barber: Barber
    @State private var coverImage: UIImage? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            if let coverImage = coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
            }
            
            Text(barber.shopName)
                .font(.headline)
                .padding([.leading, .top])
            
            Text(barber.address)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding([.leading, .bottom])
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .onAppear {
            fetchCoverPhoto(url: barber.coverPhotoURL)
        }
    }
    
    private func fetchCoverPhoto(url: String) {
        let storageRef = Storage.storage().reference(forURL: url)
        storageRef.getData(maxSize: Int64(5 * 1024 * 1024)) { data, error in
            if let error = error {
                print("Error fetching cover photo: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                self.coverImage = image
            }
        }
    }
}

struct HomePage_Previews: PreviewProvider {
    @State static var showBusiness = false
    static var previews: some View {
        HomePage(showBusiness: $showBusiness)
    }
}
