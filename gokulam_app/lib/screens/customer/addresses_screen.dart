import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../config/theme.dart';

final addressesProvider = FutureProvider.autoDispose<List<AddressModel>>((ref) async {
  final api = ApiService();
  final res = await api.get(ApiEndpoints.addresses);
  return (res.data as List).map((e) => AddressModel.fromJson(e)).toList();
});

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) return const Center(child: Text('No addresses saved'));
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: addresses.length,
            itemBuilder: (_, i) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(addresses[i].isDefault ? Icons.home : Icons.location_on, color: AppTheme.primaryColor),
                title: Text(addresses[i].label),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addresses[i].fullAddress),
                    Text('${addresses[i].city}, ${addresses[i].state} - ${addresses[i].pincode}'),
                  ],
                ),
                trailing: addresses[i].isDefault ? const Chip(label: Text('Default', style: TextStyle(fontSize: 11))) : null,
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load addresses')),
      ),
    );
  }
}