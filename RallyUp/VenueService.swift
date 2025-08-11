import Foundation
import CoreLocation

struct SportsVenue: Identifiable {
    let id: String
    let name: String
    let category: String
    let address: String
    let distance: Int
    let coordinates: CLLocationCoordinate2D
}

class VenueService: ObservableObject {
    @Published var venues: [SportsVenue] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Get API key from configuration
    private let apiKey: String = Config.foursquareApiKey
    
    func fetchNearbyVenues(latitude: Double, longitude: Double, sport: String, completion: @escaping ([SportsVenue]?, Error?) -> Void) {
        
        let sportEncoded = sport.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sport
        let urlString = "https://api.foursquare.com/v3/places/search?query=\(sportEncoded)&ll=\(latitude),\(longitude)&radius=10000"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "VenueService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        //create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(nil, NSError(domain: "VenueService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                return
            }
            
            
            guard let data = data else {
                completion(nil, NSError(domain: "VenueService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                // Parse JSON into Dictionary
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    
                    //map results to SportsVenue objects
                    var venues: [SportsVenue] = []
                    
                    for result in results {
                        //extract venue ID
                        guard let id = result["fsq_id"] as? String else { continue }
                        
                        //extract venue name
                        guard let name = result["name"] as? String else { continue }
                        
                        //extract category
                        var category = "Sports Venue"
                        if let categories = result["categories"] as? [[String: Any]],
                           let firstCategory = categories.first,
                           let categoryName = firstCategory["name"] as? String {
                            category = categoryName
                        }
                        
                        //extract location data
                        var address = "No address available"
                        if let location = result["location"] as? [String: Any],
                           let formattedAddress = location["formatted_address"] as? String {
                            address = formattedAddress
                        }
                        
                        //extract distance
                        let distance = result["distance"] as? Int ?? 0
                        
                        //extract coordinates
                        var latitude = 0.0
                        var longitude = 0.0
                        if let geocodes = result["geocodes"] as? [String: Any],
                           let main = geocodes["main"] as? [String: Any],
                           let lat = main["latitude"] as? Double,
                           let lng = main["longitude"] as? Double {
                            latitude = lat
                            longitude = lng
                        }
                        
                        //create venue object
                        let venue = SportsVenue(
                            id: id,
                            name: name,
                            category: category,
                            address: address,
                            distance: distance,
                            coordinates: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        )
                        
                        venues.append(venue)
                    }
                    
                    completion(venues, nil)
                } else {
                    completion(nil, NSError(domain: "VenueService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"]))
                }
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
}
