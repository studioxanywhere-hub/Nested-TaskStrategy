import 'package:uuid/uuid.dart';

class TaskItem {
  final String id;
  String name;
  String description;
  int weight; // 1 to 10 scale
  bool isDone;
  List<TaskItem> children;
  final DateTime? deadline;
  bool isExpanded;
  bool isFilterMatch;
  bool isFilterAncestor;

  TaskItem({
    required this.id,
    required this.name,
    this.description = '',
    this.weight = 1,
    this.isDone = false,
    List<TaskItem>? children,
    this.deadline,
    this.isExpanded = true,
    this.isFilterMatch = true,
    this.isFilterAncestor = false,
  }) : children = children ?? [];

  double get progress {
    if (children.isEmpty) {
      return isDone ? 1.0 : 0.0;
    }
    int totalWeight = 0;
    double weightedProgressSum = 0;
    for (var child in children) {
      int w = child.weight.clamp(1, 10);
      totalWeight += w;
      weightedProgressSum += child.progress * w;
    }
    if (totalWeight == 0) return isDone ? 1.0 : 0.0;
    return (weightedProgressSum / totalWeight).clamp(0.0, 1.0);
  }

  int get directChildrenTotalWeight {
    if (children.isEmpty) return weight;
    return children.fold(0, (sum, child) => sum + child.weight.clamp(1, 10));
  }

  double get earnedWeightedPoints {
    if (children.isEmpty) {
      return isDone ? weight.toDouble() : 0.0;
    }
    return progress * directChildrenTotalWeight;
  }

  double contributionPercentage(int parentTotalWeight) {
    if (parentTotalWeight <= 0) return 0.0;
    return (weight.clamp(1, 10) / parentTotalWeight) * 100;
  }

  int get totalSubtasksCount {
    int count = children.length;
    for (var child in children) {
      count += child.totalSubtasksCount;
    }
    return count;
  }

  int get completedSubtasksCount {
    int count = 0;
    for (var child in children) {
      if (child.progress >= 0.999) count++;
      count += child.completedSubtasksCount;
    }
    return count;
  }

  int get maxDepth {
    if (children.isEmpty) return 0;
    int maxChildDepth = 0;
    for (var child in children) {
      int d = child.maxDepth;
      if (d > maxChildDepth) maxChildDepth = d;
    }
    return maxChildDepth + 1;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'weight': weight,
      'isDone': isDone,
      'children': children.map((c) => c.toMap()).toList(),
      'deadline': deadline?.toIso8601String(),
      'isExpanded': isExpanded,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem.fromMap(json);

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      weight: (map['weight'] as num?)?.toInt().clamp(1, 10) ?? 1,
      isDone: map['isDone'] ?? false,
      children: (map['children'] as List<dynamic>?)
              ?.map((c) => TaskItem.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      deadline: map['deadline'] != null ? DateTime.tryParse(map['deadline']) : null,
      isExpanded: map['isExpanded'] ?? true,
    );
  }
}

class TaskStrategyMetrics {
  final double averageWeight;
  final int maxDepth;
  final int completedMilestones;
  final int totalMilestones;
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final double overallWeightedScore;
  final String strategyArchetype;
  final String archetypeDescription;
  final int minorCount;
  final int moderateCount;
  final int criticalCount;
  final double minorPercent;
  final double moderatePercent;
  final double criticalPercent;

  TaskStrategyMetrics({
    required this.averageWeight,
    required this.maxDepth,
    required this.completedMilestones,
    required this.totalMilestones,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.overallWeightedScore,
    required this.strategyArchetype,
    required this.archetypeDescription,
    required this.minorCount,
    required this.moderateCount,
    required this.criticalCount,
    required this.minorPercent,
    required this.moderatePercent,
    required this.criticalPercent,
  });

