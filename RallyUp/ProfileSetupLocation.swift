import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import MapKit
import CoreLocation


struct ProfileSetupLocationView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var bio = ""
    @State private var selectedSports: [Sport] = []
    @State private var skillLevel: SkillLevel = .beginner
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Simplified location states
    @State private var locationName = "Arizona State University"
    @State private var location = CLLocationCoordinate2D(latitude: 33.4255, longitude: -111.9400) 
    @State private var showingLocationPicker = false
    
    let primaryColor = Color(hex: "FF7E67")
    let secondaryColor = Color(hex: "FFB563")
    let backgroundColor = Color(hex: "FFF9F1")
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 10) {
                            Text("Complete Your Profile")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Tell us a bit about yourself so others can get to know you")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // Bio
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextEditor(text: $bio)
                                .frame(minHeight: 120)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
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
                        .padding(.horizontal)
                        
                        // Simplified Location Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Location")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LocationPickerButton(
                                locationName: $locationName,
                                location: $location,
                                primaryColor: primaryColor
                            )
                        }
                        .padding(.horizontal)
                        
                        // Map View
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected Location on Map")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Map(coordinateRegion: .constant(MKCoordinateRegion(
                                center: location,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )), annotationItems: [LocationMapPin(coordinate: location)]) { pin in
                                MapAnnotation(coordinate: pin.coordinate) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(primaryColor)
                                }
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        // Preferred sports
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preferred Sports")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
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
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Skill level
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Skill Level")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Skill Level", selection: $skillLevel) {
                                ForEach(SkillLevel.allCases) { level in
                                    Text(level.rawValue.capitalized).tag(level)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        
                        Button(action: saveProfile) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save Profile")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                        .shadow(color: primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        .disabled(isLoading || bio.isEmpty || selectedSports.isEmpty)
                        .opacity((isLoading || bio.isEmpty || selectedSports.isEmpty) ? 0.6 : 1)
                        
                        Spacer(minLength: 40)
                    }
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
        guard !bio.isEmpty, !selectedSports.isEmpty else {
            alertMessage = "Please fill in your bio and select at least one sport."
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

