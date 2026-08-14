import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/async_operation_queue.dart';

void main() {
  test('operations run in order', () async {
    final queue = AsyncOperationQueue();
    final firstMayFinish = Completer<void>();
    final events = <String>[];

    final first = queue.run(() async {
      events.add('first-start');
      await firstMayFinish.future;
      events.add('first-end');
    });
    final second = queue.run(() async {
      events.add('second');
    });

    await Future<void>.delayed(Duration.zero);
    expect(events, <String>['first-start']);
    firstMayFinish.complete();
    await Future.wait(<Future<void>>[first, second]);
    expect(events, <String>['first-start', 'first-end', 'second']);
  });

  test('a failed operation does not block the next operation', () async {
    final queue = AsyncOperationQueue();

    final failed = queue.run<void>(() async => throw StateError('failed'));
    final next = queue.run<int>(() async => 42);

    await expectLater(failed, throwsStateError);
    await expectLater(next, completion(42));
  });
}
