import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../auth/providers/auth_controller.dart';
import '../../common/widgets/async_value_widget.dart';
import '../models/redemption.dart';
import '../providers/history_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(redemptionHistoryProvider);
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    final points = ref.watch(authControllerProvider).user?.points ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de canjes',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: seedBackground,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revisa tus movimientos recientes y mantente al tanto de tus puntos.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: seedBackground.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
          _PointsHeader(points: points),
          const SizedBox(height: 24),
          Expanded(
            child: AsyncValueWidget<List<Redemption>>(
              value: history,
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyHistory();
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _HistoryTile(
                      redemption: item,
                      formattedDate: formatter.format(item.createdAt.toLocal()),
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

class _PointsHeader extends StatelessWidget {
  const _PointsHeader({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [seedPrimary, seedSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: seedPrimary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 42),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Puntos disponibles',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                ' pts',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.redemption, required this.formattedDate});

  final Redemption redemption;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMoney = redemption.wasMoney;
    final color = isMoney ? seedSecondary : seedPrimary;
    final icon = isMoney ? Icons.payments_rounded : Icons.card_giftcard_rounded;
    final amountText = isMoney
        ? '-${NumberFormat.simpleCurrency(name: redemption.currency).format(redemption.moneySpent)}'
        : '-${redemption.pointsSpent} pts';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          redemption.productName,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(formattedDate),
        trailing: Text(
          amountText,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 70, color: seedPrimary),
          const SizedBox(height: 12),
          Text(
            'Aun no tienes canjes registrados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Canjea productos para visualizar tu historial de movimientos.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


