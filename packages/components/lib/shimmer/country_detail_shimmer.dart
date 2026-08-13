import 'package:components/shimmer/country_detail_shimmer_body.dart';
import 'package:components/shimmer/country_detail_shimmer_title.dart';
import 'package:flutter/material.dart';

class CountryDetailShimmer extends StatelessWidget {
  const CountryDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              title: CountryDetailShimmerTitle(),
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 72, bottom: 28),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(child: CountryDetailShimmerBody()),
          ),
        ],
      ),
    );
  }
}
