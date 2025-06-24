import SwiftUI
import MapKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct PostSessionView: View {
    
    let primaryColor = Color(red: 1.0, green: 0.494, blue: 0.404)
    let secondaryColor = Color(red: 1.0, green: 0.71, blue: 0.388)
    let accentColor = Color(red: 1.0, green: 0.918, blue: 0.718)
    let backgroundColor = Color(red: 1.0, green: 0.976, blue: 0.945)
    
    @State private var isCreatingSession = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @State private var title = ""
    @State private var selectedSport: Sport = .basketball
    @State private var date = Date().addingTimeInterval(86400)
    @State private var maxParticipants = 8
    @State private var description = ""
    @State private var selectedSkillLevel: SkillLevel = .intermediate
    @State private var address = ""
    @State private var location = CLLocationCoordinate2D(latitude: 33.4255, longitude: -111.9400)
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session Title")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Give your session a name", text: $title)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Sport selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sport")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Sport.allCases) { sport in
                                        Button(action: {
                                            selectedSport = sport
                                        }) {
                                            VStack {
                                                Image(systemName: sport.icon)
                                                    .font(.system(size: 24))
                                                Text(sport.rawValue.capitalized)
                                                    .font(.caption)
                                            }
                                            .frame(width: 80, height: 80)
                                            .background(selectedSport == sport ? primaryColor : Color.white)
                                            .foregroundColor(selectedSport == sport ? .white : .primary)
                                            .cornerRadius(12)
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LocationPickerButton(
                                locationName: $address,
                                location: $location,
                                primaryColor: primaryColor,
                                selectedSport: selectedSport
                            )
                            
                            // Show map preview if location is selected
                            if !address.isEmpty {
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
                                .frame(height: 150)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                        
                        // Date and time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date & Time")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            DatePicker("", selection: $date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Participants and skill level
                        HStack(spacing: 15) {
                            // Max participants
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Max Participants")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Stepper("\(maxParticipants) people", value: $maxParticipants, in: 2...30)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Skill level
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Skill Level")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Menu {
                                    ForEach(SkillLevel.allCases) { level in
                                        Button(action: {
                                            selectedSkillLevel = level
                                        }) {
                                            Text(level.rawValue.capitalized)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedSkillLevel.rawValue.capitalized)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextEditor(text: $description)
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
                        
                        // Create button
                        Button(action: {
                            createSession()
                        }) {
                            if isCreatingSession {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Session")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                                       startPoint: .leading, endPoint: .trailing)
                                    )
                            }
                        }
                        .disabled(title.isEmpty || address.isEmpty || isCreatingSession)
                        .opacity((title.isEmpty || address.isEmpty || isCreatingSession) ? 0.6 : 1)
                        .cornerRadius(12)
                        .shadow(color: primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        .alert(isPresented: $showingConfirmation) {
                            Alert(
                                title: Text("Session Created!"),
                                message: Text("Your session has been successfully created and added to your profile."),
                                dismissButton: .default(Text("OK")) {
                                    resetForm()
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Host a Session")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func createSession() {
        guard !title.isEmpty, !address.isEmpty else { return }
        
        isCreatingSession = true
        
        guard let uid = Auth.auth().currentUser?.uid else {
            isCreatingSession = false
            errorMessage = "You must be logged in to create a session"
            showingError = true
            return
        }
        
        // Create a new session ID
        let sessionId = UUID().uuidString
        
        
        var venueName: String? = nil
        var venueCategory: String? = nil
        if address.contains(",") {
            let components = address.components(separatedBy: ", ")
            if components.count > 1 {
                venueName = components[0]
            }
        }
        
        // Create the session data
        let sessionData: [String: Any] = [
            "id": sessionId,
            "hostId": uid,
            "title": title,
            "sport": selectedSport.rawValue,
            "dateTime": date,
            "location": [
                "lat": location.latitude,
                "lng": location.longitude
            ],
            "address": address,
            "maxParticipants": maxParticipants,
            "currentParticipants": [uid], // Host is automatically a participant
            "description": description,
            "isPrivate": false,
            "skillLevel": selectedSkillLevel.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "venueName": venueName ?? "",
            "venueCategory": venueCategory ?? ""
        ]
        
        // Save to Firestore
        let db = Firestore.firestore()
        
        // Add to sessions collection
        db.collection("sessions").document(sessionId).setData(sessionData) { error in
            if let error = error {
                isCreatingSession = false
                errorMessage = "Error creating session: \(error.localizedDescription)"
                showingError = true
                return
            }
            
            // Add to user's sessions
            db.collection("users").document(uid).updateData([
                "sessionHistory": FieldValue.arrayUnion([sessionId]),
                "createdSessions": FieldValue.arrayUnion([sessionId])
            ]) { error in
                isCreatingSession = false
                
                if let error = error {
                    errorMessage = "Error updating profile: \(error.localizedDescription)"
                    showingError = true
                    return
                }
                
                // Show confirmation
                showingConfirmation = true
            }
        }
    }
    
    private func resetForm() {
        title = ""
        selectedSport = .basketball
        date = Date().addingTimeInterval(86400)
        maxParticipants = 8
        description = ""
        selectedSkillLevel = .intermediate
        address = ""
    }
}

