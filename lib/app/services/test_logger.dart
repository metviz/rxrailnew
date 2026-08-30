import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as dev;

/// Persistent test logger — works from both the main isolate and the
/// background foreground-task isolate.
///
/// Logs are written to:
///   /sdcard/Android/data/com.rxrail.app/files/rxrail_YYYYMMDD.log
///
/// Retrieve after a test session:
///   adb pull /sdcard/Android/data/com.rxrail.app/files/
class TestLogger {
  TestLogger._();

  static File? _file;
  static bool _ready = false;

  /// Call once at app start (main isolate) and once in LocationTaskHandler.onStart (bg isolate).
  static Future<void> init({String tag = 'MAIN'}) async {
    if (_ready) return;
    try {
      final dir = await _logDir();
      final name = _fileName();
      _file = File('${dir.path}/$name');
      _ready = true;
      await _append('[$tag] === RXrail session started ===');
    } catch (e) {
      dev.log('TestLogger init error: $e');
    }
  }

  /// Write a timestamped line. Safe to call before [init] — will auto-init.
  static Future<void> log(String message, {String tag = 'BG'}) async {
    dev.log(message);
    if (!_ready) await init(tag: tag);
    await _append('[$tag] $message');
  }

  /// Path of today's log file (null before first init).
  static String? get filePath => _file?.path;

  /// Human-readable size of the current log file.
  static Future<String> fileSize() async {
    try {
      final f = _file;
      if (f == null || !f.existsSync()) return '0 KB';
      final bytes = f.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } catch (_) {
      return '?';
    }
  }

  /// List all rxrail log files in the log directory, newest first.
  static Future<List<File>> listLogs() async {
    try {
      final dir = await _logDir();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('rxrail_') && f.path.endsWith('.log'))
          .toList()
        ..sort((a, b) =>
            b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (_) {
      return [];
    }
  }

  /// Delete all rxrail log files.
  static Future<void> clearAll() async {
    try {
      final files = await listLogs();
      for (final f in files) {
        await f.delete();
      }
      _ready = false;
      _file = null;
    } catch (e) {
      dev.log('TestLogger clearAll error: $e');
    }
  }

  // ── internals ──────────────────────────────────────────────────────────────

  static Future<Directory> _logDir() async {
    final ext = await getExternalStorageDirectory();
    return ext ?? await getApplicationDocumentsDirectory();
  }

  static String _fileName() {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'rxrail_$y$m$d.log';
  }

  static Future<void> _append(String message) async {
    try {
      final ts = DateTime.now().toIso8601String();
      await _file!.writeAsString('$ts $message\n', mode: FileMode.append);
    } catch (e) {
      dev.log('TestLogger write error: $e');
    }
  }
}
