import 'package:flutter/material.dart';
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
  List<TaskItem> _tasks = [];
  bool _isLoading = true;
  bool _isDarkMode = true;

  final List<TaskItem> _breadcrumbStack = [];
  TaskSortOption _sortOption = TaskSortOption.custom;
  int? _minWeightFilter;
  bool? _statusFilter;
  String _searchQuery = '';

  List<TaskItem> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  List<TaskItem> get breadcrumbStack => List.unmodifiable(_breadcrumbStack);
  TaskSortOption get sortOption => _sortOption;
  int? get minWeightFilter => _minWeightFilter;
  bool? get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  TaskStrategyMetrics get strategyMetrics => TaskStrategyMetrics.compute(_tasks);

  TaskProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    _isDarkMode = await _storageService.loadDarkMode();
    _tasks = await _storageService.loadTasks();
    _applyFiltersAndSort();
    _isLoading = false;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storageService.saveDarkMode(_isDarkMode);
    notifyListeners();
  }

  void setSortOption(TaskSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setFilter({int? minWeight, bool? status}) {
    _minWeightFilter = minWeight;
    _statusFilter = status;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _minWeightFilter = null;
    _statusFilter = null;
    _searchQuery = '';
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    for (var task in _tasks) {
      _evaluateTaskFilters(task);
    }
  }

  bool _evaluateTaskFilters(TaskItem task) {
    bool matchesSelf = true;

    if (_searchQuery.isNotEmpty) {
      bool nameMatch = task.name.toLowerCase().contains(_searchQuery);
      bool descMatch = task.description.toLowerCase().contains(_searchQuery);
      if (!nameMatch && !descMatch) matchesSelf = false;
    }

    if (_minWeightFilter != null && task.weight < _minWeightFilter!) {
      matchesSelf = false;
    }

    if (_statusFilter != null) {
      bool isComplete = task.progress >= 0.999;
      if (_statusFilter! && !isComplete) matchesSelf = false;
      if (!_statusFilter! && isComplete) matchesSelf = false;
    }

    bool hasMatchingChild = false;
    for (var child in task.children) {
      bool childMatches = _evaluateTaskFilters(child);
      if (childMatches) hasMatchingChild = true;
    }

    task.isFilterMatch = matchesSelf;
    task.isFilterAncestor = !matchesSelf && hasMatchingChild;

    return matchesSelf || hasMatchingChild;
  }

  List<TaskItem> get currentViewTasks {
    List<TaskItem> source;
    if (_breadcrumbStack.isEmpty) {
      source = _tasks;
    } else {
      source = _breadcrumbStack.last.children;
    }

    List<TaskItem> visible = source.where((t) => t.isFilterMatch || t.isFilterAncestor).toList();

    if (_sortOption == TaskSortOption.custom) {
      return visible;
    }

    final indexMap = <String, int>{};
    for (int i = 0; i < visible.length; i++) {
      indexMap[visible[i].id] = i;
    }

    final sorted = List<TaskItem>.from(visible);

    sorted.sort((a, b) {
      int primaryComparison = 0;
      switch (_sortOption) {
        case TaskSortOption.priorityHighToLow:
          primaryComparison = b.weight.compareTo(a.weight);
          break;
        case TaskSortOption.priorityLowToHigh:
          primaryComparison = a.weight.compareTo(b.weight);
          break;
        case TaskSortOption.statusActiveFirst:
          int aStatus = a.progress >= 0.999 ? 1 : 0;
          int bStatus = b.progress >= 0.999 ? 1 : 0;
          primaryComparison = aStatus.compareTo(bStatus);
          break;
        case TaskSortOption.alphabetical:
          primaryComparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case TaskSortOption.custom:
          break;
      }

      if (primaryComparison != 0) return primaryComparison;
      return (indexMap[a.id] ?? 0).compareTo(indexMap[b.id] ?? 0);
    });

    return sorted;
  }

  Future<void> reorderTasks(int oldIndex, int newIndex, {String? parentId}) async {
    if (_sortOption != TaskSortOption.custom) return;

    List<TaskItem> targetList;
    if (parentId == null) {
      targetList = _tasks;
    } else {
      final parent = _findTaskById(_tasks, parentId);
      if (parent == null) return;
      targetList = parent.children;
    }

    if (oldIndex < 0 || oldIndex >= targetList.length) return;
    if (oldIndex < newIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex > targetList.length) return;

    final movedItem = targetList.removeAt(oldIndex);
    targetList.insert(newIndex, movedItem);

    await _storageService.saveTasks(_tasks);
    notifyListeners();
  }

  void setExpansionDepth(int maxDepth, {List<TaskItem>? nodes, int currentDepth = 0}) {
    nodes ??= _tasks;
    for (var node in nodes) {
      node.isExpanded = currentDepth < maxDepth;
      if (node.children.isNotEmpty) {
        setExpansionDepth(maxDepth, nodes: node.children, currentDepth: currentDepth + 1);
      }
    }
    notifyListeners();
  }

  void setAllExpanded(bool expanded) {
    _setExpandedRecursive(_tasks, expanded);
    notifyListeners();
  }

  void _setExpandedRecursive(List<TaskItem> list, bool expanded) {
    for (var t in list) {
      t.isExpanded = expanded;
      if (t.children.isNotEmpty) {
        _setExpandedRecursive(t.children, expanded);
      }
    }
  }

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

  void popToBreadcrumb(int index) {
    if (index < 0) {
      _breadcrumbStack.clear();
    } else if (index < _breadcrumbStack.length) {
      _breadcrumbStack.removeRange(index + 1, _breadcrumbStack.length);
    }
    notifyListeners();
  }

  void navigateToBreadcrumbIndex(int index) => popToBreadcrumb(index);

  TaskItem? _findTaskById(List<TaskItem> list, String id) {
    for (var task in list) {
      if (task.id == id) return task;
      var found = _findTaskById(task.children, id);
      if (found != null) return found;
    }
    return null;
  }

  Future<void> addRootTask({required String name, String description = '', int weight = 1, DateTime? deadline}) async {
    final newTask = TaskItem(
      id: const Uuid().v4(),
      name: name,
      description: description,
      weight: weight.clamp(1, 10),
      deadline: deadline,
    );
    _tasks.add(newTask);
    _applyFiltersAndSort();
    await _storageService.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> addSubTask({required String parentId, required String name, String description = '', int weight = 1, DateTime? deadline}) async {
    final parent = _findTaskById(_tasks, parentId);
    if (parent != null) {
      parent.children.add(TaskItem(
        id: const Uuid().v4(),
        name: name,
        description: description,
        weight: weight.clamp(1, 10),
        deadline: deadline,
      ));
      parent.isExpanded = true;
      _applyFiltersAndSort();
      await _storageService.saveTasks(_tasks);
      notifyListeners();
    }
  }

  Future<void> toggleTaskDone(String id, {bool cascade = true}) async {
    final task = _findTaskById(_tasks, id);
    if (task != null) {
      bool newStatus = !(task.progress >= 0.999);
      _setDoneRecursive(task, newStatus);
      _applyFiltersAndSort();
      await _storageService.saveTasks(_tasks);
      notifyListeners();
    }
  }

  void _setDoneRecursive(TaskItem task, bool status) {
    task.isDone = status;
    for (var child in task.children) {
      _setDoneRecursive(child, status);
    }
  }

  Future<void> updateTask({required String id, required String name, required String description, required int weight, DateTime? deadline}) async {
    final task = _findTaskById(_tasks, id);
    if (task != null) {
      task.name = name;
      task.description = description;
      task.weight = weight.clamp(1, 10);
      _applyFiltersAndSort();
      await _storageService.saveTasks(_tasks);
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _deleteRecursive(_tasks, id);
    _breadcrumbStack.removeWhere((b) => b.id == id);
    _applyFiltersAndSort();
    await _storageService.saveTasks(_tasks);
    notifyListeners();
  }

  bool _deleteRecursive(List<TaskItem> list, String id) {
    int index = list.indexWhere((t) => t.id == id);
    if (index != -1) {
      list.removeAt(index);
      return true;
    }
    for (var item in list) {
      if (_deleteRecursive(item.children, id)) return true;
    }
    return false;
  }

  void toggleExpand(String id) {
    final task = _findTaskById(_tasks, id);
    if (task != null) {
      task.isExpanded = !task.isExpanded;
      notifyListeners();
    }
  }

  int get totalRootProjects => _tasks.length;
  int get totalTasksCount => _tasks.fold(0, (sum, t) => sum + 1 + t.totalSubtasksCount);

  double get overallProgress {
    if (_tasks.isEmpty) return 0.0;
    double sum = _tasks.fold(0.0, (s, t) => s + t.progress);
    return sum / _tasks.length;
  }

  int get maxProjectDepth {
    if (_tasks.isEmpty) return 0;
    return _tasks.fold(0, (max, t) {
      int d = t.maxDepth;
      return d > max ? d : max;
    });
  }
}
