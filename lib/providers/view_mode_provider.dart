import 'package:flutter/foundation.dart';

enum ViewMode { customer, staff }

class ViewModeProvider extends ChangeNotifier {
  ViewMode _mode = ViewMode.customer;

  ViewMode get mode => _mode;
  bool get isStaff => _mode == ViewMode.staff;

  void switchTo(ViewMode mode) {
    _mode = mode;
    notifyListeners();
  }
}
