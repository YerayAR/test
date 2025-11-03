import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../auth/providers/auth_controller.dart';
import '../../common/widgets/async_value_widget.dart';
import '../../history/providers/history_provider.dart';
import '../../wallet/models/wallet_summary.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../models/product.dart';
import '../providers/catalog_provider.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  bool _isRedeeming = false;
  String? _feedback;

  Future<void> _handleRedeem(Product product) async {
    setState(() {
      _isRedeeming = true;
      _feedback = null;
    });
    try {
      await ref.read(redeemProductProvider)(product.id);
      ref.invalidate(walletSummaryProvider);
      ref.invalidate(walletTransactionsProvider);
      setState(() {
        _feedback = 'Canje realizado correctamente.';
      });
    } catch (error) {
      setState(() {
        _feedback = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRedeeming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productValue = ref.watch(productBySlugProvider(widget.slug));
    final auth = ref.watch(authControllerProvider);

    return AsyncValueWidget<Product>(
      value: productValue,
      data: (product) {
        final walletSummary = walletSummaryAsync.maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
        final walletLoading = walletSummaryAsync.isLoading;
        final walletError = walletSummaryAsync.hasError;
        final userPoints = auth.user?.points ?? 0;
        final pointsCost = product.pointsCost ?? 0;
        final moneyCost = product.priceAmount ?? 0;
        final canRedeem = product.requiresPoints
            ? auth.user != null && product.pointsCost != null && userPoints >= pointsCost
            : walletSummary != null && product.priceAmount != null && walletSummary.balance >= moneyCost;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _ProductPreview(product: product)),
                            const SizedBox(width: 32),
                            Expanded(
                              child: _ProductInfo(
                                product: product,
                                authPoints: userPoints,
                                walletSummary: walletSummary,
                                walletLoading: walletLoading,
                                walletError: walletError,
                                canRedeem: canRedeem,
                                isRedeeming: _isRedeeming,
                                feedback: _feedback,
                                onRedeem: () => _handleRedeem(product),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _ProductPreview(product: product),
                            const SizedBox(height: 24),
                            _ProductInfo(
                              product: product,
                              authPoints: userPoints,
                              walletSummary: walletSummary,
                              walletLoading: walletLoading,
                              walletError: walletError,
                              canRedeem: canRedeem,
                              isRedeeming: _isRedeeming,
                              feedback: _feedback,
                              onRedeem: () => _handleRedeem(product),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [seedPrimary, seedSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: product.imageUrl != null
                  ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.white.withOpacity(0.2),
                      child: const Center(
                        child: Icon(Icons.photo, color: Colors.white, size: 48),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Chip(
            backgroundColor: Colors.white.withOpacity(0.9),
            avatar: const Icon(Icons.category, size: 18, color: seedPrimary),
            label: Text(
              product.category,
              style: const TextStyle(color: seedPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({
    required this.product,
    required this.authPoints,
    required this.walletSummary,
    required this.walletLoading,
    required this.walletError,
    required this.canRedeem,
    required this.isRedeeming,
    required this.feedback,
    required this.onRedeem,
  });

  final Product product;
  final int authPoints;
  final WalletSummary? walletSummary;
  final bool walletLoading;
  final bool walletError;
  final bool canRedeem;
  final bool isRedeeming;
  final String? feedback;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requiresMoney = product.requiresMoney;
    final highlightColor = requiresMoney ? seedSecondary : seedPrimary;
    final currencyFormatter = NumberFormat.simpleCurrency(
      name: walletSummary?.currency ?? 'EUR',
    );
    final String costValue = product.costLabel;
    final String balanceValue = requiresMoney
        ? walletSummary != null
            ? currencyFormatter.format(walletSummary!.balance)
            : walletLoading
                ? 'Actualizando...'
                : walletError
                    ? 'No disponible'
                    : '--'
        : ' pts';
    final double moneyCost = product.priceAmount ?? 0;
    final double missingAmount = walletSummary != null
        ? (moneyCost - walletSummary!.balance).clamp(0, double.maxFinite)
        : 0;

    String statusMessage;
    Color statusColor;
    Color containerColor;
    IconData statusIcon;

    if (requiresMoney) {
      if (walletLoading) {
        statusMessage = 'Consultando tu saldo disponible...';
        statusColor = seedBackground;
        containerColor = seedBackground.withOpacity(0.08);
        statusIcon = Icons.hourglass_bottom;
      } else if (walletSummary == null) {
        statusMessage = walletError
            ? 'No pudimos obtener tu saldo. Actualiza la pagina e intentalo nuevamente.'
            : 'Consulta tu saldo para canjear con dinero.';
        statusColor = Colors.redAccent;
        containerColor = Colors.redAccent.withOpacity(0.08);
        statusIcon = Icons.warning_amber_rounded;
      } else if (canRedeem) {
        statusMessage = 'Tienes saldo suficiente en tu wallet.';
        statusColor = highlightColor;
        containerColor = highlightColor.withOpacity(0.12);
        statusIcon = Icons.check_circle;
      } else {
        final missingText = currencyFormatter.format(missingAmount);
        statusMessage = 'Saldo insuficiente en tu wallet. Te faltan .';
        statusColor = Colors.redAccent;
        containerColor = Colors.redAccent.withOpacity(0.08);
        statusIcon = Icons.warning_amber_rounded;
      }
    } else {
      if (canRedeem) {
        statusMessage = 'Tienes puntos suficientes para canjear este producto.';
        statusColor = highlightColor;
        containerColor = highlightColor.withOpacity(0.1);
        statusIcon = Icons.check_circle;
      } else {
        statusMessage =
            'No cuentas con puntos suficientes. Sigue acumulando para canjearlo.';
        statusColor = Colors.redAccent;
        containerColor = Colors.redAccent.withOpacity(0.08);
        statusIcon = Icons.warning_amber_rounded;
      }
    }

    final bool isButtonEnabled =
        !isRedeeming && canRedeem && (!requiresMoney || walletSummary != null);
    final IconData actionIcon =
        requiresMoney ? Icons.payments_rounded : Icons.card_giftcard_rounded;
    final String actionLabel =
        requiresMoney ? 'Canjear con saldo' : 'Canjear producto';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Descripcion',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              product.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _InfoBadge(
                  icon: requiresMoney ? Icons.payments_outlined : Icons.stars_rounded,
                  label: 'Costo',
                  value: costValue,
                  highlightColor: highlightColor,
                ),
                const SizedBox(width: 12),
                _InfoBadge(
                  icon: requiresMoney
                      ? Icons.account_balance_wallet_rounded
                      : Icons.account_balance_wallet_outlined,
                  label: requiresMoney ? 'Saldo wallet' : 'Tus puntos',
                  value: balanceValue,
                  highlightColor: highlightColor,
                ),
              ],
            ),
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isButtonEnabled ? onRedeem : null,
              icon: isRedeeming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(actionIcon),
              label: Text(actionLabel),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: feedback == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(feedback),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: highlightColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: highlightColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feedback!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: highlightColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.highlightColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlightColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: highlightColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: highlightColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
