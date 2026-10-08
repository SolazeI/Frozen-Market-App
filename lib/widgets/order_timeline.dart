import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/order_status.dart';
import '../theme/app_colors.dart';

/// Vertical tracking timeline: Pending → Confirmed → Preparing →
/// Out for Delivery → Delivered. Rejected / cancelled orders show the steps
/// reached so far followed by a red terminal step.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.status, required this.times});

  final OrderStatus status;
  final Map<OrderStatus, DateTime> times;

  static const _flow = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  static String _hint(OrderStatus s) => switch (s) {
        OrderStatus.pending => 'Waiting for the seller to accept',
        OrderStatus.confirmed => 'The seller accepted your order',
        OrderStatus.preparing => 'Your items are being packed',
        OrderStatus.outForDelivery => 'On the way to you',
        OrderStatus.delivered => 'Order completed',
        OrderStatus.rejected => 'The seller could not accept this order',
        OrderStatus.cancelled => 'You cancelled this order',
      };

  @override
  Widget build(BuildContext context) {
    final terminalFail =
        status == OrderStatus.rejected || status == OrderStatus.cancelled;
    final steps = terminalFail ? [OrderStatus.pending, status] : _flow;
    final current = steps.indexOf(status);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _Step(
            status: steps[i],
            time: times[steps[i]],
            state: i < current
                ? _StepState.done
                : (i == current ? _StepState.current : _StepState.upcoming),
            isFailure: terminalFail && i == steps.length - 1,
            isLast: i == steps.length - 1,
            hint: _hint(steps[i]),
          ),
      ],
    );
  }
}

enum _StepState { done, current, upcoming }

class _Step extends StatelessWidget {
  const _Step({
    required this.status,
    required this.time,
    required this.state,
    required this.isFailure,
    required this.isLast,
    required this.hint,
  });

  final OrderStatus status;
  final DateTime? time;
  final _StepState state;
  final bool isFailure;
  final bool isLast;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final finished = status == OrderStatus.delivered &&
        state == _StepState.current; // last step reached = complete
    final color = isFailure
        ? AppColors.error
        : (finished ? AppColors.success : AppColors.primary);
    final reached = state != _StepState.upcoming;

    final Widget dot;
    if (isFailure) {
      dot = _circle(color, filled: true, icon: Icons.close_rounded);
    } else if (state == _StepState.done || finished) {
      dot = _circle(color, filled: true, icon: Icons.check_rounded);
    } else if (state == _StepState.current) {
      dot = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
            shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        alignment: Alignment.center,
        child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      );
    } else {
      dot = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2)),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                dot,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: state == _StepState.done
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: reached
                              ? AppColors.textPrimary
                              : AppColors.textSecondary)),
                  if (state == _StepState.current)
                    Text(hint,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  if (time != null)
                    Text(Formatters.dateTime(time!),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(Color color, {required bool filled, required IconData icon}) =>
      Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: Colors.white),
      );
}
