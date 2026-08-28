import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config.dart';
import '../../../core/themes/app_colors.dart';
import '../data/biometric_auth_service.dart';


class BiometricLockScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final bool isModal;

  const BiometricLockScreen({
    Key? key,
    this.onSuccess,
    this.isModal = false,
  }) : super(key: key);

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  String _enteredPin = '';
  bool _hasError = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkHardwareAndPromptBiometrics();
  }

  Future<void> _checkHardwareAndPromptBiometrics() async {
    final canBio = await BiometricAuthService.canCheckBiometrics();
    setState(() => _canCheckBiometrics = canBio);

    // Auto-prompt Face ID / Touch ID / Fingerprint on screen open
    if (canBio) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _triggerBiometrics();
      });
    }
  }

  Future<void> _triggerBiometrics() async {
    final success = await BiometricAuthService.authenticateWithBiometrics(
      reason: 'Desbloquear Prestamistas Pro RD',
    );
    if (success && mounted) {
      _unlockSuccess();
    }
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _hasError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _hasError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final valid = await BiometricAuthService.verifyPin(_enteredPin);
    if (valid && mounted) {
      _unlockSuccess();
    } else {
      setState(() {
        _hasError = true;
        _enteredPin = '';
      });
    }
  }

  void _unlockSuccess() {
    BiometricAuthService.markUnlocked();
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else if (widget.isModal) {
      Navigator.pop(context, true);
    } else {
      context.go('/dashboard');
    }
  }

  Widget _buildKeypadButton(String label, {VoidCallback? onTap, IconData? icon}) {
    return InkWell(
      onTap: onTap ?? () => _onKeyPress(label),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: AppColors.softShadow,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: AppColors.accent, size: 28)
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Header Brand
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              AppConfig.appName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              _hasError ? '❌ Código PIN incorrecto. Intenta de nuevo.' : 'Ingresa tu PIN o usa Face ID / Huella',
              style: TextStyle(
                fontSize: 13,
                fontWeight: _hasError ? FontWeight.bold : FontWeight.normal,
                color: _hasError ? AppColors.danger : AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 30),

            // 4 Pin Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final bool isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.accent : Colors.grey.shade300,
                    border: Border.all(
                      color: isFilled ? AppColors.accent : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const Spacer(),

            // Keypad Grid 3x4
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('1'),
                      _buildKeypadButton('2'),
                      _buildKeypadButton('3'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('4'),
                      _buildKeypadButton('5'),
                      _buildKeypadButton('6'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('7'),
                      _buildKeypadButton('8'),
                      _buildKeypadButton('9'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric button
                      _buildKeypadButton(
                        '',
                        icon: Icons.fingerprint_rounded,
                        onTap: _canCheckBiometrics ? _triggerBiometrics : null,
                      ),
                      _buildKeypadButton('0'),
                      // Backspace button
                      _buildKeypadButton(
                        '',
                        icon: Icons.backspace_outlined,
                        onTap: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Switch to full login option
            if (widget.isModal)
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
              )
            else
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.login_rounded, size: 16, color: AppColors.accent),
                label: const Text('Iniciar sesión con correo', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
