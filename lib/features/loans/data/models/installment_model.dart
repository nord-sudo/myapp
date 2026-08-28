import '../../domain/entities/installment_entity.dart';

class InstallmentModel extends InstallmentEntity {
  const InstallmentModel({
    required super.number,
    required super.amount,
    required super.dueDate,
    super.isPaid = false,
    super.paidDate,
    super.paidAmount,
  });

  factory InstallmentModel.fromJson(Map<String, dynamic> json) => InstallmentModel(
        number: int.tryParse('${json['installment_number'] ?? json['number'] ?? 1}') ?? 1,
        amount: double.tryParse('${json['total_amount'] ?? json['amount'] ?? 0}') ?? 0.0,
        dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'].toString()) : DateTime.now(),
        isPaid: json['status'] == 'paid' || (json['isPaid'] ?? false),
        paidDate: json['paid_at'] != null ? DateTime.parse(json['paid_at'].toString()) : null,
        paidAmount: double.tryParse('${json['paid_amount'] ?? 0}'),
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'amount': amount,
        'due_date': dueDate.toIso8601String(),
        'isPaid': isPaid,
        'paid_at': paidDate?.toIso8601String(),
        'paid_amount': paidAmount,
      };
}
