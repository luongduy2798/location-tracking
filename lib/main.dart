import 'package:flutter/material.dart';
import 'location_tracking_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracking Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Location Tracking Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isTracking = false;
  final List<Map<String, dynamic>> _geofences = [];
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default values for testing
    _latController.text = '10.762622'; // Ho Chi Minh City
    _lngController.text = '106.660172';
    _radiusController.text = '100';
    _nameController.text = 'Test Location';
  }

  void _startTracking() async {
    final success = await LocationTrackingService.startLocationTracking();
    if (success) {
      setState(() {
        _isTracking = true;
      });
      _showMessage('Location tracking started');
    } else {
      _showMessage('Failed to start location tracking');
    }
  }

  void _stopTracking() async {
    final success = await LocationTrackingService.stopLocationTracking();
    if (success) {
      setState(() {
        _isTracking = false;
      });
      _showMessage('Location tracking stopped');
    } else {
      _showMessage('Failed to stop location tracking');
    }
  }

  void _addGeofence() async {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    final radius = double.tryParse(_radiusController.text);
    final name = _nameController.text.trim();

    if (lat == null || lng == null || radius == null || name.isEmpty) {
      _showMessage('Please fill all fields with valid values');
      return;
    }

    final success = await LocationTrackingService.addGeofence(
      latitude: lat,
      longitude: lng,
      radius: radius,
      identifier: name,
    );

    if (success) {
      setState(() {
        _geofences.add({
          'name': name,
          'latitude': lat,
          'longitude': lng,
          'radius': radius,
        });
      });
      _showMessage('Geofence "$name" added');
      _nameController.clear();
    } else {
      _showMessage('Failed to add geofence');
    }
  }

  void _removeGeofence(String name) async {
    final success = await LocationTrackingService.removeGeofence(name);
    if (success) {
      setState(() {
        _geofences.removeWhere((fence) => fence['name'] == name);
      });
      _showMessage('Geofence "$name" removed');
    } else {
      _showMessage('Failed to remove geofence');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location Tracking Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Location Tracking',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status: ${_isTracking ? "Running" : "Stopped"}',
                      style: TextStyle(
                        color: _isTracking ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isTracking ? null : _startTracking,
                            child: const Text('Start Tracking'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isTracking ? _stopTracking : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Stop Tracking'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Geofence Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Geofences',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    // Add Geofence Form
                    TextField(
                      controller: _latController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lngController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _radiusController,
                      decoration: const InputDecoration(
                        labelText: 'Radius (meters)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Geofence Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addGeofence,
                      child: const Text('Add Geofence'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Geofence List
            if (_geofences.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Geofences',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ...._geofences.map((fence) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(fence['name']),
                          subtitle: Text(
                            'Lat: ${fence['latitude'].toStringAsFixed(6)}\n'
                            'Lng: ${fence['longitude'].toStringAsFixed(6)}\n'
                            'Radius: ${fence['radius']}m',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeGeofence(fence['name']),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Start tracking to enable background location monitoring\n'
                      '• Uses significant location changes for battery efficiency\n'
                      '• Monitors visits when you stay at a location\n'
                      '• Add geofences to get notifications when entering/exiting areas\n'
                      '• Notifications work even when app is killed\n'
                      '• Make sure to allow "Always" location permission',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
