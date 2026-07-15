// PharmConnect — 3. Drug Detail (Flutter)
// Customer flow. Owner: Calvin.
// Navigates from Home (2) → Drug Detail (3) → Cart (4).

import 'package:flutter/material.dart';
import 'wireframe_styles.dart';

class DrugDetailScreen extends StatefulWidget {
  const DrugDetailScreen({super.key});

  @override
  State<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends State<DrugDetailScreen> {
  int _quantity = 1;

  void _increment() => setState(() => _quantity++);
  void _decrement() => setState(() {
        if (_quantity > 1) _quantity--;
      });

  @override
  Widget build(BuildContext context) {
    return WireframeScaffold(
      pageTitle: 'PharmConnect — Low-Fidelity Wireframe: 3. Drug Detail',
      child: Column(
        children: [
          WireframeFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FrameTag('Customer'),
                const FrameTitle('Drug Details'),
                const PlaceholderImage(label: '[ drug image ]'),
                const WireframeRow(children: [
                  WireframeValue('Panadol 500mg'),
                  WireframeValue('KES 350'),
                ]),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: WireframeLabel('Paracetamol · 20 tablets'),
                ),
                const WireframeDivider(),
                const WireframeLabel('Description'),
                const WireframeBox(
                  child: Text(
                    'Used for relief of mild to moderate pain and fever. '
                    'Take 1–2 tablets every 4–6 hours. Do not exceed 8 '
                    'tablets in 24 hours.',
                  ),
                ),
                const WireframeLabel('Requires Prescription?'),
                const WireframeBox(child: Text('No')),
                const WireframeLabel('Quantity'),
                QtyControl(
                  quantity: _quantity,
                  onDecrement: _decrement,
                  onIncrement: _increment,
                ),
                WireframeButton(
                  'Add to Cart',
                  primary: true,
                  onTap: () {
                    // TODO: hook up to Cart (screen 4)
                  },
                ),
                WireframeButton(
                  'Request Refill',
                  onTap: () {
                    // TODO: hook up refill request flow
                  },
                ),
              ],
            ),
          ),
          const WireframeCaption(
            'Screen 3 — Customer flow. Owner: Calvin. '
            'Navigates from Home (2) → Drug Detail (3) → Cart (4).',
          ),
        ],
      ),
    );
  }
}
