import CoreLocation
import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore


struct LocationMapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}


struct FoursquareVenue: Identifiable {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let category: String
    
    // Helper to check if venue is sports-related
    var isSportsVenue: Bool {
        return category.lowercased().contains("sport") ||
               category.lowercased().contains("athletic") ||
               category.lowercased().contains("gym") ||
               category.lowercased().contains("fitness") ||
               category.lowercased().contains("court") ||
               category.lowercased().contains("field") ||
               category.lowercased().contains("stadium") ||
               category.lowercased().contains("arena")
    }
}


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var placemark: CLPlacemark?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        isLoading = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.location = location.coordinate
            self.isLoading = false
            
            
            self.reverseGeocode(location: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "Location error: \(error.localizedDescription)"
            print("Location manager error: \(error.localizedDescription)")
        }
    }
    
    
    func reverseGeocode(location: CLLocation) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                self.errorMessage = "Could not find address: \(error.localizedDescription)"
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("No placemarks found for location")
                self.errorMessage = "Could not find address for location"
                return
            }
            
            DispatchQueue.main.async {
                self.placemark = placemark
            }
        }
    }
    
    
    func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents = [String]()
        
        if let name = placemark.name {
            addressComponents.append(name)
        }
        
        if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }
        
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }
        
        if let postalCode = placemark.postalCode {
            addressComponents.append(postalCode)
        }
        
        if let country = placemark.country {
            addressComponents.append(country)
        }
        
        return addressComponents.joined(separator: ", ")
    }
}


struct LocationPickerButton: View {
    @Binding var locationName: String
    @Binding var location: CLLocationCoordinate2D
    @State private var showingLocationPicker = false
    let primaryColor: Color
    var selectedSport: Sport? = nil
    
    var body: some View {
        Button(action: {
            showingLocationPicker = true
        }) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(primaryColor)
                
                Text(locationName.isEmpty ? "Select location" : locationName)
                    .foregroundColor(locationName.isEmpty ? .gray : .primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationMapPickerView(
                locationName: $locationName,
                location: $location,
                isPresented: $showingLocationPicker,
                primaryColor: primaryColor,
                selectedSport: selectedSport
            )
        }
    }
}


struct LocationMapPickerView: View {
    @Binding var locationName: String
    @Binding var location: CLLocationCoordinate2D
    @Binding var isPresented: Bool
    let primaryColor: Color
    var selectedSport: Sport? = nil
    
    @StateObject private var locationManager = LocationManager()
    @State private var searchQuery = ""
    @State private var region: MKCoordinateRegion
    @State private var selectedPin: MKPlacemark?
    @State private var showingSearchResults = false
    @State private var searchResults = [MKMapItem]()
    @State private var errorMessage: String?
    @State private var showError = false
    
    
    @State private var nearbyVenues: [FoursquareVenue] = []
    @State private var isLoadingVenues = false
    @State private var showingVenues = false
    
    init(locationName: Binding<String>, location: Binding<CLLocationCoordinate2D>, isPresented: Binding<Bool>, primaryColor: Color, selectedSport: Sport? = nil) {
        self._locationName = locationName
        self._location = location
        self._isPresented = isPresented
        self.primaryColor = primaryColor
        self.selectedSport = selectedSport
        
        
        let initialLocation = location.wrappedValue
        self._region = State(initialValue: MKCoordinateRegion(
            center: initialLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Map view with tap gesture
                    ZStack {
                        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: selectedPin != nil ? [LocationMapPin(coordinate: selectedPin!.coordinate)] : []) { pin in
                            MapAnnotation(coordinate: pin.coordinate) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(primaryColor)
                                    .shadow(radius: 2)
                            }
                        }
                        .gesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .sequenced(before: DragGesture(minimumDistance: 0))
                                .onEnded { value in
                                    switch value {
                                    case .second(true, let drag):
                                        if let location = drag?.location {
                                            // Convert tap location to map coordinate
                                            let mapSize = UIScreen.main.bounds.size
                                            let tapPoint = CGPoint(
                                                x: location.x,
                                                y: location.y
                                            )
                                            
                                            let centerPoint = CGPoint(x: mapSize.width/2, y: mapSize.height/2)
                                            let xDisplacement = (tapPoint.x - centerPoint.x) / mapSize.width
                                            let yDisplacement = (tapPoint.y - centerPoint.y) / mapSize.height
                                            
                                            let spanMultiplier = 2.0
                                            let newLat = region.center.latitude - (yDisplacement * region.span.latitudeDelta * spanMultiplier)
                                            let newLong = region.center.longitude + (xDisplacement * region.span.longitudeDelta * spanMultiplier)
                                            
                                            let coordinate = CLLocationCoordinate2D(latitude: newLat, longitude: newLong)
                                            
                                            
                                            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                            let geocoder = CLGeocoder()
                                            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                                                if let error = error {
                                                    errorMessage = "Could not find address: \(error.localizedDescription)"
                                                    showError = true
                                                    return
                                                }
                                                
                                                if let placemark = placemarks?.first {
                                                    let formattedAddress = locationManager.formatAddress(from: placemark)
                                                    DispatchQueue.main.async {
                                                        self.selectedPin = MKPlacemark(placemark: placemark)
                                                        self.locationName = formattedAddress
                                                        self.location = coordinate
                                                    }
                                                }
                                            }
                                        }
                                    default:
                                        break
                                    }
                                }
                        )
                        
                        
                        VStack {
                            Text("Long press on map to select location")
                                .font(.caption)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.top, 10)
                            
