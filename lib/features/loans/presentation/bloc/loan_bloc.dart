import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/use_cases/get_loans_use_case.dart';
import '../../domain/use_cases/create_loan_use_case.dart';

part 'loan_event.dart';
part 'loan_state.dart';

class LoanBloc extends Bloc<LoanEvent, LoanState> {
  final GetLoansUseCase getLoans;
  final CreateLoanUseCase createLoan;

  LoanBloc({required this.getLoans, required this.createLoan})
      : super(LoanInitial()) {
    on<LoadLoans>(_onLoadLoans);
    on<CreateNewLoan>(_onCreateNewLoan);
  }

  Future<void> _onLoadLoans(LoadLoans event, Emitter<LoanState> emit) async {
    emit(LoanLoading());
    try {
      final loans = await getLoans();
      emit(LoanLoaded(loans: loans));
    } catch (e) {
      emit(LoanError(message: e.toString()));
    }
  }

  Future<void> _onCreateNewLoan(CreateNewLoan event, Emitter<LoanState> emit) async {
    try {
      final newLoan = await createLoan(event.loan);
      final currentState = state;
      if (currentState is LoanLoaded) {
        emit(LoanLoaded(loans: [newLoan, ...currentState.loans]));
      } else {
        emit(LoanLoaded(loans: [newLoan]));
      }
    } catch (e) {
      emit(LoanError(message: e.toString()));
    }
  }
}
