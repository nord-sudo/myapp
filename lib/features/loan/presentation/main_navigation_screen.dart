import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../auth/data/biometric_auth_service.dart';
import '../../auth/presentation/biometric_lock_screen.dart';
import 'dashboard_screen.dart';
import '../../kyc/presentation/customer_list_screen.dart';
import 'loan_list_screen.dart';
import '../../profile/presentation/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLockShowing = false;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CustomerListScreen(),
    LoanListScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndPromptBiometricLock();
    }
  }

  Future<void> _checkAndPromptBiometricLock() async {
    if (_isLockShowing) return;
    final shouldPrompt = await BiometricAuthService.shouldPromptLock();
    if (shouldPrompt && mounted) {
      setState(() => _isLockShowing = true);
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const BiometricLockScreen(isModal: true),
        ),
      );
      if (result == true) {
        BiometricAuthService.markUnlocked();
      }
      if (mounted) {
        setState(() => _isLockShowing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded, color: AppColors.primary),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded),
                activeIcon: Icon(Icons.people_alt_rounded, color: AppColors.primary),
                label: 'Clientes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                activeIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                label: 'Préstamos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                activeIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
                label: 'Ajustes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}


