import 'package:flutter/material.dart';
import '../config/theme.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(config.label, style: TextStyle(fontSize: 11, color: config.color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  _StatusConfig _getConfig(String status) {
    switch (status) {
      case 'pending': return _StatusConfig(Icons.hourglass_empty, AppTheme.warningColor, 'Pending');
      case 'confirmed': return _StatusConfig(Icons.check_circle_outline, AppTheme.primaryColor, 'Confirmed');
      case 'packed': return _StatusConfig(Icons.inventory_2, Colors.blue, 'Packed');
      case 'shipped': return _StatusConfig(Icons.local_shipping, Colors.indigo, 'Shipped');
      case 'out_for_delivery': return _StatusConfig(Icons.delivery_dining, Colors.orange, 'Out for Delivery');
      case 'delivered': return _StatusConfig(Icons.verified, AppTheme.successColor, 'Delivered');
      case 'cancelled': return _StatusConfig(Icons.cancel, AppTheme.errorColor, 'Cancelled');
      default: return _StatusConfig(Icons.help_outline, AppTheme.textSecondary, status);
    }
  }
}

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String label;
  _StatusConfig(this.icon, this.color, this.label);
}