import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/offline_sync_queue_manager.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../auth/data/biometric_auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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
    if (mounted) {
      setState(() {
        _isLockEnabled = lockEnabled;
        _savedPin = pin;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLock(bool enabled) async {
    await BiometricAuthService.setLockEnabled(enabled);
    if (!mounted) return;
    setState(() => _isLockEnabled = enabled);
    CustomToast.show(
      context,
      enabled ? '🔒 Bloqueo de seguridad activado (Face ID / PIN)' : '🔓 Bloqueo de seguridad desactivado',
      type: enabled ? ToastType.success : ToastType.info,
    );
  }

  void _showChangePinDialog() {
    final pinController = TextEditingController(text: _savedPin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.pin_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Cambiar Código PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
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
                CustomToast.show(context, 'Código PIN actualizado correctamente', type: ToastType.success);
              } else {
                CustomToast.show(context, 'El PIN debe tener exactamente 4 dígitos', type: ToastType.warning);
              }
            },
            child: const Text('Guardar PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmCleanData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Limpiar Base de Datos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          '¿Deseas eliminar todos los datos de prueba y vaciar la base de datos local para dejar todo completamente limpio?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.clearAllLocalData();
              if (mounted) {
                CustomToast.show(context, 'Base de datos limpiada completamente', type: ToastType.success);
                setState(() {});
              }
            },
            child: const Text('Limpiar Todo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas salir y cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              ApiService.logout();
              context.go('/login');
            },
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Ajustes y Configuración',
        subtitle: 'Perfil y Seguridad PrestaRD',
        showBackButton: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Sección 1: Perfil de Usuario
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

                // Sección 2: Seguridad y Acceso
                const Text(
                  'SEGURIDAD Y ACCESO',
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
                          title: const Text('Cambiar Código PIN de Respaldo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text('PIN actual: ****', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sección 3: Sincronización y Servidor
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
                    title: const Text('Cola de Operaciones Offline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      OfflineSyncQueueManager.pendingCount == 0
                          ? '0 operaciones pendientes (Al día)'
                          : '${OfflineSyncQueueManager.pendingCount} operaciones en cola pendientes de subir',
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
                          CustomToast.show(context, 'Sincronización con el servidor ejecutada', type: ToastType.success);
                        }
                      },
                      child: const Text('Sincronizar', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // App info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Versión de PrestaRD', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('v1.0.0+1 (Producción RD)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Limpiar Datos de Prueba
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange.shade400, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _confirmCleanData,
                    icon: Icon(Icons.cleaning_services_rounded, color: Colors.orange.shade700, size: 18),
                    label: Text(
                      'Limpiar Base de Datos Local',
                      style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sección 4: Cerrar Sesión
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Préstamos'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/clients');
              break;
            case 2:
              context.go('/loans');
              break;
            case 3:
              break;
          }
        },
      ),
    );
  }
}
