import '../../../../core/network/dio_client.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  @override
  Future<PaymentEntity> registerPayment(String loanId, double amount, String type) async {
    final payload = {
      'loan_id': loanId,
      'amount': amount,
      'payment_type': type,
      'payment_date': DateTime.now().toIso8601String(),
    };

    try {
      final response = await DioClient.instance.post('/payments', data: payload);
      return PaymentModel.fromJson(response.data);
    } catch (e) {
      return PaymentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        loanId: loanId,
        amount: amount,
        type: type,
        paymentDate: DateTime.now(),
      );
    }
  }
}
