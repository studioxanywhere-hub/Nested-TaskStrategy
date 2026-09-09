import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_item.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'weight_badge.dart';
import 'weighted_progress_bar.dart';
import 'edit_task_dialog.dart';

class ProjectCard extends StatelessWidget {
  final TaskItem task;

  const ProjectCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final hasChildren = task.children.isNotEmpty;
    final isDone = task.progress >= 0.999;
    final subtaskCount = task.recursiveSubtaskCount;
    final completedCount = task.recursiveCompletedCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 2,
        shadowColor: theme.shadowColor.withOpacity(0.08),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDone
                ? AppTheme.secondary.withOpacity(0.4)
                : theme.colorScheme.outline.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: InkWell(
          onTap: () => provider.drillDown(task),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.secondary.withOpacity(0.15)
                            : AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDone ? Icons.check_circle_outline : Icons.folder_open_rounded,
                        color: isDone ? AppTheme.secondary : AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone
                                  ? theme.colorScheme.onSurface.withOpacity(0.6)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtaskCount > 0
                                ? '$subtaskCount subtasks ($completedCount completed) • W: ${task.weight}'
                                : 'Direct Project • Weight: ${task.weight}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    WeightBadge(
                      weight: task.weight,
                      compact: false,
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (action) {
                        if (action == 'open') {
                          provider.drillDown(task);
                        } else if (action == 'add_child') {
                          showDialog(
                            context: context,
                            builder: (ctx) => EditTaskDialog(
                              parentName: task.name,
                              onSave: (name, desc, weight, deadline) {
                                provider.addSubTask(
                                  parentId: task.id,
                                  name: name,
                                  description: desc,
                                  weight: weight,
                                  deadline: deadline,
                                );
                              },
                            ),
                          );
                        } else if (action == 'edit') {
                          showDialog(
                            context: context,
                            builder: (ctx) => EditTaskDialog(
                              initialTask: task,
                              onSave: (name, desc, weight, deadline) {
                                provider.updateTask(
                                  id: task.id,
                                  name: name,
                                  description: desc,
                                  weight: weight,
                                  deadline: deadline,
                                );
                              },
                            ),
                          );
                        } else if (action == 'delete') {
                          provider.deleteTask(task.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(Icons.folder_open_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Open Project'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'add_child',
                          child: Row(
                            children: [
                              Icon(Icons.add_task, size: 18),
                              SizedBox(width: 8),
                              Text('Add Subtask'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Project'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (hasChildren) ...[
                  WeightedProgressBar(
                    progress: task.progress,
                    earnedPoints: task.earnedWeightedPoints,
                    totalWeight: task.directChildrenTotalWeight,
                    showLabel: true,
                    height: 6,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.secondary.withOpacity(0.12)
                            : (task.progress > 0
                                ? AppTheme.primary.withOpacity(0.12)
                                : theme.colorScheme.outline.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isDone
                            ? '✓ COMPLETED'
                            : (task.progress > 0
                                ? '${(task.progress * 100).toInt()}% IN PROGRESS'
                                : 'NOT STARTED'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDone
                              ? AppTheme.secondary
                              : (task.progress > 0 ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Open Project',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
