import 'package:flutter/material.dart';
import '../state/qr_app_controller.dart';

class QrControllerScope extends InheritedNotifier<QrAppController> {
  const QrControllerScope({
    super.key,
    required QrAppController controller,
    required super.child,
  }) : super(notifier: controller);

  static QrAppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<QrControllerScope>();
    assert(scope != null, 'QrControllerScope not found in context');
    return scope!.notifier!;
  }
}
