import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../radar/presentation/pages/radar_s_plus_page.dart';
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
    RadarSPlusPage(),
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
                  label: 'ÓRDENES',
                  activeColor: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBrutalistNavTab(
                  index: 1,
                  icon: Icons.radar,
                  label: 'RADAR S+',
                  activeColor: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBrutalistNavTab(
                  index: 2,
                  icon: Icons.tune,
                  label: 'AJUSTES',
                  activeColor: AppColors.gold,
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
    required Color activeColor,
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
                color: activeColor,
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
              size: 16,
              color: AppColors.ink,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 11,
                color: AppColors.ink,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

