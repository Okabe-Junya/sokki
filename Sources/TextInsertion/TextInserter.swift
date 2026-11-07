import AppKit
import ApplicationServices

public enum InsertionOutcome: Sendable, Equatable {
  /// Text was pasted into the frontmost app and the previous clipboard
  /// contents were (or will shortly be) restored.
  case pasted
  /// Secure input was active (password field, Terminal "Secure Keyboard
  /// Entry"). Nothing was inserted and the clipboard was left untouched.
  case blockedBySecureInput
}

public enum InsertionError: Error, Sendable {
  case accessibilityDenied
  case modifierStillHeld
  case eventPostFailed
}

/// Inserts text at the caret of the frontmost application.
///
/// v1 uses clipboard paste only: save every pasteboard item → write the text
/// as a promise with transient / concealed markers → post ⌘V → treat the
/// target's read of the promise as a receipt → restore the saved items once
/// the receipt arrives (or after a bounded fallback delay) and nobody else has
/// changed the pasteboard in between.
public actor TextInserter {
  // Tail of the insert chain; each insert waits for the previous restoration.
  private var tail: Task<Void, Never>?

  public init() {}

  public static func hasAccessibilityAccess() -> Bool {
    AXIsProcessTrusted()
  }

  /// Prompts the system dialog once; returns the current state.
  public static func requestAccessibilityAccess() -> Bool {
    // Literal value of kAXTrustedCheckOptionPrompt; the C global is not concurrency-safe in Swift 6.
    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
  }

  public func insert(_ text: String) async throws -> InsertionOutcome {
    let previous = tail
    let paste = Task { () async throws -> PasteResult in
      await previous?.value
      return try await Self.paste(text)
    }
    tail = Task {
      guard case .pasted(let session, let postedAt)? = try? await paste.value else { return }
      await session.finish(postedAt: postedAt)
    }
    switch try await paste.value {
    case .pasted: return .pasted
    case .blocked: return .blockedBySecureInput
    }
  }

  private enum PasteResult: Sendable {
    case pasted(PasteSession, postedAt: ContinuousClock.Instant)
    case blocked
  }

  private static func paste(_ text: String) async throws -> PasteResult {
    if SecureInput.isActive() { return .blocked }
    guard AXIsProcessTrusted() else { throw InsertionError.accessibilityDenied }

    let session = await MainActor.run { PasteSession(text: text, pasteboard: .general) }
    do {
      try await KeyEvents.waitForModifierRelease()
      return .pasted(session, postedAt: try await KeyEvents.postCommandV())
    } catch {
      await session.restoreIfUnchanged()
      throw error
    }
  }
}
