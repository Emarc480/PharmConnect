import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drug_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_grid_card.dart';
import '../../widgets/promo_carousel.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_routes.dart';

/// Landing tab shown when the customer opens the app: search + sort,
/// quick-access feature tiles, a two-column product grid, a wellness
/// promo banner, and a scrollable "Offers" rail of discounted items.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, required this.onBrowsePressed});

  /// Lets the shell (home_screen.dart) switch to the Store tab when
  /// the person taps "See all" or a category shortcut here.
  final VoidCallback onBrowsePressed;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    final drugProvider = context.read<DrugProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, AppTheme.navBarClearance),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: drugProvider.categories.map((category) {
                    final isSelected = category == drugProvider.selectedCategory;
                    return ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryNavy,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                      onSelected: (_) {
                        drugProvider.setCategory(category);
                        Navigator.pop(sheetContext);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSortSheet(BuildContext context) {
    final drugProvider = context.read<DrugProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Sort by', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
                RadioGroup<DrugSortOption>(
                  groupValue: drugProvider.sortOption,
                  onChanged: (value) {
                    if (value != null) drugProvider.setSortOption(value);
                    Navigator.pop(sheetContext);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final option in DrugSortOption.values)
                        RadioListTile<DrugSortOption>(
                          value: option,
                          title: Text(option.label),
                          activeColor: AppTheme.primaryNavy,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final drugProvider = context.watch<DrugProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.read<CartProvider>();
    final nameParts = (user?.name ?? '').trim().split(' ');
    final firstName = nameParts.isNotEmpty && nameParts.first.isNotEmpty ? nameParts.first : 'there';
    final recommended = drugProvider.filteredDrugs.take(6).toList();
    final offers = drugProvider.discountedDrugs;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, AppTheme.navBarClearance),
        children: [
          Text(
            'Hi, $firstName 👋',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'What are you looking for today?',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Search + filter + sort row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: drugProvider.setSearchQuery,
                          onSubmitted: (_) => widget.onBrowsePressed(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(28)),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Filter',
                      onPressed: () => _showFilterSheet(context),
                      icon: const Icon(Icons.tune, color: AppTheme.primaryNavy),
                    ),
                    IconButton(
                      tooltip: 'Sort',
                      onPressed: () => _showSortSheet(context),
                      icon: const Icon(Icons.swap_vert, color: AppTheme.primaryNavy),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Special Offers carousel — staff-managed, up to 5 slots
          const PromoCarousel(),

          // Quick-access feature tiles
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.file_upload_outlined,
                  label: 'Upload\nPrescription',
                  color: AppTheme.inStockGreen,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.prescription),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.notifications_active_outlined,
                  label: 'Medication\nReminders',
                  color: AppTheme.primaryNavy,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.reminders),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.chat_bubble_outline,
                  label: 'Ask a\nPharmacist',
                  color: AppTheme.lowStockOrange,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.askPharmacist),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recommended products grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recommended for you', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(onPressed: widget.onBrowsePressed, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 4),
          if (recommended.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No drugs available yet')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommended.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.46,
              ),
              itemBuilder: (context, i) {
                final drug = recommended[i];
                return ProductGridCard(
                  drug: drug,
                  isWishlisted: wishlist.isSaved(drug.id),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.drugDetail, arguments: drug),
                  onToggleWishlist: () => context.read<WishlistProvider>().toggle(drug.id),
                  onAddToCart: () {
                    cart.addToCart(drug);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${drug.name} added to cart'), duration: const Duration(seconds: 1)),
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 24),

          // Wellness promo banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryNavy.withValues(alpha: 0.08), AppTheme.primaryNavy.withValues(alpha: 0.18)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Boost Your\nDaily Wellness',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shop trusted supplements for family wellness.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: widget.onBrowsePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text('Order Now'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.medication_liquid_outlined, size: 64, color: AppTheme.primaryNavy.withValues(alpha: 0.35)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Offers rail
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Offers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(onPressed: widget.onBrowsePressed, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 4),
          if (offers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No active offers right now — check back soon', style: TextStyle(color: Colors.grey.shade500)),
            )
          else
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: offers.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final drug = offers[i];
                  return SizedBox(
                    width: 160,
                    child: ProductGridCard(
                      drug: drug,
                      isWishlisted: wishlist.isSaved(drug.id),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.drugDetail, arguments: drug),
                      onToggleWishlist: () => context.read<WishlistProvider>().toggle(drug.id),
                      onAddToCart: () {
                        cart.addToCart(drug);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${drug.name} added to cart'), duration: const Duration(seconds: 1)),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// One of the three quick-access tiles: Upload Prescription,
/// Medication Reminders, Ask a Pharmacist.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}