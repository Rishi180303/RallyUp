import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CoreLocation
import MapKit

struct UserProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    let primaryColor = Color(hex: "FF7E67")
    let secondaryColor = Color(hex: "FFB563")
    let accentColor = Color(hex: "FFEBB7")
    let backgroundColor = Color(hex: "FFF9F1")
    
    @State private var firestoreUser: User? = nil
    @State private var userSessions: [SportSession] = []
    @State private var joinedSessions: [SportSession] = []
    @State private var isEditingProfile = false
    @State private var showLogoutAlert = false
    @State private var isEditingLocation = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading profile...")
                } else if let user = firestoreUser {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            profileHeaderView(user: user)
                            
                            
                            aboutMeSection(user: user)
                            
                            
                            sportsSection(user: user)
                            
                            
                            skillLevelSection(user: user)
                            
                            
                            locationSection(user: user)
                            
                            
                            hostedSessionsSection(sessions: userSessions)
                            
                            
                            joinedSessionsSection(sessions: joinedSessions)
                            
                            
                            logoutButton()
                        }
                    }
                } else {
                    Text("Could not load profile")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isLoading = true
                loadUserProfile()
            }
            .sheet(isPresented: $isEditingProfile) {
                if let user = firestoreUser {
                    EditProfileView(
                        user: user,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        accentColor: accentColor,
                        backgroundColor: backgroundColor
                    )
                    .onDisappear {
                        
                        loadUserProfile()
                    }
                }
            }
            .sheet(isPresented: $isEditingLocation) {
                if let user = firestoreUser {
                    LocationSelectionView(
                        locationName: user.locationName,
                        location: user.location
                    ) {
                        
                        loadUserProfile()
                    }
                }
            }
        }
    }
    
    
    
    private func profileHeaderView(user: User) -> some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(primaryColor)
                .padding(.bottom, 5)

            Text(user.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: {
                isEditingProfile = true
            }) {
                Text("Edit Profile")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(primaryColor)
                    .cornerRadius(15)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private func aboutMeSection(user: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Me")
                .font(.headline)
                .foregroundColor(primaryColor)
            
            Text(user.bio)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func sportsSection(user: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferred Sports")
                .font(.headline)
                .foregroundColor(primaryColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(user.preferredSports) { sport in
                        HStack {
                            Image(systemName: sport.icon)
                            Text(sport.rawValue.capitalized)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(accentColor.opacity(0.3))
                        .cornerRadius(15)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func skillLevelSection(user: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skill Level")
                .font(.headline)
                .foregroundColor(primaryColor)
            
            Text(user.skillLevel.rawValue.capitalized)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(accentColor.opacity(0.3))
                .cornerRadius(15)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func locationSection(user: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .foregroundColor(primaryColor)
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(secondaryColor)
                Text(user.locationName.isEmpty ? "No location set" : user.locationName)
                    .foregroundColor(.secondary)
            }
            
            if !user.locationName.isEmpty {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: user.location,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [LocationMapPin(coordinate: user.location)]) { pin in
                    MapAnnotation(coordinate: pin.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(primaryColor)
                    }
                }
                .frame(height: 150)
                .cornerRadius(15)
                .padding(.top, 5)
            }
            
            Button(action: {
                isEditingLocation = true
            }) {
                Text("Update Location")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(primaryColor)
                    .cornerRadius(15)
            }
            .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func hostedSessionsSection(sessions: [SportSession]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions You're Hosting")
                .font(.headline)
                .foregroundColor(primaryColor)

            if sessions.isEmpty {
                Text("You haven't created any sessions yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(sessions) { session in
                    NavigationLink(destination: SessionManagementView(session: session)) {
                        sessionRow(session: session)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func joinedSessionsSection(sessions: [SportSession]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions You've Joined")
                .font(.headline)
                .foregroundColor(primaryColor)

            if sessions.isEmpty {
                Text("You haven't joined any sessions yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(sessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        sessionRow(session: session)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func sessionRow(session: SportSession) -> some View {
        HStack {
            Image(systemName: session.sport.icon)
                .foregroundColor(primaryColor)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(session.title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(formatDate(session.dateTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(session.currentParticipants.count)/\(session.maxParticipants)")
                .font(.caption)
                .padding(5)
                .background(accentColor.opacity(0.3))
                .cornerRadius(10)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 5)
    }
    
    private func logoutButton() -> some View {
        Button(action: {
            showLogoutAlert = true
        }) {
            Text("Log Out")
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(15)
                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 30)
        .alert(isPresented: $showLogoutAlert) {
            Alert(
                title: Text("Log Out"),
                message: Text("Are you sure you want to log out?"),
                primaryButton: .destructive(Text("Log Out")) {
                    logoutUser()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    
    
    private func logoutUser() {
        do {
            try Auth.auth().signOut()
            
            DispatchQueue.main.async {
                authVM.isLoggedIn = false
                authVM.isProfileComplete = nil
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }

        let ref = Firestore.firestore().collection("users").document(uid)
        ref.getDocument { document, error in
            if let error = error {
                print("❌ Error loading user: \(error.localizedDescription)")
                isLoading = false
                return
            }

            guard let data = document?.data(),
                  let name = data["fullName"] as? String,
                  let email = data["email"] as? String,
                  let bio = data["bio"] as? String,
                  let preferredSports = data["preferredSports"] as? [String],
                  let skillRaw = data["skillLevel"] as? String,
                  let skill = SkillLevel(rawValue: skillRaw),
                  let locationMap = data["location"] as? [String: Double],
                  let lat = locationMap["lat"],
                  let lng = locationMap["lng"],
                  let locationName = data["locationName"] as? String
            else {
                print("❌ Missing or malformed user data")
                isLoading = false
                return
            }

            let sessionHistory = data["sessionHistory"] as? [String] ?? []
            let createdSessions = data["createdSessions"] as? [String] ?? []

            let user = User(
                id: uid,
                name: name,
                email: email,
                profileImage: nil,
                bio: bio,
                preferredSports: preferredSports.compactMap { Sport(rawValue: $0.lowercased()) },
                skillLevel: skill,
                location: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                locationName: locationName,
                sessionHistory: sessionHistory,
                createdSessions: createdSessions
            )
            
            DispatchQueue.main.async {
                self.firestoreUser = user
                User.currentUser = user
                
                
                if !createdSessions.isEmpty {
                    self.loadUserSessions(sessionIds: createdSessions)
                } else {
                    self.isLoading = false
                }
                
                
                let joinedButNotCreated = sessionHistory.filter { !createdSessions.contains($0) }
                if !joinedButNotCreated.isEmpty {
                    self.loadJoinedSessions(sessionIds: joinedButNotCreated)
                }
            }
        }
    }
    
    func loadUserSessions(sessionIds: [String]) {
        let db = Firestore.firestore()
        var loadedSessions: [SportSession] = []
        let group = DispatchGroup()
        
        for sessionId in sessionIds {
            group.enter()
            
            db.collection("sessions").document(sessionId).getDocument { document, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error loading session \(sessionId): \(error.localizedDescription)")
                    return
                }
                
                guard let data = document?.data(),
                      let id = data["id"] as? String,
                      let hostId = data["hostId"] as? String,
                      let title = data["title"] as? String,
                      let sportRaw = data["sport"] as? String,
                      let sport = Sport(rawValue: sportRaw),
                      let dateTime = (data["dateTime"] as? Timestamp)?.dateValue() ?? (data["dateTime"] as? Date),
                      let locationMap = data["location"] as? [String: Double],
                      let lat = locationMap["lat"],
                      let lng = locationMap["lng"],
                      let address = data["address"] as? String,
                      let maxParticipants = data["maxParticipants"] as? Int,
                      let currentParticipants = data["currentParticipants"] as? [String],
                      let description = data["description"] as? String,
                      let skillLevelRaw = data["skillLevel"] as? String,
                      let skillLevel = SkillLevel(rawValue: skillLevelRaw)
                else {
                    print("Invalid session data for document: \(sessionId)")
                    return
                }
                
                let isPrivate = data["isPrivate"] as? Bool ?? false
                
                let session = SportSession(
                    id: id,
                    hostId: hostId,
                    title: title,
                    sport: sport,
                    dateTime: dateTime,
                    location: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                    address: address,
                    maxParticipants: maxParticipants,
                    currentParticipants: currentParticipants,
                    description: description,
                    isPrivate: isPrivate,
                    skillLevel: skillLevel
                )
                
                loadedSessions.append(session)
            }
        }
        
        group.notify(queue: .main) {
            self.userSessions = loadedSessions
            self.isLoading = false
        }
    }
    
    func loadJoinedSessions(sessionIds: [String]) {
        let db = Firestore.firestore()
        var loadedSessions: [SportSession] = []
        let group = DispatchGroup()
        
        for sessionId in sessionIds {
            group.enter()
            
            db.collection("sessions").document(sessionId).getDocument { document, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error loading joined session \(sessionId): \(error.localizedDescription)")
                    return
                }
                
                guard let data = document?.data(),
                      let id = data["id"] as? String,
                      let hostId = data["hostId"] as? String,
                      let title = data["title"] as? String,
                      let sportRaw = data["sport"] as? String,
                      let sport = Sport(rawValue: sportRaw),
                      let dateTime = (data["dateTime"] as? Timestamp)?.dateValue() ?? (data["dateTime"] as? Date),
                      let locationMap = data["location"] as? [String: Double],
                      let lat = locationMap["lat"],
                      let lng = locationMap["lng"],
                      let address = data["address"] as? String,
                      let maxParticipants = data["maxParticipants"] as? Int,
                      let currentParticipants = data["currentParticipants"] as? [String],
                      let description = data["description"] as? String,
                      let skillLevelRaw = data["skillLevel"] as? String,
                      let skillLevel = SkillLevel(rawValue: skillLevelRaw)
                else {
                    print("Invalid session data for document: \(sessionId)")
                    return
                }
                
                let isPrivate = data["isPrivate"] as? Bool ?? false
                
                let session = SportSession(
                    id: id,
                    hostId: hostId,
                    title: title,
                    sport: sport,
                    dateTime: dateTime,
                    location: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                    address: address,
                    maxParticipants: maxParticipants,
                    currentParticipants: currentParticipants,
                    description: description,
                    isPrivate: isPrivate,
                    skillLevel: skillLevel
                )
                
                loadedSessions.append(session)
            }
        }
        
        group.notify(queue: .main) {
            self.joinedSessions = loadedSessions
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d • h:mm a"
        return formatter.string(from: date)
    }
}

