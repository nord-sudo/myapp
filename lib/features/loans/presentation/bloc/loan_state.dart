part of 'loan_bloc.dart';

abstract class LoanState extends Equatable {
  const LoanState();
  @override
  List<Object?> get props => [];
}

class LoanInitial extends LoanState {}

class LoanLoading extends LoanState {}

class LoanLoaded extends LoanState {
  final List<LoanEntity> loans;
  const LoanLoaded({required this.loans});
  @override
  List<Object?> get props => [loans];
}

class LoanError extends LoanState {
  final String message;
  const LoanError({required this.message});
  @override
  List<Object?> get props => [message];
}
