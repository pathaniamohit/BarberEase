//
//  PROJECTApp.swift
//  PROJECT
//
//  Created by Nabeel Shajahan on 2024-06-22.
//
import SwiftUI
import Firebase

@main
struct PROJECTApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}






