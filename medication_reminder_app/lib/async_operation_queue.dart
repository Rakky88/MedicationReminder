import 'dart:async';
import 'dart:collection';

/// Runs asynchronous operations one at a time while keeping failures isolated.
///
/// The queue itself never remains failed, so one unsuccessful operation cannot
/// prevent later persistence or reminder work from running.
class AsyncOperationQueue {
  final Queue<Future<void> Function()> _pending =
      Queue<Future<void> Function()>();
  bool _running = false;

  Future<T> run<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _pending.add(() async {
      try {
        result.complete(await operation());
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    _drain();
    return result.future;
  }

  void _drain() {
    if (_running || _pending.isEmpty) return;
    _running = true;
    Future<void>.sync(_pending.removeFirst()).whenComplete(() {
      _running = false;
      _drain();
    });
  }
}
