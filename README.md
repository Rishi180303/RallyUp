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

### Prerequisites
- Xcode 14.0 or later
- iOS 15.0 or later
- Firebase account
- Foursquare Developer account

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/Rishi180303/RallyUp.git
   cd RallyUp
   ```

2. **Firebase Setup**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing one
   - Add an iOS app with Bundle ID: `Rishi.RallyUp`
   - Download `GoogleService-Info.plist`
   - Copy `GoogleService-Info-Template.plist` to `GoogleService-Info.plist`
   - Replace placeholder values with your actual Firebase configuration

3. **Foursquare API Setup**
   - Go to [Foursquare Developer Portal](https://developer.foursquare.com/)
   - Create a new app
   - Get your API key
   - Copy `VenueService-Template.swift` to `VenueService.swift`
   - Replace `YOUR_FOURSQUARE_API_KEY_HERE` with your actual API key

4. **Open in Xcode**
   ```bash
   open RallyUp.xcodeproj
   ```

5. **Build and Run**
   - Select an iOS Simulator
   - Press `⌘ + R` or click the ▶️ button

### ⚠️ Security Notice
- **Never commit** `GoogleService-Info.plist` or API keys to version control
- Use the provided template files as starting points
- The `.gitignore` file is configured to exclude sensitive files

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
│   ├── GoogleService-Info-Template.plist # Firebase configuration template
│   │
│   └── Assets.xcassets/              # App icons & colors
│
├── RallyUpTests/                     # Unit tests
├── RallyUpUITests/                   # UI tests
├── GoogleService-Info-Template.plist # Firebase setup template
├── VenueService-Template.swift       # API service template
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

