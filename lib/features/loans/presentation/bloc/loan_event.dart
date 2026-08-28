part of 'loan_bloc.dart';

abstract class LoanEvent extends Equatable {
  const LoanEvent();
  @override
  List<Object?> get props => [];
}

class LoadLoans extends LoanEvent {}

class CreateNewLoan extends LoanEvent {
  final LoanEntity loan;
  const CreateNewLoan(this.loan);
  @override
  List<Object?> get props => [loan];
}
