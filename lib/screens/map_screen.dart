import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = const LatLng(14.1894, 121.7226); // Mauban center
  String _currentLocationText = "Loading location...";
  bool _isDragging = false;

  // Mauban boundary limits
  final LatLng _southWestBoundary = const LatLng(14.1000, 121.6200);
  final LatLng _northEastBoundary = const LatLng(14.2800, 121.8200);

  @override
  void initState() {
    super.initState();
    _updateLocationText(_currentCenter);
  }

  // Reverse geocoding simulator based on Mauban coordinates
  void _updateLocationText(LatLng position) {
    // Generate realistic Mauban address names based on coordinate grid quadrants
    String barangay;
    String street;

    double lat = position.latitude;
    double lng = position.longitude;

    if (lat > 14.1920) {
      barangay = "Barangay Luya-luya, Mauban";
      street = "Purok 3, Gomez Street";
    } else if (lat < 14.1850) {
      barangay = "Barangay Rizal, Mauban";
      street = "Purok 2, Quezon Avenue";
    } else if (lng > 121.7280) {
      barangay = "Barangay Polo, Mauban";
      street = "Purok 4, Coastal Road";
    } else if (lng < 121.7180) {
      barangay = "Barangay Bagong Silang, Mauban";
      street = "Purok 1, San Lorenzo Street";
    } else {
      barangay = "Poblacion, Mauban Town Center";
      street = "Real Street, near Municipal Hall";
    }

    setState(() {
      _currentLocationText = "$street, $barangay";
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
              // Constrain map movements to Mauban area
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(_southWestBoundary, _northEastBoundary),
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
              padding: const EdgeInsets.only(bottom: 24.0), // offset pin center to tip
              child: AnimatedScale(
                scale: _isDragging ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.translationValues(0, _isDragging ? -8 : 0, 0),
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
                  const Icon(Icons.my_location_rounded, color: Color(0xFF0066FF), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Location',
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                    // Pass the simulated address back to report screen
                    Navigator.pop(context, _currentLocationText);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38B6FF),
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
