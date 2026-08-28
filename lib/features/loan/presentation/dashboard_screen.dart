import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/network/api_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../kyc/presentation/customer_form_screen.dart';
import 'loan_form_screen.dart';
import 'payment_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getDashboardMetrics();
    if (mounted) {
      setState(() {
        _metrics = data;
        _isLoading = false;
      });
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              ApiService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Salir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double collectedToday = (_metrics['collected_today'] is num)
        ? (_metrics['collected_today'] as num).toDouble()
        : 0.0;
    final double pendingToday = (_metrics['pending_today'] is num)
        ? (_metrics['pending_today'] as num).toDouble()
        : 0.0;
    final double totalPortfolio = (_metrics['total_portfolio_balance'] is num)
        ? (_metrics['total_portfolio_balance'] as num).toDouble()
        : 0.0;
    final int activeLoans = _metrics['active_loans_count'] ?? 0;
    final double overdueAmount = (_metrics['overdue_amount'] is num)
        ? (_metrics['overdue_amount'] as num).toDouble()
        : 0.0;
    final int overdueCustomers = _metrics['overdue_customers_count'] ?? 0;
    final List<dynamic> recentPayments = (_metrics['recent_payments'] is List)
        ? _metrics['recent_payments']
        : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 70,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Control de Préstamos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'República Dominicana (RD\$)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
            tooltip: 'Actualizar',
            onPressed: _loadMetrics,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 24),
            tooltip: 'Cerrar Sesión',
            onPressed: _confirmLogout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadMetrics,
              color: AppColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Top User Profile Card ─────────────────────────────────
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
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFFF1F5F9),
                            child: Icon(Icons.person_rounded, size: 28, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cobrador: ${ApiService.getCurrentUserName()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ApiService.getCurrentUserEmail(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.wifi_rounded, color: AppColors.success, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Conectado',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── 2x2 Metric Cards Grid ─────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Cobrado Hoy',
                            amount: CurrencyFormatter.formatDOP(collectedToday),
                            amountColor: AppColors.success,
                            icon: Icons.attach_money_rounded,
                            iconColor: AppColors.success,
                            iconBg: AppColors.successBg,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Falta por Cobra...',
                            amount: CurrencyFormatter.formatDOP(pendingToday),
                            amountColor: AppColors.warning,
                            icon: Icons.access_time_rounded,
                            iconColor: AppColors.warning,
                            iconBg: AppColors.warningBg,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Dinero Prestado',
                            amount: CurrencyFormatter.formatDOP(totalPortfolio),
                            amountColor: AppColors.textPrimary,
                            subtitle: '$activeLoans Préstamos activos',
                            icon: Icons.account_balance_rounded,
                            iconColor: AppColors.primary,
                            iconBg: const Color(0xFFF1F5F9),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Atrasos',
                            amount: CurrencyFormatter.formatDOP(overdueAmount),
                            amountColor: AppColors.danger,
                            subtitle: '$overdueCustomers Clientes atrasados',
                            icon: Icons.warning_amber_rounded,
                            iconColor: AppColors.danger,
                            iconBg: AppColors.dangerBg,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ─── Section: Opciones Rápidas ─────────────────────────────
                    const Text(
                      'Opciones Rápidas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickOptionCard(
                            label: 'Cobrar',
                            icon: Icons.attach_money_rounded,
                            iconColor: AppColors.success,
                            iconBg: AppColors.successBg,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PaymentFormScreen()),
                              );
                              _loadMetrics();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickOptionCard(
                            label: 'Nuevo Cliente',
                            icon: Icons.person_add_alt_1_rounded,
                            iconColor: AppColors.primary,
                            iconBg: const Color(0xFFF1F5F9),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
                              );
                              _loadMetrics();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickOptionCard(
                            label: 'Nuevo Préstamo',
                            icon: Icons.credit_card_rounded,
                            iconColor: const Color(0xFF7C3AED),
                            iconBg: const Color(0xFFEDE9FE),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoanFormScreen()),
                              );
                              _loadMetrics();
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ─── Section: Últimos Cobros Realizados ─────────────────────
                    const Text(
                      'Últimos Cobros Realizados',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: recentPayments.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No hay cobros registrados hoy',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: recentPayments.map((p) {
                                final amount = (p['amount'] is num)
                                    ? (p['amount'] as num).toDouble()
                                    : (double.tryParse('${p['amount']}') ?? 0.0);
                                final clientName = p['customer_name'] ?? 'Cliente';
                                final dateStr = p['payment_date'] ?? p['created_at'] ?? '';
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.successBg,
                                    child: Icon(Icons.check_rounded, color: AppColors.success, size: 20),
                                  ),
                                  title: Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  trailing: Text(
                                    CurrencyFormatter.formatDOP(amount),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String amount,
    required Color amountColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickOptionCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


