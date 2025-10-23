import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var locationManager: LocationManager!
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Initialize location manager
    locationManager = LocationManager.shared
    
    // Set up notification delegate
    UNUserNotificationCenter.current().delegate = self
    
    // Setup method channel for Flutter communication
    setupMethodChannel()
    
    // Enable background app refresh
    application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupMethodChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    let locationChannel = FlutterMethodChannel(
      name: "com.duyln.location/location_tracking",
      binaryMessenger: controller.binaryMessenger
    )
    
    locationChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "startLocationTracking":
        self?.locationManager.startLocationTracking()
        result(true)
        
      case "stopLocationTracking":
        self?.locationManager.stopLocationTracking()
        result(true)
        
      case "addGeofence":
        if let args = call.arguments as? [String: Any],
           let latitude = args["latitude"] as? Double,
           let longitude = args["longitude"] as? Double,
           let radius = args["radius"] as? Double,
           let identifier = args["identifier"] as? String {
          self?.locationManager.addGeofence(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            identifier: identifier
          )
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "removeGeofence":
        if let args = call.arguments as? [String: Any],
           let identifier = args["identifier"] as? String {
          self?.locationManager.removeGeofence(identifier: identifier)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "getCurrentLocation":
        self?.locationManager.getCurrentLocation { location in
          if let location = location {
            result([
              "latitude": location.coordinate.latitude,
              "longitude": location.coordinate.longitude
            ])
          } else {
            result(FlutterError(code: "LOCATION_ERROR", message: "Failed to get current location", details: nil))
          }
        }
        
      case "getCurrentLocationWithAddress":
        self?.locationManager.getCurrentLocationWithAddress { locationData in
          if let locationData = locationData {
            result(locationData)
          } else {
            result(FlutterError(code: "LOCATION_ERROR", message: "Failed to get current location with address", details: nil))
          }
        }
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  // MARK: - Background Fetch
  override func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // This method is called when the system wakes up the app for background execution
    print("Background fetch triggered")
    completionHandler(.newData)
  }
  
  // MARK: - Application Lifecycle
  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    print("App entered background - location tracking continues")
  }
  
  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    print("App entering foreground")
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    print("App became active")
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    super.applicationWillTerminate(application)
    print("App will terminate - background location tracking may continue")
  }
  
  // MARK: - UNUserNotificationCenterDelegate
  
  // This method is called when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show notification even when app is in foreground
    completionHandler([.alert, .sound, .badge])
  }
  
  // This method is called when user taps on notification
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("Notification tapped with userInfo: \(userInfo)")
    
    // You can handle notification tap here
    // For example, navigate to a specific screen in your Flutter app
    
    completionHandler()
  }
}
