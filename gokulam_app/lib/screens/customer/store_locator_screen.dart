import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../config/theme.dart';
import '../../providers/products_provider.dart';
import '../../widgets/delivery_map_view.dart';

class StoreLocatorScreen extends ConsumerWidget {
  const StoreLocatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(storeConfigProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Location'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: storeAsync.when(
        data: (store) {
          final storePoint = LatLng(store.latitude, store.longitude);
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppTheme.primaryColor.withAlpha(12),
                child: Row(
                  children: [
                    const Icon(Icons.store, color: AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(store.address,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: DeliveryRadiusMap(
                  center: storePoint,
                  storeCenter: storePoint,
                  radiusKm: store.deliveryRadiusKm,
                  initialZoom: 13,
                  showTierCircles: true,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    for (var km = 1; km <= store.deliveryRadiusKm.ceil(); km++) ...[
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                color: tierColorForKm(km),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('$km km', style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Delivery available within ${store.deliveryRadiusKm.toStringAsFixed(0)} km. ₹${store.deliveryChargePerHalfKm.toStringAsFixed(0)} per 0.5 km delivery charge.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
