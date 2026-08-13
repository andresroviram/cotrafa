import 'package:components/language_switcher.dart';
import 'package:components/layout/navigation_title.dart';
import 'package:components/performance_toggle.dart';
import 'package:components/theme_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:responsive_framework/responsive_framework.dart';

class NavigationAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NavigationAppBar({super.key, this.scaffoldDrawerKey, this.actions});
  final GlobalKey<ScaffoldState>? scaffoldDrawerKey;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveBreakpoints.of(context);
    return AppBar(
      forceMaterialTransparency: true,
      shape: LinearBorder.bottom(
        side: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
      title: const NavigationTitle(),
      leadingWidth: responsive.isDesktop ? 81 : null,
      leading: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.isDesktop ? 19 : 8,
          vertical: 8,
        ),
        child: IconButton(
          color: Colors.black,
          onPressed: () {
            // if (scaffoldDrawerKey?.currentState?.isDrawerOpen ?? false) {
            //   scaffoldDrawerKey?.currentState?.closeDrawer();
            // } else {
            scaffoldDrawerKey?.currentState?.openDrawer();
            // }
          },
          icon: Container(
            // height: 40,
            // width: 40,
            // decoration: BoxDecoration(
            //   shape: BoxShape.circle,
            //   color: Theme.of(context).colorScheme.background,
            // ),
            alignment: Alignment.center,
            child: Icon(Icons.menu, color: Theme.of(context).hintColor),
          ),
        ),
      ),
      centerTitle: true,
      actions:
          actions ??
          [
            PerformanceToggleButton(),
            const ThemeModeButton.icon(),
            const LanguageSwitcherButton(),
            const Gap(2),
          ],
    );
  }

  @override
  Size get preferredSize => AppBar().preferredSize;
}
