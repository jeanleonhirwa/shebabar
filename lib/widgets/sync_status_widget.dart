import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../utils/helpers.dart';
import '../providers/sync_provider.dart';
import 'custom_card.dart';

class SyncStatusWidget extends StatelessWidget {
  final bool showDetails;
  final VoidCallback? onSyncPressed;

  const SyncStatusWidget({
    super.key,
    this.showDetails = true,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _getStatusIcon(syncProvider),
                    color: _getStatusColor(syncProvider),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sync Status',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (syncProvider.isSyncing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (syncProvider.needsSync)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ThemeConfig.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${syncProvider.pendingCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.warningColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Status Text
              Text(
                syncProvider.getUserFriendlyStatus(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeConfig.secondaryText,
                ),
              ),
              
              if (showDetails) ...[
                const SizedBox(height: 16),
                
                // Connection Status
                Row(
                  children: [
                    Icon(
                      syncProvider.isOnline ? Icons.wifi : Icons.wifi_off,
                      color: syncProvider.isOnline 
                          ? ThemeConfig.successColor 
                          : ThemeConfig.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      syncProvider.isOnline ? 'Wunganiye' : 'Ntiwunganiye',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: syncProvider.isOnline 
                            ? ThemeConfig.successColor 
                            : ThemeConfig.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Last Sync Time
                if (syncProvider.lastSyncTime != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: ThemeConfig.secondaryText,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sync ya nyuma: ${_formatLastSyncTime(syncProvider.lastSyncTime!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Pending Items
                if (syncProvider.pendingCount > 0) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        color: ThemeConfig.warningColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${syncProvider.pendingCount} ibikeneye sync',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.warningColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              
              // Error/Success Messages
              if (syncProvider.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeConfig.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeConfig.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: ThemeConfig.errorColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          syncProvider.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeConfig.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (syncProvider.successMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeConfig.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeConfig.successColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: ThemeConfig.successColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          syncProvider.successMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeConfig.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Action Buttons
              if (showDetails) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: syncProvider.isSyncing 
                            ? null 
                            : (onSyncPressed ?? () => _handleSync(context, syncProvider)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getStatusColor(syncProvider),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: syncProvider.isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(_getSyncButtonIcon(syncProvider)),
                        label: Text(_getSyncButtonText(syncProvider)),
                      ),
                    ),
                    if (syncProvider.pendingCount > 0) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _showSyncDetails(context, syncProvider),
                        icon: const Icon(Icons.info_outline),
                        tooltip: 'Reba amakuru arambuye',
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(SyncProvider syncProvider) {
    if (syncProvider.isSyncing) {
      return Icons.sync;
    } else if (!syncProvider.isOnline) {
      return Icons.cloud_off;
    } else if (syncProvider.needsSync) {
      return Icons.cloud_upload;
    } else {
      return Icons.cloud_done;
    }
  }

  Color _getStatusColor(SyncProvider syncProvider) {
    if (syncProvider.isSyncing) {
      return ThemeConfig.primaryColor;
    } else if (!syncProvider.isOnline) {
      return ThemeConfig.errorColor;
    } else if (syncProvider.needsSync) {
      return ThemeConfig.warningColor;
    } else {
      return ThemeConfig.successColor;
    }
  }

  IconData _getSyncButtonIcon(SyncProvider syncProvider) {
    if (!syncProvider.isOnline) {
      return Icons.wifi_off;
    } else if (syncProvider.needsSync) {
      return Icons.sync;
    } else {
      return Icons.refresh;
    }
  }

  String _getSyncButtonText(SyncProvider syncProvider) {
    if (syncProvider.isSyncing) {
      return 'Birasync...';
    } else if (!syncProvider.isOnline) {
      return 'Ntiwunganiye';
    } else if (syncProvider.needsSync) {
      return 'Sync Now';
    } else {
      return 'Vugurura';
    }
  }

  String _formatLastSyncTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Vuba aha';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ashize';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} h ashize';
      } else {
        return Helpers.formatDate(dateTime);
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _handleSync(BuildContext context, SyncProvider syncProvider) async {
    final success = await syncProvider.performSync();
    
    if (context.mounted) {
      if (success) {
        Helpers.showSuccessMessage(context, 'Sync yarangiye neza!');
      } else {
        Helpers.showErrorMessage(context, 'Sync ntiyarangiye. Gerageza nanone.');
      }
    }
  }

  void _showSyncDetails(BuildContext context, SyncProvider syncProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Amakuru ya Sync'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: syncProvider.getDetailedSyncInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('Ntibyashobotse kubona amakuru');
            }
            
            final data = snapshot.data!;
            final pendingData = data['pendingData'] as Map<String, dynamic>? ?? {};
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ibikeneye Sync:'),
                const SizedBox(height: 8),
                Text('• Abakozi: ${pendingData['users'] ?? 0}'),
                Text('• Ibicuruzwa: ${pendingData['products'] ?? 0}'),
                Text('• Ibikorwa: ${pendingData['movements'] ?? 0}'),
                Text('• Incamake: ${pendingData['summaries'] ?? 0}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Siga'),
          ),
        ],
      ),
    );
  }
}
