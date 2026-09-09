import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

class ExportBackupDialog extends StatefulWidget {
  const ExportBackupDialog({super.key});

  @override
  State<ExportBackupDialog> createState() => _ExportBackupDialogState();
}

class _ExportBackupDialogState extends State<ExportBackupDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    super.dispose();
  }

  String _getContent(int tabIndex, TaskProvider provider) {
    switch (tabIndex) {
      case 0:
        return ExportService.exportToJson(provider.tasks);
      case 1:
        return ExportService.exportToMarkdown(provider.tasks);
      case 2:
        return ExportService.exportToPlainText(provider.tasks);
      default:
        return '';
    }
  }

  String _getFileName(int tabIndex) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    switch (tabIndex) {
      case 0:
        return 'nested_backup_$timestamp.json';
      case 1:
        return 'nested_tasks_$timestamp.md';
      case 2:
        return 'nested_tasks_$timestamp.txt';
      default:
        return 'nested_export.txt';
    }
  }

  void _saveFile(TaskProvider provider) async {
    final tabIndex = _tabController.index;
    final content = _getContent(tabIndex, provider);
    final fileName = _getFileName(tabIndex);

    final filePath = await ExportService.saveFileToDownloads(content, fileName);

    if (!mounted) return;

    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ File saved to Downloads:\n$filePath'),
          backgroundColor: AppTheme.secondary,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Saved content copied to clipboard!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _copyToClipboard(TaskProvider provider) {
    final content = _getContent(_tabController.index, provider);
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRestoreDialog(TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update_alt, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Restore Data', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your JSON backup data below to restore your projects and tasks on this device:',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _importController,
              maxLines: 8,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '{\n  "projects": [...]\n}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Restore Data'),
            onPressed: () {
              final jsonStr = _importController.text.trim();
              if (jsonStr.isEmpty) return;

              final success = provider.importBackupJson(jsonStr);
              Navigator.pop(ctx);

              if (success) {
                Navigator.pop(context); // close export dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Data restored successfully!'),
                    backgroundColor: AppTheme.secondary,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Invalid JSON format. Unable to restore.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sd_storage_outlined, color: AppTheme.primary, size: 22),
                    SizedBox(width: 8),
                    Text('Backup & Export', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Save physical files to your device Downloads folder or restore data.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),

            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
              indicatorColor: AppTheme.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'JSON Backup'),
                Tab(text: 'Markdown (.md)'),
                Tab(text: 'Text (.txt)'),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 140,
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  final content = _getContent(_tabController.index, provider);
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        content,
                        style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace'),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.download_for_offline_rounded, size: 18),
                label: const Text('Save File to Downloads Folder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () => _saveFile(provider),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Text', style: TextStyle(fontSize: 12)),
                    onPressed: () => _copyToClipboard(provider),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondary,
                      side: const BorderSide(color: AppTheme.secondary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.system_update_alt, size: 16),
                    label: const Text('Restore Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showRestoreDialog(provider),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
