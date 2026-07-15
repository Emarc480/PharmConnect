import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/drug_provider.dart';
import '../../widgets/drug_card.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  Future<void> _onNavTap(int index) async {
    if (index == 0) {
      setState(() => _navIndex = 0);
      return;
    }
    setState(() => _navIndex = index);
    final route = switch (index) {
      1 => AppRoutes.myOrders,
      2 => AppRoutes.refill,
      3 => AppRoutes.profile,
      _ => null,
    };
    if (route != null) {
      await Navigator.pushNamed(context, route);
    }
    if (mounted) setState(() => _navIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final drugProvider = context.watch<DrugProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PharmConnect', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search drugs...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: drugProvider.setSearchQuery,
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: drugProvider.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final category = drugProvider.categories[i];
                final isSelected = category == drugProvider.selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryNavy,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  onSelected: (_) => drugProvider.setCategory(category),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: drugProvider.filteredDrugs.isEmpty
                ? const Center(child: Text('No drugs found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: drugProvider.filteredDrugs.length,
                    itemBuilder: (context, i) {
                      final drug = drugProvider.filteredDrugs[i];
                      return DrugCard(
                        drug: drug,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.drugDetail,
                          arguments: drug,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        selectedItemColor: AppTheme.primaryNavy,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.refresh), label: 'Refill'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}