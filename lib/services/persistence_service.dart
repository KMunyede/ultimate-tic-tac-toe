import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PersistenceService {
  static const String _fileName = 'app_settings.json';

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<Map<String, dynamic>> loadAll() async {
    try {
      final file = await _file;
      if (!await file.exists()) return {};
      final contents = await file.readAsString();
      return json.decode(contents) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    try {
      final file = await _file;
      final existing = await loadAll();
      final updated = {...existing, ...data};
      await file.writeAsString(json.encode(updated));
    } catch (e) {
      // Silence or log error
    }
  }

  Future<double?> getDouble(String key) async {
    final data = await loadAll();
    return data[key] as double?;
  }
}
