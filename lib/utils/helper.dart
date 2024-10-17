import 'dart:async';
import 'package:reclaim_sdk/utils/errors.dart';

void clearInterval(Map<String, Timer> intervals, String sessionId) {
  if (sessionId.isNotEmpty && intervals.containsKey(sessionId)) {
    intervals[sessionId]!.cancel();
    intervals.remove(sessionId);
  }
}

void scheduleIntervalEndingTask(
  Map<String, Timer> intervals,
  String sessionId,
  void Function(Exception) onError,
) {
  Future.delayed(const Duration(minutes: 10), () {
    if (intervals.containsKey(sessionId)) {
      clearInterval(intervals, sessionId);
      onError(sessionTimeoutError('Session timed out after 10 minutes'));
    }
  });
}
