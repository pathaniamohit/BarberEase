//
//  AppointmentsPage.swift
//  PROJECT
//
//  Created by Nabeel Shajahan on 2024-06-26.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct AppointmentsPage: View {
    var body: some View {
        VStack {
            Text("Appointments")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            List {
                // Sample appointment entries
                ForEach(0..<5) { item in
                    HStack {
                        Image(systemName: "calendar")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .padding(.trailing, 10)
                        VStack(alignment: .leading) {
                            Text("Appointment \(item + 1)")
                                .font(.headline)
                            Text("Details about the appointment")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            .listStyle(PlainListStyle())
        }
        .padding()
        .background(Color(UIColor(red: 1.0, green: 0.97, blue: 0.89, alpha: 1.0)))
        .navigationBarTitle("Appointments", displayMode: .inline)
    }
}

struct AppointmentsPage_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentsPage()
    }
}

