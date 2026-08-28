import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/use_cases/get_clients_use_case.dart';
import '../../domain/use_cases/add_client_use_case.dart';

part 'client_event.dart';
part 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final GetClientsUseCase getClients;
  final AddClientUseCase addClient;

  ClientBloc({required this.getClients, required this.addClient})
      : super(ClientInitial()) {
    on<LoadClients>(_onLoadClients);
    on<AddNewClient>(_onAddNewClient);
    on<FilterClients>(_onFilterClients);
  }

  Future<void> _onLoadClients(LoadClients event, Emitter<ClientState> emit) async {
    emit(ClientLoading());
    try {
      final clients = await getClients();
      emit(ClientLoaded(clients: clients, filteredClients: clients));
    } catch (e) {
      emit(ClientError(message: e.toString()));
    }
  }

  Future<void> _onAddNewClient(AddNewClient event, Emitter<ClientState> emit) async {
    try {
      final newClient = await addClient(event.client);
      final currentState = state;
      if (currentState is ClientLoaded) {
        final updatedList = [newClient, ...currentState.clients];
        emit(ClientLoaded(clients: updatedList, filteredClients: updatedList));
      } else {
        emit(ClientLoaded(clients: [newClient], filteredClients: [newClient]));
      }
    } catch (e) {
      emit(ClientError(message: e.toString()));
    }
  }

  void _onFilterClients(FilterClients event, Emitter<ClientState> emit) {
    final currentState = state;
    if (currentState is ClientLoaded) {
      final query = event.query.toLowerCase().trim();
      if (query.isEmpty) {
        emit(ClientLoaded(clients: currentState.clients, filteredClients: currentState.clients));
      } else {
        final filtered = currentState.clients.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.cedula.contains(query) ||
              c.phone.contains(query);
        }).toList();
        emit(ClientLoaded(clients: currentState.clients, filteredClients: filtered));
      }
    }
  }
}
