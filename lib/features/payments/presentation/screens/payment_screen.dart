import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/offline_sync_queue_manager.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_toast.dart';
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

class PaymentScreen extends StatefulWidget {
  final String? loanId;
  final String? clientId;
  final String? initialAmount;

  const PaymentScreen({
    super.key,
    this.loanId,
    this.clientId,
    this.initialAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  List<dynamic> _loans = [];
  Map<String, dynamic>? _selectedLoan;
  List<dynamic> _installments = [];
  final Set<int> _selectedInstallmentIds = {};

  String _paymentMethod = 'cash';
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!;
    }
    _loadLoans();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);
    final allLoans = await ApiService.getLoans();
    final activeLoans = allLoans.where((l) => l['status'] != 'paid').toList();

    Map<String, dynamic>? preselected;
    if (widget.loanId != null) {
      final matches = activeLoans.where((l) => '${l['id']}' == widget.loanId).toList();
      preselected = matches.isNotEmpty ? Map<String, dynamic>.from(matches.first) : (activeLoans.isNotEmpty ? Map<String, dynamic>.from(activeLoans.first) : null);
    } else if (widget.clientId != null) {
      final matches = activeLoans.where((l) => '${l['customer_id']}' == widget.clientId).toList();
      preselected = matches.isNotEmpty ? Map<String, dynamic>.from(matches.first) : (activeLoans.isNotEmpty ? Map<String, dynamic>.from(activeLoans.first) : null);
    } else if (activeLoans.isNotEmpty) {
      preselected = Map<String, dynamic>.from(activeLoans.first);
    }

    setState(() {
      _loans = activeLoans;
      _selectedLoan = preselected;
    });

