import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/promo_banner_provider.dart';

/// Auto-scrolling "Special Offers" carousel shown near the top of the
/// customer Home screen. Reads live from Firestore via
/// PromoBannerProvider — whatever staff set in the Promo Banner
/// Management screen appears here for every customer. Renders nothing
/// if no banners have been set yet, so the Home layout doesn't show
/// an empty placeholder section.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  int? _lastBannerCount;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  void _startAutoScroll(int itemCount) {
    _autoScrollTimer?.cancel();
    if (itemCount <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      final next = (_currentPage + 1) % itemCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = context.watch<PromoBannerProvider>().banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    // Restart the auto-scroll timer only when the number of banners
    // actually changes, not on every rebuild.
    if (_lastBannerCount != banners.length) {
      _lastBannerCount = banners.length;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _startAutoScroll(banners.length));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final banner = banners[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double scale = 1.0;
                  if (_pageController.position.haveDimensions) {
                    final page = _pageController.page ?? _currentPage.toDouble();
                    scale = (1 - ((page - index).abs() * 0.08)).clamp(0.9, 1.0);
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: banner.imageBase64.isEmpty
                      ? Container(color: Colors.grey.shade200)
                      : Image.memory(
                          base64Decode(banner.imageBase64),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => Container(color: Colors.grey.shade200),
                        ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final active = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryNavy : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}