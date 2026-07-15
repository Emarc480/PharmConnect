// PharmConnect — shared low-fidelity wireframe styles (Flutter/Dart)
//
// This is the Flutter equivalent of wireframe.css: a small reusable
// widget library so every screen — even ones built by different
// teammates — stays visually consistent.
//
// Import this file in each screen file:
//   import 'wireframe_styles.dart';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Colors  (equivalent of the CSS color values used throughout)
// ---------------------------------------------------------------------
class WireframeColors {
  static const background = Color(0xFFF4F4F4);
  static const frameBorder = Color(0xFF999999);
  static const frameBg = Colors.white;
  static const titleTeal = Color(0xFF1A3D3D);
  static const frameTitleText = Color(0xFF333333);
  static const tagGrey = Color(0xFF888888);
  static const divider = Color(0xFFCCCCCC);
  static const lightDivider = Color(0xFFEEEEEE);
  static const label = Color(0xFF666666);
  static const value = Color(0xFF222222);
  static const boxText = Color(0xFF555555);
  static const placeholderText = Color(0xFFAAAAAA);
  static const placeholderStripeLight = Color(0xFFEEEEEE);
  static const placeholderStripeDark = Color(0xFFF7F7F7);
  static const btnBorder = Color(0xFF333333);
  static const btnBg = Color(0xFFFAFAFA);
  static const btnPrimaryBg = Color(0xFF222222);
  static const captionGrey = Color(0xFF999999);
  static const statusInactive = Color(0xFF999999);
  static const statusActive = Color(0xFF222222);
  static const statusLineInactive = Color(0xFFDDDDDD);
}

// ---------------------------------------------------------------------
// Text styles  (.page-title, .frame-tag, .frame-title, .label, .value...)
// ---------------------------------------------------------------------
class WireframeText {
  static const pageTitle = TextStyle(
      fontSize: 14, fontWeight: FontWeight.bold, color: WireframeColors.titleTeal);
  static const frameTag = TextStyle(
      fontSize: 9, letterSpacing: 0.5, color: WireframeColors.tagGrey);
  static const frameTitle = TextStyle(
      fontSize: 11, fontWeight: FontWeight.bold, color: WireframeColors.frameTitleText);
  static const label = TextStyle(fontSize: 9, color: WireframeColors.label);
  static const value =
      TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: WireframeColors.value);
  static const boxText = TextStyle(fontSize: 9, color: WireframeColors.boxText);
  static const btnText =
      TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: WireframeColors.value);
  static const btnPrimaryText =
      TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white);
  static const caption = TextStyle(fontSize: 8, color: WireframeColors.captionGrey);
}

// ---------------------------------------------------------------------
// .frame — the 320-wide bordered card every screen sits in
// ---------------------------------------------------------------------
class WireframeFrame extends StatelessWidget {
  final Widget child;
  const WireframeFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WireframeColors.frameBg,
        border: Border.all(color: WireframeColors.frameBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

// .frame-tag
class FrameTag extends StatelessWidget {
  final String text;
  const FrameTag(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text.toUpperCase(), style: WireframeText.frameTag),
      );
}

// .frame-title (with optional back arrow, like <span class="back">)
class FrameTitle extends StatelessWidget {
  final String title;
  final bool showBack;
  const FrameTitle(this.title, {super.key, this.showBack = true});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: WireframeColors.divider)),
        ),
        child: Row(
          children: [
            if (showBack)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Text('←',
                    style: TextStyle(color: WireframeColors.tagGrey, fontSize: 11)),
              ),
            Text(title, style: WireframeText.frameTitle),
          ],
        ),
      );
}

