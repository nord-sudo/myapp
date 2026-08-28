import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/network/api_service.dart';
import 'receipt_screen.dart';

// ─── Safe type helpers ────────────────────────────────────────────────────────
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
  final Map<String, dynamic> loan;
  final VoidCallback? onRefresh;

  const LoanDetailScreen({Key? key, required this.loan, this.onRefresh})
      : super(key: key);

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _installments = [];
  List<dynamic> _payments = [];
  bool _loadingInstallments = true;
  bool _loadingPayments = true;

  late Map<String, dynamic> _loan;

  @override
  void initState() {
    super.initState();
    _loan = Map<String, dynamic>.from(widget.loan);
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final updatedLoan = await ApiService.getLoanDetail(_i(_loan['id']));
    if (updatedLoan != null && mounted) {
      setState(() {
        _loan = updatedLoan;
      });
    }
    await Future.wait([_fetchInstallments(), _fetchPayments()]);
  }

  Future<void> _fetchInstallments() async {
    setState(() => _loadingInstallments = true);
    final data = await ApiService.getLoanInstallments(_i(_loan['id']));
    if (mounted) setState(() { _installments = data; _loadingInstallments = false; });
  }

  Future<void> _fetchPayments() async {
    setState(() => _loadingPayments = true);
    final data = await ApiService.getLoanPayments(_i(_loan['id']));
    if (mounted) setState(() { _payments = data; _loadingPayments = false; });
  }

  Future<void> _showCollectSheet(Map<String, dynamic> installment) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CollectSheet(
        loan: _loan,
        installment: installment,
        onSuccess: (result) async {
          await _loadData();
          widget.onRefresh?.call();
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReceiptScreen(receiptData: {
                  'receipt_number': result['receipt_number'] ?? 'REC-${DateTime.now().millisecondsSinceEpoch}',
                  'customer_name': _loan['customer_name'] ?? 'Cliente',
                  'amount': result['amount'],
                  'payment_method': _paymentMethodLabel(result['payment_method']),
                  'date': result['payment_date'] ?? DateTime.now().toString().substring(0, 10),
                  'balance_remaining': _d(_loan['balance_remaining']) - _d(result['amount']),
                }),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _showQuickCollectAll() async {
    final balance = _d(_loan['balance_remaining']);
    if (balance <= 0) {
      _showSnack('Este préstamo ya está completamente pagado', AppColors.success);
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CollectSheet(
        loan: _loan,
        installment: null,
        onSuccess: (result) async {
          await _loadData();
          widget.onRefresh?.call();
        },
      ),
    );
  }

  Future<void> _showEarlyPayoffSheet() async {
    final balance = _d(_loan['balance_remaining']);
    final origAmount = _d(_loan['amount']);
    final totalAmount = _d(_loan['total_amount'] ?? origAmount);

    final payoffData = await ApiService.getEarlyPayoff(_i(_loan['id'])) ?? {
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
        top: false,
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
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Row(children: [
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
              ]),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                ),
                child: Column(children: [
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
                ]),
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
                    _showQuickCollectAll();
                  },
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  label: const Text('Proceder a Saldar Deuda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        title: const Row(children: [
          Icon(Icons.warning_rounded, color: AppColors.danger, size: 24),
          SizedBox(width: 10),
          Text('Marcar en Mora', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuota #${installment['installment_number']} — ${CurrencyFormatter.formatDOP(_d(installment['total_amount']))}'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Al marcar esta cuota en mora, el préstamo cambiará su estado a "En Mora".',
                style: TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
          ],
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
              final ok = await ApiService.markInstallmentOverdue(
                  _i(_loan['id']), _i(installment['id']));
              if (ok) {
                setState(() => _loan['status'] = 'overdue');
                await _loadData();
                widget.onRefresh?.call();
                _showSnack('Cuota #${installment['installment_number']} marcada como mora', AppColors.warning);
              }
            },
            child: const Text('Sí, marcar mora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _paymentMethodLabel(String? m) {
    switch (m) {
      case 'cash': return 'Efectivo';
      case 'transfer': return 'Transferencia';
      case 'card': return 'Tarjeta';
      default: return m ?? 'Efectivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = _loan['status'] == 'overdue';
    final bool isPaid = _loan['status'] == 'paid';
    final double amount = _d(_loan['amount']);
    final double balance = _d(_loan['balance_remaining']);
    final double total = _d(_loan['total_amount'] ?? _loan['amount']);
    final double pctPaid = total > 0 ? ((total - balance) / total).clamp(0.0, 1.0) : 0.0;

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
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.credit_card_rounded, color: Colors.white),
                tooltip: 'Liquidación Anticipada',
                onPressed: _showEarlyPayoffSheet,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Actualizar',
                onPressed: _loadData,
              ),
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
                            'Préstamo #${_i(_loan['id'])}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _loan['customer_name'] ?? 'Cliente',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Balance pendiente: ${CurrencyFormatter.formatDOP(balance)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
            _buildSummaryTab(isOverdue, isPaid, amount, balance, total, pctPaid),
            _buildInstallmentsTab(isPaid),
            _buildPaymentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(bool isOverdue, bool isPaid, double amount,
      double balance, double total, double pctPaid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
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
                onPressed: _showQuickCollectAll,
                icon: const Icon(Icons.payments_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Registrar Cobro',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.textPrimary, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showEarlyPayoffSheet,
                icon: const Icon(Icons.calculate_outlined, color: AppColors.textPrimary, size: 18),
                label: const Text('Liquidación Anticipada',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
          child: Column(children: [
            _detailRow('Interés', '${_d(_loan['interest_rate']).toStringAsFixed(1)}%'),
            const Divider(height: 20),
            _detailRow('Frecuencia', _freqLabel(_loan['frequency'])),
            const Divider(height: 20),
            _detailRow('N° Cuotas', '${_i(_loan['term_units'])} cuotas'),
            const Divider(height: 20),
            _detailRow('Fecha Inicio', AppDateFormatter.formatDate(_loan['start_date'] ?? _loan['disbursed_at'])),
            const Divider(height: 20),
            _detailRow('Vence', AppDateFormatter.formatDate(_loan['next_payment_date'] ?? _loan['due_date'])),
          ]),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Información del Cliente',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
            const Divider(height: 20),
            _detailRow('Nombre', _loan['customer_name'] ?? '—'),
            if (_loan['customer_phone'] != null) ...[
              const Divider(height: 20),
              _detailRow('Teléfono', _loan['customer_phone'] ?? '—'),
            ],
            if (_loan['customer_cedula'] != null) ...[
              const Divider(height: 20),
              _detailRow('Cédula', CurrencyFormatter.formatCedula(_loan['customer_cedula'] ?? '')),
            ],
          ]),
        ),

        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildInstallmentsTab(bool isPaid) {
    if (_loadingInstallments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_installments.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_rounded, size: 54, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text('No hay cuotas registradas', style: TextStyle(color: AppColors.textMuted)),
        ]),
      );
    }

    final paid = _installments.where((i) => i['status'] == 'paid').length;
    final overdue = _installments.where((i) => i['status'] == 'overdue').length;
    final pending = _installments.where((i) => i['status'] == 'pending' || i['status'] == 'partial').length;

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _miniChip('$paid Pagadas', AppColors.success),
          _miniChip('$pending Pendientes', AppColors.textMuted),
          if (overdue > 0) _miniChip('$overdue En Mora', AppColors.danger),
        ]),
      ),
      const Divider(height: 1),

      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _installments.length,
          itemBuilder: (ctx, i) {
            final inst = _installments[i];
            final status = inst['status'] as String? ?? 'pending';
            final bool instPaid = status == 'paid';
            final bool instOverdue = status == 'overdue';
            final bool instPartial = status == 'partial';
            final double instTotal = _d(inst['total_amount']);
            final double instPaid2 = _d(inst['paid_amount']);
            final double instPending = (instTotal - instPaid2).clamp(0.0, double.infinity);

            int? daysOverdue;
            if (instOverdue || (status == 'pending')) {
              try {
                final due = DateTime.parse(inst['due_date']);
                final diff = DateTime.now().difference(due).inDays;
                if (diff > 0) daysOverdue = diff;
              } catch (_) {}
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: instOverdue
                      ? AppColors.danger.withOpacity(0.4)
                      : instPartial
                          ? AppColors.warning.withOpacity(0.4)
                          : Colors.grey.shade200,
                  width: instOverdue || instPartial ? 1.5 : 1,
                ),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                  child: Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${_i(inst['installment_number'])}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(
                            AppDateFormatter.formatDate(inst['due_date']),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          if (daysOverdue != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+$daysOverdue días',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _statusColor(status),
                              ),
                            ),
                          ),
                        ]),
                      ]),
                    ),

                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(
                        CurrencyFormatter.formatDOP(instTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      if (instPartial)
                        Text(
                          'Pagado: ${CurrencyFormatter.formatDOP(instPaid2)}',
                          style: const TextStyle(fontSize: 10, color: AppColors.success),
                        ),
                      if (!instPaid)
                        Text(
                          'Debe: ${CurrencyFormatter.formatDOP(instPending)}',
                          style: TextStyle(fontSize: 10, color: _statusColor(status)),
                        ),
                    ]),

                    if (!instPaid && !isPaid)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (val) {
                          if (val == 'collect') _showCollectSheet(inst);
                          if (val == 'mora') _showMarkMoraDialog(inst);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'collect',
                            child: Row(children: const [
                              Icon(Icons.payments_rounded, color: AppColors.success, size: 18),
                              SizedBox(width: 8),
                              Text('Cobrar Cuota'),
                            ]),
                          ),
                          if (!instOverdue)
                            PopupMenuItem(
                              value: 'mora',
                              child: Row(children: const [
                                Icon(Icons.warning_rounded, color: AppColors.danger, size: 18),
                                SizedBox(width: 8),
                                Text('Marcar en Mora'),
                              ]),
                            ),
                        ],
                      ),
                  ]),
                ),

                if (instPartial || instPaid)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Column(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: instTotal > 0 ? (instPaid2 / instTotal).clamp(0.0, 1.0) : 0.0,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            instPaid ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ]),
                  ),

                if (!instPaid && !isPaid)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: instOverdue ? AppColors.danger : AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          elevation: 0,
                        ),
                        onPressed: () => _showCollectSheet(inst),
                        icon: const Icon(Icons.payments_rounded, color: Colors.white, size: 16),
                        label: Text(
                          instOverdue
                              ? 'Cobrar Mora (${CurrencyFormatter.formatDOP(instPending)})'
                              : instPartial
                                  ? 'Completar Cuota (${CurrencyFormatter.formatDOP(instPending)})'
                                  : 'Cobrar Cuota',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildPaymentsTab() {
    if (_loadingPayments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_payments.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long_rounded, size: 54, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text('No hay cobros registrados', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showQuickCollectAll,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Registrar Primer Cobro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      );
    }

    final totalPaid = _payments.fold<double>(0, (s, p) => s + _d(p['amount']));

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_payments.length} cobros realizados',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total Cobrado: ${CurrencyFormatter.formatDOP(totalPaid)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ),
          ],
        ),
      ),
      const Divider(height: 1),

      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _payments.length,
          itemBuilder: (ctx, i) {
            final pay = _payments[i];
            final double payAmt = _d(pay['amount']);
            final String method = pay['payment_method'] as String? ?? 'cash';
            final String receiptNum = pay['receipt_number'] ?? 'REC-${1000 + i}';
            final IconData methodIcon = method == 'transfer'
                ? Icons.account_balance_rounded
                : method == 'card'
                    ? Icons.credit_card_rounded
                    : Icons.payments_rounded;
            final Color methodColor = method == 'transfer'
                ? AppColors.primary
                : method == 'card'
                    ? AppColors.primary
                    : AppColors.success;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.softShadow,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptScreen(
                        receiptData: {
                          'receipt_number': receiptNum,
                          'customer_name': _loan['customer_name'] ?? 'Cliente',
                          'amount': payAmt,
                          'payment_method': _paymentMethodLabel(method),
                          'date': pay['payment_date'] ?? pay['created_at'] ?? DateTime.now().toString().substring(0, 10),
                          'balance_remaining': _d(_loan['balance_remaining']),
                        },
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: methodColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(methodIcon, color: methodColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(
                          children: [
                            Text(
                              receiptNum,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Confirmado',
                                style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${AppDateFormatter.formatDate(pay['payment_date'] ?? pay['created_at'])} • ${_paymentMethodLabel(method)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(
                        CurrencyFormatter.formatDOP(payAmt),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_rounded, size: 10, color: AppColors.primary),
                            SizedBox(width: 3),
                            Text('Ver Recibo', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
        ]),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  String _freqLabel(dynamic f) {
    switch (f?.toString()) {
      case 'daily': return 'Diario';
      case 'weekly': return 'Semanal';
      case 'biweekly': return 'Quincenal';
      case 'monthly': return 'Mensual';
      default: return f?.toString() ?? '—';
    }
  }
}

class _CollectSheet extends StatefulWidget {
  final Map<String, dynamic> loan;
  final Map<String, dynamic>? installment;
  final Function(Map<String, dynamic>) onSuccess;

  const _CollectSheet({
    required this.loan,
    required this.installment,
    required this.onSuccess,
  });

  @override
  State<_CollectSheet> createState() => _CollectSheetState();
}

class _CollectSheetState extends State<_CollectSheet> {
  late TextEditingController _amountCtrl;
  String _method = 'cash';
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    double initial;
    if (widget.installment != null) {
      final total = _d(widget.installment!['total_amount']);
      final paid = _d(widget.installment!['paid_amount']);
      initial = (total - paid).clamp(0, double.infinity);
    } else {
      initial = _d(widget.loan['balance_remaining']);
    }
    _amountCtrl = TextEditingController(text: initial.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Ingresa un monto válido mayor a cero');
      return;
    }
    setState(() { _submitting = true; _error = null; });

    final result = await ApiService.processPayment(
      loanId: _i(widget.loan['id']),
      amount: amount,
      paymentMethod: _method,
      idempotencyKey: ApiService.generateIdempotencyKey(),
    );

    setState(() => _submitting = false);

    if (result != null && mounted) {
      Navigator.pop(context);
      widget.onSuccess({...result, 'amount': amount, 'payment_method': _method});
    } else if (mounted) {
      setState(() => _error = 'Error al registrar el cobro. Verifica la conexión.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = widget.loan['status'] == 'overdue' ||
        widget.installment?['status'] == 'overdue';
    final instNum = widget.installment?['installment_number'];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44, height: 5,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.payments_rounded,
                    color: isOverdue ? AppColors.danger : AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    instNum != null
                        ? 'Cobrar Cuota #$instNum'
                        : 'Registrar Cobro',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                widget.loan['customer_name'] ?? 'Cliente',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),

              if (isOverdue) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.warning_rounded, color: AppColors.danger, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'Cuota en mora — el pago se aplicará primero a las cuotas más antiguas.',
                      style: TextStyle(fontSize: 11, color: AppColors.danger),
                    )),
                  ]),
                ),
              ],

              const SizedBox(height: 20),

              Text('Monto del Cobro (RD\$)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.success),
                decoration: InputDecoration(
                  prefixText: 'RD\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.success.withOpacity(0.04),
                  errorText: _error,
                ),
              ),

              const SizedBox(height: 16),

              Text('Método de Pago',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                _methodBtn(Icons.payments_rounded, 'Efectivo', 'cash', AppColors.success),
                const SizedBox(width: 8),
                _methodBtn(Icons.account_balance_rounded, 'Transferencia', 'transfer', AppColors.accent),
                const SizedBox(width: 8),
                _methodBtn(Icons.credit_card_rounded, 'Tarjeta', 'card', AppColors.primary),
              ]),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOverdue ? AppColors.danger : AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    _submitting ? 'Procesando...' : 'Confirmar Cobro',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    ),
    );
  }

  Widget _methodBtn(IconData icon, String label, String value, Color color) {
    final selected = _method == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _method = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(children: [
            Icon(icon, color: selected ? color : AppColors.textMuted, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold,
              color: selected ? color : AppColors.textMuted,
            )),
          ]),
        ),
      ),
    );
  }
}
