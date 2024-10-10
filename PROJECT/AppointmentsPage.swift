import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseAuth

struct Appointment: Identifiable {
    let id: String
    let barberId: String
    let shopName: String
    let userId: String
    let date: Date
    let time: String
    let services: [String]
}

struct AppointmentsPage: View {
    @State private var upcomingAppointments: [Appointment] = []
    @State private var completedAppointments: [Appointment] = []

    var body: some View {
        NavigationStack{
            VStack {

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !upcomingAppointments.isEmpty {
                            Text("Upcoming")
                                .font(.headline)
                                .padding(.leading)

                            ForEach(upcomingAppointments) { appointment in
                                AppointmentCardView(appointment: appointment)
                                    .padding([.leading, .trailing])
                            }
                        } else {
                            Text("No upcoming appointments")
                                .font(.subheadline)
                                .padding(.leading)
                                .foregroundColor(.gray)
                        }

                        if !completedAppointments.isEmpty {
                            Text("Completed")
                                .font(.headline)
                                .padding(.leading)

                            ForEach(completedAppointments) { appointment in
                                AppointmentCardView(appointment: appointment)
                                    .padding([.leading, .trailing])
                            }
                        } else {
                            Text("No completed appointments")
                                .font(.subheadline)
                                .padding(.leading)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 20) // Add extra padding to the content if needed
                }
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitle("Appointments", displayMode: .inline)
            .onAppear {
                fetchUserAppointments()
            }
        }
    }

    private func fetchUserAppointments() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }

        let db = Database.database().reference().child("appointments")
        db.observeSingleEvent(of: .value) { snapshot in
            var fetchedAppointments: [Appointment] = []

            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let data = snap.value as? [String: Any],
                      let barberId = data["barberId"] as? String,
                      let userId = data["userId"] as? String,
                      let time = data["time"] as? String,
                      let servicesArray = data["services"] as? [String],
                      userId == currentUserId else {
                    if let snap = child as? DataSnapshot {
                        print("Error parsing appointment data for child: Snap (\(snap.key)), data: \(snap.value ?? "No data")")
                    }
                    continue
                }

                var appointmentDate: Date?
                if let timestamp = data["date"] as? Double {
                    appointmentDate = Date(timeIntervalSince1970: timestamp)
                } else if let dateString = data["date"] as? String,
                          let timestamp = Double(dateString) {
                    appointmentDate = Date(timeIntervalSince1970: timestamp)
                } else {
                    print("Error parsing date for appointment: \(snap.key), data: \(data)")
                    continue
                }

                guard let validDate = appointmentDate else {
                    print("Invalid date for appointment: \(snap.key), data: \(data)")
                    continue
                }

                fetchBarberDetailsAndServices(barberId: barberId, serviceIds: servicesArray) { shopName, serviceNames in
                    let appointment = Appointment(id: snap.key, barberId: barberId, shopName: shopName, userId: userId, date: validDate, time: time, services: serviceNames)

                    fetchedAppointments.append(appointment)

                    let now = Date()
                    self.upcomingAppointments = fetchedAppointments.filter { $0.date > now }.sorted(by: { $0.date < $1.date })
                    self.completedAppointments = fetchedAppointments.filter { $0.date <= now }.sorted(by: { $0.date > $1.date })

                    print("Fetched \(self.upcomingAppointments.count) upcoming appointments")
                    print("Fetched \(self.completedAppointments.count) completed appointments")
                }
            }
        } withCancel: { error in
            print("Failed to fetch appointments: \(error.localizedDescription)")
        }
    }

    private func fetchBarberDetailsAndServices(barberId: String, serviceIds: [String], completion: @escaping (String, [String]) -> Void) {
        let db = Database.database().reference().child("business_accounts").child(barberId)
        db.observeSingleEvent(of: .value) { snapshot in
            var shopName = "Unknown Barber"
            var serviceNames: [String] = []

            if let data = snapshot.value as? [String: Any] {
                shopName = data["shopName"] as? String ?? "Unknown Barber"

                if let servicesDict = data["services"] as? [[String: Any]] {
                    serviceNames = servicesDict.compactMap { service in
                        guard let id = service["id"] as? String, serviceIds.contains(id) else {
                            return nil
                        }
                        return service["name"] as? String
                    }
                }
            }

            completion(shopName, serviceNames)
        }
    }
}

struct AppointmentCardView: View {
    let appointment: Appointment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shop: \(appointment.shopName)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Date: \(formattedDate(appointment.date))")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Time: \(appointment.time)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Services: \(appointment.services.joined(separator: ", "))")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct AppointmentsPage_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentsPage()
    }
}
