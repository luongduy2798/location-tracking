import 'package:flutter/services.dart';

class LocationTrackingService {
  static const MethodChannel _channel = MethodChannel('com.duyln.location/location_tracking');

  /// Start location tracking in background
  static Future<bool> startLocationTracking() async {
    try {
      final result = await _channel.invokeMethod('startLocationTracking');
      return result == true;
    } catch (e) {
      print('Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  static Future<bool> stopLocationTracking() async {
    try {
      final result = await _channel.invokeMethod('stopLocationTracking');
      return result == true;
    } catch (e) {
      print('Error stopping location tracking: $e');
      return false;
    }
  }

  /// Add a geofence region
  static Future<bool> addGeofence({
    required double latitude,
    required double longitude,
    required double radius,
    required String identifier,
  }) async {
    try {
      final result = await _channel.invokeMethod('addGeofence', {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'identifier': identifier,
      });
      return result == true;
    } catch (e) {
      print('Error adding geofence: $e');
      return false;
    }
  }

  /// Remove a geofence region
  static Future<bool> removeGeofence(String identifier) async {
    try {
      final result = await _channel.invokeMethod('removeGeofence', {
        'identifier': identifier,
      });
      return result == true;
    } catch (e) {
      print('Error removing geofence: $e');
      return false;
    }
  }
}
