import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';
import '../../providers/products_provider.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';

class CustomerTrackingScreen extends ConsumerStatefulWidget {
  final int orderId;
  const CustomerTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends ConsumerState<CustomerTrackingScreen> {
  Timer? _pollTimer;
  Map<String, dynamic>? _tracking;
  OrderDetailModel? _order;
  List<LatLng> _routePoints = [];
  bool _loadingRoute = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTracking();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollTracking());
  }

  Future<void> _pollTracking() async {
    final data = await ref.read(ordersProvider.notifier).getTracking(widget.orderId);
    if (!mounted) return;
    final prevLat = _tracking?['lat'];
    final prevLng = _tracking?['lng'];
    setState(() {
      if (data != null) _tracking = data;
    });
    final newLat = _tracking?['lat'];
    final newLng = _tracking?['lng'];
    if (newLat != null && newLng != null) {
      final agentLat = double.tryParse(newLat.toString());
      final agentLng = double.tryParse(newLng.toString());
      if (agentLat != null && agentLng != null) {
        if (prevLat != newLat || prevLng != newLng) {
          _fetchRoute();
        }
        try {
          _mapController.move(LatLng(agentLat, agentLng), _mapController.camera.zoom);
        } catch (_) {}
      }
    }
  }

  Future<void> _loadOrder() async {
    final order = await ref.read(ordersProvider.notifier).getOrderDetail(widget.orderId);
    if (!mounted) return;
    setState(() => _order = order);
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final dest = _destination;
    final agent = _agentLocation;
    if (dest == null || agent == null) {
      if (mounted) setState(() => _loadingRoute = false);
      return;
    }
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${agent.longitude},${agent.latitude};${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = (data['routes'] as List?) ?? [];
        if (routes.isNotEmpty) {
          final geom = ((routes.first as Map<String, dynamic>)['geometry'] as Map<String, dynamic>);
          final coords = (geom['coordinates'] as List)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (coords.isNotEmpty && mounted) {
            setState(() {
              _routePoints = coords;
              _loadingRoute = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingRoute = false);
  }

  LatLng? get _destination {
    final o = _order;
    if (o == null) return null;
    if (o.deliveryLat != null && o.deliveryLng != null) {
      return LatLng(o.deliveryLat!, o.deliveryLng!);
    }
    final addr = o.deliveryAddressDetail;
    if (addr is Map<String, dynamic>) {
      final lat = double.tryParse(addr['latitude']?.toString() ?? '');
      final lng = double.tryParse(addr['longitude']?.toString() ?? '');
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return null;
  }

  LatLng? get _agentLocation {
    if (_tracking == null) return null;
    final lat = double.tryParse(_tracking!['lat']?.toString() ?? '');
    final lng = double.tryParse(_tracking!['lng']?.toString() ?? '');
    if (lat != null && lng != null) return LatLng(lat, lng);
    return null;
  }

  double? _estimateDistance(LatLng a, LatLng b) {
    const earth = 6371.0;
    final dLat = (b.latitude - a.latitude) * 3.141592653589793 / 180;
    final dLng = (b.longitude - a.longitude) * 3.141592653589793 / 180;
    final haversin = (dLat / 2).abs() * (dLat / 2).abs() +
        (a.latitude * 3.141592653589793 / 180).abs() *
            (b.latitude * 3.141592653589793 / 180).abs() *
            (dLng / 2).abs() * (dLng / 2).abs();
    return earth * 2 * (haversin > 0 ? haversin : 0);
  }

  @override
  Widget build(BuildContext context) {
    final dest = _destination;
    final agent = _agentLocation;
    final hasAgent = agent != null;
    final order = _order;

    LatLng center = dest ?? const LatLng(AppConfig.storeLat, AppConfig.storeLng);
    if (hasAgent) center = agent!;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: hasAgent ? 14 : 13,
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
              MarkerLayer(markers: [
                if (dest != null)
                  Marker(
                    point: dest,
                    width: 50,
                    height: 50,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Text('Your Address', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        const Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 32),
                      ],
                    ),
                  ),
                if (hasAgent)
                  Marker(
                    point: agent!,
                    width: 56,
                    height: 56,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green[600]),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order?.assignedTo ?? 'Agent',
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppTheme.primaryColor.withAlpha(80), blurRadius: 12)],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                  ),
              ]),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasAgent ? Icons.delivery_dining : Icons.hourglass_empty,
                        color: hasAgent ? AppTheme.primaryColor : Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasAgent ? 'Delivery agent is on the way' : 'Looking for delivery agent...',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (hasAgent)
                              Text(
                                'Order #${order?.orderId ?? ''}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (hasAgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 6),
                              Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (hasAgent && dest != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildInfoChip(Icons.straighten, '${_agentToDestKm()} km'),
                        const SizedBox(width: 8),
                        _buildInfoChip(Icons.access_time, _estimateTime()),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Column(
              children: [
                _mapButton(Icons.my_location, () {
                  if (hasAgent) {
                    _mapController.move(agent!, 15);
                  }
                }),
                const SizedBox(height: 8),
                _mapButton(Icons.fit_screen, () {
                  if (hasAgent && dest != null) {
                    final bounds = LatLngBounds.fromPoints([agent!, dest]);
                    _mapController.fitCamera(
                      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
                    );
                  }
                }),
              ],
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
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
              ),
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusTimeline(order?.status ?? 'pending', order?.deliveryType ?? 'home_delivery'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.navigation),
                      label: const Text('Open in Google Maps'),
                      onPressed: dest == null
                          ? null
                          : () async {
                              final origin = agent ?? LatLng(AppConfig.storeLat, AppConfig.storeLng);
                              final url = 'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${dest.latitude},${dest.longitude}&travelmode=driving';
                              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _agentToDestKm() {
    final agent = _agentLocation;
    final dest = _destination;
    if (agent == null || dest == null) return '--';
    final dist = _haversineKm(agent, dest);
    return dist.toStringAsFixed(1);
  }

  String _estimateTime() {
    final agent = _agentLocation;
    final dest = _destination;
    if (agent == null || dest == null) return '--';
    final distKm = _haversineKm(agent, dest);
    final speedKmPerMin = 0.5;
    final mins = (distKm / speedKmPerMin).ceil();
    if (mins < 1) return 'Arriving now';
    if (mins < 60) return '$mins min';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  double _haversineKm(LatLng a, LatLng b) {
    const earth = 6371.0;
    final dLat = (b.latitude - a.latitude) * 3.141592653589793 / 180;
    final dLng = (b.longitude - a.longitude) * 3.141592653589793 / 180;
    final la = a.latitude * 3.141592653589793 / 180;
    final lb = b.latitude * 3.141592653589793 / 180;
    final h = (dLat / 2) * (dLat / 2) + la.abs() * lb.abs() * (dLng / 2) * (dLng / 2);
    return earth * 2 * (h > 0 ? h : 0);
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Icon(icon, size: 20, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildStatusTimeline(String status, String deliveryType) {
    final steps = deliveryType == 'takeaway'
        ? ['pending', 'confirmed', 'packed', 'delivered']
        : ['pending', 'confirmed', 'packed', 'shipped', 'out_for_delivery', 'delivered'];
    final currentIndex = steps.indexOf(status);

    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= currentIndex;
        final isCurrent = i == currentIndex;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: isCurrent ? 12 : 8,
                      height: isCurrent ? 12 : 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primaryColor : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      steps[i].replaceAll('_', '\n'),
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < currentIndex ? AppTheme.primaryColor : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
