import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/products_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../widgets/delivery_map_view.dart';

class AdminStoreSettingsScreen extends ConsumerStatefulWidget {
  const AdminStoreSettingsScreen({super.key});

  @override
  ConsumerState<AdminStoreSettingsScreen> createState() => _AdminStoreSettingsScreenState();
}

class _AdminStoreSettingsScreenState extends ConsumerState<AdminStoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();
  final _chargeCtrl = TextEditingController();
  bool _saving = false;

  StoreConfigModel? _current;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final store = await ref.read(storeConfigProvider.future);
    if (!mounted) return;
    setState(() {
      _current = store;
      _nameCtrl.text = store.name;
      _addressCtrl.text = store.address;
      _latCtrl.text = store.latitude.toString();
      _lngCtrl.text = store.longitude.toString();
      _radiusCtrl.text = store.deliveryRadiusKm.toString();
      _chargeCtrl.text = store.deliveryChargePerHalfKm.toString();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final api = ApiService();
      await api.put(ApiEndpoints.storeLocation, data: {
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'latitude': double.tryParse(_latCtrl.text) ?? 12.9716,
        'longitude': double.tryParse(_lngCtrl.text) ?? 77.5946,
        'delivery_radius_km': double.tryParse(_radiusCtrl.text) ?? 5,
        'delivery_charge_per_half_km': double.tryParse(_chargeCtrl.text) ?? 5,
      });
      if (mounted) {
        ref.invalidate(storeConfigProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop settings saved'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
    setState(() => _saving = false);
  }

  void _openMapPicker() {
    final lat = double.tryParse(_latCtrl.text) ?? AppConfig.storeLat;
    final lng = double.tryParse(_lngCtrl.text) ?? AppConfig.storeLng;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminMapPicker(
          initialLat: lat,
          initialLng: lng,
          onConfirm: (newLat, newLng, address) {
            setState(() {
              _latCtrl.text = newLat.toStringAsFixed(6);
              _lngCtrl.text = newLng.toStringAsFixed(6);
              if (address.isNotEmpty) _addressCtrl.text = address;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop Location & Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Shop Location & Settings'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Mini map preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          double.tryParse(_latCtrl.text) ?? _current!.latitude,
                          double.tryParse(_lngCtrl.text) ?? _current!.longitude,
                        ),
                        initialZoom: 14,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.gokulam.traders',
                        ),
                        CircleLayer(
                          circles: [
                            for (var km = 1; km <= (_current!.deliveryRadiusKm).ceil(); km++)
                              CircleMarker(
                                point: LatLng(_current!.latitude, _current!.longitude),
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
                              point: LatLng(
                                double.tryParse(_latCtrl.text) ?? _current!.latitude,
                                double.tryParse(_lngCtrl.text) ?? _current!.longitude,
                              ),
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
                                    child: const Text('Shop', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                  Icon(Icons.store, color: AppTheme.primaryColor, size: 28),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openMapPicker,
                          child: Container(
                            alignment: Alignment.center,
                            color: Colors.black.withOpacity(0.15),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.map, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text('Tap to change on map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Current location: ${_current!.latitude.toStringAsFixed(4)}, ${_current!.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _field('Store Name *', _nameCtrl),
            _field('Address *', _addressCtrl),
            Row(
              children: [
                Expanded(child: _field('Latitude *', _latCtrl, TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 8),
                Expanded(child: _field('Longitude *', _lngCtrl, TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field('Delivery Radius (km) *', _radiusCtrl, TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 8),
                Expanded(child: _field('Delivery Charge per 0.5 km (₹) *', _chargeCtrl, TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.map),
                label: const Text('Set Location on Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Settings'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Dashboard'),
              onPressed: () => context.go('/admin'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, [TextInputType? keyboard]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard ?? TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) => label.contains('*') && (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }
}

// Full-screen map picker for admin to set shop location
class _AdminMapPicker extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final void Function(double lat, double lng, String address) onConfirm;

  const _AdminMapPicker({
    required this.initialLat,
    required this.initialLng,
    required this.onConfirm,
  });

  @override
  State<_AdminMapPicker> createState() => _AdminMapPickerState();
}

class _AdminMapPickerState extends State<_AdminMapPicker> {
  final MapController _mapController = MapController();
  late LatLng _pickedLocation;
  bool _isLoadingAddress = false;
  String _addressText = '';
  bool _gettingCurrentLocation = false;
  Timer? _moveTimer;

  @override
  void initState() {
    super.initState();
    _pickedLocation = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    super.dispose();
  }

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _moveTimer?.cancel();
    _moveTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _pickedLocation = camera.center);
      _reverseGeocode(camera.center);
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
        setState(() {
          _addressText = data['display_name'] ?? '';
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
      _mapController.move(userLoc, 16);
      setState(() {
        _pickedLocation = userLoc;
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

  void _confirm() {
    widget.onConfirm(
      _pickedLocation.latitude,
      _pickedLocation.longitude,
      _addressText,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Shop Location'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text('SET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedLocation,
              initialZoom: 16,
              onPositionChanged: _onMapMoved,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gokulam.traders',
              ),
              CircleLayer(
                circles: [
                  for (var km = 1; km <= 5; km++)
                    CircleMarker(
                      point: _pickedLocation,
                      radius: km * 1000.0,
                      useRadiusInMeter: true,
                      color: tierColorForKm(km).withOpacity(0.08),
                      borderColor: tierColorForKm(km).withOpacity(0.6),
                      borderStrokeWidth: 2,
                    ),
                ],
              ),
            ],
          ),
          // Center pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.location_pin, size: 48, color: Colors.red),
            ),
          ),
          // Info bar at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Drag the map to position the shop pin',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_pickedLocation.latitude.toStringAsFixed(6)}, ${_pickedLocation.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Address info at bottom
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                        ),
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
                      else if (_addressText.isNotEmpty)
                        Text(_addressText, style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis)
                      else
                        Text('Drag the map to set the shop location', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Set This Location', style: TextStyle(fontSize: 16)),
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