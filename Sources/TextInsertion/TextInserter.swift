import AppKit

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
    public init() {}

    public static func hasAccessibilityAccess() -> Bool {
        fatalError("unimplemented")
    }

    /// Prompts the system dialog once; returns the current state.
    public static func requestAccessibilityAccess() -> Bool {
        fatalError("unimplemented")
    }

    public func insert(_ text: String) async throws -> InsertionOutcome {
        fatalError("unimplemented")
    }
}
