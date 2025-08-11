import SwiftUI
import FirebaseAuth

struct LandingView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var showingAlert = false

    let primaryColor = Color(red: 1.0, green: 0.494, blue: 0.404)
    let secondaryColor = Color(red: 1.0, green: 0.71, blue: 0.388)
    let accentColor = Color(red: 1.0, green: 0.918, blue: 0.718)
    let backgroundColor = Color(red: 1.0, green: 0.976, blue: 0.945)

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [backgroundColor, accentColor.opacity(0.3)]),
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                        Image(systemName: "figure.run.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(primaryColor)

                        Text("RallyUp")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(primaryColor)

                        Text("Find sports buddies nearby")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)

                    VStack(spacing: 20) {
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)

                        if isSignUp {
                            TextField("Full Name", text: $fullName)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 30)

                    VStack(spacing: 15) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Button(action: {
                                isLoading = true
                                if isSignUp {
                                    // Fixed method call
                                    authVM.signUp(fullName: fullName, email: email, password: password) { success in
                                        isLoading = false
                                        if !success {
                                            showingAlert = true
                                        }
                                    }
                                } else {
                                    authVM.login(email: email, password: password) { success in
                                        isLoading = false
                                        if !success {
                                            showingAlert = true
                                        }
                                    }
                                }
                            }) {
                                Text(isSignUp ? "Sign Up" : "Log In")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }

                        Button(action: {
                            withAnimation {
                                isSignUp.toggle()
                                
                                authVM.errorMessage = nil
                            }
                        }) {
                            Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
                                .foregroundColor(primaryColor)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text(isSignUp ? "Sign Up Issue" : "Login Issue"),
                        message: Text(authVM.errorMessage ?? "An unknown error occurred"),
                        dismissButton: .default(Text("OK"))
                    )
                }

                // Navigation is handled by ContentView based on authVM state
            }
            .navigationBarHidden(true)
        }
    }
}

