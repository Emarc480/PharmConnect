import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/drug_provider.dart';
import '../../widgets/drug_card.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}