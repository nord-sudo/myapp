import '../../../../core/network/dio_client.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/repositories/loan_repository.dart';
import '../models/loan_model.dart';

class LoanRepositoryImpl implements LoanRepository {
  final List<LoanModel> _localCache = [];

  @override
  Future<List<LoanEntity>> getLoans() async {
    try {
      final response = await DioClient.instance.get('/loans');
      final data = response.data;
      final List list = (data is Map && data.containsKey('data'))
          ? data['data']
          : (data is List ? data : []);

      final items = list.map((item) => LoanModel.fromJson(item)).toList();
      _localCache.clear();
      _localCache.addAll(items);
      return items;
    } catch (e) {
      return List.from(_localCache);
    }
  }

  @override
  Future<LoanEntity> createLoan(LoanEntity loan) async {
    final model = LoanModel(
      id: loan.id,
      clientId: loan.clientId,
      clientName: loan.clientName,
      amount: loan.amount,
      interestRate: loan.interestRate,
      interest: loan.interest,
      numberOfInstallments: loan.numberOfInstallments,
      frequency: loan.frequency,
      startDate: loan.startDate,
      endDate: loan.endDate,
      totalPaid: loan.totalPaid,
      status: loan.status,
    );

    try {
      final response = await DioClient.instance.post(
        '/loans',
        data: model.toJson(),
      );
      final created = LoanModel.fromJson(response.data);
      _localCache.insert(0, created);
      return created;
    } catch (e) {
      _localCache.insert(0, model);
      return model;
    }
  }
}
