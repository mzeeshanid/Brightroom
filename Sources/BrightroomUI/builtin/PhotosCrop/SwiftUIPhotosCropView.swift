//
// Copyright (c) 2021 Hiroshi Kimura(Muukii) <muukii.app@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import SwiftUI

import BrightroomEngine
import BrightroomParametric

/**
 Apple's Photos app like crop view.
 
 You might use `SwiftUICropView` to create a fully customized user interface.
 */
@available(iOS 14, *)
public struct SwiftUIPhotosCropView: View {

  public struct LocalizedStrings {
    public var button_done_title: String = "Done"
    public var button_cancel_title: String = "Cancel"
    public var button_reset_title: String = "Reset"
    public var button_aspectratio_original: String = "ORIGINAL"
    public var button_aspectratio_freeform: String = "FREEFORM"
    public var button_aspectratio_square: String = "SQUARE"
    public var button_filter_original: String = "ORIGINAL"
    // Used by the `toolbarMenu:` layout's built-in controls.
    public var button_undo_title: String = "Undo"
    public var button_redo_title: String = "Redo"
    public var button_rotate_title: String = "Rotate"
    public var button_rotate_left_title: String = "Rotate Left"
    public var button_rotate_right_title: String = "Rotate Right"
    public var button_flip_title: String = "Flip"
    public var button_flip_horizontal_title: String = "Flip Horizontal"
    public var button_flip_vertical_title: String = "Flip Vertical"

    public init() {}
  }

  public struct Options: Equatable {

    public enum AspectRatioOptions: Equatable {
      case selectable
      case fixed(PixelAspectRatio?)
    }

    public var aspectRatioOptions: AspectRatioOptions = .selectable

    /// The presets offered by the Filters mode. Presets write into the
    /// FeatureTree's global-effects node. Pass an empty array to offer no
    /// presets.
    public var filterPresets: [PresetFeature] = PhotosCropDefaultFilterPresets.make()

    public init() {

    }
  }

  private let editingModel: PhotosCropEditingModel
  private let options: Options
  private let localizedStrings: LocalizedStrings
  private let onDone: @MainActor () -> Void
  private let onCancel: @MainActor () -> Void
  private let toolbarMenu: (@MainActor (PhotosCropEditorActions) -> AnyView)?

  public init(
    editingModel: PhotosCropEditingModel,
    options: Options = .init(),
    localizedStrings: LocalizedStrings = .init(),
    onDone: @escaping @MainActor () -> Void,
    onCancel: @escaping @MainActor () -> Void
  ) {
    self.editingModel = editingModel
    self.options = options
    self.localizedStrings = localizedStrings
    self.onDone = onDone
    self.onCancel = onCancel
    self.toolbarMenu = nil
  }

  /// Creates the editor with a host-supplied toolbar menu.
  ///
  /// The menu replaces the Rotate button with an ellipsis button. Its content
  /// receives `PhotosCropEditorActions` for undo, redo, rotating and mirroring,
  /// and may add items of its own.
  ///
  /// This layout also shows Cancel and Done as icons, Undo and Redo buttons
  /// between Cancel and the ellipsis, and Rotate and Flip menus either side of
  /// the crop tool's straighten slider.
  public init<MenuContent: View>(
    editingModel: PhotosCropEditingModel,
    options: Options = .init(),
    localizedStrings: LocalizedStrings = .init(),
    @ViewBuilder toolbarMenu: @escaping @MainActor (PhotosCropEditorActions) -> MenuContent,
    onDone: @escaping @MainActor () -> Void,
    onCancel: @escaping @MainActor () -> Void
  ) {
    self.editingModel = editingModel
    self.options = options
    self.localizedStrings = localizedStrings
    self.onDone = onDone
    self.onCancel = onCancel
    self.toolbarMenu = { AnyView(toolbarMenu($0)) }
  }

  public var body: some View {
    PhotosCropContentView(
      editingModel: editingModel,
      options: options,
      localizedStrings: localizedStrings,
      toolbarMenu: toolbarMenu,
      onDone: onDone,
      onCancel: onCancel
    )
  }
}

#Preview {
  Text("h")
}
