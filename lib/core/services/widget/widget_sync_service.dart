import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class WidgetSyncService {
  static const String appGroupId = 'group.com.jjcompany.yesdiary';
  static const String iOSWidgetName = 'WorkTimerWidget';

  static const String _keyStartTime = 'workStartTime';
  static const String _keyEndTime = 'workEndTime';
  static const String _keyOffWorkDate = 'offWorkDate';

  static Future<void> _ensureGroupId() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> syncWorkEndTime(String? endTime) async {
    await _ensureGroupId();
    await HomeWidget.saveWidgetData<String>(_keyEndTime, endTime ?? '');
    await HomeWidget.updateWidget(iOSName: iOSWidgetName);
  }

  static Future<void> syncWorkSchedule({
    String? startTime,
    String? endTime,
  }) async {
    await _ensureGroupId();
    await HomeWidget.saveWidgetData<String>(_keyStartTime, startTime ?? '');
    await HomeWidget.saveWidgetData<String>(_keyEndTime, endTime ?? '');
    await HomeWidget.updateWidget(iOSName: iOSWidgetName);
  }

  static Future<void> markOffWorkToday() async {
    await _ensureGroupId();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await HomeWidget.saveWidgetData<String>(_keyOffWorkDate, today);
    await HomeWidget.updateWidget(iOSName: iOSWidgetName);
  }

  static Future<String?> readOffWorkDate() async {
    await _ensureGroupId();
    return HomeWidget.getWidgetData<String>(_keyOffWorkDate);
  }
}
