import 'package:flutter/material.dart';
import '../../theme/activity_theme.dart';

class SyncStatusBadge extends StatelessWidget {
  final bool isSynced;
  final String? lastSyncTime;

  const SyncStatusBadge({
    super.key,
    required this.isSynced,
    this.lastSyncTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSynced ? ActivityTheme.success.withAlpha(30) : ActivityTheme.warning.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.cloud_done : Icons.cloud_upload,
            size: 14,
            color: isSynced ? ActivityTheme.success : ActivityTheme.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isSynced ? (lastSyncTime ?? 'Synced') : 'Pending Sync',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSynced ? ActivityTheme.success : ActivityTheme.warning,
            ),
          ),
        ],
      ),
    );
  }
}
