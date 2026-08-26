import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';
import '../config/app_config.dart';

const storeLatLng = LatLng(AppConfig.storeLat, AppConfig.storeLng);

const _tierColors = <int, Color>{
  1: Color(0xFF00C853),
  2: Color(0xFF00B0FF),
  3: Color(0xFFFF9800),
  4: Color(0xFFE040FB),
  5: Color(0xFFF44336),
};

Color tierColorForKm(int km) => _tierColors[km.clamp(1, 5)] ?? AppTheme.primaryColor;

Color tierColorForDistance(double distanceKm) {
  final km = distanceKm.ceil().clamp(1, 5);
  return tierColorForKm(km);
}

class DeliveryRadiusMap extends StatelessWidget {
  final LatLng center;
  final LatLng? marker;
  final bool showTierCircles;
  final double initialZoom;
  final LatLng storeCenter;
  final double radiusKm;

  const DeliveryRadiusMap({
    super.key,
    required this.center,
    this.marker,
    this.showTierCircles = true,
    this.initialZoom = 13,
    this.storeCenter = storeLatLng,
    this.radiusKm = 5,
  });

  @override
  Widget build(BuildContext context) {
    final circles = <CircleMarker>[];
    if (showTierCircles) {
      for (var km = 1; km <= radiusKm.ceil(); km++) {
        circles.add(CircleMarker(
          point: storeCenter,
          radius: km * 1000.0,
          useRadiusInMeter: true,
          color: tierColorForKm(km).withOpacity(0.08),
          borderColor: tierColorForKm(km).withOpacity(0.55),
          borderStrokeWidth: 2,
        ));
      }
    }

    final markers = <Marker>[
      Marker(
        point: storeCenter,
        width: 44,
        height: 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Text('Gokulam\nTraders', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            Icon(Icons.store, color: AppTheme.primaryColor, size: 26),
          ],
        ),
      ),
    ];

    if (marker != null) {
      markers.add(Marker(
        point: marker!,
        width: 36,
        height: 36,
        child: const Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 36),
      ));
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: initialZoom,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.gokulam.traders',
        ),
        CircleLayer(circles: circles),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
