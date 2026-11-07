/// What the dictation session is doing, as shown in the menu bar.
enum SessionState: Sendable, Equatable {
  case idle
  case listening
  case finalizing
  case inserting
  case failed(String)
}
