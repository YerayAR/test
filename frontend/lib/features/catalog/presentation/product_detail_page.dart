import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../auth/providers/auth_controller.dart';
import '../../common/widgets/async_value_widget.dart';
import '../../history/providers/history_provider.dart';
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
        final canRedeem = auth.user != null && auth.user!.points >= product.pointsCost;
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
                                authPoints: auth.user?.points ?? 0,
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
                              authPoints: auth.user?.points ?? 0,
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
    required this.canRedeem,
    required this.isRedeeming,
    required this.feedback,
    required this.onRedeem,
  });

  final Product product;
  final int authPoints;
  final bool canRedeem;
  final bool isRedeeming;
  final String? feedback;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  icon: Icons.stars_rounded,
                  label: 'Costo',
                  value: '${product.pointsCost} pts',
                ),
                const SizedBox(width: 12),
                _InfoBadge(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Tus puntos',
                  value: '$authPoints pts',
                ),
              ],
            ),
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: canRedeem ? seedPrimary.withOpacity(0.1) : Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    canRedeem ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: canRedeem ? seedPrimary : Colors.redAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      canRedeem
                          ? 'Tienes puntos suficientes para canjear este producto.'
                          : 'No cuentas con puntos suficientes. Sigue acumulando para canjearlo.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: canRedeem ? seedPrimary : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: canRedeem && !isRedeeming ? onRedeem : null,
              icon: isRedeeming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.card_giftcard_rounded),
              label: const Text('Canjear producto'),
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
                        color: seedPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: seedPrimary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feedback!,
                              style: theme.textTheme.bodyMedium?.copyWith(color: seedPrimary),
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
  const _InfoBadge({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: seedPrimary),
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
                color: seedPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
