//
//  TinyPayCheckoutApp.swift
//  TinyPayCheckout
//
//  Created by Harold on 2025/9/18.
//

import SwiftUI

@main
struct TinyPayApp: App {
    @State private var isOnboardingCompleted = UserDefaults.standard.bool(forKey: "isOnboardingCompleted")
    
    var body: some Scene {
        WindowGroup {
            if isOnboardingCompleted {
                ContentView()
            } else {
                OnboardingView(isOnboardingCompleted: $isOnboardingCompleted)
            }
        }
    }
}
