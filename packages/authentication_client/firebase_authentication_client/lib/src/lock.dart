enum _LockState { unlocked, locked }

/// A class which allows you to maintain a lock state
/// based on an asynchronous task.
class Lock {
  var _state = _LockState.unlocked;
  Future<dynamic>? _pendingRun;

  /// Whether or not the lock is currently locked.
  /// A lock is considered locked when a previous call to [run]
  /// is in progress.
  bool get isLocked => _state == _LockState.locked;

  /// Execute the [body] with a lock.
  /// If the lock instance is already locked, [run]
  /// will wait for the lock to be released before executing
  /// [body] with a new lock.
  Future<T> run<T>(Future<T> Function() body) async {
    if (isLocked && _pendingRun != null) await _pendingRun!;
    _state = _LockState.locked;
    _pendingRun = body();
    try {
      return await _pendingRun as T;
    } finally {
      _state = _LockState.unlocked;
    }
  }
}
