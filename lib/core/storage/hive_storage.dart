import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveStorage {
  static const String clientBox = 'clients';
  static const String loanBox = 'loans';
  static const String paymentBox = 'payments';
  static const String pendingBox = 'pending_operations';

  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    await Hive.openBox(clientBox);
    await Hive.openBox(loanBox);
    await Hive.openBox(paymentBox);
    await Hive.openBox(pendingBox);
  }

  static Box<T> getBox<T>(String boxName) {
    return Hive.box<T>(boxName);
  }
}
