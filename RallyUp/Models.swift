import SwiftUI
import MapKit

// User model
struct User: Identifiable {
    let id: String
    var name: String
    var email: String
    var profileImage: String?
    var bio: String
    var preferredSports: [Sport]
    var skillLevel: SkillLevel
    var location: CLLocationCoordinate2D
    var locationName: String = ""
    var sessionHistory: [String] // IDs of sessions joined
    var createdSessions: [String] = []
}

// Sport session model
struct SportSession: Identifiable {
    let id: String
    let hostId: String
    var title: String
    var sport: Sport
    var dateTime: Date
    var location: CLLocationCoordinate2D
    var address: String
    var maxParticipants: Int
    var currentParticipants: [String] // User IDs
    var description: String
    var isPrivate: Bool
    var skillLevel: SkillLevel
    var venueName: String? // Added for Foursquare venue name
    var venueCategory: String? // Added for Foursquare venue category
}

// Message model
struct Message: Identifiable, Equatable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: Date
    var isRead: Bool
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

// Conversation model
struct Conversation: Identifiable {
    let id: String
    let participants: [String] // User IDs
    var participantNames: [String: String] // Map of user IDs to names
    var lastMessage: Message
    var messages: [Message]
}

// Sport enum
enum Sport: String, CaseIterable, Identifiable {
    case pickleball, badminton, basketball, soccer, tennis, volleyball
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .pickleball: return "circle.grid.2x1.fill"
        case .badminton: return "figure.badminton"
        case .basketball: return "basketball.fill"
        case .soccer: return "sportscourt.fill"
        case .tennis: return "tennis.racket"
        case .volleyball: return "volleyball.fill"
        }
    }
}

// Skill level
enum SkillLevel: String, CaseIterable, Identifiable {
    case beginner, intermediate, advanced, professional
    
    var id: String { self.rawValue }
}

// Empty
extension User {
    static var currentUser = User(
        id: "",
        name: "",
        email: "",
        profileImage: nil,
        bio: "",
        preferredSports: [],
        skillLevel: .beginner,
        location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        locationName: "",
        sessionHistory: [],
        createdSessions: []
    )
}

