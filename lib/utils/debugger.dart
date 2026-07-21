import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = 'app_debug_logs';
const _maxStoredLogs = 500;

enum LogLevel { info, warning, error }
final List<OverlayEntry> _overlays = [];


class LogEntry {
  final String timestamp;
  final String message;
  final LogLevel level;

  LogEntry({required this.timestamp, required this.message, required this.level});

  String toStorageString() => '${level.name}|$timestamp|$message';

  static LogEntry? fromStorageString(String s) {
    final parts = s.split('|');
    if (parts.length < 3) return null;
    final level = LogLevel.values.firstWhere(
      (l) => l.name == parts[0],
      orElse: () => LogLevel.info,
    );
    return LogEntry(timestamp: parts[1], message: parts.sublist(2).join('|'), level: level);
  }

  @override
  String toString() => '$timestamp: $message';
}

class AppLogger {
  AppLogger._privateConstructor();
  static final AppLogger instance = AppLogger._privateConstructor();

  static GlobalKey<NavigatorState>? navigatorKey;
  OverlayEntry? _overlayEntry;

  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);

  Future<void> loadPersistedLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored != null && stored.isNotEmpty) {
        final lines = stored.split('\n').where((l) => l.isNotEmpty);
        final entries = lines.map(LogEntry.fromStorageString).whereType<LogEntry>().toList();
        if (entries.isNotEmpty) {
          _logs.insertAll(0, [
            LogEntry(timestamp: '──────', message: '── Önceki Oturum ──', level: LogLevel.info),
            ...entries,
            LogEntry(timestamp: '──────', message: '── Yeni Oturum ──', level: LogLevel.info),
          ]);
        }
      }
    } catch (e) {
      // ignore
    }
  }

  void log(String message, {LogLevel level = LogLevel.info}) {
    final timestamp = DateTime.now().toString().split(' ').last.substring(0, 8);
    final entry = LogEntry(timestamp: timestamp, message: message, level: level);
    _logs.add(entry);
    debugPrint('$timestamp: $message');
    _persist(entry);
  }

  void warn(String message) => log(message, level: LogLevel.warning);
  void error(String message) => log(message, level: LogLevel.error);

  void _persist(LogEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_storageKey) ?? '';
      final lines = existing.split('\n').where((l) => l.isNotEmpty).toList();
      lines.add(entry.toStorageString());
      final trimmed = lines.length > _maxStoredLogs
          ? lines.sublist(lines.length - _maxStoredLogs)
          : lines;
      await prefs.setString(_storageKey, trimmed.join('\n'));
    } catch (e) {
      // ignore
    }
  }

  Future<void> clear() async {
    _logs.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      // ignore
    }
  }

  void showOverlay(String message, LogLevel level) {
    final overlay = navigatorKey?.currentState?.overlay;
    if (overlay == null) return;

    Color color;

    switch (level) {
      case LogLevel.error:
        color = Colors.red;
        break;
      case LogLevel.warning:
        color = Colors.orange;
        break;
      case LogLevel.info:
        color = Colors.blue;
        break;
    }

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        final index = _overlays.indexOf(entry);

        return Positioned(
          bottom: 100 + (index * 60),
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
    
    _overlays.add(entry);
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
      _overlays.remove(entry);

      // rebuild all remaining overlays
      for (final e in _overlays) {
        e.markNeedsBuild();
      }
    });
  }
}

// ─────────────────────────────────────────────
// Debug Sayfası
// ─────────────────────────────────────────────

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  late List<LogEntry> _snapshot;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _snapshot = List.from(AppLogger.instance.logs);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final current = AppLogger.instance.logs;
      if (current.length != _snapshot.length) {
        setState(() => _snapshot = List.from(current));
        if (_autoScroll) _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _copyAll(BuildContext context) {
    final text = _snapshot.map((e) => '${e.timestamp}: ${e.message}').join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loglar kopyalandı.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Renkleri inline TextSpan olarak oluştur
  List<TextSpan> _buildSpans() {
    return _snapshot.map((entry) {
      Color color;
      switch (entry.level) {
        case LogLevel.warning: color = const Color(0xFFFFAA00); break;
        case LogLevel.error:   color = const Color(0xFFFF4444); break;
        case LogLevel.info:    color = const Color(0xFF00FF88); break;
      }
      return TextSpan(
        text: '${entry.timestamp}: ${entry.message}\n',
        style: TextStyle(color: color),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'DEBUG CONSOLE',
          style: TextStyle(
            color: Color(0xFF00FF88),
            fontFamily: 'monospace',
            fontSize: 14,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.pause,
              color: _autoScroll ? const Color(0xFF00FF88) : Colors.grey,
              size: 20,
            ),
            tooltip: 'Auto scroll',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
            tooltip: 'Tümünü kopyala',
            onPressed: () => _copyAll(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            tooltip: 'Temizle',
            onPressed: () async {
              await AppLogger.instance.clear();
              if (mounted) setState(() => _snapshot = []);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF00FF88), width: 1)),
        ),
        child: _snapshot.isEmpty
            ? const Center(
                child: Text(
                  'Henüz log yok.',
                  style: TextStyle(
                    color: Colors.white24,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              )
            : SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: SelectableText.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.6,
                    ),
                    children: _buildSpans(),
                  ),
                ),
              ),
      ),
    );
  }
}