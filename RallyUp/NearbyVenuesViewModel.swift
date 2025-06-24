import Foundation
import CoreLocation
import SwiftUI

class NearbyVenuesViewModel: ObservableObject {
    @Published var venues: [SportsVenue] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedVenue: SportsVenue?
    
    private let venueService = VenueService()
    
    func fetchVenues(latitude: Double, longitude: Double, sport: String) {
        isLoading = true
        errorMessage = nil
        
        venueService.fetchNearbyVenues(latitude: latitude, longitude: longitude, sport: sport) { [weak self] venues, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            if let venues = venues {
                self.venues = venues
            }
        }
    }
}

