import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/utils/offline_queue.dart';
import 'package:flutter/material.dart';
import 'package:app1/utils/database_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  bool isSyncing = false;

  Future<void> _syncQueue() async {
    if (isSyncing) return;

    setState(() {
      isSyncing = true;
    });

    try {
      await QueueHelper().syncQueue();
    } finally {
      if (mounted) {
        setState(() {
          isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(queueBox);

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box box, _) {
            final keys = box.keys.toList();

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================================
                  // HEADER
                  // ========================================================

                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: GlassTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(width: 4),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Senkronizasyon Kuyruğu',
                              style: TextStyle(
                                color: GlassTheme.textPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Veri tabanına gönderilmeyi bekleyen veriler.',
                              style: TextStyle(
                                color: GlassTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ========================================================
                  // QUEUE STATUS
                  // ========================================================

                  GlassPanel(
                    title: 'Kuyruk Durumu',
                    icon: Icons.sync_rounded,
                    child: FutureBuilder<bool>(
                      future: DatabaseService().hasInternet(),
                      builder: (context, snapshot) {
                        final online = snapshot.data ?? false;

                        return Row(
                          children: [
                            Expanded(
                              child: _QueueStat(
                                icon: Icons.inventory_2_rounded,
                                label: 'Bekleyen kayıt',
                                value: box.length.toString(),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _ConnectionStatus(
                                online: online,
                              ),
                            ),

                            const SizedBox(width: 12),

                            SizedBox(
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed:
                                    isSyncing ? null : _syncQueue,
                                icon: isSyncing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: GlassTheme.cyan,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.sync_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  isSyncing
                                      ? 'Eşitleniyor'
                                      : 'Eşitle',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ========================================================
                  // QUEUE CONTENT
                  // ========================================================

                  GlassPanel(
                    title: 'Bekleyen İşlemler',
                    icon: Icons.pending_actions_rounded,
                    child: box.isEmpty
                        ? const _EmptyQueue()
                        : Column(
                            children: [
                              for (int index = 0;
                                  index < keys.length;
                                  index++) ...[
                                _QueueItem(
                                  index: index,
                                  keyValue: keys[index],
                                  item: Map<String, dynamic>.from(
                                    box.get(keys[index]),
                                  ),
                                ),

                                if (index != keys.length - 1)
                                  const SizedBox(height: 8),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// QUEUE STAT
// ============================================================================

class _QueueStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QueueStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: GlassTheme.cyan.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GlassTheme.cyan.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GlassTheme.cyan.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 17,
              color: GlassTheme.cyan,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GlassTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: GlassTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CONNECTION STATUS
// ============================================================================

class _ConnectionStatus extends StatelessWidget {
  final bool online;

  const _ConnectionStatus({
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    final color = online
        ? Colors.greenAccent
        : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              online
                  ? Icons.wifi_rounded
                  : Icons.wifi_off_rounded,
              size: 17,
              color: color,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bağlantı',
                  style: TextStyle(
                    color: GlassTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  online ? 'Çevrimiçi' : 'Çevrimdışı',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// QUEUE ITEM
// ============================================================================

class _QueueItem extends StatelessWidget {
  final int index;
  final dynamic keyValue;
  final Map<String, dynamic> item;

  const _QueueItem({
    required this.index,
    required this.keyValue,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final path = item["path"]?.toString() ?? '-';
    final data = item["data"]?.toString() ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: GlassTheme.cyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  size: 15,
                  color: GlassTheme.cyan,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İşlem #${index + 1}',
                      style: const TextStyle(
                        color: GlassTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: $keyValue',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GlassTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.14),
                  ),
                ),
                child: const Text(
                  'Bekliyor',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _QueueDetail(
            icon: Icons.route_rounded,
            label: 'Path',
            value: path,
          ),

          const SizedBox(height: 6),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.data_object_rounded,
                      size: 14,
                      color: GlassTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Data',
                      style: TextStyle(
                        color: GlassTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                SelectableText(
                  data,
                  style: const TextStyle(
                    color: GlassTheme.textPrimary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// QUEUE DETAIL
// ============================================================================

class _QueueDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QueueDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: GlassTheme.textSecondary,
        ),

        const SizedBox(width: 7),

        Text(
          '$label:',
          style: const TextStyle(
            color: GlassTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GlassTheme.textPrimary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EMPTY QUEUE
// ============================================================================

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.cloud_done_rounded,
            size: 34,
            color: GlassTheme.cyan,
          ),

          SizedBox(height: 10),

          Text(
            'Kuyruk boş',
            style: TextStyle(
              color: GlassTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 4),

          Text(
            'Bekleyen herhangi bir senkronizasyon işlemi yok.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GlassTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
