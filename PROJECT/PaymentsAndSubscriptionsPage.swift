//
//  PaymentsAndSubscriptionsPage.swift
//  PROJECT
//
//  Created by Nabeel Shajahan on 2024-06-26.
//

import SwiftUI

struct PaymentsAndSubscriptionsPage: View {
    var body: some View {
        VStack {
            Text("Payments and Subscriptions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            // Add your content here
            Spacer()
        }
        .padding()
        .background(Color(UIColor(red: 1.0, green: 0.97, blue: 0.89, alpha: 1.0)))
        .navigationBarTitle("Payments and Subscriptions", displayMode: .inline)
    }
}

struct PaymentsAndSubscriptionsPage_Previews: PreviewProvider {
    static var previews: some View {
        PaymentsAndSubscriptionsPage()
    }
}
