import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String id;
  final String loanId;
  final double amount;
  final String type;
  final DateTime paymentDate;

  const PaymentEntity({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.type,
    required this.paymentDate,
  });

  @override
  List<Object?> get props => [id, loanId, amount, type, paymentDate];
}
