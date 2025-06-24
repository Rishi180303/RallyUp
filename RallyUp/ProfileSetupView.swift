import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import MapKit
import CoreLocation

struct ProfileSetupView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var currentStep = 0
    @State private var bio = ""
    @State private var selectedSports: [Sport] = []
    @State private var skillLevel: SkillLevel = .beginner
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Location states
    @State private var locationName = ""
    @State private var location = CLLocationCoordinate2D(latitude: 33.4255, longitude: -111.9400) // ASU
    @State private var showingLocationPicker = false
    
    let primaryColor = Color(hex: "FF7E67")
    let secondaryColor = Color(hex: "FFB563")
    let accentColor = Color(hex: "FFEBB7")
    let backgroundColor = Color(hex: "FFF9F1")
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Progress indicator
                        HStack(spacing: 8) {
                            ForEach(0..<3) { step in
                                Circle()
                                    .fill(currentStep >= step ? primaryColor : Color.gray.opacity(0.3))
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Header
                        VStack(spacing: 10) {
                            Text(headerTitle)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(headerSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 10)
                        
                        // Content based on current step
                        if currentStep == 0 {
                            
                            bioSection
                        } else if currentStep == 1 {
                            
                            sportsAndSkillSection
                        } else {
                            
                            locationSection
                        }
                        
                        // Navigation buttons
                        HStack(spacing: 15) {
                            // Back button (except on first step)
                            if currentStep > 0 {
                                Button(action: {
                                    withAnimation {
                                        currentStep -= 1
                                    }
                                }) {
                                    Text("Back")
                                        .fontWeight(.medium)
                                        .foregroundColor(primaryColor)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(15)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(primaryColor, lineWidth: 1)
                                        )
                                }
                            }
                            
                            // Next/Save button
                            Button(action: {
                                if currentStep < 2 {
                                    withAnimation {
                                        currentStep += 1
                                    }
                                } else {
                                    saveProfile()
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(currentStep == 2 ? "Save Profile" : "Next")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: currentStep > 0 ? .infinity : nil)
                            .padding()
                            .background(
                                isNextButtonDisabled ?
                                Color.gray.opacity(0.5) :
                                primaryColor
                            )
                            .cornerRadius(15)
                            .disabled(isNextButtonDisabled || isLoading)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Profile Setup"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationMapPickerView(
                    locationName: $locationName,
                    location: $location,
                    isPresented: $showingLocationPicker,
                    primaryColor: primaryColor
                )
            }
        }
    }
    
    
    
    var headerTitle: String {
        switch currentStep {
        case 0:
            return "Tell Us About Yourself"
        case 1:
            return "Your Sports Preferences"
        case 2:
            return "Set Your Location"
        default:
            return "Complete Your Profile"
        }
    }
    
    var headerSubtitle: String {
        switch currentStep {
        case 0:
            return "Let others know a bit about you"
        case 1:
            return "Select your favorite sports and skill level"
        case 2:
            return "Choose your primary location for finding sports sessions"
        default:
            return "Tell us a bit about yourself so others can get to know you"
        }
    }
    
    var isNextButtonDisabled: Bool {
        switch currentStep {
        case 0:
            return bio.isEmpty
        case 1:
            return selectedSports.isEmpty
        case 2:
            return locationName.isEmpty
        default:
            return false
        }
    }
    
    
    
    var bioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bio")
                .font(.headline)
                .foregroundColor(primaryColor)
            
            TextEditor(text: $bio)
                .frame(minHeight: 150)
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if bio.isEmpty {
                            Text("Tell us about yourself, your sports experience, and what you're looking for...")
                                .foregroundColor(.gray.opacity(0.7))
                                .padding()
                                .allowsHitTesting(false)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                )
        }
    }
    
    var sportsAndSkillSection: some View {
        VStack(spacing: 25) {
            // Preferred sports
            VStack(alignment: .leading, spacing: 12) {
                Text("Preferred Sports")
                    .font(.headline)
                    .foregroundColor(primaryColor)
                
                VStack(spacing: 10) {
                    ForEach(Sport.allCases) { sport in
                        Button(action: {
                            toggleSport(sport)
                        }) {
                            HStack {
                                Image(systemName: sport.icon)
                                    .foregroundColor(primaryColor)
                                
                                Text(sport.rawValue.capitalized)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedSports.contains(where: { $0 == sport }) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(primaryColor)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                }
            }
            
            // Skill level
            VStack(alignment: .leading, spacing: 12) {
                Text("Skill Level")
                    .font(.headline)
                    .foregroundColor(primaryColor)
                
                Picker("Skill Level", selection: $skillLevel) {
                    ForEach(SkillLevel.allCases) { level in
                        Text(level.rawValue.capitalized).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Location")
                .font(.headline)
                .foregroundColor(primaryColor)
            
            // Location button
            Button(action: {
                showingLocationPicker = true
            }) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(primaryColor)
                    
                    Text(locationName.isEmpty ? "Select location" : locationName)
                        .foregroundColor(locationName.isEmpty ? .gray : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            // Map preview
            if !locationName.isEmpty {
                Text("Selected Location")
                    .font(.headline)
                    .foregroundColor(primaryColor)
                    .padding(.top, 15)
                
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [LocationMapPin(coordinate: location)]) { pin in
                    MapAnnotation(coordinate: pin.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(primaryColor)
                    }
                }
                .frame(height: 200)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    
    
    private func toggleSport(_ sport: Sport) {
        if selectedSports.contains(where: { $0 == sport }) {
            selectedSports.removeAll(where: { $0 == sport })
        } else {
            selectedSports.append(sport)
        }
    }
    
    private func saveProfile() {
        guard !bio.isEmpty, !selectedSports.isEmpty, !locationName.isEmpty else {
            alertMessage = "Please complete all required fields."
            showAlert = true
            return
        }
        
        isLoading = true
        
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            alertMessage = "Error: User not authenticated."
            showAlert = true
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.updateData([
            "bio": bio,
            "preferredSports": selectedSports.map { $0.rawValue },
            "skillLevel": skillLevel.rawValue,
            "location": ["lat": location.latitude, "lng": location.longitude],
            "locationName": locationName,
            "profileComplete": true
        ]) { error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Error updating profile: \(error.localizedDescription)"
                showAlert = true
            } else {
                
                authVM.isProfileComplete = true
                
                // Update the current user object
                var currentUser = User.currentUser
                currentUser.bio = bio
                currentUser.preferredSports = selectedSports
                currentUser.skillLevel = skillLevel
                currentUser.location = location
                currentUser.locationName = locationName
                User.currentUser = currentUser
            }
        }
    }
}

