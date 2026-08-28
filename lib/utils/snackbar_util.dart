import 'package:flutter/material.dart';

import 'app_colors.dart';

class Variant {
  final int _value;

  const Variant._internal(this._value);

  @override
  String toString() => 'Variant.$_value';

  static const SUCCESS = Variant._internal(0);
  static const ERROR = Variant._internal(1);
  static const INFO = Variant._internal(2);
  static const WARNING = Variant._internal(3);
}

class SnackBarUtil {
  static const _backgroundColors = <Color>[
    AppColors.success,
    AppColors.danger,
    AppColors.info,
    AppColors.warning,
  ];

  static void showSnackBar(
    BuildContext scaffoldContext,
    String message,
    Variant variant, {
    Duration duration = const Duration(seconds: 3),
    SnackBarBehavior? behavior,
    String? actionLabel,
    Function? onAction,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(scaffoldContext);
    scaffoldMessenger.hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      duration: duration,
      behavior: behavior,
      backgroundColor: _backgroundColors[variant._value],
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel.toUpperCase(),
              onPressed: () => onAction.call(),
            )
          : null,
    );

    scaffoldMessenger.showSnackBar(snackBar);
  }
}
