//
//  my_collectionApp.swift
//  my-collection
//
//  Created by Ma Jade on 2026/8/12.
//

import SwiftUI

@main
struct my_collectionApp: App {
    // 首次启动标志
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    
    var body: some Scene {
        WindowGroup {
            if hasLaunchedBefore {
                ContentView()
            } else {
                OnboardingView(isOnboardingCompleted: $hasLaunchedBefore)
            }
        }
    }
}
