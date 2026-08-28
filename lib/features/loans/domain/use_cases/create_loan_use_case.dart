import '../entities/loan_entity.dart';
import '../repositories/loan_repository.dart';

class CreateLoanUseCase {
  final LoanRepository repository;
  CreateLoanUseCase(this.repository);

  Future<LoanEntity> call(LoanEntity loan) {
    return repository.createLoan(loan);
  }
}
