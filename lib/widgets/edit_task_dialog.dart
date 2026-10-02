import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';

class EditTaskDialog extends StatefulWidget {
  final TaskItem? initialTask;
  final String? parentName;
  final void Function(String name, String description, int weight, DateTime? deadline) onSave;

  const EditTaskDialog({
    super.key,
    this.initialTask,
    this.parentName,
    required this.onSave,
  });

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late int _weight;
  DateTime? _selectedDeadline;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialTask?.name ?? '');
    _descController = TextEditingController(text: widget.initialTask?.description ?? '');
    _weight = widget.initialTask?.weight ?? 5;
    if (widget.initialTask?.deadline != null) {
      _selectedDeadline = widget.initialTask!.deadline;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;
    final theme = Theme.of(context);
    final weightColor = AppTheme.getWeightColor(_weight);
    final weightLabel = AppTheme.getWeightLabel(_weight);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Task' : (widget.parentName != null ? 'Add Subtask' : 'New Project'),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                if (widget.parentName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Subtask under: ${widget.parentName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'e.g. Design Database Schema',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Notes, acceptance criteria, or details...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.notes, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Weightage (Effort / Impact):',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: weightColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: weightColor),
                      ),
                      child: Text(
                        '$_weight / 10 ($weightLabel)',
                        style: TextStyle(
                          color: weightColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _weight.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: weightColor,
                  inactiveColor: weightColor.withOpacity(0.2),
                  onChanged: (val) {
                    setState(() {
                      _weight = val.round();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 (Minor)', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    Text('5 (Standard)', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    Text('10 (Critical)', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDeadline ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDeadline = pickedDate;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedDeadline == null
                                ? 'Set Deadline (Optional)'
                                : 'Due: ${DateFormat('MMM dd, yyyy').format(_selectedDeadline!)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedDeadline == null
                                  ? theme.colorScheme.onSurface.withOpacity(0.6)
                                  : theme.colorScheme.primary,
                              fontWeight: _selectedDeadline == null ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_selectedDeadline != null)
                          GestureDetector(
                            onTap: () => setState(() => _selectedDeadline = null),
                            child: const Icon(Icons.cancel, size: 16),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        final title = _nameController.text.trim();
                        if (title.isEmpty) return;
                        widget.onSave(
                          title,
                          _descController.text.trim(),
                          _weight,
                          _selectedDeadline,
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text(isEditing ? 'Save Changes' : 'Create Task'),
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
