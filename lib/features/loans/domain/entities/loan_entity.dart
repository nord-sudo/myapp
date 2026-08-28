import 'package:equatable/equatable.dart';
import 'installment_entity.dart';

class LoanEntity extends Equatable {
  final String id;
  final String clientId;
  final String clientName;
  final double amount;
  final double interestRate;
  final double interest;
  final int numberOfInstallments;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final double totalPaid;
  final String status;
  final List<InstallmentEntity> installments;

  const LoanEntity({
    required this.id,
    required this.clientId,
    this.clientName = 'Cliente',
    required this.amount,
    required this.interestRate,
    this.interest = 0.0,
    required this.numberOfInstallments,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.totalPaid = 0.0,
    required this.status,
    this.installments = const [],
  });

  double get totalPending => (amount + interest) - totalPaid;

  @override
  List<Object?> get props => [
        id,
        clientId,
        clientName,
        amount,
        interestRate,
        interest,
        numberOfInstallments,
        frequency,
        startDate,
        endDate,
        totalPaid,
        status,
        installments,
      ];
}
