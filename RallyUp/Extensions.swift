import SwiftUI
import CoreLocation
import MapKit

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Extension for CLPlacemark to get formatted address
extension CLPlacemark {
    var formattedAddress: String? {
        let components = [
            thoroughfare,
            locality,
            administrativeArea,
            postalCode,
            country
        ].compactMap { $0 }
        
        return components.joined(separator: ", ")
    }
}


struct ASULocations {
    static let locations = [
        (name: "SDFC Basketball Courts", lat: 33.4255, lng: -111.9400),
        (name: "ASU Soccer Fields", lat: 33.4242, lng: -111.9320),
        (name: "ASU Tennis Complex", lat: 33.4180, lng: -111.9350),
        (name: "SDFC Volleyball Courts", lat: 33.4255, lng: -111.9410),
        (name: "ASU Recreation Center", lat: 33.4260, lng: -111.9380),
        (name: "SDFC Badminton Courts", lat: 33.4258, lng: -111.9405),
        (name: "ASU Main Campus", lat: 33.4232, lng: -111.9416),
        (name: "Sun Devil Stadium", lat: 33.4268, lng: -111.9325),
        (name: "ASU Fitness Complex", lat: 33.4250, lng: -111.9390)
    ]
}


extension CLLocationCoordinate2D {
    func fetchNearbyVenues(radius: Int = 1000, limit: Int = 10, sportType: String? = nil, completion: @escaping ([FoursquareVenue]) -> Void) {
        // Foursquare API endpoint
        let baseURL = "https://api.foursquare.com/v3/places/search"
        
        // Build query parameters
        var queryItems = [
            URLQueryItem(name: "ll", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "categories", value: "18000,18006,18008,18009") // Sports categories
        ]
        
        
        if let sport = sportType {
            queryItems.append(URLQueryItem(name: "query", value: sport))
        }
        
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            print("Invalid URL")
            completion([])
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue(Config.foursquareApiKey, forHTTPHeaderField: "Authorization")
        
        // Make API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Error fetching venues: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            // Check for valid response
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            // Parse JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    
                    var venues: [FoursquareVenue] = []
                    
                    for result in results {
                        guard let id = result["fsq_id"] as? String,
                              let name = result["name"] as? String,
                              let geocodes = result["geocodes"] as? [String: Any],
                              let main = geocodes["main"] as? [String: Any],
                              let latitude = main["latitude"] as? Double,
                              let longitude = main["longitude"] as? Double else {
                            continue
                        }
                        
                        // Extract category if available
                        var category = "Sports Venue"
                        if let categories = result["categories"] as? [[String: Any]],
                           let firstCategory = categories.first,
                           let categoryName = firstCategory["name"] as? String {
                            category = categoryName
                        }
                        
                        // Extract address if available
                        var address = ""
                        if let location = result["location"] as? [String: Any],
                           let formattedAddress = location["formatted_address"] as? String {
                            address = formattedAddress
                        }
                        
                        let venue = FoursquareVenue(
                            id: id,
                            name: name,
                            address: address,
                            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                            category: category
                        )
                        
                        venues.append(venue)
                    }
                    
                    DispatchQueue.main.async {
                        completion(venues)
                    }
                } else {
                    print("Invalid JSON format")
                    DispatchQueue.main.async {
                        completion([])
                    }
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
}

