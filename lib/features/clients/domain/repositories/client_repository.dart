import '../entities/client_entity.dart';

abstract class ClientRepository {
  Future<List<ClientEntity>> getClients();
  Future<ClientEntity> addClient(ClientEntity client);
}
