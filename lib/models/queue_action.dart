class QueueAction {
  String id;
  String type;
  Map<String, dynamic> data;
  int retryCount;

  QueueAction({
    required this.id,
    required this.type,
    required this.data,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'retryCount': retryCount,
    };
  }
}