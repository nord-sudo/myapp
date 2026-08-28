import '../../domain/entities/loan_entity.dart';
import 'installment_model.dart';

class LoanModel extends LoanEntity {
  const LoanModel({
    required super.id,
    required super.clientId,
    super.clientName = 'Cliente',
    required super.amount,
    required super.interestRate,
    super.interest = 0.0,
    required super.numberOfInstallments,
    required super.frequency,
    required super.startDate,
    super.endDate,
    super.totalPaid = 0.0,
    required super.status,
    super.installments = const [],
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    final List instList = (json['installments'] is List) ? json['installments'] : [];
    final installments = instList.map((i) => InstallmentModel.fromJson(i)).toList();
    final clientData = json['customer'] ?? json['client'] ?? {};

    final amt = double.tryParse('${json['amount'] ?? 0}') ?? 0.0;
    final rate = double.tryParse('${json['interest_rate'] ?? 0}') ?? 0.0;
    final totalInt = double.tryParse('${json['total_interest'] ?? (amt * (rate / 100))}') ?? 0.0;

    return LoanModel(
      id: '${json['id'] ?? ''}',
      clientId: '${json['customer_id'] ?? json['clientId'] ?? ''}',
      clientName: '${clientData['first_name'] ?? ''} ${clientData['last_name'] ?? ''}'.trim().isEmpty
          ? '${json['client_name'] ?? 'Cliente'}'
          : '${clientData['first_name'] ?? ''} ${clientData['last_name'] ?? ''}'.trim(),
      amount: amt,
      interestRate: rate,
      interest: totalInt,
      numberOfInstallments: int.tryParse('${json['term_units'] ?? json['numberOfInstallments'] ?? 1}') ?? 1,
      frequency: '${json['payment_frequency'] ?? json['frequency'] ?? 'semanal'}',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'].toString()) : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'].toString()) : null,
      totalPaid: double.tryParse('${json['total_paid'] ?? json['totalPaid'] ?? 0}') ?? 0.0,
      status: '${json['status'] ?? 'active'}',
      installments: installments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': clientId,
        'amount': amount,
        'interest_rate': interestRate,
        'total_interest': interest,
        'term_units': numberOfInstallments,
        'payment_frequency': frequency,
        'start_date': startDate.toIso8601String(),
        'total_paid': totalPaid,
        'status': status,
        'installments': installments.map((i) => (i as InstallmentModel).toJson()).toList(),
      };
}
