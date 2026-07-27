import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/customer/home_screen.dart';
import '../screens/customer/product_list_screen.dart';
import '../screens/customer/product_detail_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/orders_screen.dart';
import '../screens/customer/order_detail_screen.dart';
import '../screens/customer/wishlist_screen.dart';
import '../screens/customer/profile_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_products.dart';
import '../screens/admin/admin_orders.dart';
import '../screens/admin/admin_inventory.dart';
import '../screens/admin/admin_customers.dart';
import '../screens/cashier/billing_screen.dart';
import '../screens/delivery/delivery_home.dart';
import '../screens/khata/khata_screen.dart';
import '../screens/khata/credit_detail_screen.dart';
import '../screens/customer/addresses_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/auth/login',
    redirect: (context, state) {
      final loggedIn = authState.isLoggedIn;
      final role = authState.user?.role;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') || state.matchedLocation == '/splash';
      if (!loggedIn && !isAuthRoute) return '/auth/login';
      if (loggedIn && isAuthRoute) {
        return _getHomeRoute(role);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => _MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/products', builder: (_, __) => const ProductListScreen()),
          GoRoute(path: '/products/:id', builder: (_, s) => ProductDetailScreen(id: int.parse(s.pathParameters['id']!))),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
          GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
          GoRoute(path: '/orders/:id', builder: (_, s) => OrderDetailScreen(orderId: int.parse(s.pathParameters['id']!))),
          GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
          GoRoute(path: '/admin/products', builder: (_, __) => const AdminProductsScreen()),
          GoRoute(path: '/admin/orders', builder: (_, __) => const AdminOrdersScreen()),
          GoRoute(path: '/admin/inventory', builder: (_, __) => const AdminInventoryScreen()),
          GoRoute(path: '/admin/customers', builder: (_, __) => const AdminCustomersScreen()),
          GoRoute(path: '/billing', builder: (_, __) => const BillingScreen()),
          GoRoute(path: '/delivery', builder: (_, __) => const DeliveryHomeScreen()),
          GoRoute(path: '/khata', builder: (_, __) => const KhataScreen()),
          GoRoute(path: '/khata/:id', builder: (_, s) => CreditDetailScreen(creditId: int.parse(s.pathParameters['id']!))),
          GoRoute(path: '/profile/addresses', builder: (_, __) => const AddressesScreen()),
        ],
      ),
    ],
  );
});

String _getHomeRoute(String? role) {
  switch (role) {
    case 'admin': return '/admin';
    case 'cashier': return '/billing';
    case 'delivery': return '/delivery';
    default: return '/home';
  }
}

class _MainShell extends ConsumerWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).user?.role ?? 'customer';
    final currentLocation = GoRouterState.of(context).matchedLocation;

    final tabs = _getBottomNavItems(role);
    if (tabs.isEmpty) return Scaffold(body: child);

    final currentIndex = tabs.indexWhere((t) => currentLocation.startsWith(t.path));

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex >= 0 ? currentIndex : 0,
        onTap: (i) => context.go(tabs[i].path),
        items: tabs.map((t) => BottomNavigationBarItem(icon: Icon(t.icon), label: t.label)).toList(),
      ),
    );
  }

  List<_NavItem> _getBottomNavItems(String role) {
    if (role == 'admin') return [
      _NavItem('Dashboard', Icons.dashboard, '/admin'),
      _NavItem('Products', Icons.inventory_2, '/admin/products'),
      _NavItem('Orders', Icons.receipt_long, '/admin/orders'),
      _NavItem('Khata', Icons.book, '/khata'),
      _NavItem('Profile', Icons.person, '/profile'),
    ];
    if (role == 'cashier') return [
      _NavItem('Billing', Icons.receipt, '/billing'),
      _NavItem('Orders', Icons.receipt_long, '/orders'),
      _NavItem('Profile', Icons.person, '/profile'),
    ];
    if (role == 'delivery') return [
      _NavItem('Deliveries', Icons.delivery_dining, '/delivery'),
      _NavItem('Profile', Icons.person, '/profile'),
    ];
    return [
      _NavItem('Home', Icons.home, '/home'),
      _NavItem('Products', Icons.grid_view, '/products'),
      _NavItem('Cart', Icons.shopping_cart, '/cart'),
      _NavItem('Orders', Icons.receipt_long, '/orders'),
      _NavItem('Profile', Icons.person, '/profile'),
    ];
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  _NavItem(this.label, this.icon, this.path);
}
