import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/services/notification_service.dart';
import 'loan_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _isLoading = true;
  String _filter = 'all'; // all, urgent, warning, info

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    await NotificationService.refreshAlerts();
    if (mounted) setState(() => _isLoading = false);
  }

  List<AppAlert> get _filteredAlerts {
    final all = NotificationService.alerts;
    if (_filter == 'all') return all;
    if (_filter == 'urgent') return all.where((a) => a.priority == AlertPriority.urgent).toList();
    if (_filter == 'warning') return all.where((a) => a.priority == AlertPriority.warning).toList();
    if (_filter == 'info') return all.where((a) => a.priority == AlertPriority.info).toList();
    return all;
  }

  void _navigateToLoan(AppAlert alert) {
    if (alert.loanData != null) {
      NotificationService.markRead(alert.id);
      setState(() {});
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoanDetailScreen(
            loan: alert.loanData!,
            onRefresh: _loadAlerts,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _filteredAlerts;
    final int totalCount = NotificationService.alerts.length;
    final int unreadCount = NotificationService.alerts.where((a) => !a.isRead).length;
    final int urgentCount = NotificationService.alerts.where((a) => a.priority == AlertPriority.urgent).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 22),
            tooltip: 'Marcar todas como leídas',
            onPressed: () {
              NotificationService.markAllRead();
              setState(() {});
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ─── Filter Tabs (Todas, No leídas, Importantes) ───────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      _buildAlertTabPill('Todas ($totalCount)', 'all'),
                      const SizedBox(width: 8),
                      _buildAlertTabPill('No leídas ($unreadCount)', 'unread'),
                      const SizedBox(width: 8),
                      _buildAlertTabPill('Importantes ($urgentCount)', 'urgent'),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ─── Notification List ─────────────────────────────────────
                Expanded(
                  child: alerts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: AppColors.infoBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No tienes notificaciones',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Las alertas y avisos de cobro aparecerán aquí.',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAlerts,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: alerts.length,
                            itemBuilder: (context, index) {
                              final alert = alerts[index];
                              return _AlertCard(
                                alert: alert,
                                onTap: () => _navigateToLoan(alert),
                                onDismiss: () {
                                  NotificationService.dismiss(alert.id);
                                  setState(() {});
                                },
                                onMarkRead: () {
                                  NotificationService.markRead(alert.id);
                                  setState(() {});
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildAlertTabPill(String label, String key) {
    final bool isSelected = _filter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.infoBg : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AppAlert alert;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback onMarkRead;

  const _AlertCard({
    required this.alert,
    required this.onTap,
    required this.onDismiss,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    Color iconBgColor;
    Color iconColor;
    IconData iconData;

    switch (alert.priority) {
      case AlertPriority.urgent:
        iconBgColor = AppColors.dangerBg;
        iconColor = AppColors.danger;
        iconData = Icons.warning_rounded;
        break;
      case AlertPriority.warning:
        iconBgColor = AppColors.warningBg;
        iconColor = AppColors.warning;
        iconData = Icons.access_time_filled_rounded;
        break;
      case AlertPriority.info:
        iconBgColor = AppColors.successBg;
        iconColor = AppColors.success;
        iconData = Icons.attach_money_rounded;
        break;
    }

    // Custom icons according to notification content keywords
    final String lowerTitle = alert.title.toLowerCase();
    if (lowerTitle.contains('cliente')) {
      iconBgColor = AppColors.infoBg;
      iconColor = AppColors.info;
      iconData = Icons.person_rounded;
    } else if (lowerTitle.contains('reporte')) {
      iconBgColor = const Color(0xFFF3E8FF);
      iconColor = const Color(0xFF9333EA);
      iconData = Icons.bar_chart_rounded;
    }

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
        ),
        child: InkWell(
          onTap: alert.loanData != null ? onTap : onMarkRead,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular colored avatar icon
                CircleAvatar(
                  radius: 20,
                  backgroundColor: iconBgColor,
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        alert.message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Time ago & Unread Blue Dot Indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Hace 5 min',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    if (!alert.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

