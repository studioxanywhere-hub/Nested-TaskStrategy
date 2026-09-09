import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tree_task_item.dart';
import '../widgets/project_card.dart';
import '../widgets/focus_breadcrumb.dart';
import '../widgets/edit_task_dialog.dart';
import '../widgets/strategy_insights_dialog.dart';
import '../widgets/side_options_drawer.dart';
import 'local_insights_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final isFocusMode = provider.breadcrumbStack.isNotEmpty;
    final currentTasks = provider.currentViewTasks;

    return Scaffold(
      endDrawer: const SideOptionsDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_tree_outlined, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nested',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  'TASK STRATEGY',
                  style: TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 0.8, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Expand All',
            icon: const Icon(Icons.unfold_more, size: 20),
            onPressed: () => provider.setAllExpanded(true),
          ),
          IconButton(
            tooltip: 'Collapse All',
            icon: const Icon(Icons.unfold_less, size: 20),
            onPressed: () => provider.setAllExpanded(false),
          ),
          Builder(
            builder: (ctx) => IconButton(
              tooltip: 'Ideas, Feedback & Options',
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              provider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => provider.toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const FocusBreadcrumbBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                          ),
                          child: TextField(
                            onChanged: (q) => provider.setSearchQuery(q),
                            decoration: InputDecoration(
                              hintText: 'Search tasks...',
                              hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.search, size: 18),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                          ),
                          child: Icon(
                            Icons.tune,
                            size: 18,
                            color: (provider.minWeightFilter != null || provider.statusFilter != null)
                                ? AppTheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        onSelected: (val) {
                          if (val == 'heavy') {
                            provider.setFilter(minWeight: 8);
                          } else if (val == 'active') {
                            provider.setFilter(status: false);
                          } else if (val == 'completed') {
                            provider.setFilter(status: true);
                          } else if (val == 'clear') {
                            provider.clearFilters();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'heavy', child: Text('Heavy Effort Only (W: 8-10)')),
                          const PopupMenuItem(value: 'active', child: Text('Active Only')),
                          const PopupMenuItem(value: 'completed', child: Text('Completed Only')),
                          const PopupMenuDivider(),
                          const PopupMenuItem(value: 'clear', child: Text('Reset Filters')),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isFocusMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LocalInsightsScreen()),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 54,
                                    height: 54,
                                    child: CircularProgressIndicator(
                                      value: provider.overallProgress,
                                      strokeWidth: 6,
                                      backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        provider.overallProgress >= 0.999 ? AppTheme.secondary : AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(provider.overallProgress * 100).toInt()}%',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Overall Completion',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Insights →',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${provider.totalRootProjects} Projects • ${provider.totalTasksCount} Total Tasks',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: currentTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isFocusMode ? Icons.subdirectory_arrow_right : Icons.folder_open_outlined,
                                size: 56,
                                color: theme.colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isFocusMode ? 'No subtasks in this branch' : 'No projects found',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isFocusMode ? 'Tap + Add Subtask to add one!' : 'Tap + New Project to start!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          itemCount: currentTasks.length,
                          itemBuilder: (context, index) {
                            final task = currentTasks[index];
                            if (!isFocusMode) {
                              return ProjectCard(task: task);
                            }
                            return TreeTaskItem(
                              task: task,
                              depth: 0,
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(isFocusMode ? 'Add Subtask' : 'New Project'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => EditTaskDialog(
              parentName: isFocusMode ? provider.breadcrumbStack.last.name : null,
              onSave: (name, desc, weight, deadline) {
                if (isFocusMode) {
                  provider.addSubTask(
                    parentId: provider.breadcrumbStack.last.id,
                    name: name,
                    description: desc,
                    weight: weight,
                    deadline: deadline,
                  );
                } else {
                  provider.addRootTask(
                    name: name,
                    description: desc,
                    weight: weight,
                    deadline: deadline,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
