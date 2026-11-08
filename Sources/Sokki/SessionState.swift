/// What the dictation session is doing, as shown in the menu bar.
enum SessionState: Sendable, Equatable {
  case idle
  /// Recording. `locked` is the hands-free mode entered by double-tapping the
  /// hotkey: recording continues after the key is up until the next tap.
  case listening(locked: Bool)
  case finalizing
  case inserting
  case failed(String)

  var isListening: Bool {
    if case .listening = self { return true }
    return false
  }

  var isFailed: Bool {
    if case .failed = self { return true }
    return false
  }
}
