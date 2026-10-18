import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.ink, width: 3.0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildBrutalistNavTab(
                  index: 0,
                  icon: Icons.candlestick_chart,
                  label: 'INICIO SPOT',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildBrutalistNavTab(
                  index: 1,
                  icon: Icons.tune,
                  label: 'AJUSTES & LOGS',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrutalistNavTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        height: 48,
        decoration: isSelected
            ? AppColors.brutalistBox(
                color: AppColors.gold,
                borderWidth: 2.5,
                shadowOffset: 4.0,
              )
            : AppColors.brutalistCell(
                color: AppColors.surface,
                borderWidth: 2.0,
              ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.ink,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 12,
                color: AppColors.ink,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
