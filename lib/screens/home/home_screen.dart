import 'package:flutter/material.dart';
import 'dashboard_tab.dart';
import 'store_tab.dart';
import '../cart_screen.dart';
import '../profile_screen.dart';
import '../../widgets/floating_nav_bar.dart';

/// Customer home shell: hosts the floating pill nav bar (Home / Store
/// / Cart / Account) and swaps between the four tabs in place with an
/// IndexedStack, so switching tabs never rebuilds the others from
/// scratch and each keeps its scroll position.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  void _goToStore() => setState(() => _navIndex = 1);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(onBrowsePressed: _goToStore),
      const StoreTab(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // Deliberately NOT extendBody: true — CartScreen's checkout
      // button and ProfileScreen's log-out button sit flush at the
      // bottom of their own layouts, and extending the body behind
      // the nav bar would hide them under it. The pill still reads as
      // "floating" from its own rounded corners, margin, and shadow.
      body: IndexedStack(index: _navIndex, children: tabs),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}