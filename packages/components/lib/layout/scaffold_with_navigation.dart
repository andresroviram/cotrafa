import 'package:components/layout/navigation_appbar.dart';
import 'package:components/theme_button.dart';
import 'package:core/enum/navigation_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';
import 'package:responsive_framework/responsive_framework.dart';

const _drawerLogoWidth = 230.0;

String _resolveDrawerLogoPath(
  BuildContext context, {
  required String logoPath,
  String? logoDarkPath,
}) {
  return Theme.of(context).brightness == Brightness.dark
      ? (logoDarkPath ?? logoPath)
      : logoPath;
}

String _sfSymbolForNavigationItem(NavigationItem item) {
  return switch (item) {
    NavigationItem.home => 'square.grid.2x2',
    NavigationItem.wishlist => 'heart',
    NavigationItem.settings => 'gearshape',
    NavigationItem.funds => 'wallet.bifold',
    NavigationItem.transactions => 'list.bullet.rectangle.portrait',
  };
}

class ScaffoldWithNavigation extends StatelessWidget {
  const ScaffoldWithNavigation({
    super.key,
    required this.navigationShell,
    required this.logoPath,
    this.logoDarkPath,
    required this.navigationItems,
    this.appBarActions,
  });

  final StatefulNavigationShell navigationShell;
  final String logoPath;
  final String? logoDarkPath;
  final List<NavigationItem> navigationItems;
  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    final breakpoint = ResponsiveBreakpoints.of(context).breakpoint;
    final GlobalKey<ScaffoldState> scaffoldDrawerKey =
        GlobalKey<ScaffoldState>();
    return switch (breakpoint.name) {
      MOBILE => _ScaffoldWithNavigationBar(
        navigationShell,
        scaffoldDrawerKey,
        logoPath: logoPath,
        logoDarkPath: logoDarkPath,
        navigationItems: navigationItems,
        appBarActions: appBarActions,
      ),
      TABLET => _ScaffoldWithDrawer(
        navigationShell,
        scaffoldDrawerKey,
        logoPath: logoPath,
        logoDarkPath: logoDarkPath,
        navigationItems: navigationItems,
        appBarActions: appBarActions,
      ),
      (_) => _ScaffoldWithNavigationRail(
        navigationShell,
        scaffoldDrawerKey,
        logoPath: logoPath,
        logoDarkPath: logoDarkPath,
        navigationItems: navigationItems,
        appBarActions: appBarActions,
      ),
    };
  }
}

class _ScaffoldWithNavigationRail extends StatelessWidget {
  const _ScaffoldWithNavigationRail(
    this.navigationShell,
    this.scaffoldDrawerKey, {
    required this.logoPath,
    this.logoDarkPath,
    required this.navigationItems,
    this.appBarActions,
  });

