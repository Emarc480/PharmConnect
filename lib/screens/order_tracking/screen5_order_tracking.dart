// PharmConnect — 5. Order Tracking (Flutter)
// Customer flow. Owner: Calvin.
// Reached from Cart (4) after checkout.

import 'package:flutter/material.dart';
import 'wireframe_styles.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WireframeScaffold(
      pageTitle: 'PharmConnect — Low-Fidelity Wireframe: 5. Order Tracking',
      child: Column(
        children: [
          WireframeFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FrameTag('Customer'),
                const FrameTitle('Order #1042'),
                const WireframeStatusList(steps: [
                  StatusStep('Order Placed', StatusState.done),
                  StatusStep('Processing', StatusState.current),
                  StatusStep('Shipped', StatusState.pending),
                  StatusStep('Delivered', StatusState.pending),
                ]),
                const WireframeDivider(),
                const WireframeLabel('Estimated Delivery'),
                const WireframeValue('Today, 4:00 PM'),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: WireframeLabel('Delivery Address'),
                ),
                const WireframeBox(child: Text('123 Moi Avenue, Nairobi')),
                const WireframeLabel('Order Summary'),
                const WireframeBox(
                  child: Text(
                    'Panadol 500mg × 1        KES 350\n'
                    'Vitamin C 1000mg × 2   KES 900',
                  ),
                ),
                WireframeButton(
                  'Contact Pharmacy',
                  onTap: () {
                    // TODO: hook up contact/support flow
                  },
                ),
                WireframeButton(
                  'Cancel Order',
                  onTap: () {
                    // TODO: hook up order cancellation flow
                  },
                ),
              ],
            ),
          ),
          const WireframeCaption(
            'Screen 5 — Customer flow. Owner: Calvin. '
            'Reached from Cart (4) after checkout.',
          ),
        ],
      ),
    );
  }
}
