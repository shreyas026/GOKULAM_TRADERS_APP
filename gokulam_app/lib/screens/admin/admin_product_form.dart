import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/products_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';

class AdminProductFormScreen extends ConsumerStatefulWidget {
  final int? productId;
  const AdminProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _mrpCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _gstCtrl = TextEditingController(text: '18');
  final _stockCtrl = TextEditingController(text: '0');
  final _descCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  int? _selectedCategory;
  int? _selectedBrand;
  bool _isAvailable = true;
  bool _isFeatured = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProduct();
    }
  }

  void _loadProduct() async {
    final api = ApiService();
    try {
      final res = await api.get('${ApiEndpoints.products}${widget.productId}/');
      final data = res.data;
      setState(() {
        _nameCtrl.text = data['name'] ?? '';
        _skuCtrl.text = data['sku'] ?? '';
        _barcodeCtrl.text = data['barcode'] ?? '';
        _mrpCtrl.text = (data['mrp'] ?? 0).toString();
        _priceCtrl.text = (data['selling_price'] ?? 0).toString();
        _discountCtrl.text = (data['discount_percent'] ?? 0).toString();
        _gstCtrl.text = (data['gst_percent'] ?? 18).toString();
        _stockCtrl.text = (data['stock'] ?? 0).toString();
        _descCtrl.text = data['description'] ?? '';
        _weightCtrl.text = data['weight'] ?? '';
        _materialCtrl.text = data['material'] ?? '';
        _selectedCategory = data['category'];
        _selectedBrand = data['brand'];
        _isAvailable = data['is_available'] ?? true;
        _isFeatured = data['is_featured'] ?? false;
        final images = data['images'];
        if (images is List && images.isNotEmpty) {
          _imageCtrl.text = images[0];
        }
      });
    } catch (_) {}
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 80);
      if (file == null) return;
      setState(() => _saving = true);
      final api = ApiService();
      final res = await api.uploadFile('${ApiEndpoints.products}upload_image/', file.path);
      final url = res.data['url'] as String?;
      if (mounted && url != null) {
        setState(() => _imageCtrl.text = url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final api = ApiService();
    final body = {
      'name': _nameCtrl.text.trim(),
      'sku': _skuCtrl.text.trim(),
      'barcode': _barcodeCtrl.text.trim(),
      'mrp': double.tryParse(_mrpCtrl.text) ?? 0,
      'selling_price': double.tryParse(_priceCtrl.text) ?? 0,
      'discount_percent': double.tryParse(_discountCtrl.text) ?? 0,
      'gst_percent': double.tryParse(_gstCtrl.text) ?? 18,
      'stock': int.tryParse(_stockCtrl.text) ?? 0,
      'description': _descCtrl.text.trim(),
      'weight': _weightCtrl.text.trim(),
      'material': _materialCtrl.text.trim(),
      'category': _selectedCategory,
      'brand': _selectedBrand,
      'is_available': _isAvailable,
      'is_featured': _isFeatured,
      'images': _imageCtrl.text.isNotEmpty ? [_imageCtrl.text.trim()] : [],
    };
    try {
      if (widget.productId != null) {
        await api.patch('${ApiEndpoints.products}${widget.productId}/', data: body);
      } else {
        await api.post(ApiEndpoints.products, data: body);
      }
      if (mounted) {
        ref.invalidate(productsProvider(''));
        ref.invalidate(featuredProductsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.productId != null ? 'Product updated' : 'Product added'), backgroundColor: AppTheme.successColor),
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

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.productId != null ? 'Edit Product' : 'Add Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('Product Name *', _nameCtrl),
            _field('SKU *', _skuCtrl),
            _field('Barcode', _barcodeCtrl),
            const SizedBox(height: 12),
            catsAsync.when(
              data: (cats) => DropdownButtonFormField<int>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
                items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Failed to load categories'),
            ),
            const SizedBox(height: 12),
            _buildBrandDropdown(),
            const SizedBox(height: 12),
            _field('MRP *', _mrpCtrl, keyboard: TextInputType.number),
            _field('Selling Price *', _priceCtrl, keyboard: TextInputType.number),
            Row(children: [
              Expanded(child: _field('Discount %', _discountCtrl, keyboard: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: _field('GST %', _gstCtrl, keyboard: TextInputType.number)),
            ]),
            _field('Stock *', _stockCtrl, keyboard: TextInputType.number),
            _field('Description', _descCtrl, maxLines: 3),
            Row(children: [
              Expanded(child: _field('Weight', _weightCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('Material', _materialCtrl)),
            ]),
            const Text('Product Image', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _imageCtrl.text.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_imageCtrl.text, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 40))),
                    )
                  : const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  onPressed: _saving ? null : () => _pickAndUploadImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  onPressed: _saving ? null : () => _pickAndUploadImage(ImageSource.gallery),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _imageCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                border: OutlineInputBorder(),
                hintText: 'Paste an image URL or use Camera/Gallery',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(title: const Text('Available'), value: _isAvailable, onChanged: (v) => setState(() => _isAvailable = v)),
            SwitchListTile(title: const Text('Featured'), value: _isFeatured, onChanged: (v) => setState(() => _isFeatured = v)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Product'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) => label.contains('*') && (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildBrandDropdown() {
    final brandsAsync = ref.watch(brandsProvider);
    return brandsAsync.when(
      data: (brands) => DropdownButtonFormField<int>(
        value: _selectedBrand,
        decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder()),
        items: [const DropdownMenuItem<int>(value: null, child: Text('No Brand'))]..addAll(
            brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
          ),
        onChanged: (v) => setState(() => _selectedBrand = v),
      ),
      loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Text('Failed to load brands'),
    );
  }
}