    if (_selectedLoan != null) {
      await _loadInstallments(_i(_selectedLoan!['id']));
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInstallments(int loanId) async {
    setState(() => _isLoading = true);
    final list = await ApiService.getLoanInstallments(loanId);
    final pendingList = list.where((i) => i['status'] != 'paid').toList();

    _selectedInstallmentIds.clear();
    if (pendingList.isNotEmpty) {
      _selectedInstallmentIds.add(_i(pendingList.first['id']));
    }

    _recalcAmount(pendingList);

    setState(() {
      _installments = pendingList;
      _isLoading = false;
    });
  }

  void _recalcAmount(List<dynamic> pendingList) {
    if (widget.initialAmount != null && _amountController.text.isNotEmpty && _selectedInstallmentIds.isEmpty) {
      return;
    }
    double sum = 0.0;
    for (final inst in pendingList) {
      if (_selectedInstallmentIds.contains(_i(inst['id']))) {
        final total = _d(inst['total_amount']);
        final paid = _d(inst['paid_amount']);
        sum += (total - paid).clamp(0.0, double.infinity);
      }
    }
    if (sum > 0) {
      _amountController.text = sum.toStringAsFixed(2);
    } else if (_selectedLoan != null) {
      _amountController.text = _d(_selectedLoan!['balance_remaining']).toStringAsFixed(2);
    }
  }

  Future<void> _handleProcessPayment() async {
    if (!_formKey.currentState!.validate() || _selectedLoan == null) return;

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      CustomToast.show(context, 'Ingresa un monto válido para cobrar', type: ToastType.warning);
      return;
    }

    setState(() => _isSubmitting = true);

    final loanId = _i(_selectedLoan!['id']);
    final idempotencyKey = ApiService.generateIdempotencyKey();

    final payload = {
      'loan_id': loanId,
      'amount': amount,
      'payment_method': _paymentMethod,
      'note': _noteController.text.trim(),
      'idempotency_key': idempotencyKey,
      'created_at': DateTime.now().toIso8601String(),
    };

    final result = await ApiService.processPayment(
      loanId: loanId,
      amount: amount,
      paymentMethod: _paymentMethod,
      idempotencyKey: idempotencyKey,
    );

    // Offline Queue
    OfflineSyncQueueManager.enqueue(type: SyncTaskType.processPayment, payload: payload);

    setState(() => _isSubmitting = false);

    if (mounted) {
      final double prevBal = _d(_selectedLoan!['balance_remaining']);
      final double newBal = (prevBal - amount).clamp(0.0, double.infinity);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            receiptData: {
              'receipt_number': result?['receipt_number'] ?? 'REC-${DateTime.now().millisecondsSinceEpoch}',
              'customer_name': _selectedLoan!['customer_name'] ?? 'Cliente',
              'amount': amount,
              'payment_method': _getMethodLabel(_paymentMethod),
              'date': AppDateFormatter.formatDate(DateTime.now().toIso8601String()),
              'balance_remaining': newBal,
            },
          ),
        ),
      );
    }
  }

  String _getMethodLabel(String m) {
    switch (m) {
      case 'cash': return 'Efectivo';
      case 'transfer': return 'Transferencia Bancaria';
      case 'card': return 'Tarjeta de Débito / Crédito';
      case 'check': return 'Cheque';
      default: return 'Efectivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Registrar Cobro',
        subtitle: 'Caja y Recaudación',
        onBackPressed: () => context.go('/dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _loans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 54, color: AppColors.success),
                      const SizedBox(height: 12),
                      const Text('¡Excelente! No hay préstamos pendientes de cobro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () => context.go('/dashboard'),
                        child: const Text('Volver al Inicio', style: TextStyle(color: Colors.white)),
                      ),
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
                        // Card 1: Selección de Préstamo
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.person_search_rounded, color: AppColors.primary, size: 22),
                                  SizedBox(width: 8),
                                  Text('1. Seleccionar Préstamo a Cobrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 14),

                              DropdownButtonFormField<int>(
                                value: _selectedLoan != null ? _i(_selectedLoan!['id']) : null,
                                decoration: InputDecoration(
                                  labelText: 'Préstamo Activo',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: _loans.map<DropdownMenuItem<int>>((l) {
                                  final lid = _i(l['id']);
                                  final name = l['customer_name'] ?? 'Cliente #$lid';
                                  final bal = CurrencyFormatter.formatDOP(_d(l['balance_remaining']));
                                  return DropdownMenuItem<int>(
                                    value: lid,
                                    child: Text('$name (Debe: $bal)', style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                   if (val != null) {
                                     final matches = _loans.where((l) => _i(l['id']) == val).toList();
                                     if (matches.isNotEmpty) {
                                       setState(() => _selectedLoan = Map<String, dynamic>.from(matches.first));
                                       _loadInstallments(val);
                                     }
                                   }
                                 },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Card 2: Selección de Cuotas
                        if (_installments.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.checklist_rounded, color: AppColors.accent, size: 22),
                                    SizedBox(width: 8),
                                    Text('2. Cuotas Pendientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text('Selecciona una o más cuotas para sumarlas automáticamente:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 12),

                                ..._installments.map((inst) {
                                  final int instId = _i(inst['id']);
                                  final int instNo = _i(inst['installment_number']);
                                  final double total = _d(inst['total_amount']);
                                  final double paid = _d(inst['paid_amount']);
                                  final double due = (total - paid).clamp(0.0, double.infinity);
                                  final String dueDate = AppDateFormatter.formatDate(inst['due_date']);
                                  final bool isSelected = _selectedInstallmentIds.contains(instId);

                                  return CheckboxListTile(
                                    value: isSelected,
                                    activeColor: AppColors.accent,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('Cuota #$instNo — $dueDate', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    subtitle: Text('Pendiente: ${CurrencyFormatter.formatDOP(due)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedInstallmentIds.add(instId);
                                        } else {
                                          _selectedInstallmentIds.remove(instId);
                                        }
                                        _recalcAmount(_installments);
                                      });
                                    },
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Card 3: Monto y Método de Pago
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.payment_rounded, color: AppColors.primary, size: 22),
                                  SizedBox(width: 8),
                                  Text('3. Detalle del Cobro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Monto a Cobrar
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success),
                                decoration: InputDecoration(
                                  labelText: 'Monto a Cobrar (RD\$) *',
                                  prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.success),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Ingresa un monto válido' : null,
                              ),

                              const SizedBox(height: 14),

                              // Método de Pago
                              DropdownButtonFormField<String>(
                                value: _paymentMethod,
                                decoration: InputDecoration(
                                  labelText: 'Método de Pago',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'cash', child: Text('💵 Efectivo')),
                                  DropdownMenuItem(value: 'transfer', child: Text('🏦 Transferencia Bancaria')),
                                  DropdownMenuItem(value: 'card', child: Text('💳 Tarjeta Débito / Crédito')),
                                  DropdownMenuItem(value: 'check', child: Text('📝 Cheque')),
                                ],
                                onChanged: (val) => setState(() => _paymentMethod = val ?? 'cash'),
                              ),

                              const SizedBox(height: 14),

                              // Nota / Referencia
                              TextFormField(
                                controller: _noteController,
                                decoration: InputDecoration(
                                  labelText: 'Nota o Número de Referencia (Opcional)',
                                  prefixIcon: const Icon(Icons.description_outlined, color: AppColors.primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: _isSubmitting ? null : _handleProcessPayment,
                            icon: _isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.check_circle_rounded, color: Colors.white),
                            label: Text(
                              _isSubmitting ? 'Procesando Cobro...' : 'Confirmar Cobro y Generar Recibo',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }
}
