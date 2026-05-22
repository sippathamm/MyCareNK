import 'package:flutter/material.dart';

class LocaleProvider extends InheritedWidget {
  final Locale locale;
  final ValueChanged<Locale> onLocaleChange;

  const LocaleProvider({
    super.key,
    required this.locale,
    required this.onLocaleChange,
    required super.child,
  });

  static LocaleProvider of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleProvider>()!;

  @override
  bool updateShouldNotify(LocaleProvider old) => locale != old.locale;
}
