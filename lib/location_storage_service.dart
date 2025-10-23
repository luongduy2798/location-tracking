import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocationStorageService {
  static const String _trackingKey = 'location_tracking_status';
  static const String _geofencesKey = 'geofences_list';

  // Save tracking status
  static Future<void> saveTrackingStatus(bool isTracking) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackingKey, isTracking);
    print('Saved tracking status: $isTracking');
  }

  // Get tracking status
  static Future<bool> getTrackingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isTracking = prefs.getBool(_trackingKey) ?? false;
    print('Loaded tracking status: $isTracking');
    return isTracking;
  }

  // Save geofences list
  static Future<void> saveGeofences(List<Map<String, dynamic>> geofences) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(geofences);
    await prefs.setString(_geofencesKey, jsonString);
    print('Saved ${geofences.length} geofences to storage');
  }

  // Get geofences list
  static Future<List<Map<String, dynamic>>> getGeofences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_geofencesKey);
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final geofences = jsonList.cast<Map<String, dynamic>>();
        print('Loaded ${geofences.length} geofences from storage');
        return geofences;
      } catch (e) {
        print('Error loading geofences: $e');
        return [];
      }
    }
    
    print('No geofences found in storage');
    return [];
  }

  // Clear all storage data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_trackingKey);
    await prefs.remove(_geofencesKey);
    print('Cleared all storage data');
  }
}
