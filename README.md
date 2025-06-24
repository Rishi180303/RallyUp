# RallyUp 🏀⚽🎾

**Find your next game, meet new players, and never play alone again.**

RallyUp is an iOS app that connects sports enthusiasts in your area. Whether you're looking to join a pickup basketball game, find tennis partners, or organize a soccer match, RallyUp makes it easy to discover and connect with fellow athletes.

## What RallyUp Does

- 🗺️ **Discover Sessions** - Browse nearby sports sessions on a map or list
- 🏟️ **Find Venues** - Automatically discover sports venues using Foursquare
- 👥 **Join Games** - Connect with players of similar skill levels
- 💬 **Stay Connected** - Message other participants and build your sports community
- 🎯 **Host Sessions** - Create and organize your own sports events

## Supported Sports

- Basketball 🏀
- Soccer ⚽
- Tennis 🎾
- Volleyball 🏐
- Pickleball 🏓
- Badminton 🏸

## Tech Stack

- **Frontend**: SwiftUI, MapKit, CoreLocation
- **Backend**: Firebase (Authentication, Firestore)
- **APIs**: Foursquare (venue discovery)
- **Platform**: iOS

## Getting Started

1. Clone the repository
2. Open `RallyUp.xcodeproj` in Xcode
3. Add your Firebase configuration (`GoogleService-Info.plist`)
4. Add your Foursquare API key in `VenueService.swift`
5. Build and run!

## File Structure

```
RallyUp/
├── RallyUp/
│   ├── RallyUpApp.swift              # App entry point & Firebase setup
│   ├── ContentView.swift             # Main navigation logic
│   ├── AuthViewModel.swift           # Authentication & user management
│   ├── Models.swift                  # Data models (User, SportSession, etc.)
│   │
│   ├── Views/
│   │   ├── MainTabView.swift         # Tab navigation
│   │   ├── DashboardView.swift       # Session discovery
│   │   ├── PostSessionView.swift     # Create new sessions
│   │   ├── MessagingView.swift       # Chat functionality
│   │   ├── UserProfileView.swift     # Profile management
│   │   ├── ProfileSetupView.swift    # Initial profile setup
│   │   ├── EditProfileView.swift     # Profile editing
│   │   ├── LandingView.swift         # Login/signup screen
│   │   └── SessionManagementView.swift # Session management
│   │
│   ├── Services/
│   │   └── VenueService.swift        # Foursquare API integration
│   │
│   ├── Components/
│   │   ├── LocationComponents.swift  # Location picker & map components
│   │   └── NearbyVenuesView.swift    # Venue selection UI
│   │
│   ├── ViewModels/
│   │   └── NearbyVenuesViewModel.swift # Venue data management
│   │
│   ├── Extensions.swift              # SwiftUI extensions & utilities
│   ├── GoogleService-Info.plist      # Firebase configuration
│   │
│   └── Assets.xcassets/              # App icons & colors
│
├── RallyUpTests/                     # Unit tests
├── RallyUpUITests/                   # UI tests
└── README.md                         # This file
```

## Features in Detail

### 🔐 Authentication
- Email/password signup and login
- Profile completion flow
- Secure user data management

### 🗺️ Session Discovery
- Map and list view of nearby sessions
- Sport-specific filtering
- Real-time session updates

### 🏟️ Venue Integration
- Automatic venue discovery via Foursquare
- Sport-specific venue suggestions
- Distance-based venue ranking

### 💬 Messaging
- In-app messaging between users
- Conversation management
- Real-time message updates

### 👤 User Profiles
- Sports preferences and skill levels
- Session history tracking
- Profile customization

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is for educational purposes.

---

**Ready to find your next game? Let's RallyUp! 🚀** 