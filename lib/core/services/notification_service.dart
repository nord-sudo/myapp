import '../network/api_service.dart';

/// Types of alerts the system can generate
enum AlertType { overdue, dueSoon, dueToday, dailySummary, paymentConfirmed }

/// Priority levels for sorting/display
enum AlertPriority { urgent, warning, info }

/// A single alert/reminder
class AppAlert {
  final String id;
  final AlertType type;
  final AlertPriority priority;
  final String title;
  final String message;
  final DateTime createdAt;
  final Map<String, dynamic>? loanData;
  bool isRead;

  AppAlert({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.createdAt,
    this.loanData,
    this.isRead = false,
  });
}

/// Central service that generates alerts from loan/payment data
class NotificationService {
  static final List<AppAlert> _alerts = [];
  static final Set<String> _dismissedIds = {};

  /// Get all current alerts, sorted by priority (urgent first)
  static List<AppAlert> get alerts {
    final list = _alerts
        .where((a) => !_dismissedIds.contains(a.id))
        .toList();
    list.sort((a, b) {
      final pCmp = a.priority.index.compareTo(b.priority.index);
      if (pCmp != 0) return pCmp;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  /// Count of unread alerts
  static int get unreadCount =>
      _alerts.where((a) => !a.isRead && !_dismissedIds.contains(a.id)).length;

  /// Mark a single alert as read
  static void markRead(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) _alerts[idx].isRead = true;
  }

  /// Mark all alerts as read
  static void markAllRead() {
    for (final a in _alerts) {
      a.isRead = true;
    }
  }

  /// Dismiss (hide) a single alert
  static void dismiss(String alertId) {
    _dismissedIds.add(alertId);
  }

  /// Clear all alerts and regenerate from fresh data
  static Future<void> refreshAlerts() async {
    // Preserve read state for existing alerts
    final Map<String, bool> readState = {};
    for (final a in _alerts) {
      readState[a.id] = a.isRead;
    }

    _alerts.clear();

    // Fetch current loans
    final loans = await ApiService.getLoans();
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    double totalDueToday = 0.0;
    int overdueCount = 0;
    double overdueTotal = 0.0;

    for (final loan in loans) {
      final status = loan['status'] as String? ?? 'active';
      final balance = _d(loan['balance_remaining']);
      final customerName = loan['customer_name'] ?? 'Cliente';
      final loanId = loan['id'];
      final nextPayDateStr = loan['next_payment_date'] ?? loan['due_date'];

      if (status == 'paid' || balance <= 0) continue;

      DateTime? nextPayDate;
      if (nextPayDateStr != null) {
        nextPayDate = DateTime.tryParse(nextPayDateStr.toString());
      }

      // ─── Overdue alerts (URGENT) ─────────────────────────────
      if (status == 'overdue') {
        overdueCount++;
        overdueTotal += balance;
        int daysOverdue = 0;
        if (nextPayDate != null) {
          daysOverdue = now.difference(nextPayDate).inDays;
          if (daysOverdue < 0) daysOverdue = 0;
        }

        final id = 'overdue_${loanId}';
        _alerts.add(AppAlert(
          id: id,
          type: AlertType.overdue,
          priority: AlertPriority.urgent,
          title: '⚠️ $customerName — EN MORA',
          message: daysOverdue > 0
              ? 'Préstamo con $daysOverdue días de atraso. Pendiente: ${_fmtDOP(balance)}'
              : 'Este préstamo tiene cuotas vencidas sin pagar. Pendiente: ${_fmtDOP(balance)}',
          createdAt: now,
          loanData: Map<String, dynamic>.from(loan),
          isRead: readState[id] ?? false,
        ));
      }

      // ─── Due today alerts (WARNING) ──────────────────────────
      if (nextPayDate != null && _isSameDay(nextPayDate, now)) {
        totalDueToday += balance;
        final cuota = _d(loan['total_amount']) /
            (_d(loan['term_units']) > 0 ? _d(loan['term_units']) : 1.0);

        final id = 'due_today_${loanId}';
        _alerts.add(AppAlert(
          id: id,
          type: AlertType.dueToday,
          priority: AlertPriority.warning,
          title: '📅 Cuota de $customerName vence hoy',
          message: 'Monto de cuota: ${_fmtDOP(cuota)}. No olvides cobrar.',
          createdAt: now,
          loanData: Map<String, dynamic>.from(loan),
          isRead: readState[id] ?? false,
        ));
      }

      // ─── Due soon alerts (tomorrow / next 3 days) ────────────
      if (nextPayDate != null && !_isSameDay(nextPayDate, now)) {
        final daysUntil = nextPayDate.difference(now).inDays;
        if (daysUntil >= 0 && daysUntil <= 3) {
          final cuota = _d(loan['total_amount']) /
              (_d(loan['term_units']) > 0 ? _d(loan['term_units']) : 1.0);

          final label = daysUntil == 0
              ? 'hoy'
              : daysUntil == 1
                  ? 'mañana'
                  : 'en $daysUntil días';

          final id = 'due_soon_${loanId}';
          _alerts.add(AppAlert(
            id: id,
            type: AlertType.dueSoon,
            priority: AlertPriority.warning,
            title: '🔔 Pago de $customerName vence $label',
            message: 'Cuota de ${_fmtDOP(cuota)} pendiente. Programa el cobro.',
            createdAt: now,
            loanData: Map<String, dynamic>.from(loan),
            isRead: readState[id] ?? false,
          ));
        }
      }
    }

    // ─── Daily summary alert (INFO) ─────────────────────────────
    if (overdueCount > 0 || totalDueToday > 0) {
      final id = 'summary_$todayStr';
      final parts = <String>[];
      if (overdueCount > 0) {
        parts.add('$overdueCount préstamo${overdueCount > 1 ? "s" : ""} en mora (${_fmtDOP(overdueTotal)})');
      }
      if (totalDueToday > 0) {
        parts.add('${_fmtDOP(totalDueToday)} con cuotas que vencen hoy');
      }

      _alerts.insert(0, AppAlert(
        id: id,
        type: AlertType.dailySummary,
        priority: AlertPriority.info,
        title: '📊 Resumen del Día',
        message: parts.join('. ') + '.',
        createdAt: now,
        isRead: readState[id] ?? false,
      ));
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────
  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return (v as num).toDouble();
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _fmtDOP(double amount) {
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'),
      (m) => '${m[1]},',
    );
    return '$formatted RD\$';
  }
}
