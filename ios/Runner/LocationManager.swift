import Foundation
import CoreLocation
import UserNotifications
import UIKit

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private var geofenceRegions: [CLCircularRegion] = []
    
    override init() {
        super.init()
        
        // Initialize with current status for iOS < 14
        if #available(iOS 14.0, *) {
            // Will be set when delegate callback is called
        } else {
            // Use the class method once during initialization
            lastKnownAuthorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        setupLocationManager()
        requestNotificationPermission()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        
        // Request location permissions
        locationManager.requestAlwaysAuthorization()
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // MARK: - Location Tracking Methods
    
    func startLocationTracking() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services not enabled")
            return
        }
        
        // Configure for background execution
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Start significant location changes - works in background
        locationManager.startMonitoringSignificantLocationChanges()
        
        // Start visit monitoring - detects when user stays at location
        locationManager.startMonitoringVisits()
        
        // Start standard location updates for more frequent updates when app is active
        locationManager.startUpdatingLocation()
        
        print("Started location tracking with background updates enabled")
    }
    
    func stopLocationTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopMonitoringVisits()
        
        // Disable background location updates
        locationManager.allowsBackgroundLocationUpdates = false
        
        // Stop monitoring all geofence regions
        for region in geofenceRegions {
            locationManager.stopMonitoring(for: region)
        }
        geofenceRegions.removeAll()
        
        print("Stopped location tracking")
    }
    
    func addGeofence(latitude: Double, longitude: Double, radius: Double, identifier: String) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: coordinate, radius: radius, identifier: identifier)
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
        geofenceRegions.append(region)
        
        print("Added geofence: \(identifier) at \(latitude), \(longitude) with radius \(radius)m")
    }
    
    func removeGeofence(identifier: String) {
        if let index = geofenceRegions.firstIndex(where: { $0.identifier == identifier }) {
            let region = geofenceRegions[index]
            locationManager.stopMonitoring(for: region)
            geofenceRegions.remove(at: index)
            
            print("Removed geofence: \(identifier)")
        }
    }
    
    // MARK: - Notification Methods
    
    private func sendLocationNotification(title: String, body: String, userInfo: [String: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    private func getAddressFromLocation(_ location: CLLocation, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let address = [
                    placemark.name,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                completion(address.isEmpty ? "Unknown location" : address)
            } else {
                completion("Unknown location")
            }
        }
    }
    
    // MARK: - Current Location Methods
    
    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services not enabled")
            completion(nil)
            return
        }
        
        // Use instance method to avoid UI blocking
        let status = getLocationAuthorizationStatus()
        
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            print("Location permission required")
            completion(nil)
            return
        }
        
        // Store completion handler
        currentLocationCompletion = completion
        
        // Request one-time location
        locationManager.requestLocation()
    }
    
    func getCurrentLocationWithAddress(completion: @escaping ([String: Any]?) -> Void) {
        getCurrentLocation { location in
            guard let location = location else {
                completion(nil)
                return
            }
            
            // Get address from location
            self.getAddressFromLocation(location) { address in
                let result: [String: Any] = [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "address": address
                ]
                completion(result)
            }
        }
    }
    
    private var currentLocationCompletion: ((CLLocation?) -> Void)?
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Handle one-time location request
        if let completion = currentLocationCompletion {
            currentLocationCompletion = nil
            completion(location)
        } else {
            // Handle regular location updates (only send notification if tracking is active)
            getAddressFromLocation(location) { address in
                DispatchQueue.main.async {
                    let body = "Lat: \(String(format: "%.6f", location.coordinate.latitude)), Lng: \(String(format: "%.6f", location.coordinate.longitude))\n\(address)"
                    
                    self.sendLocationNotification(
                        title: "Location Updated",
                        body: body,
                        userInfo: [
                            "latitude": location.coordinate.latitude,
                            "longitude": location.coordinate.longitude,
                            "address": address,
                            "timestamp": Date().timeIntervalSince1970
                        ]
                    )
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        
        if let circularRegion = region as? CLCircularRegion {
            let coordinate = circularRegion.center
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            getAddressFromLocation(location) { address in
                DispatchQueue.main.async {
                    self.sendLocationNotification(
                        title: "Entered Geofence",
                        body: "You entered \(region.identifier)\n\(address)",
                        userInfo: [
                            "event": "enter",
                            "region": region.identifier,
                            "latitude": coordinate.latitude,
                            "longitude": coordinate.longitude,
                            "address": address
                        ]
                    )
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        
        if let circularRegion = region as? CLCircularRegion {
            let coordinate = circularRegion.center
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            getAddressFromLocation(location) { address in
                DispatchQueue.main.async {
                    self.sendLocationNotification(
                        title: "Exited Geofence",
                        body: "You left \(region.identifier)\n\(address)",
                        userInfo: [
                            "event": "exit",
                            "region": region.identifier,
                            "latitude": coordinate.latitude,
                            "longitude": coordinate.longitude,
                            "address": address
                        ]
                    )
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        print("Visit detected: \(visit.coordinate.latitude), \(visit.coordinate.longitude)")
        
        let location = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
        
        getAddressFromLocation(location) { address in
            DispatchQueue.main.async {
                let arrivalTime = visit.arrivalDate == Date.distantPast ? "Unknown" : DateFormatter.localizedString(from: visit.arrivalDate, dateStyle: .short, timeStyle: .short)
                let departureTime = visit.departureDate == Date.distantFuture ? "Still here" : DateFormatter.localizedString(from: visit.departureDate, dateStyle: .short, timeStyle: .short)
                
                let body = "Visit at \(address)\nArrival: \(arrivalTime)\nDeparture: \(departureTime)"
                
                self.sendLocationNotification(
                    title: "Location Visit",
                    body: body,
                    userInfo: [
                        "event": "visit",
                        "latitude": visit.coordinate.latitude,
                        "longitude": visit.coordinate.longitude,
                        "address": address,
                        "arrivalDate": visit.arrivalDate.timeIntervalSince1970,
                        "departureDate": visit.departureDate.timeIntervalSince1970
                    ]
                )
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization changed: \(status.rawValue)")
        
        // Store the status to avoid calling deprecated class method
        lastKnownAuthorizationStatus = status
        
        switch status {
        case .authorizedAlways:
            print("Location access authorized always")
        case .authorizedWhenInUse:
            // Request always authorization for background location
            manager.requestAlwaysAuthorization()
        case .denied, .restricted:
            print("Location access denied")
            sendLocationNotification(
                title: "Location Access Denied",
                body: "Please enable location access in Settings to use location features."
            )
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
        
        sendLocationNotification(
            title: "Location Error",
            body: "Failed to get location: \(error.localizedDescription)"
        )
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region: \(region?.identifier ?? "Unknown") with error: \(error)")
        
        sendLocationNotification(
            title: "Geofence Error",
            body: "Failed to monitor region \(region?.identifier ?? "Unknown"): \(error.localizedDescription)"
        )
    }
    
    // MARK: - Helper Methods
    
    func canStartLocationTracking() -> Bool {
        guard CLLocationManager.locationServicesEnabled() else {
            return false
        }
        
        let status = getLocationAuthorizationStatus()
        return status == .authorizedAlways
    }
    
    func getLocationAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            // Use stored status from delegate callback to avoid UI blocking
            return lastKnownAuthorizationStatus
        }
    }
    
    // Store the last known authorization status to avoid calling the deprecated class method
    private var lastKnownAuthorizationStatus: CLAuthorizationStatus = .notDetermined
}
