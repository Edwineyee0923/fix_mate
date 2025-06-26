import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AddressMapPreview extends StatelessWidget {
  final String address;
  final String googleApiKey;

  const AddressMapPreview({
    super.key,
    required this.address,
    required this.googleApiKey,
  });

  Future<LatLng?> _getLatLngFromAddress() async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleApiKey');
    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final location = data['results'][0]['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    } else {
      debugPrint('Geocoding failed: ${data['status']}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng?>(
      future: _getLatLngFromAddress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          final latLng = snapshot.data!;
          return Container(
            height: 180,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: latLng,
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('seeker_location'),
                    position: latLng,
                  )
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                onTap: (_) {
                  final url = Uri.encodeFull(
                      "https://www.google.com/maps/dir/?api=1&destination=${latLng.latitude},${latLng.longitude}");
                  launchUrl(Uri.parse(url));
                },
              ),
            ),
          );
        } else {
          return const Text("⚠️ Unable to locate this address on the map.");
        }
      },
    );
  }
}