import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../utils/gradient_theme.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isLoadingPlaces = false;
  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _places = [];

  // Google Places API key
  static const String _placesApiKey = 'AIzaSyCECVlPxjzB9WVBEnqwAkBcqZbyEvmdPNE';
  static const int _searchRadius = 10000; // 10 km in meters

  // Religious place types to search for
  final List<String> _religiousPlaceTypes = [
    'church',
    'mosque',
    'synagogue',
    'hindu_temple',
    'place_of_worship',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location permissions are permanently denied')),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Fetch nearby religious places
      await _fetchNearbyReligiousPlaces();
      _updateMarkers();
      _moveCameraToLocation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _fetchNearbyReligiousPlaces() async {
    if (_currentPosition == null) {
      _places = [];
      return;
    }

    setState(() {
      _isLoadingPlaces = true;
    });

    try {
      final List<Map<String, dynamic>> allPlaces = [];
      final Set<String> seenPlaceIds = {};

      // Search for each type of religious place
      for (final placeType in _religiousPlaceTypes) {
        try {
          final places = await _searchNearbyPlaces(placeType);
          
          for (final place in places) {
            final placeId = place['place_id'] as String?;
            if (placeId != null && !seenPlaceIds.contains(placeId)) {
              seenPlaceIds.add(placeId);
              allPlaces.add(place);
            }
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Error fetching places for type $placeType: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }

      // Sort by distance
      allPlaces.sort((a, b) {
        final distA = a['distance'] as double;
        final distB = b['distance'] as double;
        return distA.compareTo(distB);
      });

      setState(() {
        _places = allPlaces;
        _isLoadingPlaces = false;
      });
    } catch (e) {
      debugPrint('Error fetching nearby places: $e');
      setState(() {
        _isLoadingPlaces = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching places: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _searchNearbyPlaces(String type) async {
    if (_currentPosition == null) {
      debugPrint('⚠️ Cannot search places: current position is null');
      return [];
    }

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    debugPrint('🔍 Searching for $type at location: $lat, $lng');

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=$_searchRadius'
      '&type=$type'
      '&key=$_placesApiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      
      // Log API response for debugging
      debugPrint('🔍 Places API Response for $type: ${data['status']}');
      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
        debugPrint('❌ Places API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
      }
      
      if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
        final results = data['results'] as List<dynamic>? ?? [];
        debugPrint('✅ Found ${results.length} places of type $type');
        
        return results.map<Map<String, dynamic>>((place) {
          final location = place['geometry']?['location'] as Map<String, dynamic>?;
          // Handle both int and double types from API
          final latValue = location?['lat'];
          final lngValue = location?['lng'];
          final placeLat = (latValue is double ? latValue : (latValue is int ? latValue.toDouble() : 0.0));
          final placeLng = (lngValue is double ? lngValue : (lngValue is int ? lngValue.toDouble() : 0.0));
          
          // Calculate distance
          final distance = Geolocator.distanceBetween(
            lat,
            lng,
            placeLat,
            placeLng,
          );

          // Determine icon based on type
          IconData icon = Icons.place_rounded;
          if (type.contains('mosque')) {
            icon = Icons.mosque_rounded;
          } else if (type.contains('church')) {
            icon = Icons.church_rounded;
          } else if (type.contains('hindu_temple') || type.contains('temple')) {
            icon = Icons.temple_hindu_rounded;
          } else if (type.contains('synagogue')) {
            icon = Icons.synagogue_rounded;
          }

          return {
            'name': place['name'] as String? ?? 'Unknown',
            'type': _getPlaceTypeLabel(type),
            'distance': distance,
            'distanceText': _formatDistance(distance),
            'icon': icon,
            'latitude': placeLat,
            'longitude': placeLng,
            'place_id': place['place_id'] as String?,
            'vicinity': place['vicinity'] as String?,
            'rating': (place['rating'] is double ? place['rating'] as double? : (place['rating'] is int ? (place['rating'] as int).toDouble() : null)),
          };
        }).toList();
      } else {
        debugPrint('Places API error: ${data['status']}');
        return [];
      }
    } else {
      throw Exception('Failed to load places: ${response.statusCode}');
    }
  }

  String _getPlaceTypeLabel(String type) {
    switch (type) {
      case 'church':
        return 'Church';
      case 'mosque':
        return 'Mosque';
      case 'synagogue':
        return 'Synagogue';
      case 'hindu_temple':
        return 'Hindu Temple';
      case 'place_of_worship':
        return 'Place of Worship';
      default:
        return 'Religious Place';
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  void _updateMarkers() {
    if (_currentPosition == null) return;

    _markers.clear();
    
    // Add current location marker
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Add place markers
    for (int i = 0; i < _places.length; i++) {
      final place = _places[i];
      final lat = place['latitude'] as double;
      final lng = place['longitude'] as double;
      
      _markers.add(
        Marker(
          markerId: MarkerId('place_$i'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: place['name'] as String,
            snippet: '${place['type'] as String} • ${place['distanceText'] as String}',
          ),
        ),
      );
    }

    setState(() {});
  }

  void _moveCameraToLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          14.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GradientTheme.softBackground,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: GradientTheme.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nearby Places',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map View
                Expanded(
                  flex: 2,
                  child: _currentPosition != null
                      ? GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            zoom: 14.0,
                          ),
                          markers: _markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          mapType: MapType.normal,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                        )
                      : const Center(
                          child: Text('Unable to load map'),
                        ),
                ),
                // Places List
                Expanded(
                  flex: 1,
                  child: _isLoadingPlaces
                      ? const Center(child: CircularProgressIndicator())
                      : _places.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off_rounded,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No religious places found within 10 km',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _places.length,
                              itemBuilder: (context, index) {
                                final place = _places[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: GradientTheme.cardDecoration(borderRadius: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: GradientTheme.pastelYellow,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          place['icon'] as IconData,
                                          color: const Color(0xFFF59E0B),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place['name'] as String,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: GradientTheme.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              place['type'] as String,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: GradientTheme.textMedium,
                                              ),
                                            ),
                                            if (place['vicinity'] != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                place['vicinity'] as String,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_rounded,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  place['distanceText'] as String,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.directions_rounded,
                                          color: Color(0xFF6366F1),
                                        ),
                                        onPressed: () {
                                          // TODO: Implement actual directions opening
                                          // For now, just show a message
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Directions to ${place['name'] as String} (coming soon)'),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
