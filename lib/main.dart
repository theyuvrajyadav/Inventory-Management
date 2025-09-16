import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/screens/dashboard_screen.dart';
import 'src/screens/products_list_screen.dart';
import 'src/screens/product_form_screen.dart';
import 'src/screens/settings_screen.dart';
import 'src/screens/sell_screen.dart';
import 'src/screens/sales_history_screen.dart';
import 'src/providers/product_providers.dart';
import 'src/services/sqlite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SQLite before running app
  final sqlite = SqliteService();
  await sqlite.init();
  runApp(ProviderScope(
    overrides: [
      sqliteServiceProvider.overrideWithValue(sqlite),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9C27B0)),
        useMaterial3: true,
      ),
      home: const _RootInitializer(child: _RootScaffold()),
    );
  }
}

class _RootInitializer extends ConsumerStatefulWidget {
  const _RootInitializer({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<_RootInitializer> createState() => _RootInitializerState();
}

class _RootInitializerState extends ConsumerState<_RootInitializer> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Load products once after DB init
    Future.microtask(() async {
      await ref.read(productsProvider.notifier).load();
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}

class _RootScaffold extends StatefulWidget {
  const _RootScaffold({super.key});

  @override
  State<_RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<_RootScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final pages = <Widget>[
      const DashboardScreen(),
      const ProductsListScreen(),
      const ProductFormScreen(),
      const SettingsScreen(),
      const SellScreen(),
      const SalesHistoryScreen(),
    ];

    final destinations = const [
      NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
      NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Products'),
      NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Add'),
      NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
      NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sell'),
      NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Sales'),
    ];

    final navRail = NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      labelType: NavigationRailLabelType.selected,
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Products')),
        NavigationRailDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: Text('Add')),
        NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
        NavigationRailDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: Text('Sell')),
        NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Sales')),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Management')),
      body: Row(
        children: [
          if (isWide) navRail,
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              destinations: destinations,
              onDestinationSelected: (i) => setState(() => _index = i),
            ),
    );
  }
}


