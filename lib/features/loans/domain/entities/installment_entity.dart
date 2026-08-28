import 'package:equatable/equatable.dart';

class InstallmentEntity extends Equatable {
  final int number;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final DateTime? paidDate;
  final double? paidAmount;

  const InstallmentEntity({
    required this.number,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.paidDate,
    this.paidAmount,
  });

  @override
  List<Object?> get props => [number, amount, dueDate, isPaid, paidDate, paidAmount];
}
