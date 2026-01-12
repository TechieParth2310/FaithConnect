import 'package:faith_connect/models/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NotificationModel maps body and isRead with fallbacks', () {
    final model = NotificationModel.fromMap({
      'id': 'n1',
      'userId': 'u1',
      'actorId': 'a1',
      'actorName': 'Alice',
      'type': 'newMessage',
      'title': 'New message',
      // Back-compat: older docs may use `message`
      'message': 'hi',
      'createdAt': DateTime(2025, 1, 1).toIso8601String(),
      // missing isRead should default false
    });

    expect(model.body, 'hi');
    expect(model.isRead, isFalse);
  });
}
