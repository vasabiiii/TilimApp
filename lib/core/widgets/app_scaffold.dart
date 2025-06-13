import 'package:flutter/material.dart';
import 'app_bottom_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppScaffold({
    Key? key,
    required this.body,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: body,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: selectedIndex,
        onTap: onTap,
      ),
    );
  }
} 