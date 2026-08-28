import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

class GetClientsUseCase {
  final ClientRepository repository;
  GetClientsUseCase(this.repository);

  Future<List<ClientEntity>> call() {
    return repository.getClients();
  }
}
