import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

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
    @State private var barbers: [Barber] = []

    init() {
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.blue]
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recommended Barbers")
                        .font(.headline)
                        .padding(.leading, 16)

                    ForEach(barbers) { barber in
                        NavigationLink(destination: BarberDetailView(barber: barber)) {
                            BarberCardView(barber: barber)
                                .padding([.leading, .trailing], 16)
                        }
                    }
                }
                .padding(.top, 16)
                .background(Color.white)
            }
            .navigationTitle("Barberease")
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                fetchBarbers()
            }
        }
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
        VStack(alignment: .leading, spacing: 8) {
            if let coverImage = coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(10)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(10)
            }

            Text(barber.shopName)
                .font(.headline)
                .padding([.leading, .top], 8)

            Text(barber.address)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding([.leading, .bottom], 8)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
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

struct BarberDetailView: View {
    let barber: Barber
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: String = ""
    @State private var availableTimes: [String] = []
    @State private var selectedServices: Set<String> = []
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let url = URL(string: barber.coverPhotoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(10)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .cornerRadius(10)
                    }
                }

                // Display barber details
                Text(barber.shopName)
                    .font(.largeTitle)
                    .bold()
                    .padding(.leading, 16)

                Text(barber.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.leading, 16)

                Divider()
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Opening Hours")
                        .font(.headline)
                        .padding(.leading, 16)

                    ForEach(Array(barber.openingHours.keys), id: \.self) { day in
                        if let hours = barber.openingHours[day] {
                            Text("\(day): \(hours["opening"] ?? "") - \(hours["closing"] ?? "")")
                                .padding(.leading, 16)
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Services")
                        .font(.headline)
                        .padding(.leading, 16)

                    ForEach(barber.services) { service in
                        Toggle(isOn: Binding(
                            get: { selectedServices.contains(service.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedServices.insert(service.id)
                                } else {
                                    selectedServices.remove(service.id)
                                }
                            }
                        )) {
                            Text("\(service.name): $\(service.price)")
                        }
                        .padding(.leading, 16)
                    }
                }

                Divider()
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Appointment Date")
                        .font(.headline)
                        .padding(.leading, 16)

                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        in: Date().addingTimeInterval(24*60*60)...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding(.horizontal, 16)
                    .onChange(of: selectedDate) { _, _ in
                        updateAvailableTimes()
                    }

                    if !availableTimes.isEmpty {
                        Text("Select Appointment Time")
                            .font(.headline)
                            .padding(.leading, 16)

                        Picker("Select Time", selection: $selectedTime) {
                            ForEach(availableTimes, id: \.self) { time in
                                Text(time).tag(time)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .padding(.horizontal, 16)
                    } else {
                        Text("No available times for the selected date.")
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                    }

                    Button(action: {
                        if selectedServices.isEmpty {
                            showToast = true
                            toastMessage = "At least select one service"
                        } else {
                            bookAppointment()
                        }
                    }) {
                        Text("Set Appointment")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                            .shadow(radius: 5)
                    }
                    .disabled(selectedTime.isEmpty || selectedServices.isEmpty)
                }
                .padding(.top, 16)
            }
            .padding(.top, 16)
            .background(Color.white)
        }
        .toast(isPresented: $showToast, message: toastMessage)
        .navigationTitle("Barber Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateAvailableTimes()
        }
    }

    private func updateAvailableTimes() {
        let dayOfWeek = getDayOfWeek(from: selectedDate)
        guard let hours = barber.openingHours[dayOfWeek],
              let openingTime = hours["opening"],
              let closingTime = hours["closing"] else {
            availableTimes = []
            selectedTime = ""
            return
        }

        let allTimeSlots = generateTimeSlots(from: openingTime, to: closingTime)
        fetchBookedTimeSlots(for: selectedDate) { bookedSlots in
            self.availableTimes = allTimeSlots.filter { !bookedSlots.contains($0) }
            self.selectedTime = ""
        }
    }

    private func fetchBookedTimeSlots(for date: Date, completion: @escaping ([String]) -> Void) {
        let ref = Database.database().reference().child("appointments")
        let selectedDateTimestamp = date.timeIntervalSince1970

        ref.queryOrdered(byChild: "date").queryEqual(toValue: selectedDateTimestamp).observeSingleEvent(of: .value) { snapshot in
            var bookedSlots: [String] = []
            for child in snapshot.children {
                if let snap = child as? DataSnapshot,
                   let appointmentData = snap.value as? [String: Any],
                   let timeSlot = appointmentData["time"] as? String {
                    bookedSlots.append(timeSlot)
                }
            }
            completion(bookedSlots)
        }
    }

    private func getDayOfWeek(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: date)
    }

    private func generateTimeSlots(from startTime: String, to endTime: String) -> [String] {
        var timeSlots: [String] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        guard let start = dateFormatter.date(from: startTime),
              let end = dateFormatter.date(from: endTime) else {
            return timeSlots
        }

        var currentTime = start
        while currentTime < end {
            timeSlots.append(dateFormatter.string(from: currentTime))
            currentTime = currentTime.addingTimeInterval(30 * 60)
        }

        return timeSlots
    }

    private func bookAppointment() {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }

        let ref = Database.database().reference().child("appointments").childByAutoId()
        let appointmentData: [String: Any] = [
            "userId": user.uid,
            "barberId": barber.id,
            "date": selectedDate.timeIntervalSince1970,
            "time": selectedTime,
            "services": Array(selectedServices)
        ]

        ref.setValue(appointmentData) { error, _ in
            if let error = error {
                print("Error saving appointment: \(error.localizedDescription)")
            } else {
                showToast = true
                toastMessage = "Appointment has been set"
                print("Appointment saved successfully")
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        ZStack {
            self
            if isPresented.wrappedValue {
                VStack {
                    Spacer()
                    Text(message)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom, 50)
                }
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isPresented.wrappedValue = false
                    }
                }
            }
        }
    }
}
