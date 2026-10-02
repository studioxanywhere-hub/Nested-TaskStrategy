import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../screens/local_insights_screen.dart';
import 'export_backup_dialog.dart';

class SideOptionsDrawer extends StatelessWidget {
  const SideOptionsDrawer({super.key});

  void _exportTasksJson(BuildContext context, TaskProvider provider) {
    try {
      final jsonList = provider.tasks.map((t) => t.toJson()).toList();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonList);
      Clipboard.setData(ClipboardData(text: jsonStr));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Full tasks backup JSON copied to clipboard!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export JSON: $e')),
      );
    }
  }

  void _showFeedbackSheet(BuildContext context, TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FeedbackModalSheet(provider: provider),
    );
  }

  void _showWeightGuideSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.scale_outlined, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Effort Weight Guide (1–10)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTierGuideCard(
                color: AppTheme.weightLow,
                tier: '1–3 Minor Effort',
                desc: 'Quick wins and errands taking less than 1 hour.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildTierGuideCard(
                color: AppTheme.weightMedium,
                tier: '4–7 Moderate Effort',
                desc: 'Core workload and deliverables spanning half a day to several days.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildTierGuideCard(
                color: AppTheme.weightHigh,
                tier: '8–10 Critical Effort',
                desc: 'Major strategic milestones, architecture, and high-impact goals.',
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 22),
            SizedBox(width: 8),
            Text('About Nested', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nested: Task Strategy v2.1.7',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              'A modern task manager designed for breaking complex goals into structured, weighted subtasks with automatic progress calculation.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              '100% private and stored locally on your device.',
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _buildTierGuideCard({
    required Color color,
    required String tier,
    required String desc,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final metrics = provider.strategyMetrics;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > 1200
        ? screenWidth * 0.25
        : (screenWidth > 400 ? 340.0 : screenWidth * 0.88);

    return Drawer(
      width: drawerWidth,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_tree_outlined, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nested: Task Strategy',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'v2.1.7 • Release',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Strategy Snapshot Card (Compact)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'PRODUCTIVITY PROFILE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                                color: AppTheme.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                metrics.strategyArchetype,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${metrics.completionRate.toStringAsFixed(0)}% Completed',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Level ${metrics.maxDepth} • ${metrics.totalTasks} Tasks',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LocalInsightsScreen()),
                                );
                              },
                              child: const Text('Full Insights →', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Menu Tiles (Clean, modern list)
                  _buildActionTile(
                    context: context,
                    icon: Icons.lightbulb_outline_rounded,
                    iconColor: Colors.amber,
                    title: 'Feedback & Feature Requests',
                    subtitle: 'Share ideas or suggestions directly',
                    onTap: () => _showFeedbackSheet(context, provider),
                  ),
                  const SizedBox(height: 8),

                  _buildActionTile(
                    context: context,
                    icon: Icons.scale_outlined,
                    iconColor: AppTheme.primary,
                    title: 'Effort Weight Guide (1–10)',
                    subtitle: 'Minor, Moderate & Critical tier scale',
                    onTap: () => _showWeightGuideSheet(context),
                  ),
                  const SizedBox(height: 8),

                  _buildActionTile(
                    context: context,
                    icon: Icons.cloud_download_outlined,
                    iconColor: AppTheme.secondary,
                    title: 'Export Tasks Backup',
                    subtitle: 'Copy offline JSON to clipboard',
                    trailing: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                    onTap: () => _exportTasksJson(context, provider),
                  ),
                  const SizedBox(height: 8),

                  _buildActionTile(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    iconColor: Colors.blueAccent,
                    title: 'About Nested',
                    subtitle: 'Task strategy overview & version',
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),

            // Minimalist Trust Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: AppTheme.secondary),
                    const SizedBox(width: 5),
                    Text(
                      '🔒 100% Private & Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withOpacity(0.7) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155).withOpacity(0.7) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _FeedbackModalSheet extends StatefulWidget {
  final TaskProvider provider;

  const _FeedbackModalSheet({required this.provider});

  @override
  State<_FeedbackModalSheet> createState() => _FeedbackModalSheetState();
}

class _FeedbackModalSheetState extends State<_FeedbackModalSheet> {
  String _selectedCategory = 'idea';
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _includeStats = true;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _formatFeedback() {
    final metrics = widget.provider.strategyMetrics;
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    final catLabel = _selectedCategory == 'idea'
        ? 'Feature Request / Idea'
        : _selectedCategory == 'bug'
            ? 'Bug Report'
            : 'User Feedback';

    final buffer = StringBuffer();
    buffer.writeln('### [Nested $catLabel] ${subject.isEmpty ? "Untitled" : subject}');
    buffer.writeln();
    buffer.writeln(message.isEmpty ? 'No description provided.' : message);
    buffer.writeln();

    if (_includeStats) {
      buffer.writeln('---');
      buffer.writeln('**Strategy Summary (100% Private)**:');
      buffer.writeln('• Profile: ${metrics.strategyArchetype}');
      buffer.writeln('• Total Tasks: ${metrics.totalTasks} (${metrics.completedTasks} completed, ${metrics.completionRate.toStringAsFixed(1)}%)');
      buffer.writeln('• Deepest Nested Level: Level ${metrics.maxDepth}');
      buffer.writeln('• Average Task Weight: ${metrics.averageWeight.toStringAsFixed(1)} / 10');
      buffer.writeln('• Platform: Android / Flutter (Nested: Task Strategy v2.1.7)');
    }

    return buffer.toString();
  }

  void _copyFeedbackMessage() {
    final formatted = _formatFeedback();
    Clipboard.setData(ClipboardData(text: formatted));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Formatted message copied to clipboard!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSubmissionLinks() {
    final formatted = _formatFeedback();
    Clipboard.setData(ClipboardData(text: formatted));
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.launch_rounded, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text('Submit Feedback', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your formatted message is copied to your clipboard. Submit via GitHub Issues or email directly:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: const SelectableText(
                'GitHub: https://github.com/studioxanywhere-hub/Nested-TaskStrategy/issues\n\n'
                'Email: studioxanywhere@gmail.com',
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Backup & Export Data Section
            Card(
              elevation: 0,
              color: AppTheme.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => const ExportBackupDialog(),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.sd_storage_outlined, color: AppTheme.primary, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backup, Export & Restore Data',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Save physical files (.json, .md, .txt) to Downloads',
                              style: TextStyle(fontSize: 10.5, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Feedback & Feature Requests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '100% Private',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category Chips
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('💡 Feature Idea', style: TextStyle(fontSize: 11)),
                  selected: _selectedCategory == 'idea',
                  onSelected: (_) => setState(() => _selectedCategory = 'idea'),
                ),
                ChoiceChip(
                  label: const Text('🐛 Bug Report', style: TextStyle(fontSize: 11)),
                  selected: _selectedCategory == 'bug',
                  onSelected: (_) => setState(() => _selectedCategory = 'bug'),
                ),
                ChoiceChip(
                  label: const Text('💬 Feedback', style: TextStyle(fontSize: 11)),
                  selected: _selectedCategory == 'feedback',
                  onSelected: (_) => setState(() => _selectedCategory = 'feedback'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Subject input
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: _selectedCategory == 'idea'
                    ? 'Summary (e.g. Add recurring tasks)...'
                    : _selectedCategory == 'bug'
                        ? 'Bug summary (e.g. Subtask does not collapse)...'
                        : 'Subject...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.white,
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),

            // Message input
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _selectedCategory == 'idea'
                    ? 'Describe what you would like to see or workflow ideas...'
                    : _selectedCategory == 'bug'
                        ? 'Describe what happened and steps to reproduce...'
                        : 'Share your suggestions or thoughts...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.white,
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),

            // Anonymous Stats Checkbox
            InkWell(
              onTap: () => setState(() => _includeStats = !_includeStats),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _includeStats,
                      onChanged: (val) => setState(() => _includeStats = val ?? true),
                      activeColor: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Include strategy summary (no task names)',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Message', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _copyFeedbackMessage,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Submit Links', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _showSubmissionLinks,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Nested v2.1.8 (Build 13)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
