import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

struct DashboardView: View {
    
    let primaryColor = Color(hex: "FF7E67")
    let secondaryColor = Color(hex: "FFB563")
    let accentColor = Color(hex: "FFEBB7")
    let backgroundColor = Color(hex: "FFF9F1")
    
    @State private var selectedSport: Sport? = nil
    @State private var maxDistance: Double = 10 // km
    @State private var showingMapView = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.4255, longitude: -111.9400),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var allSessions: [SportSession] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var userLocation: CLLocationCoordinate2D?
    
    var filteredSessions: [SportSession] {
        var sessions = allSessions
        
        if let sport = selectedSport {
            sessions = sessions.filter { $0.sport == sport }
        }
        
        return sessions
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with welcome message and upcoming sessions count
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Hello, \(User.currentUser.name.components(separatedBy: " ").first ?? "there")!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("There are \(filteredSessions.count) sessions near you")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 15)
                    .padding(.bottom, 10)
                    
                    // Sport filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Sport.allCases) { sport in
                                Button(action: {
                                    if selectedSport == sport {
                                        selectedSport = nil
                                    } else {
                                        selectedSport = sport
                                    }
                                }) {
                                    VStack {
                                        Image(systemName: sport.icon)
                                            .font(.system(size: 20))
                                        Text(sport.rawValue.capitalized)
                                            .font(.caption)
                                    }
                                    .frame(width: 70, height: 70)
                                    .background(selectedSport == sport ? primaryColor : Color.white)
                                    .foregroundColor(selectedSport == sport ? .white : .primary)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                    }
                    
                    // View toggle
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                showingMapView.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: showingMapView ? "list.bullet" : "map")
                                Text(showingMapView ? "List View" : "Map View")
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal, 15)
                        .padding(.bottom, 10)
                    }
                    
                    // Content area
                    if isLoading {
                        VStack {
                            ProgressView()
                            Text("Loading sessions...")
                                .foregroundColor(.secondary)
                                .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    else if filteredSessions.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(primaryColor.opacity(0.5))
                            
                            Text("No sessions found")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Text("Try adjusting your filters or create a new session")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    else {
                        if showingMapView {
                            // Map view
                            Map(coordinateRegion: $region, annotationItems: filteredSessions) { session in
                                MapAnnotation(coordinate: session.location) {
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        VStack {
                                            Image(systemName: session.sport.icon)
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                                .frame(width: 36, height: 36)
                                                .background(primaryColor)
                                                .clipShape(Circle())
                                                .shadow(radius: 2)
                                            
                                            Text(session.title)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .padding(5)
                                                .background(Color.white.opacity(0.9))
                                                .cornerRadius(8)
                                                .shadow(radius: 1)
                                        }
                                    }
                                }
                            }
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.bottom)
                        } else {
                            // List view
                            ScrollView {
                                LazyVStack(spacing: 15) {
                                    ForEach(filteredSessions) { session in
                                        NavigationLink(destination: SessionDetailView(session: session)) {
                                            SessionCard(session: session, primaryColor: primaryColor)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Discover Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadUserLocation()
                fetchSessions()
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func loadUserLocation() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error getting user location: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data(),
                  let locationMap = data["location"] as? [String: Double],
                  let lat = locationMap["lat"],
                  let lng = locationMap["lng"] else {
                print("No location data found")
                return
            }
            
            self.userLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    
    private func fetchSessions() {
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("sessions").getDocuments { snapshot, error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error loading sessions: \(error.localizedDescription)"
                showError = true
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No sessions found")
                return
            }
            
            var fetchedSessions: [SportSession] = []
            
            for document in documents {
                let data = document.data()
                
                guard let id = data["id"] as? String,
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
                    print("Invalid session data for document: \(document.documentID)")
                    continue
                }
                
                let isPrivate = data["isPrivate"] as? Bool ?? false
                let venueName = data["venueName"] as? String
                let venueCategory = data["venueCategory"] as? String
                
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
                    skillLevel: skillLevel,
                    venueName: venueName,
                    venueCategory: venueCategory
                )
                
                fetchedSessions.append(session)
            }
            
            self.allSessions = fetchedSessions
        }
    }
}

struct SessionCard: View {
    let session: SportSession
    let primaryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with sport icon and date
            HStack {
                Image(systemName: session.sport.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(primaryColor)
                    .clipShape(Circle())
                
                Text(session.sport.rawValue.capitalized)
                    .font(.headline)
                
                Spacer()
                
                Text(formatDate(session.dateTime))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Title
            Text(session.title)
                .font(.title3)
                .fontWeight(.bold)
            
            // Location
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.secondary)
                Text(session.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Participants
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.secondary)
                Text("\(session.currentParticipants.count)/\(session.maxParticipants) participants")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Skill level badge
                Text(session.skillLevel.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d • h:mm a"
        return formatter.string(from: date)
    }
}


struct SessionDetailView: View {
    let session: SportSession
    let primaryColor = Color(hex: "FF7E67")
    let secondaryColor = Color(hex: "FFB563")
    let backgroundColor = Color(hex: "FFF9F1")
    
    @State private var isInterested = false
    @State private var isJoining = false
    @State private var isUserParticipant = false
    @State private var isUserHost = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var hostName: String = ""
    @State private var showingChatView = false
    @State private var conversation: Conversation?
    @State private var isLoadingChat = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header image or map
                ZStack(alignment: .bottomLeading) {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: session.location,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [LocationMapPin(coordinate: session.location)]) { pin in
                        MapAnnotation(coordinate: pin.coordinate) {
                            Image(systemName: session.sport.icon)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(primaryColor)
                                .clipShape(Circle())
                        }
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    
                    HStack {
                        Text(session.sport.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(primaryColor)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        
                        Text(session.skillLevel.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(20)
                    }
                    .padding()
                }
                
                // Title and host
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.secondary)
                        Text("Hosted by \(hostName.isEmpty ? "..." : hostName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Date and time
                HStack(spacing: 15) {
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(primaryColor)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date & Time")
                            .font(.headline)
                        Text(formatDate(session.dateTime))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Location
                HStack(spacing: 15) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 20))
                        .foregroundColor(primaryColor)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location")
                            .font(.headline)
                        
                        if let venueName = session.venueName, !venueName.isEmpty {
                            Text(venueName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(primaryColor)
                        }
                        
                        Text(session.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Participants
                HStack(spacing: 15) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20))
                        .foregroundColor(primaryColor)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Participants")
                            .font(.headline)
                        Text("\(session.currentParticipants.count) of \(session.maxParticipants) spots filled")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("About this session")
                        .font(.headline)
                    
                    Text(session.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 30)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        toggleParticipation()
                    }) {
                        if isJoining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(buttonText)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(buttonColor)
                    .cornerRadius(12)
                    .disabled(isJoining || isUserHost)
                    .opacity((isJoining || isUserHost) ? 0.6 : 1)
                    
                    
                    if !isUserHost {
                        Button(action: {
                            messageHost()
                        }) {
                            if isLoadingChat {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Message Host")
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(secondaryColor)
                        .cornerRadius(12)
                        .disabled(isLoadingChat)
                        .opacity(isLoadingChat ? 0.6 : 1)
                    }
                }
            }
            .padding()
            .background(backgroundColor)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkUserStatus()
            fetchHostName()
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingChatView) {
            if let conversation = conversation {
                NavigationView {
                    ChatView(conversation: conversation, primaryColor: primaryColor)
                        .navigationBarItems(trailing: Button("Done") {
                            showingChatView = false
                        })
                }
            }
        }
    }
    
    private var buttonText: String {
        if isUserHost {
            return "You're the Host"
        } else if isUserParticipant {
            return "Leave Session"
        } else {
            return "Join Session"
        }
    }
    
    private var buttonColor: Color {
        if isUserParticipant {
            return Color.red
        } else {
            return primaryColor
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy • h:mm a"
        return formatter.string(from: date)
    }
    
    private func checkUserStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isUserHost = session.hostId == uid
        isUserParticipant = session.currentParticipants.contains(uid)
    }
    
    private func fetchHostName() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        
        if session.hostId == currentUserId {
            hostName = "You"
            return
        }
        
        
        let db = Firestore.firestore()
        db.collection("users").document(session.hostId).getDocument { document, error in
            if let document = document, document.exists,
               let data = document.data(),
               let name = data["fullName"] as? String {
                DispatchQueue.main.async {
                    self.hostName = name
                }
            }
        }
    }
    
    private func messageHost() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to message the host"
            showError = true
            return
        }
        
        if isUserHost {
            errorMessage = "You can't message yourself"
            showError = true
            return
        }
        
        isLoadingChat = true
        
        
        let db = Firestore.firestore()
        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    isLoadingChat = false
                    errorMessage = "Error loading conversations: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                
                if let documents = snapshot?.documents {
                    for document in documents {
                        let data = document.data()
                        if let participants = data["participants"] as? [String],
                           participants.contains(session.hostId) {
                            
                            loadConversation(document.documentID)
                            return
                        }
                    }
                }
                
                
                createNewConversation()
            }
    }
    
    private func loadConversation(_ conversationId: String) {
        let db = Firestore.firestore()
        db.collection("conversations").document(conversationId).getDocument { document, error in
            if let error = error {
                isLoadingChat = false
                errorMessage = "Error loading conversation: \(error.localizedDescription)"
                showError = true
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let participants = data["participants"] as? [String],
                  let lastMessageData = data["lastMessage"] as? [String: Any],
                  let senderId = lastMessageData["senderId"] as? String,
                  let receiverId = lastMessageData["receiverId"] as? String,
                  let content = lastMessageData["content"] as? String,
                  let timestamp = lastMessageData["timestamp"] as? Timestamp,
                  let isRead = lastMessageData["isRead"] as? Bool else {
            isLoadingChat = false
            errorMessage = "Invalid conversation data"
            showError = true
            return
        }
        
        
        var participantNames: [String: String] = [:]
        let group = DispatchGroup()
        
        for participantId in participants {
            group.enter()
            
            db.collection("users").document(participantId).getDocument { userDoc, userError in
                defer { group.leave() }
                
                if let userData = userDoc?.data(),
                   let name = userData["fullName"] as? String {
                    participantNames[participantId] = name
                }
            }
        }
        
        //  last message
        let lastMessage = Message(
            id: lastMessageData["id"] as? String ?? UUID().uuidString,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            timestamp: timestamp.dateValue(),
            isRead: isRead
        )
        
        
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments { messagesSnapshot, messagesError in
                isLoadingChat = false
                
                if let messagesError = messagesError {
                    errorMessage = "Error loading messages: \(messagesError.localizedDescription)"
                    showError = true
                    return
                }
                
                var messages: [Message] = []
                
                if let documents = messagesSnapshot?.documents {
                    for document in documents {
                        let data = document.data()
                        
                        guard let id = data["id"] as? String,
                              let senderId = data["senderId"] as? String,
                              let receiverId = data["receiverId"] as? String,
                              let content = data["content"] as? String,
                              let timestamp = data["timestamp"] as? Timestamp,
                              let isRead = data["isRead"] as? Bool else {
                            continue
                        }
                        
                        let message = Message(
                            id: id,
                            senderId: senderId,
                            receiverId: receiverId,
                            content: content,
                            timestamp: timestamp.dateValue(),
                            isRead: isRead
                        )
                        
                        messages.append(message)
                    }
                }
                
                group.notify(queue: .main) {
                    
                    self.conversation = Conversation(
                        id: conversationId,
                        participants: participants,
                        participantNames: participantNames,
                        lastMessage: lastMessage,
                        messages: messages.isEmpty ? [lastMessage] : messages
                    )
                    
                    self.showingChatView = true
                }
            }
    }
}
    
    private func createNewConversation() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            isLoadingChat = false
            return
        }
        
        let db = Firestore.firestore()
        
        
        db.collection("users").document(currentUserId).getDocument { currentUserDoc, currentUserError in
            if let currentUserError = currentUserError {
                isLoadingChat = false
                errorMessage = "Error getting user data: \(currentUserError.localizedDescription)"
                showError = true
                return
            }
            
            guard let currentUserData = currentUserDoc?.data(),
                  let currentUserName = currentUserData["fullName"] as? String else {
                isLoadingChat = false
                errorMessage = "Could not get your user data"
                showError = true
                return
            }
            
            
            let getHostName = hostName.isEmpty || hostName == "..."
            
            if getHostName {
                db.collection("users").document(session.hostId).getDocument { hostDoc, hostError in
                    if let hostError = hostError {
                        isLoadingChat = false
                        errorMessage = "Error getting host data: \(hostError.localizedDescription)"
                        showError = true
                        return
                    }
                    
                    guard let hostData = hostDoc?.data(),
                          let hostName = hostData["fullName"] as? String else {
                        isLoadingChat = false
                        errorMessage = "Could not get host data"
                        showError = true
                        return
                    }
                    
                    self.hostName = hostName
                    createConversationWithNames(currentUserName: currentUserName, hostName: hostName)
                }
            } else {
                createConversationWithNames(currentUserName: currentUserName, hostName: hostName)
            }
        }
    }
    
    private func createConversationWithNames(currentUserName: String, hostName: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            isLoadingChat = false
            return
        }
        
        let db = Firestore.firestore()
        let conversationId = UUID().uuidString
        let messageId = UUID().uuidString
        let timestamp = Date()
        
        // Create initial message
        let initialMessage = Message(
            id: messageId,
            senderId: currentUserId,
            receiverId: session.hostId,
            content: "Hi! I'm interested in your \(session.sport.rawValue) session: \(session.title)",
            timestamp: timestamp,
            isRead: false
        )
        
        // Message data for Firestore
        let messageData: [String: Any] = [
            "id": messageId,
            "senderId": currentUserId,
            "receiverId": session.hostId,
            "content": "Hi! I'm interested in your \(session.sport.rawValue) session: \(session.title)",
            "timestamp": Timestamp(date: timestamp),
            "isRead": false
        ]
        
        // Participant names
        let participantNames: [String: String] = [
            currentUserId: currentUserName,
            session.hostId: hostName
        ]
        
        // Conversation data for Firestore
        let conversationData: [String: Any] = [
            "participants": [currentUserId, session.hostId],
            "participantNames": participantNames,
            "lastMessage": messageData,
            "createdAt": Timestamp(date: timestamp)
        ]
        
        // Create the conversation in Firestore
        db.collection("conversations").document(conversationId).setData(conversationData) { error in
            if let error = error {
                isLoadingChat = false
                errorMessage = "Error creating conversation: \(error.localizedDescription)"
                showError = true
                return
            }
            
            // Add the initial message to the conversation
            db.collection("conversations").document(conversationId).collection("messages").document(messageId).setData(messageData) { error in
                isLoadingChat = false
                
                if let error = error {
                    errorMessage = "Error sending message: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                // Create the conversation object
                self.conversation = Conversation(
                    id: conversationId,
                    participants: [currentUserId, session.hostId],
                    participantNames: participantNames,
                    lastMessage: initialMessage,
                    messages: [initialMessage]
                )
                
                self.showingChatView = true
            }
        }
    }
    
    private func toggleParticipation() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to join sessions"
            showError = true
            return
        }
        
        isJoining = true
        
        let db = Firestore.firestore()
        let sessionRef = db.collection("sessions").document(session.id)
        let userRef = db.collection("users").document(uid)
        
        if isUserParticipant {
            // Leave the session
            sessionRef.updateData([
                "currentParticipants": FieldValue.arrayRemove([uid])
            ]) { error in
                if let error = error {
                    self.isJoining = false
                    self.errorMessage = "Error leaving session: \(error.localizedDescription)"
                    self.showError = true
                    return
                }
                
                userRef.updateData([
                    "sessionHistory": FieldValue.arrayRemove([self.session.id])
                ]) { error in
                    self.isJoining = false
                    
                    if let error = error {
                        self.errorMessage = "Error updating profile: \(error.localizedDescription)"
                        self.showError = true
                        return
                    }
                    
                    self.isUserParticipant = false
                }
            }
        } else {
            // Join the session
            sessionRef.updateData([
                "currentParticipants": FieldValue.arrayUnion([uid])
            ]) { error in
                if let error = error {
                    self.isJoining = false
                    self.errorMessage = "Error joining session: \(error.localizedDescription)"
                    self.showError = true
                    return
                }
                
                userRef.updateData([
                    "sessionHistory": FieldValue.arrayUnion([self.session.id])
                ]) { error in
                    self.isJoining = false
                    
                    if let error = error {
                        self.errorMessage = "Error updating profile: \(error.localizedDescription)"
                        self.showError = true
                        return
                    }
                    
                    self.isUserParticipant = true
                }
            }
        }
    }
}

