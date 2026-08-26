import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';

class DeliveryRouteScreen extends ConsumerStatefulWidget {
  final int orderId;

  const DeliveryRouteScreen({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryRouteScreen> createState() => _DeliveryRouteScreenState();
}

class _DeliveryRouteScreenState extends ConsumerState<DeliveryRouteScreen> {
  List<LatLng> _routePoints = [];
  bool _loadingRoute = true;
  OrderModel? _order;
  String _addressText = '';
  LatLng? _origin;
  bool _originIsCurrent = false;

  Future<LatLng?> _currentPosition() async {
    try {
      var status = await Permission.location.status;
      if (!status.isGranted) status = await Permission.location.request();
      if (!status.isGranted) return null;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  LatLng? get _destination {
    final o = _order;
    if (o == null) return null;
    if (o.deliveryLat != null && o.deliveryLng != null) {
      return LatLng(o.deliveryLat!, o.deliveryLng!);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = ref.read(ordersProvider).valueOrNull ?? [];
    final order = orders.where((o) => o.id == widget.orderId).firstOrNull;
    if (order != null) {
      setState(() {
        _order = order;
        _addressText = order.deliveryAddressText;
      });
      final api = ApiService();
      try {
        final res = await api.get('${ApiEndpoints.orders}${widget.orderId}/');
        final detail = OrderDetailModel.fromJson(res.data);
        if (mounted) {
          setState(() {
            _order = detail;
            final addr = detail.deliveryAddressDetail;
            if (addr is Map<String, dynamic>) {
              _addressText = (addr['full_address'] ?? '') +
                  (addr['city'] != null && (addr['city'] as String).isNotEmpty ? ', ${addr['city']}' : '');
            }
          });
        }
      } catch (_) {}
    }
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final store = await ref.read(storeConfigProvider.future);
    final dest = _destination;
    if (dest == null) {
      if (mounted) setState(() => _loadingRoute = false);
      return;
    }
    final storePoint = LatLng(store.latitude, store.longitude);
    var origin = storePoint;
    var originIsCurrent = false;
    final current = await _currentPosition();
    if (current != null) {
      origin = current;
      originIsCurrent = true;
    }
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = (data['routes'] as List?) ?? [];
        if (routes.isNotEmpty) {
          final geom = ((routes.first as Map<String, dynamic>)['geometry'] as Map<String, dynamic>);
          final coords = (geom['coordinates'] as List)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (coords.isNotEmpty) {
            if (mounted) {
              setState(() {
                _routePoints = coords;
                _loadingRoute = false;
                _origin = origin;
                _originIsCurrent = originIsCurrent;
              });
            }
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _loadingRoute = false;
        _origin = origin;
        _originIsCurrent = originIsCurrent;
      });
    }
  }

  LatLng _mid(LatLng a, LatLng b) {
    return LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2);
  }

  @override
  Widget build(BuildContext context) {
    final dest = _destination;
    final storeAsync = ref.watch(storeConfigProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Route'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: storeAsync.when(
        data: (store) {
          final storePoint = LatLng(store.latitude, store.longitude);
          final origin = _origin ?? storePoint;
          final center = _mid(origin, dest ?? origin);
          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.gokulam.traders',
                    ),
                    if (_routePoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5,
                            color: const Color(0xFF1565C0),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: origin,
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
                                child: Text(_originIsCurrent ? 'You' : 'Store', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                              Icon(_originIsCurrent ? Icons.my_location : Icons.store, color: AppTheme.primaryColor, size: 26),
                            ],
                          ),
                        ),
                        if (dest != null)
                          Marker(
                            point: dest,
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
                                  child: const Text('Delivery', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                                const Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 30),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.receipt_long, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text(_order?.orderId ?? 'Order', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('₹${(_order?.totalAmount ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.place, size: 18, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _addressText.isNotEmpty
                              ? _addressText
                              : 'Delivery location selected on map',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ]),
                    if (_loadingRoute) ...[
                      const SizedBox(height: 12),
                      const Center(child: CircularProgressIndicator()),
                    ] else if (_routePoints.isEmpty && dest != null) ...[
                      const SizedBox(height: 8),
                      Text('Showing straight-line route. Turn-by-turn opens in Google Maps.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.navigation),
                        label: const Text('Open in Google Maps'),
                        onPressed: dest == null
                            ? null
                            : () async {
                                final url = 'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${dest.latitude},${dest.longitude}&travelmode=driving';
                                final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                if (!launched && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open Google Maps. Route shown above.')),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load store location')),
      ),
    );
  }
}