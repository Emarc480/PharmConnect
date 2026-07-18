import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drug_provider.dart';
import '../../widgets/drug_card.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_routes.dart';

/// Landing tab shown when the customer opens the app: a quick
/// greeting, category shortcuts, and a short list of drugs to browse
/// — separate from StoreTab, which is the full searchable catalog.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.onBrowsePressed});

  /// Lets the shell (home_screen.dart) switch to the Store tab when
  /// the person taps "Browse all" or a category shortcut here.
  final VoidCallback onBrowsePressed;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final drugProvider = context.watch<DrugProvider>();
    final nameParts = (user?.name ?? '').trim().split(' ');
    final firstName = nameParts.isNotEmpty && nameParts.first.isNotEmpty ? nameParts.first : 'there';
    final featured = drugProvider.allDrugs.take(5).toList();
    final shortcutCategories = drugProvider.categories.where((c) => c != 'All').toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
          InkWell(
            onTap: onBrowsePressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text('Search the pharmacy...', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Categories', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shortcutCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final category = shortcutCategories[i];
                return InkWell(
                  onTap: () {
                    drugProvider.setCategory(category);
                    onBrowsePressed();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.medication_outlined, color: AppTheme.primaryNavy),
                        const SizedBox(height: 6),
                        Text(
                          category,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Popular right now', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(onPressed: onBrowsePressed, child: const Text('See all')),
            ],
          ),
          if (featured.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No drugs available yet')),
            )
          else
            ...featured.map(
              (drug) => DrugCard(
                drug: drug,
                onTap: () => Navigator.pushNamed(context, AppRoutes.drugDetail, arguments: drug),
              ),
            ),
        ],
      ),
    );
  }
}