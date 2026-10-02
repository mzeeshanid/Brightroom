# mzeeshanid/Brightroom fork

This fork carries a small patch stack on top of an upstream
[FluidGroup/Brightroom](https://github.com/FluidGroup/Brightroom) release for
[MZFileManage](#the-app-side). Keep the stack small and generic: add extension
points here, and keep app-specific UI and behaviour in the app.

## Where things are

| What | Where |
| --- | --- |
| Local clone | `~/Developer/Brightroom` |
| App project | `~/Downloads/MZFileManage` (`MZFileManage.xcodeproj`) |
| `origin` | `https://github.com/mzeeshanid/Brightroom.git` (fetch), `git@github.com:mzeeshanid/Brightroom.git` (push) |
| `upstream` | `https://github.com/FluidGroup/Brightroom.git` |

Push over SSH: HTTPS has no stored credentials and `gh` isn't installed. If the
clone is missing:

```bash
git clone https://github.com/mzeeshanid/Brightroom.git ~/Developer/Brightroom
cd ~/Developer/Brightroom
git remote set-url --push origin git@github.com:mzeeshanid/Brightroom.git
git remote add upstream https://github.com/FluidGroup/Brightroom.git
git fetch upstream --tags
git switch mz/main
```

## Branches and tags

| Ref | Contents |
| --- | --- |
| `main` | Exact mirror of upstream `main`. Never commit here; use **Sync fork** on GitHub. |
| `mz/main` | The upstream release in use plus the patches below. Rebased, so force-pushed. |
| `<upstream>-mz.<n>` | Release tags of `mz/main`, e.g. `5.1.2-mz.1`. The app pins one exactly. |

Old tags keep their commits reachable after a rebase, so never delete a tag an
app build may still resolve.

## Patches

Current base: **5.1.2**, released as **5.1.2-mz.2**. `git log 5.1.2..mz/main` lists them.

| Patch | Files | Why | Upstream PR |
| --- | --- | --- | --- |
| Add `MirrorFeature` and `Edit.mirror(_:)` | `BrightroomParametric/MirrorFeature.swift`, `BrightroomEngine/Core/EditingStack.Edit+Mirror.swift` | Flip horizontal/vertical as an undoable document node | — |
| Show the source mirror on the crop canvas | `BrightroomUI/Shared/Components/Crop/CropViewDocument.swift` | The canvas skips domain nodes, so it applies the mirror itself | — |
| Add `SwiftUICropView.ReloadAction` and `CropRotation.previous()` | `SwiftUICropView.swift`, `CropRotation.swift` | Reload the canvas after undo/redo/flip; rotate right | — |
| Test `MirrorFeature` | `Tests/BrightroomParametricTests/MirrorFeatureTests.swift` | — | — |
| Host toolbar menu for `SwiftUIPhotosCropView` | `builtin/PhotosCrop/PhotosCropEditorActions.swift` (new), `SwiftUIPhotosCropView.swift`, `PhotosCropContentView.swift`, `PhotosCropEditingModel.swift` | Ellipsis menu replacing the Rotate button, with undo/redo, rotate and mirror | — |
| Add `SourceFeatureType` and `PhotosCropEditorActions.applyEdit(_:)` | `BrightroomParametric/SourceFeature.swift` (new), `MirrorFeature.swift`, `EditingStack.Edit+Mirror.swift`, `CropViewDocument.swift`, `PhotosCropEditorActions.swift`, `PhotosCropContentView.swift`, `PhotosCropEditingModel.swift`, `Tests/BrightroomParametricTests/SourceFeatureTests.swift` | Host-defined source-domain features (the app's background removal) that the canvas shows and undo covers | — |
| This file | `FORK.md` | — | — |

## Design decisions to keep when resolving conflicts

- **Flip is a domain node, not an effect.** The canvas applies global effects to
  the *already cropped* preview, but export applies them *before* the crop, so a
  mirror effect would preview one thing and export another whenever the crop
  isn't centred. `MirrorFeature` is an extent-preserving `DomainFeatureType` kept
  at **index 0** of the main tree under `EditingFeatureTree.mirrorNodeID`, and is
  removed again once it mirrors along neither axis.
- **`Edit.mirror(_:)` maps the rest of the edit into the mirrored domain**: the
  crop rect is reflected, straighten is negated, and brush-mask stamps are
  reflected, up to and including the first crop. The result is the old output
  mirrored, rather than the same crop over mirrored pixels.
- **The canvas ignores domain nodes**, so `CropViewDocument.snapshot` applies the
  mirror to `editingSourceImage` itself. It caches the mirrored image per source
  and mirror state because `CropView.CanvasInputKey` keys on
  `ObjectIdentifier(editingSourceImage)`; a new `CIImage` every snapshot would
  force a re-render on every update.
- **`CropView` doesn't observe the stack while mounted** and only writes its crop
  on `ApplyAction`. So undo, redo and mirror in `PhotosCropContentView`:
  apply the pending crop → commit a checkpoint → change the stack → `ReloadAction`.
  Undo/redo also reset the aspect-ratio selection to freeform, or the locked ratio
  would refit the restored crop on the next update.
- **Rotate right goes through the `rotation` binding** (`previous()`), not a stack
  edit, so `CropView.setRotation` swaps a locked aspect ratio for sideways turns
  exactly as the built-in Rotate (`rotateAction`, which is `next()`) does.
  `next()` turns *left* on screen despite `rotateClockwise()`'s name.
- **Source features generalize the mirror's canvas patch.** `SourceFeatureType`
  marks an extent-preserving domain feature in oriented-source coordinates.
  `CropViewDocument.snapshot` applies every enabled one ahead of the first crop
  (`MainTree.applyingLeadingSourceFeatures`) to `editingSourceImage`, caching on
  source identity plus the features, so host features show on the canvas without
  the canvas knowing about them. Their `apply` must be scale-independent: the
  canvas evaluates them on the downsampled editing source, export on the full one.
- **The mirror goes after other leading source features**, not at index 0, so a
  host feature made from the unmirrored source (a subject mask) stays aligned
  when the image is flipped later.
- **`applyEdit(_:)` is the host's way to change the stack**: commit pending
  edits → mutate the current edit → commit a checkpoint → `ReloadAction`, the
  same sequence as mirror, so a host edit is one undo step. It works in every tool.
- **Mirroring while rotated sideways swaps the source axis**
  (`PhotosCropEditingModel.mirrorOutput`): the mirror applies before the crop's
  quarter turn.
- **Undo availability** includes crop work not yet applied: the canvas's
  `stateHandler` sets `hasUnappliedCropChanges` by comparing the proposed crop to
  the stack's final crop.
- **Rotate and mirror are crop-tool only** (`PhotosCropEditorActions.canTransform`),
  matching the built-in Rotate button. Undo/redo work in every tool.
- **The original `SwiftUIPhotosCropView` initializer is unchanged**; the menu is
  opt-in through the `toolbarMenu:` initializer.

## Known limitations

- Reset restores the crop but not the mirror; Undo removes a mirror.
- Features after the first crop aren't mapped by `Edit.mirror(_:)` (PhotosCrop has one crop).
- Filter preset thumbnails are rendered from the unmirrored source, without
  source features.

## Building and testing

- Tests run through the **`Brightroom-Package`** scheme; the per-target schemes have no test action.
- Command-line builds of the app need `-skipPackagePluginValidation -skipMacroValidation`.
  In Xcode, every new Brightroom revision disables the `BuildColorAdjustmentKernels`
  plugin until a person chooses **Trust & Enable**; an agent can't do that, so ask.

```bash
cd ~/Developer/Brightroom
xcodebuild test -scheme Brightroom-Package -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

## Updating to a new upstream release

```bash
cd ~/Developer/Brightroom
git fetch upstream --tags
git switch mz/main
git rebase --onto <new> <old> mz/main     # e.g. --onto 5.1.3 5.1.2
# Resolve conflicts using the design decisions above, then run the tests.
git push --force-with-lease origin mz/main
git tag -a <new>-mz.1 -m "Upstream <new> plus MZFileManage patches"
git push origin <new>-mz.1
```

Then update the app ([below](#updating-the-app-pin)), build it, and run the
[smoke test](#smoke-test). Update the patch table and "Current base" here.

## The app side

App code that depends on this fork's API, which must change if the API does:

- `MZFileManage/Features/ImageEditor/ImageEditorView.swift`: uses the
  `toolbarMenu:` initializer, `PhotosCropEditorActions` (`undo`, `redo`, `rotate`,
  `mirror`, `commitPendingEdits`, `applyEdit`, `canUndo`, `canRedo`, `canTransform`),
  `MirrorAxis`, and `EditingStack.featureTree?.finalCrop` for the output size.
- `BackgroundRemovalFeature.swift`: a `SourceFeatureType` holding a Vision subject
  mask made from `loadedState.editingSourceImage`, inserted at index 0 through
  `applyEdit`. Export switches JPEG to PNG while it's in the edit.
- `AdjustSizeView.swift` and `ImageSizeAdjustment.swift` are app-only; Adjust Size
  is applied after Brightroom renders and isn't part of Brightroom's undo.

### Updating the app pin

Change both files, then build:

1. `MZFileManage.xcodeproj/project.pbxproj`, in the
   `XCRemoteSwiftPackageReference "Brightroom"` block:
   `kind = exactVersion;` and `version = "<new>-mz.1";`.
   Xcode rewrites this file's formatting (it drops quotes it doesn't need), so
   read the block before editing instead of matching remembered text.
2. `MZFileManage.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`,
   the `brightroom` pin: `"revision"` = `git rev-parse <new>-mz.1^{commit}`,
   `"version"` = `"<new>-mz.1"`, `"location"` = the fork URL.

### Smoke test

In the editor (Files → an image → Edit), in the Crop tool:

1. Drag the crop, then Undo: the crop returns; Redo brings it back.
2. Lock an aspect ratio, Rotate Left and Rotate Right: the ratio swaps on each turn.
3. Rotate 90°, then Flip Horizontal: the image mirrors left–right on screen.
4. Paint a blur mask, then Flip: the blur stays on the same subject.
5. Adjust Size to half the width, Done, and check the saved image's size and that it
   matches the preview, including the flip.
6. Remove Background: the canvas shows the cut-out; Flip keeps it aligned; Undo brings
   the background back and Redo removes it again; Done saves a transparent PNG.
