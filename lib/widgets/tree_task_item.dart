import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_item.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'weight_badge.dart';
import 'weighted_progress_bar.dart';
import 'edit_task_dialog.dart';

class TreeTaskItem extends StatelessWidget {
  final TaskItem task;
  final int depth;
  final int? parentTotalWeight;

  const TreeTaskItem({
    super.key,
    required this.task,
    this.depth = 0,
    this.parentTotalWeight,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final hasChildren = task.children.isNotEmpty;
    final isDone = task.progress >= 0.999;
    final contribution = parentTotalWeight != null ? task.contributionPercentage(parentTotalWeight!) : null;

    final double surfaceOpacity = depth == 0 ? 1.0 : (depth == 1 ? 0.92 : (depth == 2 ? 0.84 : 0.76));
    final Color? leftAccentColor = depth == 1
        ? AppTheme.primary
        : (depth == 2 ? AppTheme.secondary : (depth >= 3 ? AppTheme.weightMedium : null));
    final double fontSize = depth == 0 ? 15.0 : (depth == 1 ? 14.0 : (depth == 2 ? 13.5 : 12.5));
    final EdgeInsets padding = depth == 0
        ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0)
        : (depth == 1
            ? const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0)
            : const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0));

    return Padding(
      padding: EdgeInsets.only(
        left: depth > 0 ? (depth == 1 ? 12.0 : 10.0) : 0.0,
        top: 2.0,
        bottom: 2.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: depth == 0 ? 1.5 : 0.5,
            color: theme.cardColor.withOpacity(surfaceOpacity),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(depth >= 2 ? 8 : 12),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(depth == 0 ? 0.3 : 0.15),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                border: leftAccentColor != null
                    ? Border(left: BorderSide(color: leftAccentColor, width: 3.5))
                    : null,
              ),
              child: InkWell(
                onTap: () {
                  if (hasChildren) {
                    provider.toggleExpand(task.id);
                  }
                },
                child: Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: depth == 0 ? 1.1 : 1.0,
                            child: Checkbox(
                              value: hasChildren ? (task.progress >= 0.999) : task.isDone,
                              activeColor: AppTheme.secondary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              onChanged: (val) {
                                provider.toggleTaskDone(task.id, cascade: true);
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.name,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: depth == 0 ? FontWeight.w700 : (depth == 1 ? FontWeight.w600 : FontWeight.w500),
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    color: isDone
                                        ? theme.colorScheme.onSurface.withOpacity(0.5)
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (task.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    task.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: depth > 1 ? 10.5 : 11.0,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          WeightBadge(
                            weight: task.weight,
                            contributionPercent: contribution,
                            compact: depth > 0,
                          ),
                          const SizedBox(width: 4),
                          if (hasChildren)
                            IconButton(
                              icon: AnimatedRotation(
                                turns: task.isExpanded ? 0.25 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(Icons.chevron_right, size: depth > 1 ? 18 : 20),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => provider.toggleExpand(task.id),
                            ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: depth > 1 ? 16 : 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (action) {
                              if (action == 'add_child') {
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
                              } else if (action == 'focus') {
                                provider.drillDown(task);
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
                                value: 'add_child',
                                child: Row(
                                  children: [
                                    Icon(Icons.subdirectory_arrow_right, size: 18),
                                    SizedBox(width: 8),
                                    Text('Add Subtask'),
                                  ],
                                ),
                              ),
                              if (hasChildren)
                                const PopupMenuItem(
                                  value: 'focus',
                                  child: Row(
                                    children: [
                                      Icon(Icons.filter_center_focus, size: 18),
                                      SizedBox(width: 8),
                                      Text('Focus on Branch'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit Task'),
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
                      if (hasChildren) ...[
                        const SizedBox(height: 6),
                        WeightedProgressBar(
                          progress: task.progress,
                          earnedPoints: task.earnedWeightedPoints,
                          totalWeight: task.directChildrenTotalWeight,
                          showLabel: true,
                          height: depth > 1 ? 4 : 5,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            clipBehavior: Clip.antiAlias,
            child: (hasChildren && task.isExpanded)
                ? Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 2,
                          top: 0,
                          bottom: 12,
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              color: leftAccentColor?.withOpacity(0.5) ?? theme.colorScheme.outline.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: task.children
                              .map((child) => TreeTaskItem(
                                    task: child,
                                    depth: depth + 1,
                                    parentTotalWeight: task.directChildrenTotalWeight,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
