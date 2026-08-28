import 'package:equatable/equatable.dart';

class ClientEntity extends Equatable {
  final String id;
  final String name;
  final String cedula;
  final String phone;
  final String address;
  final bool hasCedulaImage;
  final String? cedulaFrontUrl;
  final String? cedulaBackUrl;
  final DateTime createdAt;
  final String status;

  const ClientEntity({
    required this.id,
    required this.name,
    required this.cedula,
    required this.phone,
    required this.address,
    this.hasCedulaImage = false,
    this.cedulaFrontUrl,
    this.cedulaBackUrl,
    required this.createdAt,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        cedula,
        phone,
        address,
        hasCedulaImage,
        cedulaFrontUrl,
        cedulaBackUrl,
        createdAt,
        status,
      ];
}
