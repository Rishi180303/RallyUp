# RallyUp

A social networking iOS app that connects sports enthusiasts in your area. Find, join, and organize sports sessions with players of similar skill levels.

## Features

- **Session Discovery** - Browse nearby sports sessions on map or list view
- **Venue Integration** - Find sports venues using Foursquare API
- **User Authentication** - Secure login/signup with Firebase
- **Messaging** - In-app communication between users
- **Profile Management** - Sports preferences and skill levels

## Supported Sports

Basketball, Soccer, Tennis, Volleyball, Pickleball, Badminton

## Tech Stack

- **Frontend**: SwiftUI, MapKit, CoreLocation
- **Backend**: Firebase (Authentication, Firestore)
- **APIs**: Foursquare (venue discovery)
- **Platform**: iOS 15.0+

## Setup

### Prerequisites
- Xcode 14.0+
- Firebase account
- Foursquare Developer account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Rishi180303/RallyUp.git
   cd RallyUp
   ```

2. **Firebase Setup**
   - Create a Firebase project
   - Add iOS app with Bundle ID: `Rishi.RallyUp`
   - Download `GoogleService-Info.plist`
   - Copy `GoogleService-Info-Template.plist` to `GoogleService-Info.plist`
   - Replace placeholder values with your Firebase config

3. **Foursquare API Setup**
   - Create a Foursquare app
   - Get your API key
   - Copy `VenueService-Template.swift` to `VenueService.swift`
   - Replace `YOUR_FOURSQUARE_API_KEY_HERE` with your API key

4. **Run the app**
   ```bash
   open RallyUp.xcodeproj
   ```
   - Select iOS Simulator
   - Press `⌘ + R`

## Security

- Never commit `GoogleService-Info.plist` or API keys
- Use provided template files as starting points
- `.gitignore` excludes sensitive files

## Project Structure

```
RallyUp/
├── RallyUp/
│   ├── Views/           # UI components
│   ├── Services/        # API integrations
│   ├── Models.swift     # Data models
│   └── AuthViewModel.swift
├── Templates/           # Setup templates
└── Tests/              # Unit & UI tests
```

## Contributing

Submit issues and enhancement requests.

## License

Educational purposes only.

---

**Ready to find your next game? Let's RallyUp! 🚀**

