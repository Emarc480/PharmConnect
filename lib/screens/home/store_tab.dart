import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/drug_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_grid_card.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/drug_categories.dart';
import '../../core/theme/app_theme.dart';

/// The searchable drug catalog — this is the exact content that used
/// to live directly on HomeScreen, now just one tab of the shell in
/// home_screen.dart alongside Home/Cart/Account.
class StoreTab extends StatelessWidget {
  const StoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final drugProvider = context.watch<DrugProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.read<CartProvider>();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                  avatar: category == 'All'
                      ? null
                      : Icon(
                          categoryIcon(category),
                          size: 16,
                          color: isSelected ? Colors.white : categoryColor(category),
                        ),
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
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: drugProvider.filteredDrugs.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.46,
                    ),
                    itemBuilder: (context, i) {
                      final drug = drugProvider.filteredDrugs[i];
                      return ProductGridCard(
                        drug: drug,
                        isWishlisted: wishlist.isSaved(drug.id),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.drugDetail,
                          arguments: drug,
                        ),
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
          ),
        ],
      ),
    );
  }
}