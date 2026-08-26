import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/products_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _showForm(context, ref)),
      ]),
      body: catsAsync.when(
        data: (cats) => ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: cats.length,
          itemBuilder: (_, i) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: cats[i].image.isNotEmpty
                    ? CachedNetworkImage(imageUrl: cats[i].image, width: 50, height: 50, fit: BoxFit.cover, memCacheWidth: 120, maxWidthDiskCache: 120,
                        placeholder: (_, __) => Container(color: Colors.grey[200], width: 50, height: 50),
                        errorWidget: (_, __, ___) => Container(color: Colors.grey[200], width: 50, height: 50, child: const Icon(Icons.category)),
                      )
                    : Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.category)),
              ),
              title: Text(cats[i].name),
              subtitle: Text(cats[i].isActive ? 'Active' : 'Inactive', style: TextStyle(color: cats[i].isActive ? AppTheme.successColor : AppTheme.errorColor)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showForm(context, ref, category: cats[i])),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorColor), onPressed: () => _delete(context, ref, cats[i])),
              ]),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, {CategoryModel? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final imageCtrl = TextEditingController(text: category?.image ?? '');
    bool isActive = category?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category != null ? 'Edit Category' : 'Add Category', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              SwitchListTile(title: const Text('Active'), value: isActive, onChanged: (v) => setModalState(() => isActive = v)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final api = ApiService();
                    final body = {'name': nameCtrl.text.trim(), 'image': imageCtrl.text.trim(), 'is_active': isActive};
                    try {
                      if (category != null) {
                        await api.patch('${ApiEndpoints.categories}${category.id}/', data: body);
                      } else {
                        await api.post(ApiEndpoints.categories, data: body);
                      }
                      ref.invalidate(categoriesProvider);
                      Navigator.pop(ctx);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _delete(BuildContext context, WidgetRef ref, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}"? Products in this category will be unassigned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            Navigator.pop(ctx);
            try {
              final api = ApiService();
              await api.delete('${ApiEndpoints.categories}${cat.id}/');
              ref.invalidate(categoriesProvider);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
            }
          }, child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
  }
}
