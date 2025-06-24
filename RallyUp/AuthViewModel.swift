import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String?
    @Published var isProfileComplete: Bool? = nil
    
    private let db = Firestore.firestore()

    init() {
        // Check if user is already logged in
        if let currentUser = Auth.auth().currentUser {
            
            checkUserProfile(uid: currentUser.uid)
        } else {
            
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.isProfileComplete = nil
            }
        }
    }

    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🔥 Firebase Login Error:", error.localizedDescription)
                    print("🔥 Firebase Error Code:", (error as NSError).code)
                    
                    // Check for specific error codes first
                    let authError = error as NSError
                    
                    // Check for wrong password first
                    if authError.code == AuthErrorCode.wrongPassword.rawValue {
                        self?.errorMessage = "Oops! That password doesn't match our records. Try again? 🔑"
                    }
                    // Then check for user not found
                    else if authError.code == AuthErrorCode.userNotFound.rawValue ||
                            error.localizedDescription.contains("no user record") {
                        self?.errorMessage = "This account doesn't exist yet. Would you like to sign up instead? 😊"
                    }
                    // Check for invalid email
                    else if authError.code == AuthErrorCode.invalidEmail.rawValue {
                        self?.errorMessage = "Please enter a valid email address 📧"
                    }
                    // Check for too many requests
                    else if authError.code == AuthErrorCode.tooManyRequests.rawValue {
                        self?.errorMessage = "Too many attempts. Please try again later ⏱️"
                    }
                    
                    else if error.localizedDescription.contains("malformed or has expired") {
                        self?.errorMessage = "Your login session has expired. Please try again 🔄"
                    }
                    // Default error message
                    else {
                        self?.errorMessage = error.localizedDescription
                    }
                    
                    completion(false)
                } else if let uid = authResult?.user.uid {
                    self?.checkUserProfile(uid: uid)
                    completion(true)
                } else {
                    self?.errorMessage = "Unexpected error: No user ID found"
                    completion(false)
                }
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.isProfileComplete = nil
            }
        } catch {
            errorMessage = "Logout failed: \(error.localizedDescription)"
        }
    }

    func checkUserProfile(uid: String) {
        let ref = db.collection("users").document(uid)
        ref.getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let document = document, document.exists, let data = document.data() {
                
                let bio = data["bio"] as? String ?? ""
                let preferredSports = data["preferredSports"] as? [String] ?? []
            
                
                let isProfileIncomplete = bio.isEmpty || preferredSports.isEmpty
            
                if isProfileIncomplete {
                    print("⚠️ Profile is incomplete: Empty bio or no sports selected")
                    DispatchQueue.main.async {
                        self.isProfileComplete = false
                        self.isLoggedIn = true
                    }
                    return
                }
            
                
                guard
                    let name = data["fullName"] as? String,
                    let email = data["email"] as? String,
                    let skillRaw = data["skillLevel"] as? String,
                    let skillLevel = SkillLevel(rawValue: skillRaw),
                    let sportsRaw = data["preferredSports"] as? [String],
                    let locationMap = data["location"] as? [String: Double],
                    let lat = locationMap["lat"],
                    let lng = locationMap["lng"]
                else {
                    print("❌ Missing or malformed user data")
                    DispatchQueue.main.async {
                        self.isProfileComplete = false
                        self.isLoggedIn = true
                    }
                    return
                }

                let sports = sportsRaw.compactMap { Sport(rawValue: $0.lowercased()) }
                let location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let sessionHistory = data["sessionHistory"] as? [String] ?? []
                let createdSessions = data["createdSessions"] as? [String] ?? []

                let user = User(
                    id: uid,
                    name: name,
                    email: email,
                    profileImage: nil,
                    bio: bio,
                    preferredSports: sports,
                    skillLevel: skillLevel,
                    location: location,
                    locationName: data["locationName"] as? String ?? "",
                    sessionHistory: sessionHistory,
                    createdSessions: createdSessions
                )

                DispatchQueue.main.async {
                    User.currentUser = user
                    self.isProfileComplete = true
                    self.isLoggedIn = true
                }
            } else {
                print("❌ No document or error: \(error?.localizedDescription ?? "unknown error")")
                DispatchQueue.main.async {
                    
                    self.isProfileComplete = nil
                    self.isLoggedIn = false
                    
                    
                    try? Auth.auth().signOut()
                }
            }
        }
    }
    
    func signUp(fullName: String, email: String, password: String, completion: @escaping (Bool) -> Void) {
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            } else if let user = result?.user {
                
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                changeRequest.commitChanges { [weak self] err in
                    guard let self = self else { return }
                    
                    if let err = err {
                        DispatchQueue.main.async {
                            self.errorMessage = err.localizedDescription
                            completion(false)
                        }
                    } else {
                        
                        let userData: [String: Any] = [
                            "fullName": fullName,
                            "email": email,
                            "sessionHistory": [],
                            "createdSessions": [],
                            "preferredSports": [],
                            "skillLevel": "beginner",
                            "bio": "",
                            "locationName": "",
                            "location": ["lat": 33.4255, "lng": -111.9400],
                            "availability": "",
                            "profileComplete": false
                        ]
                        self.db.collection("users").document(user.uid).setData(userData, merge: true) { [weak self] err in
                            guard let self = self else { return }
                            
                            if let err = err {
                                DispatchQueue.main.async {
                                    self.errorMessage = err.localizedDescription
                                    completion(false)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.isLoggedIn = true
                                    
                                    self.isProfileComplete = false
                                    completion(true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

