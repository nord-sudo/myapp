import '../../../../core/network/dio_client.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/client_repository.dart';
import '../models/client_model.dart';

class ClientRepositoryImpl implements ClientRepository {
  final List<ClientModel> _localCache = [];

  @override
  Future<List<ClientEntity>> getClients() async {
    try {
      final response = await DioClient.instance.get('/customers');
      final data = response.data;
      final List list = (data is Map && data.containsKey('data'))
          ? data['data']
          : (data is List ? data : []);

      final items = list.map((item) => ClientModel.fromJson(item)).toList();
      _localCache.clear();
      _localCache.addAll(items);
      return items;
    } catch (e) {
      return List.from(_localCache);
    }
  }

  @override
  Future<ClientEntity> addClient(ClientEntity client) async {
    final model = ClientModel(
      id: client.id,
      name: client.name,
      cedula: client.cedula,
      phone: client.phone,
      address: client.address,
      hasCedulaImage: client.hasCedulaImage,
      cedulaFrontUrl: client.cedulaFrontUrl,
      cedulaBackUrl: client.cedulaBackUrl,
      createdAt: client.createdAt,
      status: client.status,
    );

    try {
      final response = await DioClient.instance.post(
        '/customers',
        data: model.toJson(),
      );
      final created = ClientModel.fromJson(response.data);
      _localCache.insert(0, created);
      return created;
    } catch (e) {
      _localCache.insert(0, model);
      return model;
    }
  }
}
