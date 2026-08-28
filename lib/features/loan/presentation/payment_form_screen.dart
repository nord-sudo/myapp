import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/services/offline_sync_queue_manager.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/network/api_service.dart';
import 'receipt_screen.dart';


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

class PaymentFormScreen extends StatefulWidget {
  final int? loanId;
  final Map<String, dynamic>? loanData;
  final Map<String, dynamic>? loan;
  final int? preselectedCustomerId;

  const PaymentFormScreen({
    Key? key,
    this.loanId,
    this.loanData,
    this.loan,
    this.preselectedCustomerId,
  }) : super(key: key);

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedPaymentMethod = 'cash';
  int? _selectedLoanId;
  String? _proofImageName;
  bool _isSubmitting = false;
  bool _isLoadingLoans = true;

  List<Map<String, dynamic>> _loans = [];
  Map<String, dynamic>? _activeLoan;

  @override
  void initState() {
    super.initState();
    _initLoanData();
  }

  Future<void> _initLoanData() async {
    final directLoan = widget.loan ?? widget.loanData;
    if (directLoan != null) {
      final loan = directLoan;
      final total = _d(loan['total_amount'] ?? loan['amount']);
      final terms = _d(loan['term_units']);
      final cuota = (total > 0 && terms > 0) ? total / terms : 0.0;
      setState(() {
        _activeLoan = loan;
        _selectedLoanId = loan['id'] is int ? loan['id'] : int.tryParse('${loan['id']}');
        _loans = [loan];
        _amountController.text = cuota.toStringAsFixed(2);
        _isLoadingLoans = false;
      });
      return;
    }


    // Otherwise fetch from API
    setState(() => _isLoadingLoans = true);
    final data = await ApiService.getLoans();
    final activeLoans = data.where((l) => l['status'] == 'active' || l['status'] == 'overdue').toList();

    Map<String, dynamic>? matchedLoan;
    int? initialId;

    if (widget.loanId != null) {
      // Try to find the loan that matches the passed ID
      try {
        matchedLoan = activeLoans.firstWhere((l) {
          final id = l['id'] is int ? l['id'] : int.tryParse('${l['id']}');
          return id == widget.loanId;
        });
      } catch (_) {
        // Not found in active list — add a placeholder so dropdown doesn't crash
        matchedLoan = null;
      }
      initialId = widget.loanId;
    }

    // If the passed loanId isn't in the active list, fall back to first loan
    if (matchedLoan == null && activeLoans.isNotEmpty) {
      matchedLoan = activeLoans.first;
      initialId = activeLoans.first['id'] is int
          ? activeLoans.first['id']
          : int.tryParse('${activeLoans.first['id']}');
    }

    double cuotaAmount = 0.0;
    if (matchedLoan != null) {
      final total = _d(matchedLoan['total_amount']);
      final terms = _d(matchedLoan['term_units']);
      cuotaAmount = (total > 0 && terms > 0) ? total / terms : 0.0;
    }

    setState(() {
      _loans = activeLoans.cast<Map<String, dynamic>>();
      _activeLoan = matchedLoan;
      _selectedLoanId = initialId;
      _amountController.text = cuotaAmount.toStringAsFixed(2);
      _isLoadingLoans = false;
    });
  }

  void _onLoanSelected(int? loanId) {
    if (loanId == null) return;
    final loan = _loans.firstWhere(
      (l) => (l['id'] is int ? l['id'] : int.tryParse('${l['id']}')) == loanId,
      orElse: () => {},
    );
    final total = _d(loan['total_amount']);
    final terms = _d(loan['term_units']);
    final cuota = (total > 0 && terms > 0) ? total / terms : 0.0;
    setState(() {
      _selectedLoanId = loanId;
      _activeLoan = loan;
      _amountController.text = cuota.toStringAsFixed(2);
    });
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate() || _selectedLoanId == null) return;

