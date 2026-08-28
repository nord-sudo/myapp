import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/network/api_service.dart';


double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return (v as num).toDouble();
}

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchPortfolio();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPortfolio() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getLoans();
    if (mounted) {
      setState(() {
        _loans = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _loans.where((l) => l['status'] == 'active').toList();
    final overdueList = _loans.where((l) => l['status'] == 'overdue').toList();
    final paidList = _loans.where((l) => l['status'] == 'paid').toList();

    double totalDisbursed = 0.0;
    double totalOverdue = 0.0;
    for (final l in _loans) {
      totalDisbursed += _d(l['amount']);
      if (l['status'] == 'overdue') {
        totalOverdue += _d(l['balance_remaining']);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Cobranza y Atrasos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Todos (${_loans.length})'),
            Tab(text: 'Al Día (${activeList.length})'),
            Tab(text: 'En Mora (${overdueList.length})'),
            Tab(text: 'Completados (${paidList.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPortfolio,
              child: Column(
                children: [
                  // Portfolio Summary Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric('Total Desembolsado', CurrencyFormatter.formatDOP(totalDisbursed), AppColors.accent),
                        _buildMetric('Total Atrasado', CurrencyFormatter.formatDOP(totalOverdue), AppColors.danger),
                        _buildMetric('Activos / Mora', '${activeList.length} / ${overdueList.length}', AppColors.success),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPortfolioList(_loans),
                        _buildPortfolioList(activeList),
                        _buildPortfolioList(overdueList),
                        _buildPortfolioList(paidList),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPortfolioList(List<dynamic> list) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 60),
          Center(
            child: Text('No hay préstamos en esta categoría',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final bool isOverdue = item['status'] == 'overdue';
        final bool isPaid = item['status'] == 'paid';

        final String customerName = item['customer_name'] ?? 'Cliente';
        final String phone = item['customer_phone'] ?? 'Sin teléfono';
        final double balance = _d(item['balance_remaining']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isOverdue
                                ? AppColors.danger
                                : (isPaid ? AppColors.success : AppColors.accent))
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOverdue
                            ? 'EN MORA'
                            : (isPaid ? 'COMPLETADO' : 'AL DÍA'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOverdue
                              ? AppColors.danger
                              : (isPaid ? AppColors.success : AppColors.accent),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('📞 $phone', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const Divider(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo Pendiente: ${CurrencyFormatter.formatDOP(balance)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isOverdue ? AppColors.danger : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
