import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';

class StorageService {
  static const String _storageKey = 'treetask_v2_tasks';
  static const String _themeKey = 'treetask_v2_theme';

  Future<void> saveTasks(List<TaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  List<TaskItem> parseTasksFromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('projects') && decoded['projects'] is List) {
        list = decoded['projects'] as List;
      } else if (decoded.containsKey('tasks') && decoded['tasks'] is List) {
        list = decoded['tasks'] as List;
      } else {
        throw const FormatException('Invalid backup format');
      }
    } else {
      throw const FormatException('Invalid JSON format');
    }
    return list.map((item) => TaskItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<TaskItem>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return _generateDefaultSampleTasks();
    }
    try {
      return parseTasksFromJsonString(jsonString);
    } catch (e) {
      return _generateDefaultSampleTasks();
    }
  }

  Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  Future<bool> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? true; // default dark
  }

  List<TaskItem> _generateDefaultSampleTasks() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      TaskItem(
        id: '1',
        name: 'Launch Mobile App',
        description: 'Prepare complete launch strategy and release engineering',
        weight: 9,
        createdAt: now,
        isExpanded: true,
        children: [
          TaskItem(
            id: '1-1',
            parentId: '1',
            name: 'Backend Architecture',
            description: 'Scalable cloud infrastructure & database',
            weight: 8,
            createdAt: now,
            isExpanded: true,
            children: [
              TaskItem(
                id: '1-1-1',
                parentId: '1-1',
                name: 'Database Schema Design',
                description: 'PostgreSQL relational schemas with migrations',
                weight: 6,
                isDone: true,
                createdAt: now,
              ),
              TaskItem(
                id: '1-1-2',
                parentId: '1-1',
                name: 'Authentication & Security',
                description: 'OAuth2 and JWT token session management',
                weight: 8,
                isDone: true,
                createdAt: now,
              ),
              TaskItem(
                id: '1-1-3',
                parentId: '1-1',
                name: 'Load Balancing & Caching',
                description: 'Redis cluster with Redis Sentinel',
                weight: 5,
                isDone: false,
                createdAt: now,
              ),
            ],
          ),
          TaskItem(
            id: '1-2',
            parentId: '1',
            name: 'UI & User Experience',
            description: 'Material 3 design system with animations',
            weight: 7,
            createdAt: now,
            isExpanded: true,
            children: [
              TaskItem(
                id: '1-2-1',
                parentId: '1-2',
                name: 'Design System & Figma Tokens',
                weight: 7,
                isDone: true,
                createdAt: now,
              ),
              TaskItem(
                id: '1-2-2',
                parentId: '1-2',
                name: 'Dark Mode & Micro-Interactions',
                weight: 4,
                isDone: false,
                createdAt: now,
              ),
            ],
          ),
          TaskItem(
            id: '1-3',
            parentId: '1',
            name: 'App Store & Marketing Assets',
            description: 'Screenshots, promo video, and release notes',
            weight: 4,
            isDone: false,
            createdAt: now,
          ),
        ],
      ),
      TaskItem(
        id: '2',
        name: 'Personal Fitness & Health',
        description: 'Quarterly workout routines and nutrition tracking',
        weight: 6,
        createdAt: now,
        isExpanded: false,
        children: [
          TaskItem(
            id: '2-1',
            parentId: '2',
            name: 'Morning Cardio (30 mins)',
            weight: 5,
            isDone: true,
            createdAt: now,
          ),
          TaskItem(
            id: '2-2',
            parentId: '2',
            name: 'Meal Prep & Protein Targets',
            weight: 7,
            isDone: false,
            createdAt: now,
          ),
        ],
      ),
    ];
  }
}
