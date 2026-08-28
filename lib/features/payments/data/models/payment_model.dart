import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.loanId,
    required super.amount,
    required super.type,
    required super.paymentDate,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: '${json['id'] ?? ''}',
        loanId: '${json['loan_id'] ?? json['loanId'] ?? ''}',
        amount: double.tryParse('${json['amount'] ?? 0}') ?? 0.0,
        type: '${json['payment_type'] ?? json['type'] ?? 'installment'}',
        paymentDate: json['payment_date'] != null ? DateTime.parse(json['payment_date'].toString()) : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'loan_id': loanId,
        'amount': amount,
        'payment_type': type,
        'payment_date': paymentDate.toIso8601String(),
      };
}
