import 'package:flutter/material.dart';
import 'staff_dashboard.dart';
import 'inventory_screen.dart';
import 'order_management_screen.dart';
import 'profile_screen.dart';
import '../widgets/staff_floating_nav_bar.dart';

/// Staff home shell: hosts the floating pill nav bar (Dashboard /
/// Inventory / Orders / Profile) and swaps between the four tabs in
/// place with an IndexedStack — mirrors the customer HomeScreen shell
/// so both sides of the app now share the same modern navigation
/// pattern instead of staff screens pushing on top of each other with
/// a plain BottomNavigationBar.
class StaffHomeShell extends StatefulWidget {
  const StaffHomeShell({super.key});

  @override
  State<StaffHomeShell> createState() => _StaffHomeShellState();
}

class _StaffHomeShellState extends State<StaffHomeShell> {
  int _navIndex = 0;

  void _goToTab(int index) => setState(() => _navIndex = index);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      StaffDashboard(onNavigateToTab: _goToTab),
      const InventoryScreen(),
      const OrderManagementScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _navIndex, children: tabs),
      bottomNavigationBar: StaffFloatingNavBar(
        currentIndex: _navIndex,
        onTap: _goToTab,
      ),
    );
  }
}