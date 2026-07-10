import 'package:flutter/material.dart';
import '../models/drug.dart';
import '../core/theme/app_theme.dart';

class DrugCard extends StatelessWidget {
  final Drug drug;
  final VoidCallback? onTap;

  const DrugCard({super.key, required this.drug, this.onTap});
}