  factory TaskStrategyMetrics.compute(List<TaskItem> tasks) {
    if (tasks.isEmpty) {
      return TaskStrategyMetrics(
        averageWeight: 0.0,
        maxDepth: 0,
        completedMilestones: 0,
        totalMilestones: 0,
        totalTasks: 0,
        completedTasks: 0,
        completionRate: 0.0,
        overallWeightedScore: 0.0,
        strategyArchetype: 'Strategic Starter',
        archetypeDescription: 'Add your first project to discover your structuring archetype.',
        minorCount: 0,
        moderateCount: 0,
        criticalCount: 0,
        minorPercent: 0.0,
        moderatePercent: 0.0,
        criticalPercent: 0.0,
      );
    }

    int totalCount = 0;
    int completedCount = 0;
    int weightSum = 0;
    int maxD = 0;
    int minor = 0;
    int moderate = 0;
    int critical = 0;

    int rootMilestones = tasks.length;
    int rootCompletedMilestones = tasks.where((t) => t.progress >= 0.999).length;

    void process(TaskItem t, int d) {
      totalCount++;
      if (t.progress >= 0.999) completedCount++;
      weightSum += t.weight;
      if (d > maxD) maxD = d;

      if (t.weight <= 3) {
        minor++;
      } else if (t.weight <= 7) {
        moderate++;
      } else {
        critical++;
      }

      for (var child in t.children) {
        process(child, d + 1);
      }
    }

    for (var t in tasks) {
      process(t, 1);
    }

    double avgW = totalCount > 0 ? weightSum / totalCount : 0.0;
    double compRate = totalCount > 0 ? (completedCount / totalCount) * 100.0 : 0.0;
    double overallScore = tasks.fold(0.0, (s, t) => s + t.progress) / tasks.length * 100.0;

    double minorP = totalCount > 0 ? (minor / totalCount) * 100.0 : 0.0;
    double modP = totalCount > 0 ? (moderate / totalCount) * 100.0 : 0.0;
    double critP = totalCount > 0 ? (critical / totalCount) * 100.0 : 0.0;

    String archetype;
    String archetypeDesc;

    if (maxD >= 4) {
      archetype = 'Deep Systems Architect';
      archetypeDesc = 'You excel at breaking complex goals down into deeply structured sub-milestones.';
    } else if (avgW >= 7.5) {
      archetype = 'High-Impact Operator';
      archetypeDesc = 'Your focus is heavily concentrated on high-leverage, heavy strategic objectives.';
    } else if (minorP >= 50.0) {
      archetype = 'Tactical Execution Specialist';
      archetypeDesc = 'You build momentum through quick wins and highly actionable micro-tasks.';
    } else {
      archetype = 'Balanced Strategist';
      archetypeDesc = 'You maintain a healthy equilibrium between broad vision and detailed execution.';
    }

    return TaskStrategyMetrics(
      averageWeight: avgW,
      maxDepth: maxD,
      completedMilestones: rootCompletedMilestones,
      totalMilestones: rootMilestones,
      totalTasks: totalCount,
      completedTasks: completedCount,
      completionRate: compRate,
      overallWeightedScore: overallScore,
      strategyArchetype: archetype,
      archetypeDescription: archetypeDesc,
      minorCount: minor,
      moderateCount: moderate,
      criticalCount: critical,
      minorPercent: minorP,
      moderatePercent: modP,
      criticalPercent: critP,
    );
  }

  String toDiagnosticString() {
    return 'Nested Strategy Metrics:\n'
        '• Archetype: $strategyArchetype\n'
        '• Overall Score: ${overallWeightedScore.toStringAsFixed(1)}%\n'
        '• Max Depth: Level $maxDepth\n'
        '• Total Tasks: $totalTasks ($completedTasks completed)\n'
        '• Avg Weight: ${averageWeight.toStringAsFixed(1)}/10\n'
        '• Minor (1-3): $minorCount (${minorPercent.toStringAsFixed(0)}%)\n'
        '• Moderate (4-7): $moderateCount (${moderatePercent.toStringAsFixed(0)}%)\n'
        '• Critical (8-10): $criticalCount (${criticalPercent.toStringAsFixed(0)}%)';
  }
}

