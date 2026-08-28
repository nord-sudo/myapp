import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/pdf_document_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_toast.dart';

double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return (v as num).toDouble();
}

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return (v as num).toInt();
}

String _statusLabel(String? s) {
  switch (s) {
    case 'paid': return 'Pagada';
    case 'partial': return 'Parcial';
    case 'overdue': return 'En Mora';
    case 'pending': return 'Pendiente';
    default: return s ?? '';
  }
}

Color _statusColor(String? s) {
  switch (s) {
    case 'paid': return AppColors.success;
    case 'partial': return AppColors.warning;
    case 'overdue': return AppColors.danger;
    default: return AppColors.textMuted;
  }
}

class LoanDetailScreen extends StatefulWidget {
  final String loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _loan;
  List<dynamic> _installments = [];
  List<dynamic> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLoanData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLoanData() async {
    setState(() => _isLoading = true);
    final int lid = int.tryParse(widget.loanId) ?? 0;
    final loan = await ApiService.getLoanDetail(lid);
    final installments = await ApiService.getLoanInstallments(lid);
    final payments = await ApiService.getLoanPayments(lid);

    if (mounted) {
      setState(() {
        _loan = loan;
        _installments = installments;
        _payments = payments;
        _isLoading = false;
      });
    }
  }

  Future<void> _showEarlyPayoffDialog() async {
    if (_loan == null) return;
    final balance = _d(_loan!['balance_remaining']);
    final origAmount = _d(_loan!['amount']);
    final totalAmount = _d(_loan!['total_amount'] ?? origAmount);

    final payoffData = await ApiService.getEarlyPayoff(_i(_loan!['id'])) ?? {
      'balance_remaining': balance,
      'discount_rate': 5.0,
      'discount_amount': ((totalAmount - origAmount) * 0.05).clamp(0.0, balance),
      'settlement_amount': (balance - ((totalAmount - origAmount) * 0.05)).clamp(0.0, balance),
    };

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calculate_rounded, color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Liquidación Anticipada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('Saldar deuda hoy con descuento', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _detailRow('Balance Actual', CurrencyFormatter.formatDOP(_d(payoffData['balance_remaining']))),
                    const Divider(height: 20),
                    _detailRow('Descuento de Interés (${_d(payoffData['discount_rate'])}%)',
                        '- ${CurrencyFormatter.formatDOP(_d(payoffData['discount_amount']))}'),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monto Final a Pagar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          CurrencyFormatter.formatDOP(_d(payoffData['settlement_amount'])),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: AppColors.success),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/payment?loanId=${widget.loanId}&amount=${payoffData['settlement_amount']}');
                  },
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  label: const Text('Proceder a Saldar Deuda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMarkMoraDialog(Map<String, dynamic> installment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 10),
            Text('Marcar en Mora', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '¿Deseas marcar la Cuota #${installment['installment_number']} (${CurrencyFormatter.formatDOP(_d(installment['total_amount']))}) como vencida en mora?',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ApiService.markInstallmentOverdue(_i(widget.loanId), _i(installment['id']));
              if (ok) {
                _loadLoanData();
                if (mounted) {
                  CustomToast.show(context, 'Cuota #${installment['installment_number']} marcada en mora', type: ToastType.warning);
                }
              }
            },
            child: const Text('Sí, marcar mora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

    if (_loan == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(title: 'Detalle de Préstamo', onBackPressed: () => context.go('/loans')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.credit_card_off_rounded, size: 54, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('Préstamo no encontrado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => context.go('/loans'),
                child: const Text('Volver a Préstamos', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final double amount = _d(_loan!['amount']);
    final double balance = _d(_loan!['balance_remaining']);
    final double total = _d(_loan!['total_amount'] ?? _loan!['amount']);
    final double pctPaid = total > 0 ? ((total - balance) / total).clamp(0.0, 1.0) : 0.0;
    final String clientName = _loan!['customer_name'] ?? 'Cliente';
    final String clientCedula = _loan!['customer_cedula'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 24, color: Colors.white),
              tooltip: 'Atrás',
              onPressed: () => context.go('/loans'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                tooltip: 'Exportar Contrato PDF',
                onPressed: () async {
                  await PdfDocumentService.generateAndShareContract(
                    loanData: _loan!,
                    customerName: clientName,
                    customerCedula: clientCedula,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.calculate_rounded, color: Colors.white),
                tooltip: 'Liquidación Anticipada',
                onPressed: _showEarlyPayoffDialog,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Actualizar',
                onPressed: _loadLoanData,
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            'Préstamo #${widget.loanId}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Balance pendiente: ${CurrencyFormatter.formatDOP(balance)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pctPaid,
                            minHeight: 4,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${(pctPaid * 100).toStringAsFixed(0)}% pagado',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                            Text('Capital: ${CurrencyFormatter.formatDOP(amount)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'Resumen'),
                  Tab(icon: Icon(Icons.table_chart_outlined, size: 18), text: 'Cuotas'),
                  Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Pagos'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSummaryTab(amount, balance, total),
            _buildInstallmentsTab(),
            _buildPaymentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(double amount, double balance, double total) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => context.go('/payment?loanId=${widget.loanId}'),
                  icon: const Icon(Icons.payments_rounded, color: Colors.white, size: 18),
                  label: const Text('Registrar Cobro', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showEarlyPayoffDialog,
                  icon: const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 18),
                  label: const Text('Liquidación Anticipada', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _statCard('Monto Original', CurrencyFormatter.formatDOP(amount), Icons.account_balance_rounded, AppColors.primary),
              _statCard('Total a Pagar', CurrencyFormatter.formatDOP(total), Icons.calculate_rounded, AppColors.primary),
              _statCard('Balance Pendiente', CurrencyFormatter.formatDOP(balance), Icons.description_outlined, AppColors.warning),
              _statCard('Total Cobrado', CurrencyFormatter.formatDOP(total - balance), Icons.check_circle_outline_rounded, AppColors.success),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              children: [
                _detailRow('Tasa de Interés', '${_d(_loan!['interest_rate']).toStringAsFixed(1)}%'),
                const Divider(height: 20),
                _detailRow('Frecuencia', '${_loan!['frequency']}'.toUpperCase()),
                const Divider(height: 20),
                _detailRow('N° Cuotas', '${_i(_loan!['term_units'])} cuotas'),
                const Divider(height: 20),
                _detailRow('Fecha de Inicio', AppDateFormatter.formatDate(_loan!['start_date'] ?? _loan!['disbursed_at'])),
                const Divider(height: 20),
                _detailRow('Fecha Próximo Pago', AppDateFormatter.formatDate(_loan!['next_payment_date'] ?? _loan!['due_date'])),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInstallmentsTab() {
    if (_installments.isEmpty) {
      return const Center(child: Text('No hay cuotas registradas'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _installments.length,
      itemBuilder: (ctx, i) {
        final inst = _installments[i];
        final status = inst['status'] as String? ?? 'pending';
        final bool instPaid = status == 'paid';
        final bool instOverdue = status == 'overdue';
        final double instTotal = _d(inst['total_amount']);
        final double instPaid2 = _d(inst['paid_amount']);
        final double instPending = (instTotal - instPaid2).clamp(0.0, double.infinity);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: instOverdue ? AppColors.danger.withOpacity(0.4) : Colors.grey.shade200,
            ),
            boxShadow: AppColors.softShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(status).withOpacity(0.12),
                child: Text(
                  '${_i(inst['installment_number'])}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor(status)),
                ),
              ),
              title: Text(AppDateFormatter.formatDate(inst['due_date']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(_statusLabel(status), style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(CurrencyFormatter.formatDOP(instTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (!instPaid)
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'collect') {
                          context.go('/payment?loanId=${widget.loanId}&amount=$instPending');
                        } else if (val == 'mora') {
                          _showMarkMoraDialog(inst);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'collect', child: Text('Cobrar Cuota')),
                        if (!instOverdue) const PopupMenuItem(value: 'mora', child: Text('Marcar en Mora')),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return const Center(child: Text('No hay pagos registrados para este préstamo'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (ctx, i) {
        final p = _payments[i];
        final amount = _d(p['amount']);
        final date = p['payment_date'] ?? p['created_at'] ?? '';
        final method = p['payment_method'] ?? 'Efectivo';
        final recNo = p['receipt_number'] ?? 'REC-${p['id']}';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: AppColors.softShadow,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.successBg,
              child: Icon(Icons.check_rounded, color: AppColors.success),
            ),
            title: Text(recNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('$date • $method', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            trailing: Text(
              CurrencyFormatter.formatDOP(amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success),
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
