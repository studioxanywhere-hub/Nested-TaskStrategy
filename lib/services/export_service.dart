import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/task_item.dart';

class ExportService {
  // Generate JSON backup string
  static String exportToJson(List<TaskItem> tasks) {
    final Map<String, dynamic> backupData = {
      'app': 'Nested: Task Strategy',
      'version': '2.1.8',
      'exportedAt': DateTime.now().toIso8601String(),
      'totalProjects': tasks.length,
      'projects': tasks.map((t) => t.toJson()).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backupData);
  }

  // Generate Markdown outline
  static String exportToMarkdown(List<TaskItem> tasks) {
    final buffer = StringBuffer();
    buffer.writeln('# Nested: Task Strategy Export');
    buffer.writeln('Exported on: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln();

    void renderTaskMarkdown(TaskItem task, int depth) {
      final indent = '  ' * depth;
      final status = (task.children.isNotEmpty ? task.progress >= 0.999 : task.isDone) ? '[x]' : '[ ]';
      final desc = task.description.isNotEmpty ? ' - *${task.description}*' : '';
      
      if (depth == 0) {
        buffer.writeln('## $status ${task.name} (Weight: ${task.weight})');
        if (task.description.isNotEmpty) {
          buffer.writeln('> ${task.description}');
        }
        buffer.writeln();
      } else {
        buffer.writeln('$indent- $status **${task.name}** (W: ${task.weight})$desc');
      }

      for (final child in task.children) {
        renderTaskMarkdown(child, depth + 1);
      }
    }

    for (final task in tasks) {
      renderTaskMarkdown(task, 0);
      buffer.writeln();
    }

    return buffer.toString();
  }

  // Generate Plain Text outline
  static String exportToPlainText(List<TaskItem> tasks) {
    final buffer = StringBuffer();
    buffer.writeln('=========================================');
    buffer.writeln('NESTED: TASK STRATEGY EXPORT');
    buffer.writeln('Date: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('=========================================\n');

    void renderTaskText(TaskItem task, int depth) {
      final indent = '  ' * depth;
      final status = (task.children.isNotEmpty ? task.progress >= 0.999 : task.isDone) ? '[COMPLETED]' : '[ACTIVE]';
      final desc = task.description.isNotEmpty ? ' ($task.description)' : '';
      
      buffer.writeln('${indent}• $status ${task.name} [Weight: ${task.weight}]$desc');
      for (final child in task.children) {
        renderTaskText(child, depth + 1);
      }
    }

    for (final task in tasks) {
      renderTaskText(task, 0);
      buffer.writeln();
    }

    return buffer.toString();
  }

  // Save string content to local device Download folder
  static Future<String?> saveFileToDownloads(String content, String fileName) async {
    try {
      Directory? targetDir;

      if (kIsWeb) {
        return null;
      }

      if (Platform.isAndroid) {
        // Standard Android Download directory
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        } else {
          final fallbackDir = Directory('/sdcard/Download');
          if (await fallbackDir.exists()) {
            targetDir = fallbackDir;
          }
        }
      }

      if (targetDir == null) {
        targetDir = Directory.systemTemp;
      }

      final file = File('${targetDir.path}/$fileName');
      await file.writeAsString(content, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Error saving file locally: $e');
      return null;
    }
  }
}
