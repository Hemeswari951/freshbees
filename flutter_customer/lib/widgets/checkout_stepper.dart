import 'package:flutter/material.dart';

/// The "Address — Order Summary — Payment" progress row shown at the top
/// of all three checkout screens. [currentStep] is 0-indexed
/// (0 = Address, 1 = Order Summary, 2 = Payment). Steps before
/// [currentStep] are shown as completed (check mark), the current step is
/// highlighted, and later steps are greyed out — same visual language as
/// Flipkart's checkout stepper.
class CheckoutStepper extends StatelessWidget {
  final int currentStep;

  const CheckoutStepper({super.key, required this.currentStep});

  static const List<String> _labels = ['Address', 'Order Summary', 'Payment'];
  static const Color _accent = Color(0xFF8B7355);
  static const Color _inactive = Color(0xFFD9D2C6);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          // Even indices are circles, odd indices are the connecting line.
          if (i.isOdd) {
            final leftStep = i ~/ 2;
            final lineDone = leftStep < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: lineDone ? _accent : _inactive,
              ),
            );
          }

          final step = i ~/ 2;
          final done = step < currentStep;
          final active = step == currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (done || active) ? _accent : Colors.white,
                  border: Border.all(
                    color: (done || active) ? _accent : _inactive,
                    width: 1.5,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : Colors.black45,
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                _labels[step],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: (done || active) ? Colors.black87 : Colors.black38,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