                            Spacer()
                        }
                    }
                    .frame(height: 300)
                    .edgesIgnoringSafeArea(.top)
                    
                    
                    VStack(spacing: 15) {
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search for a location", text: $searchQuery)
                                .onSubmit {
                                    searchLocation()
                                }
                            
                            if !searchQuery.isEmpty {
                                Button(action: {
                                    searchQuery = ""
                                    searchResults = []
                                    showingSearchResults = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {
                                searchLocation()
                            }) {
                                Text("Search")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(primaryColor)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        
                        Button(action: {
                            locationManager.requestLocation()
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(primaryColor)
                                Text("Use Current Location")
                                    .foregroundColor(primaryColor)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        
                        if let sport = selectedSport {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Nearby \(sport.rawValue.capitalized) Venues")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        fetchNearbyVenues()
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(primaryColor)
                                    }
                                }
                                .padding(.horizontal)
                                
                                if isLoadingVenues {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Text("Finding venues...")
                                            .font(.caption)
                                            .padding(.leading, 8)
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                } else if nearbyVenues.isEmpty {
                                    Text("No venues found. Try searching for a location first.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                        .padding(.vertical, 10)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(nearbyVenues) { venue in
                                                Button(action: {
                                                    selectVenue(venue)
                                                }) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(venue.name)
                                                            .font(.subheadline)
                                                            .fontWeight(.medium)
                                                            .lineLimit(1)
                                                        
                                                        Text(venue.category)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(1)
                                                        
                                                        if !venue.address.isEmpty {
                                                            Text(venue.address)
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                                .lineLimit(2)
                                                        }
                                                    }
                                                    .padding()
                                                    .frame(width: 200)
                                                    .background(Color.white)
                                                    .cornerRadius(10)
                                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .frame(height: 120)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        
                        if showingSearchResults {
                            // Search results
                            Text("Search Results")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 5)
                            
                            ScrollView {
                                VStack(spacing: 10) {
                                    ForEach(searchResults, id: \.self) { item in
                                        Button(action: {
                                            selectMapItem(item)
                                        }) {
                                            HStack {
                                                Image(systemName: "mappin")
                                                    .foregroundColor(primaryColor)
                                                
                                                VStack(alignment: .leading) {
                                                    Text(item.name ?? "Unknown Location")
                                                        .foregroundColor(.primary)
                                                    
                                                    if let address = item.placemark.thoroughfare {
                                                        Text(address)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 14))
                                            }
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(10)
                                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else if selectedPin != nil {
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Selected Location")
                                    .font(.headline)
                                
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(primaryColor)
                                    
                                    Text(locationName)
                                        .foregroundColor(.primary)
                                }
                                
                                Button(action: {
                                    
                                    isPresented = false
                                }) {
                                    Text("Use This Location")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(primaryColor)
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                    .background(Color(hex: "FFF9F1"))
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .offset(y: -20)
                }
                
                
                if locationManager.isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Getting your location...")
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Location Error"),
                    message: Text(errorMessage ?? "An error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onReceive(locationManager.$location) { newLocation in
                if let newLocation = newLocation {
                    
                    region = MKCoordinateRegion(
                        center: newLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    
                    
                    location = newLocation
                    
                    
                    let location = CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude)
                    let geocoder = CLGeocoder()
                    geocoder.reverseGeocodeLocation(location) { placemarks, error in
                        if let placemark = placemarks?.first {
                            let formattedAddress = locationManager.formatAddress(from: placemark)
                            DispatchQueue.main.async {
                                self.selectedPin = MKPlacemark(placemark: placemark)
                                self.locationName = formattedAddress
                                
                                
                                if let sport = self.selectedSport {
                                    self.fetchNearbyVenues()
                                }
                            }
                        }
                    }
                }
            }
            .onReceive(locationManager.$errorMessage) { error in
                if let error = error {
                    errorMessage = error
                    showError = true
                }
            }
            .onAppear {
                
                if let sport = selectedSport, location.latitude != 0 {
                    fetchNearbyVenues()
                }
            }
        }
    }
    
    
    private func fetchNearbyVenues() {
        guard let sport = selectedSport else { return }
        
        isLoadingVenues = true
        
        location.fetchNearbyVenues(radius: 3000, limit: 15, sportType: sport.rawValue) { venues in
            self.nearbyVenues = venues.filter { $0.isSportsVenue }
            self.isLoadingVenues = false
        }
    }
    
    
    private func selectVenue(_ venue: FoursquareVenue) {
        location = venue.coordinate
        locationName = venue.name + (venue.address.isEmpty ? "" : ", " + venue.address)
        
        // Update the map region
        region = MKCoordinateRegion(
            center: venue.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        // Create a placemark for the selected venue
        let placemark = MKPlacemark(coordinate: venue.coordinate)
        selectedPin = placemark
        showingSearchResults = false
    }
    
    private func searchLocation() {
        guard !searchQuery.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                errorMessage = "Search error: \(error.localizedDescription)"
                showError = true
                return
            }
            
            guard let response = response else {
                errorMessage = "No results found"
                showError = true
                return
            }
            
            self.searchResults = response.mapItems
            self.showingSearchResults = true
        }
    }
    
    private func selectMapItem(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        location = coordinate
        
        
        let placemark = item.placemark
        locationName = locationManager.formatAddress(from: placemark)
        
        
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        selectedPin = item.placemark
        showingSearchResults = false
        
        
        if let sport = selectedSport {
            fetchNearbyVenues()
        }
    }
}

// MARK: - Location Selection View
struct LocationSelectionView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var locationName: String
    @State private var location: CLLocationCoordinate2D
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    var onDismiss: (() -> Void)?
    var sport: Sport? = nil
    
    let primaryColor = Color(hex: "FF7E67")
    let secondaryColor = Color(hex: "FFB563")
    let backgroundColor = Color(hex: "FFF9F1")
    
    
    init() {
        _locationName = State(initialValue: "")
        _location = State(initialValue: CLLocationCoordinate2D(latitude: 33.4255, longitude: -111.9400))
    }
    
    
    init(locationName: String, location: CLLocationCoordinate2D, onDismiss: (() -> Void)? = nil, sport: Sport? = nil) {
        _locationName = State(initialValue: locationName)
        _location = State(initialValue: location)
        self.onDismiss = onDismiss
        self.sport = sport
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Location Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Location")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LocationPickerButton(
                            locationName: $locationName,
                            location: $location,
                            primaryColor: primaryColor,
                            selectedSport: sport // NEW - Pass the sport
                        )
                    }
                    .padding(.horizontal)
                    
                    // Map View
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Location")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Map(coordinateRegion: .constant(MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )), annotationItems: [LocationMapPin(coordinate: location)]) { pin in
                            MapAnnotation(coordinate: pin.coordinate) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(primaryColor)
                            }
                        }
                        .frame(height: 300)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Save button
                    Button(action: saveLocation) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Save Location")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(primaryColor)
                    .cornerRadius(15)
                    .shadow(color: primaryColor.opacity(0.3), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .disabled(locationName.isEmpty)
                    .opacity(locationName.isEmpty ? 0.6 : 1)
                }
                .navigationTitle("Set Your Location")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Location"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("successfully") {
                            presentationMode.wrappedValue.dismiss()
                            onDismiss?()
                        }
                    }
                )
            }
        }
    }
    
    private func saveLocation() {
        isLoading = true
        
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            alertMessage = "Error: User not authenticated."
            showAlert = true
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.updateData([
            "location": ["lat": location.latitude, "lng": location.longitude],
            "locationName": locationName
        ]) { error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Error updating location: \(error.localizedDescription)"
                showAlert = true
            } else {
                
                var currentUser = User.currentUser
                currentUser.location = location
                currentUser.locationName = locationName
                User.currentUser = currentUser
                
                
                alertMessage = "Location saved successfully!"
                showAlert = true
            }
        }
    }
}


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

