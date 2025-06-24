import SwiftUI

struct MainTabView: View {
    
    let primaryColor = Color(hex: "FF7E67")
    let secondaryColor = Color(hex: "FFB563")
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Discover", systemImage: "map.fill")
                }
                .tag(0)
            
            PostSessionView()
                .tabItem {
                    Label("Host", systemImage: "plus.circle.fill")
                }
                .tag(1)
            
            MessagingView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
                .tag(2)
            
            
            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(primaryColor)
        .onAppear {
            
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = UIColor(Color.white.opacity(0.95))
            
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

