/// What `TextInserter.insert(_:)` did with the text.
public enum InsertionOutcome: Sendable, Equatable {
  /// Text was pasted into the frontmost app and the previous clipboard
  /// contents were (or will shortly be) restored.
  case pasted
  /// ⌘V was sent but no app read the text before the receipt timeout, so the
  /// paste most likely landed nowhere. The clipboard is restored as usual.
  case unread
  /// Secure input was active (password field, Terminal "Secure Keyboard
  /// Entry"). Nothing was inserted and the clipboard was left untouched.
  case blockedBySecureInput
}
