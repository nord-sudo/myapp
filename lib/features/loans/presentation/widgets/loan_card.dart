import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/loan_entity.dart';

class LoanCard extends StatelessWidget {
  final LoanEntity loan;
  const LoanCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final statusColor = loan.status == 'active'
        ? Colors.green
        : loan.status == 'overdue'
            ? Colors.red
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(Icons.attach_money, color: statusColor),
        ),
        title: Text(loan.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Monto: ${CurrencyFormatter.format(loan.amount)} • ${loan.frequency}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(loan.totalPending),
              style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
            ),
            const SizedBox(height: 2),
            Text(
              loan.status == 'active' ? 'Activo' : (loan.status == 'overdue' ? 'En Mora' : 'Pagado'),
              style: TextStyle(fontSize: 11, color: statusColor),
            ),
          ],
        ),
        onTap: () => context.go('/loans/${loan.id}'),
      ),
    );
  }
}
