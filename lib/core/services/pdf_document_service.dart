import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class PdfDocumentService {
  /// Genera y comparte el Contrato de Préstamo con la firma digital embebida
  static Future<void> generateAndShareContract({
    required Map<String, dynamic> loanData,
    required String customerName,
    required String customerCedula,
    Uint8List? signatureBytes,
  }) async {
    final pdf = pw.Document();

    final double amount = (loanData['amount'] is num)
        ? (loanData['amount'] as num).toDouble()
        : double.tryParse('${loanData['amount']}') ?? 0.0;
    final double rate = (loanData['interest_rate'] is num)
        ? (loanData['interest_rate'] as num).toDouble()
        : double.tryParse('${loanData['interest_rate']}') ?? 0.0;
    final int terms = int.tryParse('${loanData['term_units']}') ?? 1;
    final String freq = (loanData['frequency'] ?? 'mensual').toString();
    final String startDate = AppDateFormatter.formatDate(loanData['start_date'] ?? DateTime.now().toIso8601String());
    final double totalAmount = (loanData['total_amount'] is num)
        ? (loanData['total_amount'] as num).toDouble()
        : amount + (amount * (rate / 100));
    final double perInstallment = terms > 0 ? totalAmount / terms : totalAmount;

    pw.MemoryImage? signatureImage;
    if (signatureBytes != null && signatureBytes.isNotEmpty) {
      signatureImage = pw.MemoryImage(signatureBytes);
    } else if (loanData['signature_base64'] != null) {
      try {
        final String b64 = loanData['signature_base64'].toString().contains(',')
            ? loanData['signature_base64'].toString().split(',').last
            : loanData['signature_base64'].toString();
        signatureImage = pw.MemoryImage(base64Decode(b64));
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PRESTA RD',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('1B4D3E'),
                        ),
                      ),
                      pw.Text(
                        'Sistema de Préstamos y Cobranza - Rep. Dominicana',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('F1F5F9'),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'CONTRATO DE PRÉSTAMO',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('1B4D3E'),
                      ),
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Clause preamble
              pw.Text(
                'CONTRATO DE MUTUO DINERARIO',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Entre el Prestamista autorizado y el Cliente que suscribe, se conviene y pacta lo siguiente bajo las leyes de la República Dominicana:',
                style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
              ),
              pw.SizedBox(height: 14),

              // Client details box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DATOS DEL PRESTATARIO (DEUDOR)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('1B4D3E'))),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(child: pw.Text('Nombre: $customerName', style: const pw.TextStyle(fontSize: 10))),
                        pw.Expanded(child: pw.Text('Cédula: ${CurrencyFormatter.formatCedula(customerCedula)}', style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Financial breakdown
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('F8FAF9'),
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CONDICIONES FINANCIERAS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('1B4D3E'))),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _pdfKeyVal('Capital Prestado:', CurrencyFormatter.formatDOP(amount)),
                        _pdfKeyVal('Tasa de Interés:', '${rate.toStringAsFixed(2)}%'),
                        _pdfKeyVal('Frecuencia:', freq.toUpperCase()),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _pdfKeyVal('Plazo / Cuotas:', '$terms cuotas'),
                        _pdfKeyVal('Monto por Cuota:', CurrencyFormatter.formatDOP(perInstallment)),
                        _pdfKeyVal('Total a Pagar:', CurrencyFormatter.formatDOP(totalAmount)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        _pdfKeyVal('Fecha de Desembolso:', startDate),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Clauses
              pw.Text(
                'CLÁUSULAS PRINCIPALES:\n'
                '1. El Deudor reconoce haber recibido la suma indicada en calidad de préstamo y se compromete a pagarla en las cuotas y fechas estipuladas.\n'
                '2. En caso de mora, se aplicarán los recargos e intereses de acuerdo a las disposiciones acordadas.\n'
                '3. El Deudor autoriza la consulta y reporte en los burós de crédito autorizados en caso de incumplimiento.',
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 2, color: PdfColors.grey800),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Lender
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 160, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 4),
                      pw.Text('Firma del Prestamista / Cobrador', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('PrestaRD', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),

                  // Borrower Signature Canvas Output
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (signatureImage != null)
                        pw.Container(
                          width: 140,
                          height: 50,
                          child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.SizedBox(height: 50),
                      pw.Container(width: 160, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 4),
                      pw.Text('Firma del Prestatario', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text(customerName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Céd: ${CurrencyFormatter.formatCedula(customerCedula)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Contrato_Prestamo_${customerName.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Genera y comparte el Recibo de Pago Digital en PDF
  static Future<void> generateAndShareReceipt({
    required Map<String, dynamic> receiptData,
  }) async {
    final pdf = pw.Document();

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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('PRESTA RD', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('1B4D3E'))),
              pw.Text('COMPROBANTE DE PAGO', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('N° $receiptNo', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.Text('Fecha: $date', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cliente:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(customerName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Método:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(method, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('MONTO RECIBIDO:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    CurrencyFormatter.formatDOP(amount),
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('10B981')),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Balance Pendiente:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.Text(
                    CurrencyFormatter.formatDOP(balanceRemaining),
                    style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Text('¡Gracias por su pago puntual!', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Recibo_$receiptNo.pdf',
    );
  }

  static pw.Widget _pdfKeyVal(String key, String val) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(key, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(val, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
