import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/pdf_document_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> receiptData;

  const ReceiptScreen({super.key, required this.receiptData});

  @override
  Widget build(BuildContext context) {
    final String receiptNo = receiptData['receipt_number'] ?? 'REC-${DateTime.now().millisecondsSinceEpoch}';
    final String customerName = receiptData['customer_name'] ?? 'Cliente';
    final double amount = (receiptData['amount'] is num)
        ? (receiptData['amount'] as num).toDouble()
        : double.tryParse('${receiptData['amount']}') ?? 0.0;
    final String method = receiptData['payment_method'] ?? 'Efectivo';
    final String date = receiptData['date'] ?? DateTime.now().toIso8601String().substring(0, 10);
    final double balanceRemaining = (receiptData['balance_remaining'] is num)
        ? (receiptData['balance_remaining'] as num).toDouble()
        : double.tryParse('${receiptData['balance_remaining']}') ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Comprobante de Pago',
        subtitle: 'Recibo Oficial PrestaRD',
        onBackPressed: () => context.go('/dashboard'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Receipt Ticket Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    // Success Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 52),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      '¡Cobro Registrado con Éxito!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'N° de Recibo: $receiptNo',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    _ticketRow('Cliente', customerName),
                    const SizedBox(height: 10),
                    _ticketRow('Fecha y Hora', date),
                    const SizedBox(height: 10),
                    _ticketRow('Método de Pago', method),
                    const SizedBox(height: 10),
                    _ticketRow('Estado', 'Confirmado ✓', valueColor: AppColors.success),

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monto Cobrado:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(
                          CurrencyFormatter.formatDOP(amount),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Balance Restante:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          CurrencyFormatter.formatDOP(balanceRemaining),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      onPressed: () async {
                        await PdfDocumentService.generateAndShareReceipt(receiptData: receiptData);
                      },
                      icon: const Icon(Icons.share_rounded, color: AppColors.primary, size: 18),
                      label: const Text('Compartir PDF', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => context.go('/dashboard'),
                      icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
                      label: const Text('Finalizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ticketRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
