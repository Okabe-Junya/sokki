import AppKit
import ApplicationServices

/// Inserts text at the caret of the frontmost application.
///
/// v1 uses clipboard paste only: save every pasteboard item → write the text
/// as a promise with transient / concealed markers → post ⌘V → treat the
/// target's read of the promise as a receipt → restore the saved items once
/// the receipt arrives (or after a bounded fallback delay) and nobody else has
/// changed the pasteboard in between.
public actor TextInserter {
  private enum PasteResult: Sendable {
    case pasted(PasteSession, postedAt: ContinuousClock.Instant)
    case blocked
  }

  // Tail of the insert chain; each insert waits for the previous restoration.
  private var tail: Task<Void, Never>?

  /// Creates an inserter with no paste in flight.
  public init() {}

  /// Whether the user has granted Accessibility access.
  public static func hasAccessibilityAccess() -> Bool {
    AXIsProcessTrusted()
  }

  /// Prompts the system dialog once; returns the current state.
  public static func requestAccessibilityAccess() -> Bool {
    // Literal value of kAXTrustedCheckOptionPrompt; the C global is not concurrency-safe in Swift 6.
    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
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

  /// Pastes `text` at the caret, waiting for any earlier insert's clipboard restore first.
  /// Returns once the target has read the text, or after the receipt timeout.
  public func insert(_ text: String) async throws -> InsertionOutcome {
    let previous = tail
    let paste = Task { () async throws -> PasteResult in
      await previous?.value
      return try await Self.paste(text)
    }
    let receipt = Task { () async -> Bool in
      guard case .pasted(let session, let postedAt)? = try? await paste.value else { return false }
      return await session.waitForReceipt(postedAt: postedAt)
    }
    tail = Task {
      guard case .pasted(let session, _)? = try? await paste.value else { return }
      await session.finish(afterReceipt: await receipt.value)
    }
    switch try await paste.value {
    case .pasted: return await receipt.value ? .pasted : .unread
    case .blocked: return .blockedBySecureInput
    }
  }
}
