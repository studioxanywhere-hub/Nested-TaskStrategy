import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
import '../services/storage_service.dart';

enum TaskSortOption {
  custom,
  priorityHighToLow,
  priorityLowToHigh,
  statusActiveFirst,
  alphabetical,
}

class TaskProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final Uuid _uuid = const Uuid();

  List<TaskItem> _tasks = [];
  final List<TaskItem> _breadcrumbStack = [];

  bool _isDarkMode = true;
  String _searchQuery = '';
  int? _minWeightFilter;
  bool? _statusFilter; // null = all, true = completed, false = active
  TaskSortOption _sortOption = TaskSortOption.custom;
  bool _isLoading = true;

  TaskProvider() {
    _init();
  }

  // Getters
  List<TaskItem> get tasks => _tasks;
  List<TaskItem> get rootTasks => _tasks;
  List<TaskItem> get breadcrumbStack => _breadcrumbStack;
  bool get isDarkMode => _isDarkMode;
  String get searchQuery => _searchQuery;
  int? get minWeightFilter => _minWeightFilter;
  bool? get statusFilter => _statusFilter;
  TaskSortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;

  void setSortOption(TaskSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    notifyListeners();
  }

  // Active view: either the current focused subtask children or root tasks
  List<TaskItem> get currentViewTasks {
    List<TaskItem> source;
    if (_breadcrumbStack.isEmpty) {
      source = _tasks;
    } else {
      source = _breadcrumbStack.last.children;
    }

    // Apply Search & Filter
    final filtered = source.where((task) {
      if (_searchQuery.isNotEmpty) {
        final matchesName = task.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesDesc = task.description.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesName && !matchesDesc) return false;
      }
      if (_minWeightFilter != null && task.weight < _minWeightFilter!) {
        return false;
      }
      if (_statusFilter != null) {
        final isComplete = task.progress >= 0.999;
        if (_statusFilter == true && !isComplete) return false;
        if (_statusFilter == false && isComplete) return false;
      }
      return true;
    }).toList();

    // Non-destructive Derived Sort with Stable Secondary Ordering (Canonical Custom Index)
    if (_sortOption == TaskSortOption.custom) {
      return filtered;
    }

    final indexMap = <String, int>{};
    for (int i = 0; i < source.length; i++) {
      indexMap[source[i].id] = i;
    }

    final sorted = List<TaskItem>.from(filtered);

    switch (_sortOption) {
      case TaskSortOption.priorityHighToLow:
        sorted.sort((a, b) {
          final cmp = b.weight.compareTo(a.weight);
          if (cmp != 0) return cmp;
          return (indexMap[a.id] ?? 0).compareTo(indexMap[b.id] ?? 0);
        });
        break;
      case TaskSortOption.priorityLowToHigh:
        sorted.sort((a, b) {
          final cmp = a.weight.compareTo(b.weight);
          if (cmp != 0) return cmp;
          return (indexMap[a.id] ?? 0).compareTo(indexMap[b.id] ?? 0);
        });
        break;
      case TaskSortOption.statusActiveFirst:
        sorted.sort((a, b) {
          final aDone = a.progress >= 0.999 || a.isDone;
          final bDone = b.progress >= 0.999 || b.isDone;
          if (aDone != bDone) {
            return aDone ? 1 : -1;
          }
          return (indexMap[a.id] ?? 0).compareTo(indexMap[b.id] ?? 0);
        });
        break;
      case TaskSortOption.alphabetical:
        sorted.sort((a, b) {
          final cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          if (cmp != 0) return cmp;
          return (indexMap[a.id] ?? 0).compareTo(indexMap[b.id] ?? 0);
        });
        break;
      case TaskSortOption.custom:
        break;
    }

    return sorted;
  }

  // Project statistics
  int get totalRootProjects => _tasks.length;
  
  double get overallProgress {
    if (_tasks.isEmpty) return 0.0;
    final totalWeight = _tasks.fold(0, (sum, t) => sum + t.weight);
    if (totalWeight == 0) return 0.0;
    final weightedSum = _tasks.fold(0.0, (sum, t) => sum + (t.progress * t.weight));
    return (weightedSum / totalWeight).clamp(0.0, 1.0);
  }

  int get totalTasksCount {
    int count = _tasks.length;
    for (final task in _tasks) {
      count += task.recursiveSubtaskCount;
    }
    return count;
  }

  TaskStrategyMetrics get strategyMetrics => TaskStrategyMetrics.compute(_tasks);

  Future<void> _init() async {
    _isDarkMode = await _storageService.loadThemeMode();
    _tasks = await _storageService.loadTasks();
    _isLoading = false;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storageService.saveThemeMode(_isDarkMode);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter({int? minWeight, bool? status}) {
    _minWeightFilter = minWeight;
    _statusFilter = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _minWeightFilter = null;
    _statusFilter = null;
    notifyListeners();
  }

  // Drill-down Focus Mode
  void drillDown(TaskItem task) {
    _breadcrumbStack.add(task);
    notifyListeners();
  }

  void popBreadcrumb() {
    if (_breadcrumbStack.isNotEmpty) {
      _breadcrumbStack.removeLast();
      notifyListeners();
    }
  }

  void navigateToBreadcrumbIndex(int index) {
    if (index < 0) {
      _breadcrumbStack.clear();
    } else if (index < _breadcrumbStack.length) {
      _breadcrumbStack.removeRange(index + 1, _breadcrumbStack.length);
    }
    notifyListeners();
  }

  // Task Mutations
  void addRootTask({
    required String name,
    String description = '',
    int weight = 5,
    int? deadline,
  }) {
    final newTask = TaskItem(
      id: _uuid.v4(),
      name: name,
      description: description,
      weight: weight,
      deadline: deadline,
    );
    _tasks.insert(0, newTask);
    _save();
    notifyListeners();
  }

  void addSubTask({
    required String parentId,
    required String name,
    String description = '',
    int weight = 5,
    int? deadline,
  }) {
    final newTask = TaskItem(
      id: _uuid.v4(),
      parentId: parentId,
      name: name,
      description: description,
      weight: weight,
      deadline: deadline,
    );

    _insertChildRecursive(_tasks, parentId, newTask);
    _save();
    notifyListeners();
  }

  bool _insertChildRecursive(List<TaskItem> list, String parentId, TaskItem newChild) {
    for (final task in list) {
      if (task.id == parentId) {
        task.children.add(newChild);
        task.isExpanded = true;
        return true;
      }
      if (_insertChildRecursive(task.children, parentId, newChild)) {
        return true;
      }
    }
    return false;
  }

  void updateTask({
    required String id,
    required String name,
    required String description,
    required int weight,
    int? deadline,
  }) {
    _updateRecursive(_tasks, id, (task) {
      task.name = name;
      task.description = description;
      task.weight = weight.clamp(1, 10);
      task.deadline = deadline;
    });
    _save();
    notifyListeners();
  }

  bool _updateRecursive(List<TaskItem> list, String id, void Function(TaskItem) updater) {
    for (final task in list) {
      if (task.id == id) {
        updater(task);
        return true;
      }
      if (_updateRecursive(task.children, id, updater)) {
        return true;
      }
    }
    return false;
  }

  void toggleTaskDone(String id, {bool cascade = true}) {
    _toggleDoneRecursive(_tasks, id, cascade);
    _save();
    notifyListeners();
  }

  bool _toggleDoneRecursive(List<TaskItem> list, String id, bool cascade) {
    for (final task in list) {
      if (task.id == id) {
        final newDone = !task.isDone;
        if (cascade) {
          task.setDoneRecursive(newDone);
        } else {
          task.isDone = newDone;
        }
        return true;
      }
      if (_toggleDoneRecursive(task.children, id, cascade)) {
        return true;
      }
    }
    return false;
  }

  void deleteTask(String id) {
    _deleteRecursive(_tasks, id);
    _breadcrumbStack.removeWhere((t) => t.id == id);
    _save();
    notifyListeners();
  }

  bool _deleteRecursive(List<TaskItem> list, String id) {
    final index = list.indexWhere((t) => t.id == id);
    if (index != -1) {
      list.removeAt(index);
      return true;
    }
    for (final task in list) {
      if (_deleteRecursive(task.children, id)) {
        return true;
      }
    }
    return false;
  }

  void toggleExpand(String id) {
    _updateRecursive(_tasks, id, (task) {
      task.isExpanded = !task.isExpanded;
    });
    notifyListeners();
  }

  void setAllExpanded(bool expanded) {
    void expandAll(List<TaskItem> list) {
      for (final task in list) {
        task.isExpanded = expanded;
        expandAll(task.children);
      }
    }
    expandAll(_tasks);
    notifyListeners();
  }

  // Reorder tasks at current level or specified parent sibling level
  void reorderTasks(int oldIndex, int newIndex, {String? parentId}) {
    if (_sortOption != TaskSortOption.custom) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    List<TaskItem> targetList;
    if (parentId != null) {
      final parent = _findTaskByIdRecursive(_tasks, parentId);
      if (parent != null) {
        targetList = parent.children;
      } else {
        return;
      }
    } else {
      if (_breadcrumbStack.isEmpty) {
        targetList = _tasks;
      } else {
        targetList = _breadcrumbStack.last.children;
      }
    }

    if (oldIndex < 0 || oldIndex >= targetList.length) return;
    if (newIndex < 0 || newIndex >= targetList.length) return;

    final item = targetList.removeAt(oldIndex);
    targetList.insert(newIndex, item);

    _save();
    notifyListeners();
  }

  TaskItem? _findTaskByIdRecursive(List<TaskItem> list, String id) {
    for (final task in list) {
      if (task.id == id) return task;
      final found = _findTaskByIdRecursive(task.children, id);
      if (found != null) return found;
    }
    return null;
  }

  // Restore Tasks from JSON Backup
  bool importBackupJson(String jsonStr) {
    try {
      final List<TaskItem> imported = _storageService.parseTasksFromJsonString(jsonStr);
      if (imported.isEmpty) return false;
      _tasks = imported;
      _breadcrumbStack.clear();
      _save();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Import Backup Error: $e');
      return false;
    }
  }

  void _save() {
    _storageService.saveTasks(_tasks);
  }
}
