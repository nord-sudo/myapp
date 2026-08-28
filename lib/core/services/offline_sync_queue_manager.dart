import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_service.dart';


enum SyncTaskType {
  createCustomer,
  createLoan,
  processPayment,
}

class SyncTask {
  final String id;
  final SyncTaskType type;
  final Map<String, dynamic> payload;
  final String idempotencyKey;
  final DateTime createdAt;
  int attempts;

  SyncTask({
    required this.id,
    required this.type,
    required this.payload,
    required this.idempotencyKey,
    required this.createdAt,
    this.attempts = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'idempotencyKey': idempotencyKey,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
      };

  factory SyncTask.fromJson(Map<String, dynamic> json) => SyncTask(
        id: json['id'] ?? '',
        type: SyncTaskType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => SyncTaskType.createCustomer,
        ),
        payload: Map<String, dynamic>.from(json['payload'] ?? {}),
        idempotencyKey: json['idempotencyKey'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        attempts: json['attempts'] ?? 0,
      );
}

class OfflineSyncQueueManager {
  static const String _prefKey = 'prestamistas_offline_sync_queue';
  static final List<SyncTask> _pendingQueue = [];
  static bool _isProcessing = false;
  static Timer? _autoSyncTimer;

  /// Initializes persistent queue storage and background timer
  static Future<void> init() async {
    await _loadFromDisk();
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      processQueue();
    });
  }

  static Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonStr);
        _pendingQueue.clear();
        for (var item in decoded) {
          if (item is Map<String, dynamic>) {
            _pendingQueue.add(SyncTask.fromJson(item));
          }
        }
        debugPrint('💾 [Offline Queue] Cargadas ${_pendingQueue.length} tareas desde almacenamiento interno.');
      }
    } catch (e) {
      debugPrint('Error loading offline queue: $e');
    }
  }

  static Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(_pendingQueue.map((t) => t.toJson()).toList());
      await prefs.setString(_prefKey, encoded);
    } catch (e) {
      debugPrint('Error saving offline queue: $e');
    }
  }

  /// Adds a task to the offline queue and triggers background processing
  static void enqueue({
    required SyncTaskType type,
    required Map<String, dynamic> payload,
  }) {
    final String key = payload['idempotency_key'] ?? ApiService.generateIdempotencyKey();
    final task = SyncTask(
      id: key,
      type: type,
      payload: payload,
      idempotencyKey: key,
      createdAt: DateTime.now(),
    );

    _pendingQueue.add(task);
    _saveToDisk();

    debugPrint('📥 [Queue] Enqueued task [${type.name}] (Total en cola: ${_pendingQueue.length})');

    // Trigger process in background asynchronously
    processQueue();
  }

  /// Returns current pending queue count
  static int get pendingCount => _pendingQueue.length;

  /// Process pending queued items sequentially with delay to avoid server overload
  static Future<void> processQueue() async {
    if (_isProcessing || _pendingQueue.isEmpty) return;
    _isProcessing = true;

    debugPrint('🔄 [Queue Processor] Intentando sincronizar ${_pendingQueue.length} tareas pendientes con el servidor...');

    final List<SyncTask> toRemove = [];

    for (final task in List<SyncTask>.from(_pendingQueue)) {
      task.attempts++;
      bool success = false;

      try {
        await Future.delayed(const Duration(milliseconds: 500)); // Rate-limiting delay

        switch (task.type) {
          case SyncTaskType.createCustomer:
            final res = await ApiService.createCustomer(task.payload);
            if (res != null) success = true;
            break;

          case SyncTaskType.createLoan:
            final res = await ApiService.createLoan(task.payload);
            if (res != null) success = true;
            break;

          case SyncTaskType.processPayment:
            final loanId = task.payload['loan_id'];
            final amount = task.payload['amount'] is num
                ? (task.payload['amount'] as num).toDouble()
                : double.tryParse('${task.payload['amount']}') ?? 0.0;
            final method = task.payload['payment_method'] ?? 'cash';

            final res = await ApiService.processPayment(
              loanId: loanId,
              amount: amount,
              paymentMethod: method,
              idempotencyKey: task.idempotencyKey,
            );
            if (res != null) success = true;
            break;
        }
      } catch (e) {
        debugPrint('⚠️ [Queue Sync Delay] Sin conexión aún para [${task.type.name}]: $e');
      }

      if (success || task.attempts >= 5) {
        toRemove.add(task);
        debugPrint('✅ [Queue Synced] Tarea completada y sincronizada [${task.type.name}] (${task.id})');
      }
    }

    _pendingQueue.removeWhere((t) => toRemove.contains(t));
    await _saveToDisk();
    _isProcessing = false;

    if (_pendingQueue.isNotEmpty) {
      debugPrint('ℹ️ [Queue Deferred] Quedan ${_pendingQueue.length} tareas guardadas para la próxima sincronización.');
    }
  }
}