    if (_selectedPaymentMethod == 'transfer' && _proofImageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes adjuntar el comprobante de transferencia.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final double amount = double.parse(_amountController.text);
    final String idempotencyKey = ApiService.generateIdempotencyKey();

    final result = await ApiService.processPayment(
      loanId: _selectedLoanId!,
      amount: amount,
      paymentMethod: _selectedPaymentMethod,
      idempotencyKey: idempotencyKey,
    );

    // Queue in global offline sync manager
    OfflineSyncQueueManager.enqueue(
      type: SyncTaskType.processPayment,
      payload: {
        'loan_id': _selectedLoanId,
        'amount': amount,
        'payment_method': _selectedPaymentMethod,
        'idempotency_key': idempotencyKey,
      },
    );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      final customerName = _activeLoan?['customer_name'] ?? 'Cliente';
      final balanceRemaining = _d(_activeLoan?['balance_remaining']) - amount;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            receiptData: {
              'receipt_number': result['receipt_number'] ?? 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
              'customer_name': customerName,
              'amount': amount,
              'payment_method': _selectedPaymentMethod == 'cash'
                  ? 'Efectivo'
                  : _selectedPaymentMethod == 'transfer'
                      ? 'Transferencia Bancaria'
                      : 'Tarjeta',
              'proof_image': _proofImageName,
              'date': DateTime.now().toString().substring(0, 10),
              'balance_remaining': balanceRemaining < 0 ? 0.0 : balanceRemaining,
            },
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo registrar el cobro. Verifica tu conexión.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _simulateUploadProof() {
    setState(() {
      _proofImageName = 'comprobante_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Comprobante adjuntado correctamente'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = _activeLoan?['status'] == 'overdue';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: isOverdue ? AppColors.danger : AppColors.primary,
        title: Text(
          isOverdue ? '⚠️ Cobrar Mora' : 'Registrar Cobro',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoadingLoans
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      const Text('No hay préstamos activos para cobrar',
                          style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mora alert
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_rounded, color: AppColors.danger, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Este préstamo está EN MORA. El cobro se aplicará a cuotas vencidas primero.',
                                    style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Loan selector (hidden if loanId was passed and only one loan)
                        if (_loans.length > 1) ...[
                          const Text('Cliente / Préstamo',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: (_selectedLoanId != null && _loans.any((l) => _i(l['id']) == _selectedLoanId))
                                ? _selectedLoanId
                                : null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: () {
                              final Set<int> addedLoanIds = {};
                              final List<DropdownMenuItem<int>> menuItems = [];
                              for (final l in _loans) {
                                final id = _i(l['id']);
                                if (id > 0 && !addedLoanIds.contains(id)) {
                                  addedLoanIds.add(id);
                                  menuItems.add(
                                    DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(
                                        '${l['customer_name']} • ${CurrencyFormatter.formatDOP(_d(l['balance_remaining']))}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  );
                                }
                              }
                              return menuItems;
                            }(),
                            onChanged: _onLoanSelected,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Loan summary chip
                        if (_activeLoan != null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: (isOverdue ? AppColors.danger : AppColors.accent)
                                      .withOpacity(0.12),
                                  child: Icon(Icons.person_rounded,
                                      color: isOverdue ? AppColors.danger : AppColors.accent),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _activeLoan!['customer_name'] ?? 'Cliente',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        'Pendiente: ${CurrencyFormatter.formatDOP(_d(_activeLoan!['balance_remaining']))}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: isOverdue ? AppColors.danger : AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Amount field
                        const Text('Monto del Cobro',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.success),
                          decoration: const InputDecoration(
                            prefixText: 'RD\$ ',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.attach_money_rounded, color: AppColors.success),
                          ),
                          validator: (v) =>
                              (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Monto inválido' : null,
                        ),

                        const SizedBox(height: 20),

                        // Payment method
                        const Text('Método de Pago',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MethodTile(
                              icon: Icons.payments_rounded,
                              label: 'Efectivo',
                              selected: _selectedPaymentMethod == 'cash',
                              onTap: () => setState(() {
                                _selectedPaymentMethod = 'cash';
                                _proofImageName = null;
                              }),
                            ),
                            const SizedBox(width: 8),
                            _MethodTile(
                              icon: Icons.account_balance_rounded,
                              label: 'Transferencia',
                              selected: _selectedPaymentMethod == 'transfer',
                              onTap: () => setState(() => _selectedPaymentMethod = 'transfer'),
                            ),
                            const SizedBox(width: 8),
                            _MethodTile(
                              icon: Icons.credit_card_rounded,
                              label: 'Tarjeta',
                              selected: _selectedPaymentMethod == 'card',
                              onTap: () => setState(() {
                                _selectedPaymentMethod = 'card';
                                _proofImageName = null;
                              }),
                            ),
                          ],
                        ),

                        // Transfer proof upload
                        if (_selectedPaymentMethod == 'transfer') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _proofImageName != null
                                    ? AppColors.success
                                    : AppColors.warning,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(children: [
                                  Icon(Icons.receipt_long_rounded, color: AppColors.accent),
                                  SizedBox(width: 8),
                                  Text('Comprobante de Transferencia *',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 14)),
                                ]),
                                const SizedBox(height: 4),
                                const Text(
                                  'Obligatorio: adjunta la captura del depósito.',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                if (_proofImageName != null)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.image_rounded,
                                          color: AppColors.success, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(_proofImageName!,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.success,
                                                  fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis)),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_rounded,
                                            color: AppColors.danger, size: 18),
                                        onPressed: () =>
                                            setState(() => _proofImageName = null),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ]),
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: const BorderSide(color: AppColors.accent),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: _simulateUploadProof,
                                      icon: const Icon(Icons.add_a_photo_rounded,
                                          color: AppColors.accent),
                                      label: const Text('Subir Foto del Comprobante',
                                          style: TextStyle(color: AppColors.accent)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        SafeArea(
                          top: false,
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isOverdue ? AppColors.danger : AppColors.success,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _isSubmitting ? null : _submitPayment,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 24),
                              label: Text(
                                _isSubmitting
                                    ? 'Procesando...'
                                    : 'Confirmar Cobro',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
