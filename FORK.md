# mzeeshanid/Brightroom fork

This fork carries a small patch stack on top of an upstream
[FluidGroup/Brightroom](https://github.com/FluidGroup/Brightroom) release for
MZFileManage. Keep the stack small and generic; app-specific UI belongs in the app.

## Branches and tags

| Ref | Contents |
| --- | --- |
| `main` | Exact mirror of upstream `main`. Never commit here; use **Sync fork**. |
| `mz/main` | The upstream release in use plus the patches below. |
| `<upstream>-mz.<n>` | Release tags of `mz/main`, e.g. `5.1.2-mz.1`. The app pins one exactly. |

## Patches

| Patch | Why | Upstream PR |
| --- | --- | --- |
| Add `MirrorFeature` and `Edit.mirror(_:)` | Flip horizontal/vertical as an undoable document node | — |
| Show the source mirror on the crop canvas | The canvas skips domain nodes, so it applies the mirror itself | — |
| Add `SwiftUICropView.ReloadAction` and `CropRotation.previous()` | Reload the canvas after undo/redo; rotate right | — |
| PhotosCrop toolbar menu and editor actions | Host menu replacing the Rotate button, with undo/redo, rotate and mirror | — |

## Updating to a new upstream release

```bash
git fetch upstream --tags
git switch mz/main
git rebase --onto <new> <old> mz/main     # e.g. --onto 5.1.3 5.1.2
# resolve conflicts, then run the tests:
xcodebuild test -scheme Brightroom-Package -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
git push --force-with-lease origin mz/main
git tag <new>-mz.1 && git push origin <new>-mz.1
```

Then update MZFileManage's exact Brightroom version to the new tag.
