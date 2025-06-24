import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MapKit

struct SessionManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var session: SportSession
    @State private var editedSession: SportSession
    @State private var isEditing = false
    @State private var participants: [User] = []
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var selectedParticipant: User? = nil
    @State private var showingRemoveConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeletingSession = false
    
    let primaryColor = Color(hex: "FF7E67")
    let secondaryColor = Color(hex: "FFB563")
    let accentColor = Color(hex: "FFEBB7")
    let backgroundColor = Color(hex: "FFF9F1")
    
    init(session: SportSession) {
        self.session = session
        self._editedSession = State(initialValue: session)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with map
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
                
                // Session details
                VStack(alignment: .leading, spacing: 15) {
                    if isEditing {
                        // Editable title
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Title")
                                .font(.headline)
                                .foregroundColor(primaryColor)
                            
                            TextField("Session title", text: $editedSession.title)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        }
                        
                        // Editable description
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(primaryColor)
                            
                            TextEditor(text: $editedSession.description)
                                .frame(minHeight: 100)
                                .padding(5)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        }
                        
                        // Editable max participants
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Max Participants")
                                .font(.headline)
                                .foregroundColor(primaryColor)
                            
                            Stepper("\(editedSession.maxParticipants) participants", value: $editedSession.maxParticipants, in: editedSession.currentParticipants.count...30)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        }
                        
                        // Save and cancel buttons
                        HStack {
                            Button(action: {
                                isEditing = false
                                editedSession = session // Reset changes
                            }) {
                                Text("Cancel")
                                    .fontWeight(.medium)
                                    .foregroundColor(primaryColor)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(primaryColor, lineWidth: 1)
                                    )
                            }
                            
                            Button(action: saveChanges) {
                                Text("Save Changes")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(primaryColor)
                                    .cornerRadius(12)
                            }
                        }
                    } else {
                        // View
                        Text(session.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
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
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About this session")
                                .font(.headline)
                                .foregroundColor(primaryColor)
                            
                            Text(session.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Edit button
                        Button(action: {
                            isEditing = true
                        }) {
                            Text("Edit Session Details")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(primaryColor)
                                .cornerRadius(12)
                        }
                        
                        // Cancel session button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            if isDeletingSession {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Cancel Session")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                        .padding(.top, 10)
                        .disabled(isDeletingSession)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Participants list
                VStack(alignment: .leading, spacing: 15) {
                    Text("Participants")
                        .font(.headline)
                        .foregroundColor(primaryColor)
                    
                    if isLoading {
                        ProgressView("Loading participants...")
                            .padding()
                    } else if participants.isEmpty {
                        Text("No participants have joined yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(participants) { participant in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(secondaryColor)
                                
                                VStack(alignment: .leading) {
                                    Text(participant.name)
                                        .fontWeight(.medium)
                                    
                                    Text(participant.skillLevel.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Only show remove button for participants who are not the host
                                if participant.id != session.hostId {
                                    Button(action: {
                                        selectedParticipant = participant
                                        showingRemoveConfirmation = true
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 22))
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding()
            .background(backgroundColor)
        }
        .navigationTitle("Manage Session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadParticipants()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertTitle == "Session Deleted" {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
        .actionSheet(isPresented: $showingRemoveConfirmation) {
            ActionSheet(
                title: Text("Remove Participant"),
                message: Text("Are you sure you want to remove \(selectedParticipant?.name ?? "this participant") from the session?"),
                buttons: [
                    .destructive(Text("Remove")) {
                        if let participant = selectedParticipant {
                            removeParticipant(participant)
                        }
                    },
                    .cancel()
                ]
            )
        }
        .actionSheet(isPresented: $showingDeleteConfirmation) {
            ActionSheet(
                title: Text("Cancel Session"),
                message: Text("Are you sure you want to cancel this session? This action cannot be undone and all participants will be notified."),
                buttons: [
                    .destructive(Text("Cancel Session")) {
                        deleteSession()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy • h:mm a"
        return formatter.string(from: date)
    }
    
    private func loadParticipants() {
        isLoading = true
        
        let db = Firestore.firestore()
        var loadedParticipants: [User] = []
        let group = DispatchGroup()
        
        for participantId in session.currentParticipants {
            group.enter()
            
            db.collection("users").document(participantId).getDocument { document, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error loading participant \(participantId): \(error.localizedDescription)")
                    return
                }
                
                guard let data = document?.data(),
                      let name = data["fullName"] as? String,
                      let email = data["email"] as? String,
                      let bio = data["bio"] as? String,
                      let preferredSports = data["preferredSports"] as? [String],
                      let skillRaw = data["skillLevel"] as? String,
                      let skill = SkillLevel(rawValue: skillRaw)
                else {
                    print("Invalid participant data for user: \(participantId)")
                    return
                }
                
                let user = User(
                    id: participantId,
                    name: name,
                    email: email,
                    profileImage: nil,
                    bio: bio,
                    preferredSports: preferredSports.compactMap { Sport(rawValue: $0.lowercased()) },
                    skillLevel: skill,
                    location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                    locationName: "",
                    sessionHistory: []
                )
                
                loadedParticipants.append(user)
            }
        }
        
        group.notify(queue: .main) {
            self.participants = loadedParticipants
            self.isLoading = false
        }
    }
    
    private func saveChanges() {
        guard editedSession.title.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            alertTitle = "Invalid Title"
            alertMessage = "Session title cannot be empty"
            showingAlert = true
            return
        }
        
        let db = Firestore.firestore()
        let sessionRef = db.collection("sessions").document(session.id)
        
        sessionRef.updateData([
            "title": editedSession.title,
            "description": editedSession.description,
            "maxParticipants": editedSession.maxParticipants
        ]) { error in
            if let error = error {
                alertTitle = "Error"
                alertMessage = "Failed to update session: \(error.localizedDescription)"
                showingAlert = true
            } else {
                alertTitle = "Success"
                alertMessage = "Session details updated successfully"
                showingAlert = true
                isEditing = false

            }
        }
    }
    
    private func removeParticipant(_ participant: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid, currentUserId == session.hostId else {
            alertTitle = "Error"
            alertMessage = "Only the host can remove participants"
            showingAlert = true
            return
        }
        
        let db = Firestore.firestore()
        let sessionRef = db.collection("sessions").document(session.id)
        let userRef = db.collection("users").document(participant.id)
        
        // Remove participant from session
        sessionRef.updateData([
            "currentParticipants": FieldValue.arrayRemove([participant.id])
        ]) { error in
            if let error = error {
                alertTitle = "Error"
                alertMessage = "Failed to remove participant: \(error.localizedDescription)"
                showingAlert = true
                return
            }
            
            // Remove session from participant's history
            userRef.updateData([
                "sessionHistory": FieldValue.arrayRemove([session.id])
            ]) { error in
                if let error = error {
                    print("Error updating user's session history: \(error.localizedDescription)")
                }
                
                
                sendRemovalMessage(to: participant)
                
                // Update local participants list
                self.participants.removeAll { $0.id == participant.id }
                
                alertTitle = "Success"
                alertMessage = "Participant removed and notified"
                showingAlert = true
            }
        }
    }
    
    private func deleteSession() {
        guard let currentUserId = Auth.auth().currentUser?.uid, currentUserId == session.hostId else {
            alertTitle = "Error"
            alertMessage = "Only the host can cancel this session"
            showingAlert = true
            return
        }
        
        isDeletingSession = true
        
        let db = Firestore.firestore()
        let sessionRef = db.collection("sessions").document(session.id)
        
        
        for participant in participants {
            if participant.id != currentUserId {
                sendCancellationMessage(to: participant)
            }
        }
        
        // Remove session from all participants' histories
        let group = DispatchGroup()
        
        for participantId in session.currentParticipants {
            group.enter()
            
            db.collection("users").document(participantId).updateData([
                "sessionHistory": FieldValue.arrayRemove([session.id])
            ]) { error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error removing session from participant \(participantId): \(error.localizedDescription)")
                }
            }
        }
        
        // Remove session from host's created sessions
        db.collection("users").document(currentUserId).updateData([
            "createdSessions": FieldValue.arrayRemove([session.id])
        ]) { error in
            if let error = error {
                print("Error removing session from host's created sessions: \(error.localizedDescription)")
            }
        }
        
        // Finally, delete the session document
        group.notify(queue: .main) {
            sessionRef.delete { error in
                isDeletingSession = false
                
                if let error = error {
                    alertTitle = "Error"
                    alertMessage = "Failed to delete session: \(error.localizedDescription)"
                    showingAlert = true
                } else {
                    alertTitle = "Session Deleted"
                    alertMessage = "The session has been cancelled and all participants have been notified."
                    showingAlert = true
                }
            }
        }
    }
    
    private func sendRemovalMessage(to participant: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Check if a conversation already exists
        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking for existing conversation: \(error.localizedDescription)")
                    return
                }
                
                var existingConversationId: String?
                
                // Look for an existing conversation with the participant
                if let documents = snapshot?.documents {
                    for document in documents {
                        let data = document.data()
                        if let participants = data["participants"] as? [String],
                           participants.contains(participant.id) {
                            existingConversationId = document.documentID
                            break
                        }
                    }
                }
                
                if let conversationId = existingConversationId {
                    // Use existing conversation
                    self.sendMessageInConversation(conversationId: conversationId, to: participant)
                } else {
                    // Create new conversation
                    self.createConversationAndSendMessage(to: participant)
                }
            }
    }
    
    private func sendCancellationMessage(to participant: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Check if a conversation already exists
        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking for existing conversation: \(error.localizedDescription)")
                    return
                }
                
                var existingConversationId: String?
                
                // Look for an existing conversation with the participant
                if let documents = snapshot?.documents {
                    for document in documents {
                        let data = document.data()
                        if let participants = data["participants"] as? [String],
                           participants.contains(participant.id) {
                            existingConversationId = document.documentID
                            break
                        }
                    }
                }
                
                let messageContent = "The session '\(session.title)' has been cancelled by the host."
                
                if let conversationId = existingConversationId {
                    // Use existing conversation
                    self.sendSpecificMessageInConversation(conversationId: conversationId, to: participant, content: messageContent)
                } else {
                    // Create new conversation
                    self.createConversationAndSendSpecificMessage(to: participant, content: messageContent)
                }
            }
    }
    
    private func sendMessageInConversation(conversationId: String, to participant: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let messageId = UUID().uuidString
        let timestamp = Date()
        
        // Create message content
        let messageContent = "Sorry, you have been removed from the session '\(session.title)'. Please contact the host if you have any questions."
        
        // Message data
        let messageData: [String: Any] = [
            "id": messageId,
            "senderId": currentUserId,
            "receiverId": participant.id,
            "content": messageContent,
            "timestamp": Timestamp(date: timestamp),
            "isRead": false
        ]
        
        // Add message to conversation
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .setData(messageData) { error in
                if let error = error {
                    print("Error sending removal message: \(error.localizedDescription)")
                    return
                }
                
                // Update last message in conversation
                db.collection("conversations")
                    .document(conversationId)
                    .updateData([
                        "lastMessage": messageData
                    ])
            }
    }
    
    private func sendSpecificMessageInConversation(conversationId: String, to participant: User, content: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let messageId = UUID().uuidString
        let timestamp = Date()
        
        // Message data
        let messageData: [String: Any] = [
            "id": messageId,
            "senderId": currentUserId,
            "receiverId": participant.id,
            "content": content,
            "timestamp": Timestamp(date: timestamp),
            "isRead": false
        ]
        
        // Add message to conversation
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .setData(messageData) { error in
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                    return
                }
                
                // Update last message in conversation
                db.collection("conversations")
                    .document(conversationId)
                    .updateData([
                        "lastMessage": messageData
                    ])
            }
    }
    
    private func createConversationAndSendMessage(to participant: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Get current user's name
        db.collection("users").document(currentUserId).getDocument { currentUserDoc, currentUserError in
            if let currentUserError = currentUserError {
                print("Error getting host data: \(currentUserError.localizedDescription)")
                return
            }
            
            guard let currentUserData = currentUserDoc?.data(),
                  let currentUserName = currentUserData["fullName"] as? String else {
                print("Could not get host data")
                return
            }
            
            let conversationId = UUID().uuidString
            let messageId = UUID().uuidString
            let timestamp = Date()
            
            // Create message content
            let messageContent = "Sorry, you have been removed from the session '\(session.title)'. Please contact the host if you have any questions."
            
            // Message data
            let messageData: [String: Any] = [
                "id": messageId,
                "senderId": currentUserId,
                "receiverId": participant.id,
                "content": messageContent,
                "timestamp": Timestamp(date: timestamp),
                "isRead": false
            ]
            
            // Participant names
            let participantNames: [String: String] = [
                currentUserId: currentUserName,
                participant.id: participant.name
            ]
            
            // Conversation data
            let conversationData: [String: Any] = [
                "participants": [currentUserId, participant.id],
                "participantNames": participantNames,
                "lastMessage": messageData,
                "createdAt": Timestamp(date: timestamp)
            ]
            
            // Create conversation
            db.collection("conversations").document(conversationId).setData(conversationData) { error in
                if let error = error {
                    print("Error creating conversation: \(error.localizedDescription)")
                    return
                }
                
                // Add message to conversation
                db.collection("conversations")
                    .document(conversationId)
                    .collection("messages")
                    .document(messageId)
                    .setData(messageData) { error in
                        if let error = error {
                            print("Error sending removal message: \(error.localizedDescription)")
                        }
                    }
            }
        }
    }
    
    private func createConversationAndSendSpecificMessage(to participant: User, content: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Get current user's name
        db.collection("users").document(currentUserId).getDocument { currentUserDoc, currentUserError in
            if let currentUserError = currentUserError {
                print("Error getting host data: \(currentUserError.localizedDescription)")
                return
            }
            
            guard let currentUserData = currentUserDoc?.data(),
                  let currentUserName = currentUserData["fullName"] as? String else {
                print("Could not get host data")
                return
            }
            
            let conversationId = UUID().uuidString
            let messageId = UUID().uuidString
            let timestamp = Date()
            
            // Message data
            let messageData: [String: Any] = [
                "id": messageId,
                "senderId": currentUserId,
                "receiverId": participant.id,
                "content": content,
                "timestamp": Timestamp(date: timestamp),
                "isRead": false
            ]
            
            // Participant names
            let participantNames: [String: String] = [
                currentUserId: currentUserName,
                participant.id: participant.name
            ]
            
            
            let conversationData: [String: Any] = [
                "participants": [currentUserId, participant.id],
                "participantNames": participantNames,
                "lastMessage": messageData,
                "createdAt": Timestamp(date: timestamp)
            ]
            
            
            db.collection("conversations").document(conversationId).setData(conversationData) { error in
                if let error = error {
                    print("Error creating conversation: \(error.localizedDescription)")
                    return
                }
                
                
                db.collection("conversations")
                    .document(conversationId)
                    .collection("messages")
                    .document(messageId)
                    .setData(messageData) { error in
                        if let error = error {
                            print("Error sending message: \(error.localizedDescription)")
                        }
                    }
            }
        }
    }
}

