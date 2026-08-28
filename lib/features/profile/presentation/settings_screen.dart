import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../auth/data/biometric_auth_service.dart';
import '../../../core/services/offline_sync_queue_manager.dart';
import '../../../core/network/api_service.dart';
import '../../auth/presentation/login_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLockEnabled = false;
  String _savedPin = '1234';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lockEnabled = await BiometricAuthService.isLockEnabled();
    final pin = await BiometricAuthService.getSavedPin();
    setState(() {
      _isLockEnabled = lockEnabled;
      _savedPin = pin;
      _isLoading = false;
    });
  }

  Future<void> _toggleLock(bool enabled) async {
    await BiometricAuthService.setLockEnabled(enabled);
    if (!mounted) return;
    setState(() => _isLockEnabled = enabled);
    if (enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Bloqueo de seguridad activado (Face ID / PIN)'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔓 Bloqueo de seguridad desactivado'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showChangePinDialog() {
    final pinController = TextEditingController(text: _savedPin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.pin_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Cambiar Código PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa un nuevo PIN de 4 dígitos para proteger el acceso a la aplicación:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final newPin = pinController.text.trim();
              if (newPin.length == 4) {
                await BiometricAuthService.savePin(newPin);
                if (!mounted) return;
                setState(() => _savedPin = newPin);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Código PIN actualizado correctamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Guardar PIN', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Ajustes y Cuenta',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.person_rounded, size: 30, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ApiService.getCurrentUserName(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ApiService.getCurrentUserEmail(),
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '👔 Prestamista / Cobrador Activo',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section: Security & Biometrics (Optional)
                const Text(
                  'SEGURIDAD Y ACCESO (OPCIONAL)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: AppColors.softShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _isLockEnabled,
                        onChanged: _toggleLock,
                        activeColor: AppColors.accent,
                        title: const Text('Bloqueo de Seguridad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text(
                          'Solicitar PIN o Huella dactilar al entrar',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        secondary: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                      ),
                      if (_isLockEnabled) ...[
                        const Divider(height: 1),
                        ListTile(
                          onTap: _showChangePinDialog,
                          leading: const Icon(Icons.pin_rounded, color: AppColors.primary),
                          title: const Text('Cambiar Código PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text('PIN actual: ****', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section: Sync & Backend Network
                const Text(
                  'SINCRONIZACIÓN Y SERVIDOR',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: AppColors.softShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.sync_rounded, color: AppColors.primary, size: 26),
                    title: const Text('Conexión con el Servidor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      OfflineSyncQueueManager.pendingCount == 0
                          ? 'Todos los datos están sincronizados'
                          : '${OfflineSyncQueueManager.pendingCount} operaciones pendientes',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        await OfflineSyncQueueManager.processQueue();
                        setState(() {});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔄 Sincronización con el servidor completada'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      child: const Text('Sincronizar', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ApiService.logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
    );
  }
}

