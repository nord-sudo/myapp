import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/soft_card.dart';
import 'client_form_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  Map<String, dynamic>? _client;
  List<dynamic> _clientLoans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    setState(() => _isLoading = true);
    final customers = await ApiService.getCustomers();
    final matches = customers.where((c) => '${c['id']}' == widget.clientId).toList();
    final match = matches.isNotEmpty ? matches.first : null;

    List<dynamic> loans = [];
    if (match != null) {
      final allLoans = await ApiService.getLoans();
      loans = allLoans.where((l) => '${l['customer_id']}' == widget.clientId).toList();
    }

    if (mounted) {
      setState(() {
        _client = match != null ? Map<String, dynamic>.from(match) : null;
        _clientLoans = loans;
        _isLoading = false;
      });
    }
  }

  void _confirmDeleteClient() {
    if (_client == null) return;
    final int id = int.tryParse('${_client!['id']}') ?? 0;
    final String fullName = '${_client!['first_name']} ${_client!['last_name']}';

    final hasActiveLoans = _clientLoans.any((l) => l['status'] == 'active' || l['status'] == 'overdue');
    if (hasActiveLoans) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 26),
              SizedBox(width: 10),
              Text('No se puede eliminar'),
            ],
          ),
          content: const Text(
            'Este cliente tiene préstamos activos o en mora. Debes liquidar o saldar sus préstamos antes de eliminarlo.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 26),
            SizedBox(width: 10),
            Text('Eliminar Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "$fullName"? Esta acción quitará el expediente de tu cartera.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ApiService.deleteCustomer(id);
              if (ok && mounted) {
                CustomToast.show(context, 'Cliente "$fullName" eliminado', type: ToastType.success);
                context.go('/clients');
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_client == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'Detalle de Cliente',
          onBackPressed: () => context.go('/clients'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_rounded, size: 54, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('Cliente no encontrado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => context.go('/clients'),
                child: const Text('Volver a Clientes', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final String first = _client!['first_name'] ?? '';
    final String last = _client!['last_name'] ?? '';
    final String fullName = '$first $last'.trim();
    final String initials = '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'.toUpperCase();
    final String cedula = _client!['identity_document'] ?? '';
    final String phone = _client!['phone'] ?? '—';
    final String address = _client!['address'] ?? _client!['city'] ?? '—';
    final String email = _client!['email'] ?? '—';
    final String status = _client!['status'] ?? 'active';
    final bool isOverdue = status == 'overdue';

    double totalPrestado = 0.0;
    double totalPendiente = 0.0;
    double totalPagado = 0.0;

    for (final l in _clientLoans) {
      final amt = (l['amount'] is num) ? (l['amount'] as num).toDouble() : double.tryParse('${l['amount']}') ?? 0.0;
      final bal = (l['balance_remaining'] is num) ? (l['balance_remaining'] as num).toDouble() : double.tryParse('${l['balance_remaining']}') ?? amt;
      final tot = (l['total_amount'] is num) ? (l['total_amount'] as num).toDouble() : amt;
      totalPrestado += tot;
      totalPendiente += bal;
      totalPagado += (tot > bal ? tot - bal : 0.0);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: fullName,
        subtitle: 'Expediente del Cliente',
        onBackPressed: () => context.go('/clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            tooltip: 'Editar Cliente',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClientFormScreen(clientToEdit: _client)),
              );
              _loadClientData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            tooltip: 'Eliminar Cliente',
            onPressed: _confirmDeleteClient,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadClientData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initials.isNotEmpty ? initials : 'CL',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cédula: ${CurrencyFormatter.formatCedula(cedula)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOverdue ? AppColors.dangerBg : AppColors.successBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isOverdue ? 'En Mora' : 'Al Día',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isOverdue ? AppColors.danger : AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Metrics 2x2
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Préstamos Activos',
                      value: '${_clientLoans.where((l) => l['status'] == 'active' || l['status'] == 'overdue').length}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      icon: Icons.payments_rounded,
                      label: 'Total Prestado',
                      value: CurrencyFormatter.formatDOP(totalPrestado),
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'Balance Pendiente',
                      value: CurrencyFormatter.formatDOP(totalPendiente),
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Total Pagado',
                      value: CurrencyFormatter.formatDOP(totalPagado),
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Contact Info
              SoftCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.contact_phone_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Información de Contacto',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _detailRow(Icons.phone_rounded, 'Teléfono / WhatsApp', phone),
                    const Divider(height: 18),
                    _detailRow(Icons.location_on_rounded, 'Dirección', address),
                    const Divider(height: 18),
                    _detailRow(Icons.email_rounded, 'Correo Electrónico', email),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Associated Loans Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Préstamos del Cliente',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/loans/new?customerId=${widget.clientId}'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nuevo Préstamo'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_clientLoans.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 40, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text('Sin préstamos registrados aún', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _clientLoans.length,
                  itemBuilder: (ctx, i) {
                    final loan = _clientLoans[i];
                    final double amount = (loan['amount'] is num) ? (loan['amount'] as num).toDouble() : double.tryParse('${loan['amount']}') ?? 0.0;
                    final double balance = (loan['balance_remaining'] is num) ? (loan['balance_remaining'] as num).toDouble() : double.tryParse('${loan['balance_remaining']}') ?? amount;
                    final String statusStr = (loan['status'] ?? 'active').toString().toUpperCase();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                          ),
                          title: Text('Préstamo #${loan['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            'Pendiente: ${CurrencyFormatter.formatDOP(balance)} • $statusStr',
                            style: TextStyle(fontSize: 12, color: statusStr == 'OVERDUE' ? AppColors.danger : AppColors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          onTap: () => context.go('/loans/${loan['id']}'),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/payment?clientId=${widget.clientId}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.payments_rounded, color: Colors.white, size: 18),
                      label: const Text('Registrar Cobro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/loans/new?customerId=${widget.clientId}'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.note_add_rounded, color: AppColors.primary, size: 18),
                      label: const Text('Nuevo Préstamo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}
