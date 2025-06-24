import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        Group {
            if authVM.isLoggedIn {
                if let isComplete = authVM.isProfileComplete {
                    if isComplete {
                        MainTabView()
                    } else {
                        
                        ProfileSetupView()
                    }
                } else {
                    ProgressView("Checking profile...")
                }
            } else {
                LandingView()
            }
        }
    }
}

