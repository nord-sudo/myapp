import '../entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<PaymentEntity> registerPayment(String loanId, double amount, String type);
}