// .row
class WireframeRow extends StatelessWidget {
  final List<Widget> children;
  const WireframeRow({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
}

// .box
class WireframeBox extends StatelessWidget {
  final Widget child;
  const WireframeBox({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: WireframeColors.divider),
          borderRadius: BorderRadius.circular(3),
        ),
        child: DefaultTextStyle(style: WireframeText.boxText, child: child),
      );
}

// .placeholder-img — diagonal-stripe placeholder box
class PlaceholderImage extends StatelessWidget {
  final String label;
  final double height;
  const PlaceholderImage({super.key, this.label = '[ image ]', this.height = 90});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: height,
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(color: WireframeColors.divider),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(painter: _StripePainter(), size: Size.infinite),
            Text(label,
                style:
                    const TextStyle(fontSize: 8, color: WireframeColors.placeholderText)),
          ],
        ),
      );
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = WireframeColors.placeholderStripeLight);
    final stripePaint = Paint()..color = WireframeColors.placeholderStripeDark;
    const gap = 12.0;
    for (double x = -size.height; x < size.width; x += gap) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + 6, 0)
        ..lineTo(x + 6, size.height)
        ..close();
      canvas.drawPath(path, stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// .label
class WireframeLabel extends StatelessWidget {
  final String text;
  final EdgeInsets? margin;
  const WireframeLabel(this.text, {super.key, this.margin});
  @override
  Widget build(BuildContext context) => Padding(
        padding: margin ?? const EdgeInsets.only(bottom: 3),
        child: Text(text, style: WireframeText.label),
      );
}

// .value
class WireframeValue extends StatelessWidget {
  final String text;
  const WireframeValue(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text, style: WireframeText.value);
}

// .btn / .btn.primary
class WireframeButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback? onTap;
  const WireframeButton(this.label, {super.key, this.primary = false, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary ? WireframeColors.btnPrimaryBg : WireframeColors.btnBg,
              border: Border.all(
                  color: primary ? WireframeColors.btnPrimaryBg : WireframeColors.btnBorder),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(label,
                style: primary ? WireframeText.btnPrimaryText : WireframeText.btnText),
          ),
        ),
      );
}

// .qty-control — quantity stepper
class QtyControl extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  const QtyControl(
      {super.key, required this.quantity, this.onDecrement, this.onIncrement});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: WireframeColors.divider),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onDecrement,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('−', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Text('$quantity', style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onIncrement,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('+', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      );
}

// One item in .status-list
enum StatusState { pending, current, done }

class StatusStep {
  final String label;
  final StatusState state;
  const StatusStep(this.label, this.state);
}

// .status-list — vertical order-tracking timeline
class WireframeStatusList extends StatelessWidget {
  final List<StatusStep> steps;
  const WireframeStatusList({super.key, required this.steps});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps.map((s) {
            final active = s.state != StatusState.pending;
            return Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: active
                        ? WireframeColors.statusActive
                        : WireframeColors.statusLineInactive,
                    width: 2,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? WireframeColors.statusActive : Colors.white,
                        border: Border.all(
                            color: active
                                ? WireframeColors.statusActive
                                : WireframeColors.statusInactive),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 9,
                        color: active
                            ? WireframeColors.statusActive
                            : WireframeColors.statusInactive,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
}

// .divider
class WireframeDivider extends StatelessWidget {
  const WireframeDivider({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, thickness: 1, color: WireframeColors.lightDivider),
      );
}

// .caption
class WireframeCaption extends StatelessWidget {
  final String text;
  const WireframeCaption(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: SizedBox(
          width: 320,
          child: Text(text, textAlign: TextAlign.center, style: WireframeText.caption),
        ),
      );
}

// .page-title
class WireframePageTitle extends StatelessWidget {
  final String text;
  const WireframePageTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(text, textAlign: TextAlign.center, style: WireframeText.pageTitle),
      );
}

/// Wraps a screen body the same way every wireframe page in the set does:
/// light-grey background, centered column, page title on top.
/// (Equivalent of the shared `body { ... }` rules in wireframe.css.)
class WireframeScaffold extends StatelessWidget {
  final String pageTitle;
  final Widget child;
  const WireframeScaffold({super.key, required this.pageTitle, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WireframeColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  WireframePageTitle(pageTitle),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
}
