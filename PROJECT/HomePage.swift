import SwiftUI
import Firebase
import FirebaseFirestore

struct HomePage: View {
    @Binding var showBusiness: Bool
    @State private var recommendedBarbers: [Barber] = [] // State to hold barber data
    @State private var isLoading = true // State to track loading status

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Search bar and notification icon
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search", text: .constant(""))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    Button(action: {
                        // Notification action
                    }) {
                        Image(systemName: "bell.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.black)
                            .padding()
                    }
                }
                .padding([.leading, .trailing, .top])
                .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top) // Adjust padding for the top safe area
                
                // Ads and Offers section
                VStack(alignment: .leading) {
                    Text("Ads and Offers")
                        .font(.headline)
                        .padding([.leading, .trailing, .top])
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 150)
                        .cornerRadius(10)
                        .padding([.leading, .trailing, .bottom])
                }
                
                // Categories section
                VStack(alignment: .leading) {
                    Text("Categories")
                        .font(.headline)
                        .padding([.leading, .trailing, .top])
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            CategoryView(name: "Hair Dressing", iconName: "scissors", action: { print("Hair Dressing clicked") })
                            CategoryView(name: "Beard Trimming", iconName: "mustache", action: { print("Beard Trimming clicked") })
                            CategoryView(name: "Facial Treatment", iconName: "face.smiling", action: { print("Facial Treatment clicked") })
                            CategoryView(name: "Other", iconName: "ellipsis", action: { print("Other clicked") })
                        }
                        .padding([.leading, .trailing, .bottom])
                    }
                }
                
                // Recommended barbers section
                VStack(alignment: .leading) {
                    Text("Recommended Barbers")
                        .font(.headline)
                        .padding([.leading, .trailing, .top])
                    
                    if isLoading {
                        ProgressView() // Show a loading indicator while data is loading
                            .padding()
                    } else {
                        ForEach(recommendedBarbers, id: \.self) { barber in
                            BarberView(barber: barber)
                        }
                    }
                }
            }
        }
        .background(Color(UIColor(red: 1.0, green: 0.97, blue: 0.89, alpha: 1.0)))
        .edgesIgnoringSafeArea(.bottom)
        .onAppear(perform: fetchRecommendedBarbers) // Fetch data on appear
    }
    
    private func fetchRecommendedBarbers() {
        let db = Firestore.firestore()
        db.collection("barbers").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching barbers: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            if let snapshot = snapshot {
                self.recommendedBarbers = snapshot.documents.compactMap { document -> Barber? in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let address = data["address"] as? String else {
                        return nil
                    }
                    return Barber(name: name, address: address)
                }
                self.isLoading = false
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

// Components
struct CategoryView: View {
    let name: String
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: iconName)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
                Text(name)
                    .font(.caption)
                    .padding(.top, 5)
            }
            .frame(width: 80, height: 100)
        }
    }
}

struct BarberView: View {
    let barber: Barber
    
    var body: some View {
        VStack {
            Image("barberImagePlaceholder") // Replace with actual image
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .cornerRadius(10)
                .padding(.bottom, 10)
            Text(barber.name)
                .font(.headline)
            Text(barber.address)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding([.leading, .trailing, .bottom])
    }
}

// Data Models
struct Barber: Hashable {
    let name: String
    let address: String
}
