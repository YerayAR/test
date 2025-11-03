import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../config/theme.dart';
import '../../common/widgets/async_value_widget.dart';
import '../models/wallet_summary.dart';
import '../models/wallet_transaction.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _amountController = TextEditingController(text: '25.00');
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(walletSummaryProvider);
    ref.invalidate(walletTransactionsProvider);
    await ref.read(walletSummaryProvider.future);
    await ref.read(walletTransactionsProvider.future);
  }

  Future<void> _startDeposit(String currency) async {
    final rawValue = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(rawValue);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa un monto valido.')),
        );
      }
      return;
    }
    setState(() => _submitting = true);
    final depositService = ref.read(walletDepositServiceProvider);
    try {
      final baseUri = Uri.base.removeFragment();
      final successUrl = _buildCallbackUrl(baseUri, 'success');
      final cancelUrl = _buildCallbackUrl(baseUri, 'cancel');
      final session = await depositService.createDeposit(
        amount: amount,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );
      final launched = await launchUrlString(
        session.url,
        mode: kIsWeb ? LaunchMode.externalApplication : LaunchMode.platformDefault,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la pasarela de pago.')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesion de pago creada. Completa el pago en la ventana abierta.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la recarga: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _buildCallbackUrl(Uri base, String status) {
    final params = Map<String, String>.from(base.queryParameters);
    params['checkout_status'] = status;
    return base.replace(queryParameters: params).toString();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(walletSummaryProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AsyncValueWidget<WalletSummary>(
                value: summaryAsync,
                data: (summary) => _BalanceCard(summary: summary),
              ),
              const SizedBox(height: 24),
              summaryAsync.when(
                data: (summary) => _DepositCard(
                  controller: _amountController,
                  isSubmitting: _submitting,
                  onSubmit: () => _startDeposit(summary.currency),
                  currency: summary.currency,
                ),
                loading: () => const _DepositCardSkeleton(),
                error: (err, stack) => _DepositError(message: err.toString()),
              ),
              const SizedBox(height: 32),
              Text(
                'Movimientos recientes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: seedBackground,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              AsyncValueWidget<List<WalletTransaction>>(
                value: transactionsAsync,
                data: (items) => items.isEmpty
                    ? const _EmptyTransactions()
                    : Column(
                        children: items
                            .map((tx) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TransactionTile(transaction: tx),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(name: summary.currency);
    return Container(
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
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 48),
              SizedBox(width: 16),
              Text(
                'Mi Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatter.format(summary.balance),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actualizado: ${DateFormat('dd/MM/yyyy HH:mm').format(summary.updatedAt.toLocal())}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
          ),
        ],
      ),
    );
  }
}

class _DepositCard extends StatelessWidget {
  const _DepositCard({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    required this.currency,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(name: currency);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recargar saldo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ingresa el monto que deseas recargar. Seras redirigido a Stripe para completar el pago de forma segura.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: seedBackground.withOpacity(0.7)),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto ($currency)',
                prefixIcon: const Icon(Icons.payments_rounded),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: const Text('Recargar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepositCardSkeleton extends StatelessWidget {
  const _DepositCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _DepositError extends StatelessWidget {
  const _DepositError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: seedSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No se pudo cargar la informacion de la wallet: $message',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: seedSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(name: transaction.currency);
    final amountText = formatter.format(transaction.amount.abs());
    final isPositive = transaction.amount >= 0;
    final color = isPositive ? seedPrimary : seedSecondary;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final titlePrefix = transaction.type;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          '$titlePrefix${transaction.description.isNotEmpty ? ' • ${transaction.description}' : ''}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy, HH:mm').format(transaction.createdAt.toLocal()),
        ),
        trailing: Text(
          '${isPositive ? '+' : '-'}$amountText',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.receipt_long_outlined, size: 64, color: seedPrimary),
        const SizedBox(height: 12),
        Text(
          'Sin movimientos todavia',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Cuando recargues saldo o realices canjes veras los movimientos en esta lista.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
