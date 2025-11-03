import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../common/widgets/async_value_widget.dart';
import '../models/product.dart';
import '../providers/catalog_provider.dart';
import 'widgets/product_card.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catalogo de recompensas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: seedBackground,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Descubre productos que puedes canjear con tus puntos acumulados.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: seedBackground.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: AsyncValueWidget<List<Product>>(
              value: products,
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyCatalog();
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 1000;
                    final crossAxisCount = isWide
                        ? 4
                        : constraints.maxWidth > 700
                            ? 3
                            : constraints.maxWidth > 480
                                ? 2
                                : 1;
                    final childAspectRatio = isWide ? 0.8 : 0.9;
                    return GridView.builder(
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final product = items[index];
                        return ProductCard(
                          product: product,
                          onTap: () => context.go('/catalog/'),
                        );
                      },
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

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_rounded, size: 72, color: seedPrimary),
          const SizedBox(height: 12),
          Text(
            'Aun no hay productos disponibles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Vuelve pronto para descubrir nuevas recompensas.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
