import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';

class CountriesGridShimmer extends StatelessWidget {
  const CountriesGridShimmer({
    super.key,
    this.itemCount = 6,
    this.gridDelegate = _mobileDelegate,
    this.padding = const EdgeInsets.all(16),
  });

  final int itemCount;
  final SliverGridDelegate gridDelegate;
  final EdgeInsets padding;

  static const _mobileDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.75,
  );

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectivePadding = padding;
        final availableWidth =
            constraints.maxWidth -
            effectivePadding.left -
            effectivePadding.right;

        final maxExtent =
            gridDelegate is SliverGridDelegateWithMaxCrossAxisExtent
            ? (gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent)
                  .maxCrossAxisExtent
            : null;
        final fixedCount =
            gridDelegate is SliverGridDelegateWithFixedCrossAxisCount
            ? (gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
                  .crossAxisCount
            : null;

        final double crossAxisSpacing;
        final double mainAxisSpacing;
        final double childAspectRatio;
        if (gridDelegate is SliverGridDelegateWithMaxCrossAxisExtent) {
          final d = gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
          crossAxisSpacing = d.crossAxisSpacing;
          mainAxisSpacing = d.mainAxisSpacing;
          childAspectRatio = d.childAspectRatio;
        } else if (gridDelegate is SliverGridDelegateWithFixedCrossAxisCount) {
          final d = gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
          crossAxisSpacing = d.crossAxisSpacing;
          mainAxisSpacing = d.mainAxisSpacing;
          childAspectRatio = d.childAspectRatio;
        } else {
          crossAxisSpacing = 0;
          mainAxisSpacing = 0;
          childAspectRatio = 1;
        }

        final int crossCount;
        if (maxExtent != null) {
          crossCount = (availableWidth / maxExtent).ceil().clamp(1, 999);
        } else {
          crossCount = fixedCount ?? 2;
        }

        final itemWidth =
            (availableWidth - crossAxisSpacing * (crossCount - 1)) / crossCount;
        final itemHeight = itemWidth / childAspectRatio;

        return Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: effectivePadding,
              child: Wrap(
                spacing: crossAxisSpacing,
                runSpacing: mainAxisSpacing,
                children: List.generate(
                  itemCount,
                  (_) => SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: const _CountryCardSkeleton(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountryCardSkeleton extends StatelessWidget {
  const _CountryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(color: color),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                _ShimmerInfoRow(color: color),
                const Gap(6),
                _ShimmerInfoRow(color: color, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerInfoRow extends StatelessWidget {
  const _ShimmerInfoRow({required this.color, this.width = 100});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(6),
        Container(
          width: width,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
