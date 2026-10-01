import BrightroomParametric

/// The direction of a quarter-turn rotation, as seen on screen.
public enum PhotosCropRotationDirection: Equatable, Sendable {
  case left
  case right
}

/// Editing commands and their availability, handed to a host-supplied
/// `SwiftUIPhotosCropView` toolbar menu.
///
/// A fresh value is built on every update of the editor, so the availability
/// flags always describe the current state.
@MainActor
public struct PhotosCropEditorActions {

  /// Whether there's an edit to undo.
  public let canUndo: Bool

  /// Whether there's an undone edit to redo.
  public let canRedo: Bool

  /// Whether rotating and mirroring are available, which they are while the
  /// crop tool is active.
  public let canTransform: Bool

  let onUndo: () -> Void
  let onRedo: () -> Void
  let onRotate: (PhotosCropRotationDirection) -> Void
  let onMirror: (MirrorAxis) -> Void
  let onCommitPendingEdits: () -> Void

  /// Undoes the most recent edit, including crop work not yet committed.
  public func undo() {
    onUndo()
  }

  /// Redoes the most recently undone edit.
  public func redo() {
    onRedo()
  }

  /// Turns the crop a quarter turn.
  public func rotate(_ direction: PhotosCropRotationDirection) {
    onRotate(direction)
  }

  /// Mirrors the image across an on-screen axis.
  public func mirror(_ axis: MirrorAxis) {
    onMirror(axis)
  }

  /// Writes the crop canvas's pending work into the editing stack and records
  /// an undo checkpoint, so the stack reflects exactly what's on screen.
  ///
  /// Call this before reading the stack's current edit, for example to show
  /// the output size.
  public func commitPendingEdits() {
    onCommitPendingEdits()
  }
}
