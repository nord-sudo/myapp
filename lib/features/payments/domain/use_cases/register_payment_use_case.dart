import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class RegisterPaymentUseCase {
  final PaymentRepository repository;
  RegisterPaymentUseCase(this.repository);

  Future<PaymentEntity> call(String loanId, double amount, String type) {
    return repository.registerPayment(loanId, amount, type);
  }
}
