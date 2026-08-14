enum AppFlavor { dev, qa, prod }

final AppFlavor kFlavor = AppFlavor.values.byName(
  const String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
);

extension AppFlavorX on AppFlavor {
  String get label => switch (this) {
    AppFlavor.dev => 'DEV',
    AppFlavor.qa => 'QA',
    AppFlavor.prod => 'PROD',
  };

  bool get showBanner => this != AppFlavor.prod;

  int get bannerColor => switch (this) {
    AppFlavor.dev => 0xFF00856A,
    AppFlavor.qa => 0xFFFF9800,
    AppFlavor.prod => 0xFFF44336,
  };
}
