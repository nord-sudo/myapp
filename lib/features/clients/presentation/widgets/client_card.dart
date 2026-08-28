import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/client_entity.dart';

class ClientCard extends StatelessWidget {
  final ClientEntity client;

  const ClientCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final statusColor = client.status == 'al_dia'
        ? Colors.green
        : client.status == 'en_mora'
            ? Colors.red
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Text(
            client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cédula: ${client.cedula}'),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    client.address,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                client.status == 'al_dia' ? 'Al día' : 'En mora',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              client.hasCedulaImage ? Icons.verified : Icons.warning,
              color: client.hasCedulaImage ? Colors.green : Colors.orange,
              size: 16,
            ),
          ],
        ),
        onTap: () => context.go('/clients/${client.id}'),
      ),
    );
  }
}
