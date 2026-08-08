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

  static const LatLng _soledadCenter = LatLng(14.2050, 121.7250);
  static const LatLng _soledadSouthWest = LatLng(14.1700, 121.6950);
  static const LatLng _soledadNorthEast = LatLng(14.2350, 121.7550);

  LatLng _currentCenter = _soledadCenter;
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

  bool _isWithinSoledad(LatLng point) {
    return point.latitude >= _soledadSouthWest.latitude &&
        point.latitude <= _soledadNorthEast.latitude &&
        point.longitude >= _soledadSouthWest.longitude &&
        point.longitude <= _soledadNorthEast.longitude;
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
        _handleOutsideOrDisabledGps();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _handleOutsideOrDisabledGps();
        return;
      }

      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final target = LatLng(pos.latitude, pos.longitude);
      if (_isWithinSoledad(target)) {
        _currentCenter = target;
        _mapController.move(target, 15.0);
        _updateLocationText(target);
        setState(() {
          _isLocating = false;
        });
        return;
      }

      _handleOutsideOrDisabledGps();
    } catch (_) {
      if (!mounted) return;
      _handleOutsideOrDisabledGps();
    }
  }

  void _handleOutsideOrDisabledGps() {
    if (!mounted) return;
    _currentCenter = _soledadCenter;
    _mapController.move(_soledadCenter, 15.0);
    _updateLocationText(_soledadCenter);
    setState(() {
      _isLocating = false;
    });
    _showOutsideSoledadDialog();
  }

  Future<void> _showOutsideSoledadDialog() async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFFFF3DC),
                  child: Icon(
                    Icons.wrong_location_rounded,
                    color: Color(0xFFF59E0B),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Outside Barangay Soledad',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'you are not in the baranggay soledad area in Mauban Quezon',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Option 1: Manually pin point an issue in the map
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Manually pin point an issue in the map',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Option 2: Exit
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black.withValues(alpha: 0.7),
                      side: const BorderSide(color: Colors.black26),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Exit',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatLocationText(LatLng position) {
    double lat = position.latitude;
    double lng = position.longitude;

    String landmark;
    if (lat > 14.2150) {
      landmark = "near Mountain & Rural Area / Inland Channel";
    } else if (lat > 14.2000) {
      landmark = "near Upper Soledad / Gomez Street & Foothills";
    } else if (lat < 14.1850) {
      landmark = "near South Soledad / Quezon Avenue";
    } else if (lng > 121.7380) {
      landmark = "near Coastal Edge / East Drainage Line";
    } else if (lng < 121.7100) {
      landmark = "near West Mountain Stream / Inland Purok";
    } else {
      landmark = "near Barangay Hall & Main Drainage Channel";
    }

    return "Barangay Soledad, Mauban, Quezon - $landmark - pinned location ${_formatPinnedCoordinates(position)}";
  }

  String _formatPinnedCoordinates(LatLng position) {
    return '(${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)})';
  }

  void _updateLocationText(LatLng position) {
    setState(() {
      _currentLocationText = _formatLocationText(position);
    });
  }

  LatLng _clampToSoledad(LatLng point) {
    final clampedLat = point.latitude.clamp(
      _soledadSouthWest.latitude,
      _soledadNorthEast.latitude,
    );
    final clampedLng = point.longitude.clamp(
      _soledadSouthWest.longitude,
      _soledadNorthEast.longitude,
    );
    return LatLng(clampedLat, clampedLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map Widget focused on Barangay Soledad
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              minZoom: 13.0,
              maxZoom: 19.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(_soledadSouthWest, _soledadNorthEast),
              ),
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
                  final clamped = _clampToSoledad(position.center!);
                  _currentCenter = clamped;
                  _updateLocationText(_currentCenter);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.drainage.user',
                maxZoom: 19.0,
              ),
            ],
          ),

          // Central Pin Pointer Overlay
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
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

          // Recenter Button
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
                      'Drag map to select drainage location in Brgy. Soledad',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm Button
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
