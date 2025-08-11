import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MessagingView: View {
    
    let primaryColor = Color(hex: "FF7E67")
    let secondaryColor = Color(hex: "FFB563")
    let accentColor = Color(hex: "FFEBB7")
    let backgroundColor = Color(hex: "FFF9F1") 
    
    @State private var searchText = ""
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var conversationsListener: ListenerRegistration?
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        } else {
            return conversations.filter { conversation in
                // Get the other user in the conversation
                if let otherUserId = getOtherUserId(from: conversation),
                   let otherUserName = conversation.participantNames[otherUserId] {
                    return otherUserName.lowercased().contains(searchText.lowercased()) ||
                           conversation.lastMessage.content.lowercased().contains(searchText.lowercased())
                }
                return false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search messages", text: $searchText)
                            .font(.system(size: 16))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if isLoading {
                        Spacer()
                        ProgressView("Loading conversations...")
                        Spacer()
                    } else if filteredConversations.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "message.fill")
                                .font(.system(size: 60))
                                .foregroundColor(primaryColor.opacity(0.3))
                            
                            Text("No messages yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("When you connect with other players, your conversations will appear here.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Spacer()
                        }
                    } else {
                        // Conversation list
                        List {
                            ForEach(filteredConversations) { conversation in
                                NavigationLink(destination: ChatView(conversation: conversation, primaryColor: primaryColor)) {
                                    ConversationRow(conversation: conversation, primaryColor: primaryColor)
                                }
                                .listRowBackground(Color.white)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startConversationsListener()
            }
            .onDisappear {
                conversationsListener?.remove()
                conversationsListener = nil
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
    
    private func startConversationsListener() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to view messages"
            showError = true
            return
        }
        isLoading = true
        let db = Firestore.firestore()
        conversationsListener?.remove()
        conversationsListener = db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .addSnapshotListener { _, _ in
                // Reuse existing fetch to build full models (names + messages)
                fetchConversations()
            }
    }

    private func fetchConversations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to view messages"
            showError = true
            return
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    isLoading = false
                    errorMessage = "Error loading conversations: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    isLoading = false
                    return
                }
                
                var loadedConversations: [Conversation] = []
                let group = DispatchGroup()
                
                for document in documents {
                    group.enter()
                    
                    let data = document.data()
                    let id = document.documentID
                    
                    guard let participants = data["participants"] as? [String],
                          let lastMessageData = data["lastMessage"] as? [String: Any],
                          let senderId = lastMessageData["senderId"] as? String,
                          let receiverId = lastMessageData["receiverId"] as? String,
                          let content = lastMessageData["content"] as? String,
                          let timestamp = lastMessageData["timestamp"] as? Timestamp,
                          let isRead = lastMessageData["isRead"] as? Bool else {
                        group.leave()
                        continue
                    }
                    
                    // Create the last message
                    let lastMessage = Message(
                        id: lastMessageData["id"] as? String ?? UUID().uuidString,
                        senderId: senderId,
                        receiverId: receiverId,
                        content: content,
                        timestamp: timestamp.dateValue(),
                        isRead: isRead
                    )
                    
                    // Get participant names
                    var participantNames: [String: String] = [:]
                    let participantsGroup = DispatchGroup()
                    
                    for participantId in participants {
                        participantsGroup.enter()
                        
                        db.collection("users").document(participantId).getDocument { userDoc, userError in
                            defer { participantsGroup.leave() }
                            
                            if let userData = userDoc?.data(),
                               let name = userData["fullName"] as? String {
                                participantNames[participantId] = name
                            }
                        }
                    }
                    
                    
                    db.collection("conversations")
                        .document(id)
                        .collection("messages")
                        .order(by: "timestamp", descending: false)
                        .getDocuments { messagesSnapshot, messagesError in
                            
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
                            
                            participantsGroup.notify(queue: .main) {
                                // Create the conversation
                                let conversation = Conversation(
                                    id: id,
                                    participants: participants,
                                    participantNames: participantNames,
                                    lastMessage: lastMessage,
                                    messages: messages.isEmpty ? [lastMessage] : messages
                                )
                                
                                loadedConversations.append(conversation)
                                group.leave()
                            }
                        }
                }
                
                group.notify(queue: .main) {
                    
                    self.conversations = loadedConversations.sorted {
                        $0.lastMessage.timestamp > $1.lastMessage.timestamp
                    }
                    isLoading = false
                }
            }
    }
    
    private func getOtherUserId(from conversation: Conversation) -> String? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        return conversation.participants.first { $0 != currentUserId }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let primaryColor: Color
    
    var otherUserId: String? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        return conversation.participants.first { $0 != currentUserId }
    }
    
    var otherUserName: String {
        if let otherUserId = otherUserId,
           let name = conversation.participantNames[otherUserId] {
            return name
        }
        return "Unknown User"
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile image
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(primaryColor)
            
            // Message preview
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(otherUserName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(timeAgo(conversation.lastMessage.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(conversation.lastMessage.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if !conversation.lastMessage.isRead && conversation.lastMessage.receiverId == Auth.auth().currentUser?.uid {
                        Circle()
                            .fill(primaryColor)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

struct ChatView: View {
    let conversation: Conversation
    let primaryColor: Color
    let secondaryColor: Color
    
    @State private var messageText = ""
    @State private var messages: [Message]
    @State private var scrollToBottom = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var messagesListener: ListenerRegistration?
    
    init(conversation: Conversation, primaryColor: Color) {
        self.conversation = conversation
        self.primaryColor = primaryColor
        self.secondaryColor = Color(hex: "FFB563")
        _messages = State(initialValue: conversation.messages)
    }
    
    var otherUserId: String? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        return conversation.participants.first { $0 != currentUserId }
    }
    
    var otherUserName: String {
        if let otherUserId = otherUserId,
           let name = conversation.participantNames[otherUserId] {
            return name
        }
        return "Unknown User"
    }
    
    var body: some View {
        VStack {
            if messages.isEmpty {
                ProgressView("Loading messages...")
                    .padding()
            } else {
                // Chat messages
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, primaryColor: primaryColor, secondaryColor: secondaryColor)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .onChange(of: messages) { _ in
                        if scrollToBottom {
                            withAnimation {
                                scrollView.scrollTo(messages.last?.id, anchor: .bottom)
                            }
                            scrollToBottom = false
                        }
                    }
                    .onAppear {
                        scrollToBottom = true
                    }
                }
            }
            
            // Message input
            HStack {
                TextField("Type a message...", text: $messageText)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(primaryColor)
                        .clipShape(Circle())
                        .shadow(color: primaryColor.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
            }
            .padding()
            .background(Color.white)
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "FFF9F1").ignoresSafeArea())
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            startMessagesListener()
        }
        .onDisappear {
            messagesListener?.remove()
            messagesListener = nil
        }
    }
    
    private func startMessagesListener() {
        let db = Firestore.firestore()
        messagesListener?.remove()
        messagesListener = db.collection("conversations")
            .document(conversation.id)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.errorMessage = "Error loading messages: \(error.localizedDescription)"
                    self.showError = true
                    return
                }
                guard let documents = snapshot?.documents else { return }
                var loaded: [Message] = []
                var unreadIds: [String] = []
                let currentUserId = Auth.auth().currentUser?.uid
                for doc in documents {
                    let data = doc.data()
                    guard
                        let id = data["id"] as? String,
                        let senderId = data["senderId"] as? String,
                        let receiverId = data["receiverId"] as? String,
                        let content = data["content"] as? String,
                        let ts = data["timestamp"] as? Timestamp,
                        let isRead = data["isRead"] as? Bool
                    else { continue }
                    let msg = Message(id: id, senderId: senderId, receiverId: receiverId, content: content, timestamp: ts.dateValue(), isRead: isRead)
                    loaded.append(msg)
                    if receiverId == currentUserId, !isRead { unreadIds.append(id) }
                }
                self.messages = loaded
                self.scrollToBottom = true
                // Mark messages as read for current user
                if let currentUserId = currentUserId, !unreadIds.isEmpty {
                    let convoRef = db.collection("conversations").document(conversation.id)
                    for mid in unreadIds {
                        convoRef.collection("messages").document(mid).updateData(["isRead": true])
                    }
                }
            }
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard let receiverId = otherUserId else { return }
        
        let messageId = UUID().uuidString
        let timestamp = Date()
        
        let newMessage = Message(
            id: messageId,
            senderId: currentUserId,
            receiverId: receiverId,
            content: messageText,
            timestamp: timestamp,
            isRead: false
        )
        

        messages.append(newMessage)
        scrollToBottom = true
        
   
        let messageContent = messageText
        messageText = ""
        
        // Save to Firebase
        let db = Firestore.firestore()
        
        // Message data
        let messageData: [String: Any] = [
            "id": messageId,
            "senderId": currentUserId,
            "receiverId": receiverId,
            "content": messageContent,
            "timestamp": Timestamp(date: timestamp),
            "isRead": false
        ]
        
        // Add message to conversation
        db.collection("conversations")
            .document(conversation.id)
            .collection("messages")
            .document(messageId)
            .setData(messageData) { error in
                if let error = error {
                    errorMessage = "Error sending message: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                // Update last message in conversation
                db.collection("conversations")
                    .document(conversation.id)
                    .updateData([
                        "lastMessage": messageData
                    ])
            }
    }
}

struct MessageBubble: View {
    let message: Message
    let primaryColor: Color
    let secondaryColor: Color
    
    var isFromCurrentUser: Bool {
        return message.senderId == Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 5) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? primaryColor : Color.white)
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

