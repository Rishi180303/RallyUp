# RallyUp

iOS app for finding people to play sports with. Basically like Tinder but for sports buddies.

## What it does

- Find sports sessions near you
- Connect with other players
- Chat with people you want to play with
- Find sports venues (basketball courts, soccer fields, etc.)

## Sports

Basketball, Soccer, Tennis, Volleyball, Pickleball, Badminton

## Tech stuff

- SwiftUI for the UI
- Firebase for user accounts and chat
- Foursquare API for finding venues
- iOS 15+

## Getting it running

1. Clone this repo
2. You'll need Firebase and Foursquare accounts
3. Copy the template files and add your API keys
4. Open in Xcode and run

## Setup details

### Firebase
- Make a Firebase project
- Add iOS app with bundle ID `Rishi.RallyUp`
- Download `GoogleService-Info.plist`

### Foursquare
- Get an API key from Foursquare
- Put it in `Config.swift`

## Notes

- Don't commit the config files with your API keys
- The .gitignore should handle this but double-check

## Project structure

```
RallyUp/
├── Views/           # UI screens
├── Models.swift     # Data structures
├── Services/        # API calls
└── AuthViewModel.swift
```

---

This is a school project, so feel free to use it for learning.

