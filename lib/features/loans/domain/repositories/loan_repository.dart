import '../entities/loan_entity.dart';

abstract class LoanRepository {
  Future<List<LoanEntity>> getLoans();
  Future<LoanEntity> createLoan(LoanEntity loan);
}
