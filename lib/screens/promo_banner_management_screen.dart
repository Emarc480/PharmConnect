import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/promo_banner.dart';
import '../providers/promo_banner_provider.dart';

/// Staff-only screen for managing the up-to-5 promotional banner
/// images shown in the customer Home carousel. Each of the 5 slots
/// maps to a fixed position (0-4); tapping the edit icon picks a
/// photo for that slot, and the delete icon empties it. Reached from
/// the Staff Dashboard (see staff_dashboard.dart).
class PromoBannerManagementScreen extends StatefulWidget {
  const PromoBannerManagementScreen({super.key});

  @override
  State<PromoBannerManagementScreen> createState() =>
      _PromoBannerManagementScreenState();
}

class _PromoBannerManagementScreenState
    extends State<PromoBannerManagementScreen> {
  final Set<int> _savingSlots = {};

  Future<void> _pickForSlot(int slotIndex) async {
    // Grab the provider before any `await` — using `context` after an
    // await without this is what the analyzer's
    // use_build_context_synchronously check flags, since the widget
    // could theoretically be gone from the tree by the time we get
    // back from the picker.
    final promoBannerProvider = context.read<PromoBannerProvider>();
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 70,
      );
      if (picked == null) return;

      setState(() => _savingSlots.add(slotIndex));
      final bytes = await File(picked.path).readAsBytes();
      final base64Str = base64Encode(bytes);
      await promoBannerProvider.setSlot(slotIndex, base64Str);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload that image. Try a smaller photo.')),
      );
    } finally {
      if (mounted) setState(() => _savingSlots.remove(slotIndex));
    }
  }

  Future<void> _removeSlot(int slotIndex) async {
    setState(() => _savingSlots.add(slotIndex));
    await context.read<PromoBannerProvider>().clearSlot(slotIndex);
    if (mounted) setState(() => _savingSlots.remove(slotIndex));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoBannerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Promo Banners')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'These images appear as a swipeable carousel at the top of '
            'the customer Home screen. Fill any of the 5 slots below — '
            'empty ones are simply skipped.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),
          for (int slotIndex = 0; slotIndex < PromoBannerProvider.maxSlots; slotIndex++) ...[
            _SlotCard(
              slotIndex: slotIndex,
              banner: provider.bannerForSlot(slotIndex),
              isSaving: _savingSlots.contains(slotIndex),
              onPick: () => _pickForSlot(slotIndex),
              onRemove: () => _removeSlot(slotIndex),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final int slotIndex;
  final PromoBanner? banner;
  final bool isSaving;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _SlotCard({
    required this.slotIndex,
    required this.banner,
    required this.isSaving,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = banner != null && banner!.imageBase64.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: hasImage
                ? Image.memory(base64Decode(banner!.imageBase64), fit: BoxFit.cover)
                : Container(
                    color: Colors.grey.shade100,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Text('Slot ${slotIndex + 1} — empty', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
          ),
          if (isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Row(
              children: [
                _RoundIconButton(
                  icon: Icons.edit_outlined,
                  onTap: isSaving ? null : onPick,
                ),
                if (hasImage) ...[
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    icon: Icons.delete_outline,
                    onTap: isSaving ? null : onRemove,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
        ),
        child: Icon(icon, size: 18, color: AppTheme.primaryNavy),
      ),
    );
  }
}