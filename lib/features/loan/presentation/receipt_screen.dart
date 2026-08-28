import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';


class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> receiptData;
  const ReceiptScreen({Key? key, required this.receiptData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Comprobante de Pago'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Ticket Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¡PAGO REGISTRADO!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.success),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recibo #${receiptData['receipt_number']}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),

                  _buildReceiptRow('Cliente:', receiptData['customer_name'] ?? 'Juan Pérez'),
                  _buildReceiptRow('Fecha:', AppDateFormatter.formatDate(receiptData['date'])),
                  _buildReceiptRow('Método:', receiptData['payment_method'] ?? 'Efectivo'),
                  if (receiptData['proof_image'] != null)
                    _buildReceiptRow('Comprobante:', '📷 Adjuntado'),
                  const Divider(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monto Pagado:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        CurrencyFormatter.formatDOP(receiptData['amount']),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.success),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _buildReceiptRow('Balance Restante:', CurrencyFormatter.formatDOP(receiptData['balance_remaining'])),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Share by WhatsApp Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enviando recibo por WhatsApp...')),
                  );
                },
                icon: const Icon(Icons.chat_rounded, color: Colors.white),
                label: const Text('Enviar Recibo por WhatsApp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Volver al Inicio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
