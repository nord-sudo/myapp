import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

class AddClientUseCase {
  final ClientRepository repository;
  AddClientUseCase(this.repository);

  Future<ClientEntity> call(ClientEntity client) {
    return repository.addClient(client);
  }
}
