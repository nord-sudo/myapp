import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/network/api_service.dart';
import 'loan_form_screen.dart';
import 'loan_detail_screen.dart';
import 'payment_form_screen.dart';

double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return (v as num).toDouble();
}

class LoanListScreen extends StatefulWidget {
  const LoanListScreen({super.key});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> {
  List<dynamic> _loans = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getLoans();
    if (mounted) {
      setState(() {
        _loans = data;
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredLoans {
    if (_statusFilter == 'active') {
      return _loans.where((l) => l['status'] == 'active').toList();
    } else if (_statusFilter == 'overdue') {
      return _loans.where((l) => l['status'] == 'overdue').toList();
    } else if (_statusFilter == 'paid') {
      return _loans.where((l) => l['status'] == 'paid').toList();
    }
    return _loans;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredLoans;
    final int activeCount = _loans.where((l) => l['status'] == 'active').length;
    final int overdueCount = _loans.where((l) => l['status'] == 'overdue').length;

    double totalBalanceRemaining = 0.0;
    double totalOverdueAmount = 0.0;

    for (final l in _loans) {
      final balance = _d(l['balance_remaining'] ?? l['total_amount'] ?? l['amount']);
      totalBalanceRemaining += balance;
      if (l['status'] == 'overdue') {
        totalOverdueAmount += balance;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Préstamos & Cobranza',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_rounded, color: Colors.white, size: 24),
            tooltip: 'Nuevo Préstamo',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoanFormScreen()),
              );
              if (result == true) _fetchLoans();
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderTab('Todos', 'all', Icons.list_rounded),
                _buildHeaderTab('Activos', 'active', Icons.play_circle_outline_rounded),
                _buildHeaderTab('En Mora', 'overdue', Icons.warning_amber_rounded),
                _buildHeaderTab('Pagados', 'paid', Icons.check_circle_outline_rounded),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoanFormScreen()),
          );
          if (result == true) _fetchLoans();
        },
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: const Text(
          'Nuevo Préstamo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _fetchLoans,
              color: AppColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Cartera Total Pendiente',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.formatDOP(totalBalanceRemaining),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$activeCount Activos',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const Text('|', style: TextStyle(color: Colors.white38)),
                                Row(
                                  children: [
                                    const Icon(Icons.warning_rounded, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$overdueCount En Mora',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const Text('|', style: TextStyle(color: Colors.white38)),
                                Text(
                                  'Mora: ${CurrencyFormatter.formatDOP(totalOverdueAmount)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (list.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.credit_card_off_rounded, size: 48, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text(
                                'No hay préstamos en esta categoría',
                                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final loan = list[index];
                          final String clientName = loan['customer_name'] ?? 'Cliente';
                          final String status = (loan['status'] ?? 'active').toString().toUpperCase();
                          final double amount = _d(loan['amount']);
                          final double balance = _d(loan['balance_remaining'] ?? loan['total_amount'] ?? amount);
                          final double rate = _d(loan['interest_rate']);
                          final int terms = int.tryParse('${loan['term_units']}') ?? 4;
                          final String freq = (loan['frequency'] ?? 'mensual').toString().toLowerCase();
                          final String freqLabel = freq == 'weekly' ? 'Semanal' : (freq == 'biweekly' ? 'Quincenal' : 'Mensual');
                          final String startDate = AppDateFormatter.formatDate(loan['disbursed_at'] ?? loan['start_date']);
                          final String dueDate = AppDateFormatter.formatDate(loan['due_date'] ?? loan['next_payment_date']);

                          final double total = _d(loan['total_amount'] ?? (amount + (amount * rate / 100)));
                          final double paid = total > balance ? (total - balance) : 0.0;
                          final double progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
                          final int progressPct = (progress * 100).toInt();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Color(0xFFF1F5F9),
                                        child: Icon(Icons.person_rounded, size: 22, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Cliente: $clientName',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$freqLabel • $terms cuotas',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: status == 'OVERDUE'
                                              ? AppColors.dangerBg
                                              : (status == 'PAID' ? AppColors.infoBg : const Color(0xFFF1F5F9)),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: status == 'OVERDUE'
                                                ? AppColors.danger
                                                : (status == 'PAID' ? AppColors.info : const Color(0xFF475569)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accent,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                          ),
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PaymentFormScreen(
                                                  loan: loan,
                                                  preselectedCustomerId: loan['customer_id'] != null
                                                      ? int.tryParse('${loan['customer_id']}')
                                                      : null,
                                                ),
                                              ),
                                            );
                                            _fetchLoans();
                                          },
                                          icon: const Icon(Icons.payments_rounded, color: Colors.white, size: 18),
                                          label: const Text(
                                            'Cobrar Cuota',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.grey.shade300, width: 1),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => LoanDetailScreen(loan: loan, onRefresh: _fetchLoans),
                                            ),
                                          ),
                                          icon: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.textPrimary, size: 18),
                                          label: const Text(
                                            'Ver Cuotas',
                                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAF9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Inicio: $startDate',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.event_available_rounded, size: 13, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Pago: $dueDate',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Prestado', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyFormatter.formatDOP(amount),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Pendiente', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyFormatter.formatDOP(balance),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Tasa', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${rate.toStringAsFixed(2)}%',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Progreso de pago', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      Text('$progressPct%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 5,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderTab(String label, String key, IconData icon) {
    final bool isSelected = _statusFilter == key;
    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white60,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 32,
            color: isSelected ? Colors.white : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

