import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/services/offline_sync_queue_manager.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/network/api_service.dart';


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

class LoanFormScreen extends StatefulWidget {
  const LoanFormScreen({Key? key}) : super(key: key);

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '20000');
  final _interestRateController = TextEditingController(text: '20');
  final _termUnitsController = TextEditingController(text: '20');

  String _selectedFrequency = 'weekly';
  String _selectedInterestType = 'fixed';
  int? _selectedCustomerId;
  List<dynamic> _customers = [];

  // ── Date fields ──────────────────────────────────────────────
  DateTime _startDate = DateTime.now();
  // First payment date is auto-calculated from frequency but can be overridden
  DateTime? _firstPaymentDate;
  bool _customFirstPayment = false;

  Map<String, dynamic>? _simulatedSchedule;
  bool _isSimulating = false;
  bool _isSubmitting = false;

  final DateFormat _fmt = DateFormat('dd MMM yyyy', 'es');

  @override
  void initState() {
    super.initState();
    _firstPaymentDate = _calcFirstPayment(_startDate, _selectedFrequency);
    _loadCustomers();
    _runSimulation();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _interestRateController.dispose();
    _termUnitsController.dispose();
    super.dispose();
  }

  /// Auto-calculate the first payment date based on frequency
  DateTime _calcFirstPayment(DateTime start, String frequency) {
    switch (frequency) {
      case 'daily':
        return start.add(const Duration(days: 1));
      case 'weekly':
        return start.add(const Duration(days: 7));
      case 'biweekly':
        return start.add(const Duration(days: 15));
      case 'monthly':
        return DateTime(start.year, start.month + 1, start.day);
      default:
        return start.add(const Duration(days: 7));
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (!_customFirstPayment) {
          _firstPaymentDate = _calcFirstPayment(picked, _selectedFrequency);
        }
      });
      _runSimulation();
    }
  }

  Future<void> _pickFirstPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstPaymentDate ?? _calcFirstPayment(_startDate, _selectedFrequency),
      firstDate: _startDate,
      lastDate: DateTime(2030),
      locale: const Locale('es'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _firstPaymentDate = picked;
        _customFirstPayment = true;
      });
      _runSimulation();
    }
  }

  Future<void> _loadCustomers() async {
    final list = await ApiService.getCustomers();
    final Set<int> seen = {};
    final List<dynamic> uniqueList = [];
    for (final c in list) {
      final cid = _i(c['id']);
      if (cid > 0 && !seen.contains(cid)) {
        seen.add(cid);
        uniqueList.add(c);
      }
    }
    setState(() {
      _customers = uniqueList;
      if (_customers.isNotEmpty) {
        final firstId = _i(_customers[0]['id']);
        _selectedCustomerId = firstId > 0 ? firstId : null;
      }
    });
  }

  Future<void> _runSimulation() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final rate = double.tryParse(_interestRateController.text) ?? 0.0;
    final terms = int.tryParse(_termUnitsController.text) ?? 0;

    if (amount <= 0 || rate < 0 || terms <= 0) return;

    setState(() => _isSimulating = true);

    final startStr = _startDate.toIso8601String().substring(0, 10);

    final res = await ApiService.calculateLoanSchedule(
      amount: amount,
      interestRate: rate,
      termUnits: terms,
      frequency: _selectedFrequency,
      startDate: startStr,
      interestType: _selectedInterestType,
    );

    setState(() {
      _simulatedSchedule = res;
      _isSimulating = false;
    });
  }

  Future<void> _submitLoan() async {
    if (!_formKey.currentState!.validate() || _selectedCustomerId == null) return;
    setState(() => _isSubmitting = true);

    final startStr = _startDate.toIso8601String().substring(0, 10);

    final payload = {
      'customer_id': _selectedCustomerId,
      'amount': double.parse(_amountController.text),
      'interest_rate': double.parse(_interestRateController.text),
      'term_units': int.parse(_termUnitsController.text),
      'frequency': _selectedFrequency,
      'start_date': startStr,
      'interest_type': _selectedInterestType,
    };

    final result = await ApiService.createLoan(payload);
    setState(() => _isSubmitting = false);

    // Queue background sync
    OfflineSyncQueueManager.enqueue(
      type: SyncTaskType.createLoan,
      payload: payload,
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Préstamo desembolsado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al crear el préstamo. Verifica los datos.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Nuevo préstamo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Cliente ──────────────────────────────────────
              _sectionLabel('Cliente Destino', Icons.person_outline_rounded),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: (_selectedCustomerId != null && _customers.any((c) => _i(c['id']) == _selectedCustomerId))
                    ? _selectedCustomerId
                    : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.people_rounded),
                ),
                items: () {
                  final Set<int> addedIds = {};
                  final List<DropdownMenuItem<int>> menuItems = [];
                  for (final c in _customers) {
                    final int cid = _i(c['id']);
                    if (cid > 0 && !addedIds.contains(cid)) {
                      addedIds.add(cid);
                      menuItems.add(
                        DropdownMenuItem<int>(
                          value: cid,
                          child: Text(
                            '${c['first_name']} ${c['last_name']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }
                  }
                  return menuItems;
                }(),
                onChanged: (val) => setState(() => _selectedCustomerId = val),
                validator: (v) => v == null ? 'Selecciona un cliente' : null,
              ),

              const SizedBox(height: 20),

              // ── Monto e Interés ───────────────────────────────
              _sectionLabel('Monto e Interés', Icons.attach_money_rounded),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _runSimulation(),
                    decoration: const InputDecoration(
                      labelText: 'Monto (RD\$)',
                      prefixText: 'RD\$ ',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) =>
                        (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Inválido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _interestRateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _runSimulation(),
                    decoration: const InputDecoration(
                      labelText: 'Interés (%)',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) =>
                        (double.tryParse(v ?? '') ?? -1) < 0 ? 'Inválido' : null,
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Cuotas y Frecuencia ───────────────────────────
              _sectionLabel('Cuotas y Frecuencia', Icons.calendar_view_week_rounded),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _termUnitsController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _runSimulation(),
                    decoration: const InputDecoration(
                      labelText: 'Nº Cuotas',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Inválido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedFrequency,
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Diario', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'weekly', child: Text('Semanal', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'biweekly', child: Text('Quincenal', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'monthly', child: Text('Mensual', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedFrequency = val!;
                        if (!_customFirstPayment) {
                          _firstPaymentDate = _calcFirstPayment(_startDate, val);
                        }
                      });
                      _runSimulation();
                    },
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Sistema de Amortización ────────────────────────
              _sectionLabel('Sistema de Interés / Amortización', Icons.tune_rounded),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedInterestType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cálculo',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.calculate_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'fixed', child: Text('Interés Fijo (Simple)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'declining_balance', child: Text('Saldo Insoluto (Sistema Francés)', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) {
                  setState(() => _selectedInterestType = val!);
                  _runSimulation();
                },
              ),

              const SizedBox(height: 20),

              // ── Fechas ────────────────────────────────────────
              _sectionLabel('Fechas del Préstamo', Icons.event_rounded),
              const SizedBox(height: 10),

              // Fecha de Inicio
              _DatePickerTile(
                label: 'Fecha de Inicio (Desembolso)',
                icon: Icons.play_circle_rounded,
                iconColor: AppColors.primary,
                date: _startDate,
                onTap: _pickStartDate,
                formatter: _fmt,
              ),

              const SizedBox(height: 10),

              // Primera Fecha de Pago
              _DatePickerTile(
                label: 'Primera Fecha de Cobro',
                icon: Icons.payments_rounded,
                iconColor: AppColors.accent,
                date: _firstPaymentDate ?? _calcFirstPayment(_startDate, _selectedFrequency),
                onTap: _pickFirstPaymentDate,
                formatter: _fmt,
                subtitle: _customFirstPayment
                    ? 'Personalizada'
                    : 'Auto-calculada según frecuencia',
                subtitleColor: _customFirstPayment ? AppColors.accent : AppColors.textMuted,
                trailing: _customFirstPayment
                    ? IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            size: 18, color: AppColors.textMuted),
                        tooltip: 'Restablecer',
                        onPressed: () => setState(() {
                          _customFirstPayment = false;
                          _firstPaymentDate =
                              _calcFirstPayment(_startDate, _selectedFrequency);
                        }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
              ),

              if (_simulatedSchedule != null &&
                  (_simulatedSchedule!['schedule'] as List).isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Última cuota: ${_simulatedSchedule!['schedule'].last['due_date']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.accent),
                      ),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 24),

              // ── Calculadora de Cuotas ─────────────────────────
              _sectionLabel('Plan de Pagos', Icons.table_chart_rounded),
              const SizedBox(height: 8),

              if (_isSimulating)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (_simulatedSchedule != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      // Summary header
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total a Pagar',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                                Text(
                                  CurrencyFormatter.formatDOP(
                                      _d(_simulatedSchedule!['total_amount'])),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Cuotas',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                                Text(
                                  '${_i(_simulatedSchedule!['term_units'])} x ${CurrencyFormatter.formatDOP(_d((_simulatedSchedule!['schedule'] as List).isNotEmpty ? _simulatedSchedule!['schedule'][0]['total_amount'] : 0))}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Installment list
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount:
                              (_simulatedSchedule!['schedule'] as List).length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 16),
                          itemBuilder: (context, index) {
                            final cuota =
                                _simulatedSchedule!['schedule'][index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      AppColors.accent.withOpacity(0.1),
                                  child: Text(
                                    '${cuota['installment_number']}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cuota['due_date'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatDOP(
                                      _d(cuota['total_amount'])),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textPrimary),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // ── Entregar / Guardar Préstamo ─────────────────────
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E60F9).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSubmitting ? null : _submitLoan,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Guardar préstamo',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Date Picker Tile
// ─────────────────────────────────────────────────────────────────────────────
class _DatePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final DateTime date;
  final VoidCallback onTap;
  final DateFormat formatter;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;

  const _DatePickerTile({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.date,
    required this.onTap,
    required this.formatter,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  formatter.format(date),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 10,
                          color: subtitleColor ?? AppColors.textMuted)),
              ],
            ),
          ),
          trailing ??
              Icon(Icons.edit_calendar_rounded,
                  color: iconColor.withOpacity(0.6), size: 18),
        ]),
      ),
    );
  }
}
