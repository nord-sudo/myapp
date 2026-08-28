import '../../domain/entities/client_entity.dart';

class ClientModel extends ClientEntity {
  const ClientModel({
    required super.id,
    required super.name,
    required super.cedula,
    required super.phone,
    required super.address,
    super.hasCedulaImage = false,
    super.cedulaFrontUrl,
    super.cedulaBackUrl,
    required super.createdAt,
    required super.status,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
        id: '${json['id'] ?? json['identity_document'] ?? ''}',
        name: '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim().isEmpty
            ? '${json['name'] ?? 'Cliente'}'
            : '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
        cedula: '${json['identity_document'] ?? json['cedula'] ?? ''}',
        phone: '${json['phone'] ?? ''}',
        address: '${json['address'] ?? 'No especificada'}',
        hasCedulaImage: json['hasCedulaImage'] ??
            (json['identity_document_front'] != null &&
                json['identity_document_front'].toString().isNotEmpty),
        cedulaFrontUrl: json['identity_document_front'] ?? json['cedulaFrontUrl'],
        cedulaBackUrl: json['identity_document_back'] ?? json['cedulaBackUrl'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        status: json['status'] ?? 'al_dia',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'first_name': name.split(' ').first,
        'last_name': name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : '',
        'identity_document': cedula,
        'cedula': cedula,
        'phone': phone,
        'address': address,
        'hasCedulaImage': hasCedulaImage,
        'identity_document_front': cedulaFrontUrl,
        'identity_document_back': cedulaBackUrl,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };
}
