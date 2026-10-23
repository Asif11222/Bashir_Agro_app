enum NotificationEventType {
  newTask,
  reminder,
  approval,
  rejection,
  cancellation,
}

class AppNotificationModel {
  final String id;
  final NotificationEventType eventType;
  final String title;
  final String message;
  final DateTime timestamp;
  final int? assignmentId;
  bool isRead;

  AppNotificationModel({
    required this.id,
    required this.eventType,
    required this.title,
    required this.message,
    required this.timestamp,
    this.assignmentId,
    this.isRead = false,
  });

  String get eventNameBengali {
    switch (eventType) {
      case NotificationEventType.newTask:
        return 'নতুন কাজ';
      case NotificationEventType.reminder:
        return 'কাজের তাগিদ';
      case NotificationEventType.approval:
        return 'অনুমোদন';
      case NotificationEventType.rejection:
        return 'পুনরায় যাচাই';
      case NotificationEventType.cancellation:
        return 'কাজ বাতিল';
    }
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      eventType: NotificationEventType.values.firstWhere(
        (e) => e.name == json['event_type'],
        orElse: () => NotificationEventType.newTask,
      ),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      assignmentId: json['assignment_id'] is int
          ? json['assignment_id']
          : int.tryParse(json['assignment_id']?.toString() ?? ''),
      isRead: json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_type': eventType.name,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'assignment_id': assignmentId,
    'is_read': isRead,
  };
}
