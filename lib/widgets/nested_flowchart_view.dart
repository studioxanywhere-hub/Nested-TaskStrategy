import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_item.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'weight_badge.dart';
import 'edit_task_dialog.dart';

class NestedFlowchartView extends StatefulWidget {
  final TaskItem rootTask;

  const NestedFlowchartView({
    super.key,
    required this.rootTask,
  });

  @override
  State<NestedFlowchartView> createState() => _NestedFlowchartViewState();
}

class _NestedFlowchartViewState extends State<NestedFlowchartView> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);

    return Column(
      children: [
        // Flowchart Control Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_tree_rounded, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Nested Flowchart View',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                icon: const Icon(Icons.unfold_more, size: 16),
                label: const Text('Expand All', style: TextStyle(fontSize: 11)),
                onPressed: () => provider.setAllExpanded(true),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                icon: const Icon(Icons.unfold_less, size: 16),
                label: const Text('Collapse All', style: TextStyle(fontSize: 11)),
                onPressed: () => provider.setAllExpanded(false),
              ),
              IconButton(
                tooltip: 'Reset Zoom',
                icon: const Icon(Icons.center_focus_strong, size: 18),
                onPressed: _resetZoom,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ),

        // Zoomable Canvas Container
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(300),
            minScale: 0.4,
            maxScale: 2.5,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 32.0, right: 32.0, top: 24.0, bottom: 120.0),
                  child: FlowchartNodeWidget(
                    task: widget.rootTask,
                    depth: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FlowchartNodeWidget extends StatelessWidget {
  final TaskItem task;
  final int depth;

  const FlowchartNodeWidget({
    super.key,
    required this.task,
    this.depth = 0,
  });

  Color _getTierColor(int d) {
    switch (d) {
      case 0:
        return AppTheme.primary;
      case 1:
        return AppTheme.secondary;
      case 2:
        return AppTheme.weightMedium;
      default:
        return Colors.purpleAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final hasChildren = task.children.isNotEmpty;
    final isDone = task.progress >= 0.999;
    final tierColor = _getTierColor(depth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Node Card Box
        Card(
          elevation: depth == 0 ? 3 : 1,
          shadowColor: tierColor.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDone ? AppTheme.secondary : tierColor.withOpacity(0.6),
              width: depth == 0 ? 2 : 1.2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 270,
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(left: BorderSide(color: tierColor, width: 4.5)),
            ),
            child: InkWell(
              onTap: () {
                if (hasChildren) {
                  provider.toggleExpand(task.id);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: hasChildren ? (task.progress >= 0.999) : task.isDone,
                            activeColor: AppTheme.secondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              provider.toggleTaskDone(task.id, cascade: true);
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            task.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: depth == 0 ? 14.5 : 13.5,
                              fontWeight: FontWeight.bold,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone
                                  ? theme.colorScheme.onSurface.withOpacity(0.5)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        WeightBadge(weight: task.weight, compact: true),
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tierColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hasChildren
                                ? '${(task.progress * 100).toInt()}% • ${task.children.length} subtasks'
                                : (isDone ? 'COMPLETED' : 'DIRECT NODE'),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: tierColor,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (hasChildren)
                              InkWell(
                                onTap: () => provider.toggleExpand(task.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        task.isExpanded ? Icons.remove : Icons.add,
                                        size: 12,
                                        color: tierColor,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        task.isExpanded ? 'Collapse' : 'Expand',
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: tierColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 16),
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
                                      Icon(Icons.subdirectory_arrow_right, size: 16),
                                      SizedBox(width: 6),
                                      Text('Add Subtask', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (hasChildren)
                                  const PopupMenuItem(
                                    value: 'focus',
                                    child: Row(
                                      children: [
                                        Icon(Icons.filter_center_focus, size: 16),
                                        SizedBox(width: 6),
                                        Text('Focus Branch', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 16),
                                      SizedBox(width: 6),
                                      Text('Edit Node', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                      SizedBox(width: 6),
                                      Text('Delete', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                                    ],
                                  ),
                                ),
                              ],
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
        ),

        // Subtask Nodes Hierarchy with Vertical Line Connectors
        if (hasChildren && task.isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: IntrinsicWidth(
              child: Stack(
                children: [
                  Positioned(
                    left: 6,
                    top: 0,
                    bottom: 24,
                    child: Container(
                      width: 2.5,
                      decoration: BoxDecoration(
                        color: tierColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: task.children.map((child) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 14,
                              height: 2.5,
                              margin: const EdgeInsets.only(top: 24, right: 6),
                              color: tierColor.withOpacity(0.4),
                            ),
                            FlowchartNodeWidget(
                              task: child,
                              depth: depth + 1,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