  final StatefulNavigationShell navigationShell;
  final GlobalKey<ScaffoldState>? scaffoldDrawerKey;
  final String logoPath;
  final String? logoDarkPath;
  final List<NavigationItem> navigationItems;
  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: NavigationAppBar(
        scaffoldDrawerKey: scaffoldDrawerKey,
        actions: appBarActions,
      ),
      key: scaffoldDrawerKey,
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(border: Border()),
              margin: EdgeInsets.zero,
              child: Center(
                child: Image.asset(
                  _resolveDrawerLogoPath(
                    context,
                    logoPath: logoPath,
                    logoDarkPath: logoDarkPath,
                  ),
                  width: _drawerLogoWidth,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // const SizedBox(height: 16),
            Expanded(
              child: _NavigationDrawer(
                navigationShell: navigationShell,
                expand: true,
                navigationItems: navigationItems,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: ThemeModeButton.outlined(),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Column(
            children: [
              const SizedBox(height: 15),
              Expanded(
                child: _NavigationRail(
                  navigationShell: navigationShell,
                  expand: false,
                  navigationItems: navigationItems,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: ThemeModeButton.icon(),
              ),
            ],
          ),
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _ScaffoldWithDrawer extends StatelessWidget {
  const _ScaffoldWithDrawer(
    this.navigationShell,
    this.scaffoldDrawerKey, {
    required this.logoPath,
    this.logoDarkPath,
    required this.navigationItems,
    this.appBarActions,
  });

  final StatefulNavigationShell navigationShell;
  final GlobalKey<ScaffoldState>? scaffoldDrawerKey;
  final String logoPath;
  final String? logoDarkPath;
  final List<NavigationItem> navigationItems;
  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavigationAppBar(
        scaffoldDrawerKey: scaffoldDrawerKey,
        actions: appBarActions,
      ),
      body: navigationShell,
      key: scaffoldDrawerKey,
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(border: Border()),
              margin: EdgeInsets.zero,
              child: Center(
                child: Image.asset(
                  _resolveDrawerLogoPath(
                    context,
                    logoPath: logoPath,
                    logoDarkPath: logoDarkPath,
                  ),
                  width: _drawerLogoWidth,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Expanded(
              child: _NavigationRail(
                navigationShell: navigationShell,
                expand: true,
                navigationItems: navigationItems,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: ThemeModeButton.outlined(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.navigationShell,
    required this.expand,
    required this.navigationItems,
  });

  final StatefulNavigationShell navigationShell;
  final bool expand;
  final List<NavigationItem> navigationItems;

  @override
  Widget build(BuildContext context) {
    final NavigationRailLabelType labelType = expand
        ? NavigationRailLabelType.none
        : NavigationRailLabelType.all;
    final theme = Theme.of(context);
    return NavigationRail(
      extended: expand,
      selectedIndex: navigationShell.currentIndex,
      unselectedLabelTextStyle: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
      ),
      selectedLabelTextStyle: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index != navigationShell.currentIndex,
        );
      },
      destinations: [
        for (final item in navigationItems)
          NavigationRailDestination(
            icon: Icon(item.iconData),
            label: Text(item.label.tr()),
          ),
      ],
      labelType: labelType,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    );
  }
}

class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({
    required this.navigationShell,
    required this.expand,
    required this.navigationItems,
  });

  final StatefulNavigationShell navigationShell;
  final bool expand;
  final List<NavigationItem> navigationItems;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index != navigationShell.currentIndex,
        );
      },
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            'dashboard'.tr(),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final item in navigationItems)
          NavigationDrawerDestination(
            icon: Icon(item.iconData),
            label: Text(item.label.tr()),
          ),
        // const Padding(
        //   padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
        //   child: Divider(),
        // ),
      ],
    );
  }
}

class _ScaffoldWithNavigationBar extends StatelessWidget {
  const _ScaffoldWithNavigationBar(
    this.navigationShell,
    this.scaffoldDrawerKey, {
    required this.logoPath,
    this.logoDarkPath,
    required this.navigationItems,
    this.appBarActions,
  });

  final StatefulNavigationShell navigationShell;
  final GlobalKey<ScaffoldState>? scaffoldDrawerKey;
  final String logoPath;
  final String? logoDarkPath;
  final List<NavigationItem> navigationItems;
  final List<Widget>? appBarActions;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index != navigationShell.currentIndex,
    );
  }

  Widget _buildMaterialNavigationBar() {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _onDestinationSelected,
      destinations: [
        for (final item in navigationItems)
          NavigationDestination(
            icon: Icon(item.iconData),
            label: item.label.tr(),
          ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return NativeGlassNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onDestinationSelected,
        tabs: [
          for (final item in navigationItems)
            NativeGlassNavBarItem(
              label: item.label.tr(),
              symbol: _sfSymbolForNavigationItem(item),
            ),
        ],
      );
    }

    return _buildMaterialNavigationBar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavigationAppBar(
        scaffoldDrawerKey: scaffoldDrawerKey,
        actions: appBarActions,
      ),
      key: scaffoldDrawerKey,
      body: navigationShell,
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(border: Border()),
              margin: EdgeInsets.zero,
              child: Center(
                child: Image.asset(
                  _resolveDrawerLogoPath(
                    context,
                    logoPath: logoPath,
                    logoDarkPath: logoDarkPath,
                  ),
                  width: _drawerLogoWidth,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Expanded(
              child: _NavigationRail(
                navigationShell: navigationShell,
                expand: true,
                navigationItems: navigationItems,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: ThemeModeButton.outlined(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}
