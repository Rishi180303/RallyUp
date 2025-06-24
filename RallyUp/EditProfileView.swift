import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var user: User
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    let backgroundColor: Color
    
    @State private var name: String
    @State private var bio: String
    @State private var selectedSports: [Sport]
    @State private var skillLevel: SkillLevel
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(user: User, primaryColor: Color, secondaryColor: Color, accentColor: Color, backgroundColor: Color) {
        self.user = user
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        
        // Initialize state variables with user data
        _name = State(initialValue: user.name)
        _bio = State(initialValue: user.bio)
        _selectedSports = State(initialValue: user.preferredSports)
        _skillLevel = State(initialValue: user.skillLevel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.headline)
                                .foregroundColor(primaryColor)
                            
                            TextField("Your name", text: $name)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        // Bio field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.headline)
                                .foregroundColor(primaryColor)
                            
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
                        }
                        .padding(.horizontal)
                        
                        // Preferred sports
                        VStack(alignment: .leading, spacing: 8) {
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
                                .foregroundColor(primaryColor)
                            
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
                        
                        // Save button
                        Button(action: saveProfile) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save Changes")
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
                        .disabled(isLoading || name.isEmpty || selectedSports.isEmpty)
                        .opacity((isLoading || name.isEmpty || selectedSports.isEmpty) ? 0.6 : 1)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Profile Update"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("successfully") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
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
        guard !name.isEmpty, !selectedSports.isEmpty else {
            alertMessage = "Please fill in your name and select at least one sport."
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
            "fullName": name,
            "bio": bio,
            "preferredSports": selectedSports.map { $0.rawValue },
            "skillLevel": skillLevel.rawValue
        ]) { error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Error updating profile: \(error.localizedDescription)"
                showAlert = true
            } else {
                // Update the current user object
                var currentUser = User.currentUser
                currentUser.name = name
                currentUser.bio = bio
                currentUser.preferredSports = selectedSports
                currentUser.skillLevel = skillLevel
                User.currentUser = currentUser
                
                alertMessage = "Profile updated successfully!"
                showAlert = true
            }
        }
    }
}

