import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/offline_sync_queue_manager.dart';
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

class LoanFormScreen extends StatefulWidget {
  final int? preselectedCustomerId;

  const LoanFormScreen({super.key, this.preselectedCustomerId});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '20000');
  final _interestRateController = TextEditingController(text: '20');
  final _termUnitsController = TextEditingController(text: '4');

  String _selectedFrequency = 'mensual';
  String _selectedInterestType = 'fixed';
  int? _selectedCustomerId;
  List<dynamic> _customers = [];

  DateTime _startDate = DateTime.now();
  DateTime? _firstPaymentDate;
  bool _customFirstPayment = false;

  Map<String, dynamic>? _simulatedSchedule;
  bool _isSimulating = false;
  bool _isSubmitting = false;

  final DateFormat _fmt = DateFormat('dd MMM yyyy', 'es');

  // Interactive Digital Signature Controller
  late final SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: const Color(0xFF1B4D3E),
      exportBackgroundColor: Colors.white,
    );
    _firstPaymentDate = _calcFirstPayment(_startDate, _selectedFrequency);
    _loadCustomers();
    _runSimulation();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _interestRateController.dispose();
    _termUnitsController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  DateTime _calcFirstPayment(DateTime start, String frequency) {
    switch (frequency) {
      case 'daily':
        return start.add(const Duration(days: 1));
      case 'weekly':
        return start.add(const Duration(days: 7));
      case 'biweekly':
        return start.add(const Duration(days: 15));
      case 'monthly':
      case 'mensual':
        return DateTime(start.year, start.month + 1, start.day);
      default:
        return start.add(const Duration(days: 30));
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es'),
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
      if (widget.preselectedCustomerId != null) {
        _selectedCustomerId = widget.preselectedCustomerId;
      } else if (_customers.isNotEmpty) {
        _selectedCustomerId = _i(_customers[0]['id']);
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
    if (!_formKey.currentState!.validate() || _selectedCustomerId == null) {
      CustomToast.show(context, 'Por favor completa todos los campos requeridos', type: ToastType.warning);
      return;
    }

    setState(() => _isSubmitting = true);

    final startStr = _startDate.toIso8601String().substring(0, 10);
    final dueStr = (_firstPaymentDate ?? _calcFirstPayment(_startDate, _selectedFrequency)).toIso8601String().substring(0, 10);

    // Export digital signature if drawn
    Uint8List? signatureBytes;
    String? signatureBase64;
    if (_signatureController.isNotEmpty) {
      signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes != null) {
        signatureBase64 = 'data:image/png;base64,${base64Encode(signatureBytes)}';
      }
    }

    final payload = {
      'customer_id': _selectedCustomerId,
      'amount': double.parse(_amountController.text),
      'interest_rate': double.parse(_interestRateController.text),
      'term_units': int.parse(_termUnitsController.text),
      'frequency': _selectedFrequency,
      'start_date': startStr,
      'disbursed_at': startStr,
      'due_date': dueStr,
      'interest_type': _selectedInterestType,
      'signature_base64': signatureBase64,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    };

    await ApiService.createLoan(payload);
    OfflineSyncQueueManager.enqueue(type: SyncTaskType.createLoan, payload: payload);

    setState(() => _isSubmitting = false);

    if (mounted) {
      CustomToast.show(context, 'Préstamo creado con éxito', type: ToastType.success);

      // Offer contract download / share dialog
      if (signatureBytes != null && _selectedCustomerId != null) {
        final custMatch = _customers.firstWhere((c) => _i(c['id']) == _selectedCustomerId, orElse: () => {});
        final String custName = custMatch.isNotEmpty ? '${custMatch['first_name']} ${custMatch['last_name']}' : 'Cliente';
        final String custCedula = custMatch.isNotEmpty ? '${custMatch['identity_document']}' : '';

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Contrato Firmado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: const Text(
              'El préstamo ha sido firmado y guardado. ¿Deseas exportar o compartir el contrato en PDF ahora?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/loans');
                },
                child: const Text('Más tarde', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await PdfDocumentService.generateAndShareContract(
                    loanData: payload,
                    customerName: custName,
                    customerCedula: custCedula,
                    signatureBytes: signatureBytes,
                  );
                  if (mounted) context.go('/loans');
                },
                icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                label: const Text('Compartir PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        context.go('/loans');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double rate = double.tryParse(_interestRateController.text) ?? 0.0;
    final int terms = int.tryParse(_termUnitsController.text) ?? 1;
    final double totalAmount = _d(_simulatedSchedule?['total_amount'] ?? (amount + (amount * (rate / 100))));
    final double perInstallment = terms > 0 ? totalAmount / terms : totalAmount;
    final List<dynamic> schedule = (_simulatedSchedule?['schedule'] is List) ? _simulatedSchedule!['schedule'] : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Nuevo Préstamo',
        subtitle: 'Amortización y Firma Digital',
        onBackPressed: () => context.go('/loans'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Paso 1: Selección de Cliente
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
                        Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text('1. Selección de Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_customers.isEmpty)
                      ListTile(
                        title: const Text('No hay clientes registrados'),
                        subtitle: const Text('Registra primero un cliente para otorgarle un préstamo'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () => context.go('/clients/new'),
                          child: const Text('Crear Cliente', style: TextStyle(color: Colors.white)),
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedCustomerId,
                        decoration: InputDecoration(
                          labelText: 'Cliente Destinatario',
                          prefixIcon: const Icon(Icons.people_outline_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _customers.map<DropdownMenuItem<int>>((c) {
                          final cid = _i(c['id']);
                          final name = '${c['first_name']} ${c['last_name']}';
                          final ced = CurrencyFormatter.formatCedula('${c['identity_document']}');
                          return DropdownMenuItem<int>(
                            value: cid,
                            child: Text('$name ($ced)', style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCustomerId = val),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Paso 2: Datos Financieros del Préstamo
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
                        Icon(Icons.monetization_on_rounded, color: AppColors.accent, size: 22),
                        SizedBox(width: 8),
                        Text('2. Condiciones del Préstamo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Monto Prestado
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Monto a Prestar (RD\$) *',
                        prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.accent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => _runSimulation(),
                      validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Ingresa un monto válido' : null,
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        // Tasa de Interés (%)
                        Expanded(
                          child: TextFormField(
                            controller: _interestRateController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tasa Interés (%) *',
                              suffixText: '%',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) => _runSimulation(),
                            validator: (val) => val == null || double.tryParse(val) == null ? 'Inválido' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Número de Cuotas
                        Expanded(
                          child: TextFormField(
                            controller: _termUnitsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'N° de Cuotas *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) => _runSimulation(),
                            validator: (val) => val == null || int.tryParse(val) == null || int.parse(val) <= 0 ? 'Inválido' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Frecuencia de Pago
                    DropdownButtonFormField<String>(
                      value: _selectedFrequency,
                      decoration: InputDecoration(
                        labelText: 'Frecuencia de Cobro',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Diario')),
                        DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                        DropdownMenuItem(value: 'biweekly', child: Text('Quincenal')),
                        DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedFrequency = val;
                            _firstPaymentDate = _calcFirstPayment(_startDate, val);
                          });
                          _runSimulation();
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    // Fecha de Desembolso
                    InkWell(
                      onTap: _pickStartDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Fecha de Inicio / Desembolso', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    Text(_fmt.format(_startDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Paso 3: Simulación de Tabla de Amortización
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.table_view_rounded, color: Color(0xFF7C3AED), size: 22),
                            SizedBox(width: 8),
                            Text('3. Resumen y Amortización', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                          ],
                        ),
                        if (_isSimulating)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Total a Pagar', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const SizedBox(height: 2),
                              Text(CurrencyFormatter.formatDOP(totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                            ],
                          ),
                          const Text('|', style: TextStyle(color: Colors.black12)),
                          Column(
                            children: [
                              const Text('Por Cuota', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const SizedBox(height: 2),
                              Text(CurrencyFormatter.formatDOP(perInstallment), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.accent)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (schedule.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Plan de Cuotas Simuladas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: schedule.take(5).length,
                        itemBuilder: (ctx, i) {
                          final row = schedule[i];
                          final due = row['due_date'] ?? '';
                          final cuotaMonto = _d(row['total_amount']);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Cuota #${i + 1} (${AppDateFormatter.formatDate(due)})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text(CurrencyFormatter.formatDOP(cuotaMonto), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                          );
                        },
                      ),
                      if (schedule.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('... y ${schedule.length - 5} cuotas más.', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Paso 4: Firma Digital Interactiva
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.draw_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text('4. Firma Digital del Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _signatureController.clear()),
                          icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: AppColors.danger),
                          label: const Text('Limpiar', style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('El cliente debe firmar con el dedo sobre el lienzo para validar el contrato:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Signature(
                        controller: _signatureController,
                        height: 150,
                        backgroundColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Paso 5: Botón de Confirmación y Creación
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitLoan,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Creando Préstamo...' : 'Crear Préstamo y Generar Contrato',
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
