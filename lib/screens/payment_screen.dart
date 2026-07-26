import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _phoneController = TextEditingController();
  final _paymentService = PaymentService();
  PaymentProvider _provider = PaymentProvider.mtn;
  bool _isProcessing = false;
  String? _statusMessage;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Enter the phone number to pay from.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
      _statusMessage = 'Sending payment prompt to $phone…';
    });

    try {
      await _paymentService.initiatePayment(
        provider: _provider,
        orderId: widget.orderId,
        phone: phone,
        amount: widget.amount,
      );

      if (!mounted) return;
      setState(() => _statusMessage =
          'Approve the payment on your phone. Waiting for confirmation…');

      final status = await _paymentService.pollPaymentStatus(
        provider: _provider,
        orderId: widget.orderId,
      );

      if (!mounted) return;

      if (status == 'paid') {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.orderTracking,
          arguments: widget.orderId,
        );
        return;
      }

      setState(() {
        _isProcessing = false;
        _statusMessage = null;
        _error = status == 'failed'
            ? 'Payment failed or was declined. Please try again.'
            : 'Still waiting for confirmation. Check your phone, then try again.';
      });
    } on PaymentException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = null;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = null;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay for order')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Amount due', style: TextStyle(color: Colors.grey.shade600)),
              Text(
                _formatUgx(widget.amount.round()),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 24),
              const Text('Pay with', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('MTN MoMo'),
                      selected: _provider == PaymentProvider.mtn,
                      onSelected: _isProcessing
                          ? null
                          : (_) => setState(() => _provider = PaymentProvider.mtn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Airtel Money'),
                      selected: _provider == PaymentProvider.airtel,
                      onSelected: _isProcessing
                          ? null
                          : (_) => setState(() => _provider = PaymentProvider.airtel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                enabled: !_isProcessing,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number (e.g. 2567XXXXXXXX)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_statusMessage!)),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isProcessing ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_isProcessing ? 'Processing…' : 'Confirm Payment'),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ll get a prompt on your phone to approve the payment with your PIN.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatUgx(int amount) {
  final s = amount.toString();
  final withCommas = s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return 'UGX $withCommas';
}
