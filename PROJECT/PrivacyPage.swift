//
//  PrivacyPage.swift
//  PROJECT
//
//  Created by Nabeel Shajahan on 2024-06-26.
//
import SwiftUI

struct PrivacyPage: View {
    var body: some View {
        VStack {
            Text("Privacy")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            // Add your content here
            Spacer()
        }
        .padding()
        .background(Color(UIColor(red: 1.0, green: 0.97, blue: 0.89, alpha: 1.0)))
        .navigationBarTitle("Privacy", displayMode: .inline)
    }
}

struct PrivacyPage_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPage()
    }
}
