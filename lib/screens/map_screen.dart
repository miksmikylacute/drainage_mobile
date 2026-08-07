import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/drainage_report.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  static const LatLng _maubanSouthWest = LatLng(14.1000, 121.6200);
  static const LatLng _maubanNorthEast = LatLng(14.2800, 121.8200);
  LatLng _currentCenter = const LatLng(14.1894, 121.7226); // Mauban center
  String _currentLocationText = 'Finding your current location...';
  bool _isDragging = false;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnCurrentLocation();
    });
  }

  Future<void> _centerOnCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocating = true;
      _currentLocationText = 'Finding your current location...';
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _useFallbackLocation(
          'Location service is turned off. Drag the map to select the issue location.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _useFallbackLocation(
          'Location permission denied. Drag the map to select the issue location.',
        );
        return;
      }

      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (!mounted) return;
      final target = LatLng(pos.latitude, pos.longitude);
      _currentCenter = target;
      _mapController.move(target, 18.0);
      _updateLocationText(target);
      setState(() {
        _isLocating = false;
      });
    } catch (_) {
      if (!mounted) return;
      _useFallbackLocation(
        'Unable to determine exact GPS. Drag the map to select your location.',
      );
    }
  }

  void _useFallbackLocation(String warningMessage) {
    if (!mounted) return;
    final fallback = const LatLng(14.1894, 121.7226);
    _currentCenter = fallback;
    _mapController.move(fallback, 18.0);
    _updateLocationText(fallback);
    setState(() {
      _isLocating = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(warningMessage), duration: const Duration(seconds: 4)),
    );
  }



  // Reverse geocoding simulator based on Mauban coordinates
  String _formatLocationText(LatLng position) {
    if (!_isWithinMaubanLabelArea(position)) {
      return 'Selected map area, near pinned location ${_formatPinnedCoordinates(position)}';
    }

    // Generate realistic Mauban address names based on coordinate grid quadrants
    String barangay;
    String landmark;

    double lat = position.latitude;
    double lng = position.longitude;

    if (lat > 14.1920) {
      barangay = "Barangay Luya-luya, Mauban";
      landmark = "near Gomez Street / Purok 3";
    } else if (lat < 14.1850) {
      barangay = "Barangay Rizal, Mauban";
      landmark = "near Quezon Avenue / Purok 2";
    } else if (lng > 121.7280) {
      barangay = "Barangay Polo, Mauban";
      landmark = "near Coastal Road / Purok 4";
    } else if (lng < 121.7180) {
      barangay = "Barangay Bagong Silang, Mauban";
      landmark = "near San Lorenzo Street / Purok 1";
    } else {
      barangay = "Poblacion, Mauban Town Center";
      landmark = "near Real Street / Municipal Hall";
    }

    return "$barangay, $landmark - pinned location ${_formatPinnedCoordinates(position)}";
  }

  String _formatPinnedCoordinates(LatLng position) {
    return '(${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)})';
  }

  bool _isWithinMaubanLabelArea(LatLng point) {
    return point.latitude >= _maubanSouthWest.latitude &&
        point.latitude <= _maubanNorthEast.latitude &&
        point.longitude >= _maubanSouthWest.longitude &&
        point.longitude <= _maubanNorthEast.longitude;
  }

  void _updateLocationText(LatLng position) {
    setState(() {
      _currentLocationText = _formatLocationText(position);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map Widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 18.0,
              minZoom: 12.0,
              maxZoom: 22.0,
              onPointerDown: (event, point) {
                setState(() {
                  _isDragging = true;
                });
              },
              onPointerUp: (event, point) {
                setState(() {
                  _isDragging = false;
                });
              },
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  _currentCenter = position.center!;
                  _updateLocationText(_currentCenter);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.drainage.user',
                maxZoom: 22.0,
              ),
            ],
          ),

          // Central Pin Pointer Overlay (hovering crosshair effect)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 24.0,
              ), // offset pin center to tip
              child: AnimatedScale(
                scale: _isDragging ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.translationValues(
                    0,
                    _isDragging ? -8 : 0,
                    0,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
          ),

          // Overlay Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ),

          // Top Floating Address Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 72,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF0066FF),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLocating
                              ? 'Current Location'
                              : 'Selected Location',
                          style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          _currentLocationText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 104,
            child: FloatingActionButton.small(
              heroTag: 'center-on-current-location',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0066FF),
              elevation: 4,
              onPressed: _isLocating ? null : _centerOnCurrentLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0066FF),
                      ),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),

          // Bottom Confirmation Panel
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Hint
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Drag map to select drainage location',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      IssueLocation(
                        label: _currentLocationText,
                        latitude: _currentCenter.latitude,
                        longitude: _currentCenter.longitude,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black26,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Confirm Location',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
