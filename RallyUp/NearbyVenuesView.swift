import SwiftUI
import MapKit
import CoreLocation

struct NearbyVenuesView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = NearbyVenuesViewModel()
    
    let sport: Sport
    let location: CLLocationCoordinate2D
    let primaryColor = Color(hex: "FF7E67")
    let secondaryColor = Color(hex: "FFB563")
    let accentColor = Color(hex: "FFEBB7")
    let backgroundColor = Color(hex: "FFF9F1")
    
    var onVenueSelected: ((SportsVenue) -> Void)?
    @State private var showMap = false
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack {
                // Toggle between list and map view
                Picker("View", selection: $showMap) {
                    Text("List").tag(false)
                    Text("Map").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading venues...")
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("Error loading venues")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Try Again") {
                            viewModel.fetchVenues(
                                latitude: location.latitude,
                                longitude: location.longitude,
                                sport: sport.rawValue
                            )
                        }
                        .padding()
                        .background(primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    Spacer()
                } else if viewModel.venues.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No venues found")
                            .font(.headline)
                        
                        Text("Try searching for a different sport or location")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    Spacer()
                } else {
                    if showMap {
                        // Map View
                        VenueMapView(venues: viewModel.venues, selectedVenue: $viewModel.selectedVenue, onVenueSelected: { venue in
                            if let onVenueSelected = onVenueSelected {
                                onVenueSelected(venue)
                                presentationMode.wrappedValue.dismiss()
                            }
                        })
                    } else {
                        // List View
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.venues) { venue in
                                    VenueRow(venue: venue, primaryColor: primaryColor, accentColor: accentColor)
                                        .onTapGesture {
                                            if let onVenueSelected = onVenueSelected {
                                                onVenueSelected(venue)
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationTitle("Nearby \(sport.rawValue.capitalized) Venues")
        .onAppear {
            viewModel.fetchVenues(
                latitude: location.latitude,
                longitude: location.longitude,
                sport: sport.rawValue
            )
        }
    }
}

struct VenueRow: View {
    let venue: SportsVenue
    let primaryColor: Color
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(primaryColor)
                
                Text(venue.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(venue.distance)m")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.3))
                    .cornerRadius(8)
            }
            
            Text(venue.category)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(venue.address)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct VenueMapView: View {
    let venues: [SportsVenue]
    @Binding var selectedVenue: SportsVenue?
    var onVenueSelected: (SportsVenue) -> Void
    
    @State private var region: MKCoordinateRegion
    
    init(venues: [SportsVenue], selectedVenue: Binding<SportsVenue?>, onVenueSelected: @escaping (SportsVenue) -> Void) {
        self.venues = venues
        self._selectedVenue = selectedVenue
        self.onVenueSelected = onVenueSelected
        
        //  the initial region based on venues
        if let firstVenue = venues.first {
            let initialRegion = MKCoordinateRegion(
                center: firstVenue.coordinates,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            self._region = State(initialValue: initialRegion)
        } else {
            // Default region if no venues
            self._region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 33.4255, longitude: -111.9400),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: venues) { venue in
            MapAnnotation(coordinate: venue.coordinates) {
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                    
                    Text(venue.name)
                        .font(.caption)
                        .padding(4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(4)
                }
                .onTapGesture {
                    selectedVenue = venue
                }
            }
        }
        .overlay(
            Group {
                if let venue = selectedVenue {
                    VStack {
                        Spacer()
                        VenueInfoCard(venue: venue, onSelect: {
                            onVenueSelected(venue)
                        })
                        .padding()
                    }
                }
            }
        )
    }
}

struct VenueInfoCard: View {
    let venue: SportsVenue
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(venue.name)
                .font(.headline)
            
            Text(venue.category)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(venue.address)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(venue.distance) meters away")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: onSelect) {
                Text("Select This Venue")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "FF7E67"))
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

