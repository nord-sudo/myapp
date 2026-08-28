part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class RegisterPayment extends PaymentEvent {
  final String loanId;
  final double amount;
  final String type;

  const RegisterPayment({
    required this.loanId,
    required this.amount,
    required this.type,
  });

  @override
  List<Object?> get props => [loanId, amount, type];
}
