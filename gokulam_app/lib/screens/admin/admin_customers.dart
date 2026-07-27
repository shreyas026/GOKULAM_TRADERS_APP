import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';

final customersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final api = ApiService();
  try {
    final res = await api.get(ApiEndpoints.customers);
    return (res.data as List).map((e) => UserModel.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

class AdminCustomersScreen extends ConsumerWidget {
  const AdminCustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: customersAsync.when(
        data: (customers) => ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: customers.length,
          itemBuilder: (_, i) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(child: Text(customers[i].username[0].toUpperCase())),
              title: Text(customers[i].username),
              subtitle: Text(customers[i].phone.isNotEmpty ? customers[i].phone : customers[i].email),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
      ),
    );
  }
}