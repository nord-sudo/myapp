part of 'client_bloc.dart';

abstract class ClientState extends Equatable {
  const ClientState();
  @override
  List<Object?> get props => [];
}

class ClientInitial extends ClientState {}

class ClientLoading extends ClientState {}

class ClientLoaded extends ClientState {
  final List<ClientEntity> clients;
  final List<ClientEntity> filteredClients;
  const ClientLoaded({required this.clients, required this.filteredClients});
  @override
  List<Object?> get props => [clients, filteredClients];
}

class ClientError extends ClientState {
  final String message;
  const ClientError({required this.message});
  @override
  List<Object?> get props => [message];
}
