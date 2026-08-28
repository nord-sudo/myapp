part of 'client_bloc.dart';

abstract class ClientEvent extends Equatable {
  const ClientEvent();
  @override
  List<Object?> get props => [];
}

class LoadClients extends ClientEvent {}

class AddNewClient extends ClientEvent {
  final ClientEntity client;
  const AddNewClient(this.client);
  @override
  List<Object?> get props => [client];
}

class FilterClients extends ClientEvent {
  final String query;
  const FilterClients(this.query);
  @override
  List<Object?> get props => [query];
}
