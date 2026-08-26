import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/delivery_map_view.dart';

class MapLocationPickerResult {
  final double latitude;
  final double longitude;
  final AddressModel? address;
  final double distanceKm;
  final double deliveryCharge;

  MapLocationPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.distanceKm,
    required this.deliveryCharge,
  });
}

class MapLocationPicker extends StatefulWidget {
  final LatLng storePoint;
  final double radiusKm;
  final double chargePerHalfKm;

  const MapLocationPicker({
    super.key,
    this.storePoint = storeLatLng,
    this.radiusKm = 5,
    this.chargePerHalfKm = 5,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final MapController _mapController = MapController();
  late LatLng _storePoint;
  late LatLng _pickedLocation;
  double _distanceKm = 0;
  bool _isLoadingAddress = false;
  String _addressText = '';
  String _city = '';
  String _state = '';
  String _pincode = '';
  String _label = 'Home';
  bool _gettingCurrentLocation = false;
  Timer? _moveTimer;

  double get _deliveryCharge => AppConfig.deliveryChargeForDistanceBooking(_distanceKm, widget.chargePerHalfKm);

  @override
  void initState() {
    super.initState();
    _storePoint = widget.storePoint;
    _pickedLocation = widget.storePoint;
    _distanceKm = _calculateDistance(_pickedLocation);
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    super.dispose();
  }

  double _calculateDistance(LatLng point) {
    const earthRadius = 6371.0;
    final dLat = _toRad(point.latitude - _storePoint.latitude);
    final dLon = _toRad(point.longitude - _storePoint.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(_storePoint.latitude)) *
            cos(_toRad(point.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _moveTimer?.cancel();
    _moveTimer = Timer(const Duration(milliseconds: 300), () {
      final center = camera.center;
      setState(() {
        _pickedLocation = center;
        _distanceKm = _calculateDistance(center);
      });
      _reverseGeocode(center);
    });
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() {
      _isLoadingAddress = true;
      _addressText = '';
    });
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&addressdetails=1',
      );
      final response = await http.get(url, headers: {'User-Agent': 'GokulamTraders/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addr = data['address'] ?? {};
        setState(() {
          _addressText = data['display_name'] ?? '';
          _city = addr['city'] ?? addr['town'] ?? addr['village'] ?? '';
          _state = addr['state'] ?? '';
          _pincode = addr['postcode'] ?? '';
          _isLoadingAddress = false;
        });
      } else {
        setState(() => _isLoadingAddress = false);
      }
    } catch (_) {
      setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingCurrentLocation = true);
    try {
      var status = await Permission.location.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        setState(() => _gettingCurrentLocation = false);
        return;
      }
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required')),
          );
        }
        setState(() => _gettingCurrentLocation = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final userLoc = LatLng(position.latitude, position.longitude);
      _mapController.move(userLoc, 15);
      setState(() {
        _pickedLocation = userLoc;
        _distanceKm = _calculateDistance(userLoc);
        _gettingCurrentLocation = false;
      });
      _reverseGeocode(userLoc);
    } catch (e) {
      setState(() => _gettingCurrentLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  Future<void> _confirmLocation() async {
    if (_distanceKm > widget.radiusKm) return;
    setState(() => _isLoadingAddress = true);

    final address = AddressModel(
      label: _label,
      fullAddress: _addressText,
      city: _city,
      state: _state,
      pincode: _pincode,
      latitude: _pickedLocation.latitude,
      longitude: _pickedLocation.longitude,
    );

    try {
      final api = ApiService();
      final res = await api.post(ApiEndpoints.addresses, data: address.toJson());
      final savedAddress = AddressModel.fromJson(res.data);

      if (mounted) {
        Navigator.pop(
          context,
          MapLocationPickerResult(
            latitude: _pickedLocation.latitude,
            longitude: _pickedLocation.longitude,
            address: savedAddress,
            distanceKm: _distanceKm,
            deliveryCharge: _deliveryCharge,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingAddress = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWithinRadius = _distanceKm <= widget.radiusKm;
    final tierColor = tierColorForDistance(_distanceKm);
    final deliveryCharge = _deliveryCharge;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Delivery Location'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _storePoint,
              initialZoom: 13,
              onPositionChanged: _onMapMoved,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gokulam.traders',
              ),
              CircleLayer(
                circles: [
                  for (var km = 1; km <= widget.radiusKm.ceil(); km++)
                    CircleMarker(
                      point: _storePoint,
                      radius: km * 1000.0,
                      useRadiusInMeter: true,
                      color: tierColorForKm(km).withOpacity(0.08),
                      borderColor: tierColorForKm(km).withOpacity(0.6),
                      borderStrokeWidth: 2,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _storePoint,
                    width: 40,
                    height: 40,
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
                        Icon(Icons.store, color: AppTheme.primaryColor, size: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Icon(Icons.location_pin, size: 48, color: isWithinRadius ? Colors.red : Colors.grey),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: isWithinRadius ? tierColor : Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Icon(isWithinRadius ? Icons.check_circle : Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isWithinRadius
                            ? '${_distanceKm.toStringAsFixed(1)} km — Delivery ₹${deliveryCharge.toStringAsFixed(0)}'
                            : '${_distanceKm.toStringAsFixed(1)} km — Out of delivery area (max ${widget.radiusKm.toStringAsFixed(0)} km)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Label', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Home'),
                            selected: _label == 'Home',
                            onSelected: (_) => setState(() => _label = 'Home'),
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Work'),
                            selected: _label == 'Work',
                            onSelected: (_) => setState(() => _label = 'Work'),
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Other'),
                            selected: _label == 'Other',
                            onSelected: (_) => setState(() => _label = 'Other'),
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingAddress)
                        const Row(
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Getting address...'),
                          ],
                        )
                      else if (_addressText.isNotEmpty) ...[
                        Text(_addressText, style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ] else
                        Text('Drag the map to set your delivery location', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(color: tierColorForDistance(_distanceKm), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_distanceKm.toStringAsFixed(1)} km — Delivery ₹${deliveryCharge.toStringAsFixed(0)} (₹5 per 0.5 km)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (isWithinRadius && !_isLoadingAddress) ? _confirmLocation : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: _isLoadingAddress
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Confirm Location', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'current_location',
            onPressed: _gettingCurrentLocation ? null : _useCurrentLocation,
            backgroundColor: AppTheme.primaryColor,
            child: _gettingCurrentLocation
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, currentZoom + 1);
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, currentZoom - 1);
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
