import 'package:flutter/material.dart';
import 'cache_helper.dart';

class CacheRevertButton extends StatelessWidget {
  const CacheRevertButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CacheHelper.instance,
      builder: (context, _) {
        if (!CacheHelper.instance.hasPendingJob) {
          return const SizedBox.shrink();
        }

        return Positioned(
          right: 16,
          bottom: 16,
          child: Material(
            color: Colors.transparent,
            child: AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 200),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// 🟢 KAYDET
                      _ActionButton(
                        icon: Icons.check_rounded,
                        label: "Kaydet",
                        color: Colors.green,
                        onTap: () {
                          CacheHelper.instance.commitNow();
                        },
                      ),

                      const SizedBox(height: 8),

                      /// 🔴 GERİ AL
                      _ActionButton(
                        icon: Icons.undo_rounded,
                        label: "İptal",
                        color: Colors.red,
                        onTap: () {
                          CacheHelper.instance.cancelPending();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

