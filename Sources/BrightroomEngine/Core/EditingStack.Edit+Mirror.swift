import CoreGraphics

import BrightroomParametric

extension EditingFeatureTree {

  /// The identity of the source mirror node, when the edit mirrors its source.
  public static let mirrorNodeID = FeatureID(
    rawValue: "brightroom.editing-stack.mirror"
  )

  /// The source mirror node, if the edit mirrors its source.
  public var mirror: MirrorFeature? {
    guard case let .domain(domain)? = node(id: Self.mirrorNodeID) else {
      return nil
    }
    return domain as? MirrorFeature
  }
}

extension EditingStack.Edit {

  /// Mirrors the oriented source across `axis`, carrying the crop and the
  /// local-adjustment masks with it so the output is the previous output
  /// mirrored, rather than the same crop rectangle over mirrored pixels.
  ///
  /// The mirror is a single domain node at the front of the main tree, removed
  /// again once it mirrors along neither axis. Features up to and including the
  /// first crop are mapped into the mirrored domain; features after that crop
  /// live in its output domain and are left as they are.
  public mutating func mirror(_ axis: MirrorAxis) {
    let domainSize = imageSize

    var mirror = EditingFeatureTree(edit: self).mirror
      ?? MirrorFeature(id: EditingFeatureTree.mirrorNodeID)
    mirror.toggle(axis)

    var hasPassedCrop = false
    var features = self.features.compactMap { feature -> MainFeature? in
      guard feature.id != EditingFeatureTree.mirrorNodeID else {
        return nil
      }
      guard hasPassedCrop == false else {
        return feature
      }

      switch feature {
      case .domain(let domain):
        guard var crop = domain as? CropFeature else {
          return feature
        }
        hasPassedCrop = true
        crop.cropRect = crop.cropRect.mirrored(across: axis, in: domainSize)
        // A mirror reverses the sense of rotation about the crop centre.
        crop.straightenRadians = -crop.straightenRadians
        return .domain(crop)

      case .localAdjustment(var adjustment):
        adjustment.maskTree = MaskTree(
          root: adjustment.maskTree.root.mirroringStamps(across: axis, in: domainSize)
        )
        return .localAdjustment(adjustment)

      case .effect:
        return feature
      }
    }

    if mirror.isIdentity == false {
      features.insert(.domain(mirror), at: 0)
    }
    replaceFeatures(features)
  }
}

extension CGRect {

  /// This rectangle reflected across the centre line of a domain of `size`.
  ///
  /// The reflection is symmetric, so it holds for y-up and y-down rectangles.
  fileprivate func mirrored(across axis: MirrorAxis, in size: CGSize) -> CGRect {
    var rect = self
    switch axis {
    case .horizontal:
      rect.origin.x = size.width - maxX
    case .vertical:
      rect.origin.y = size.height - maxY
    }
    return rect
  }
}

extension MaskNode {

  /// Reflects brush-stroke stamps across the centre line of a domain of `size`.
  /// Composite and refinement nodes carry no coordinates, so only their brush
  /// leaves change.
  fileprivate func mirroringStamps(across axis: MirrorAxis, in size: CGSize) -> MaskNode {
    switch self {
    case .brush(var mask):
      mask.strokes = mask.strokes.map { stroke in
        var mirrored = stroke
        mirrored.stamps = stroke.stamps.map { point in
          switch axis {
          case .horizontal: CGPoint(x: size.width - point.x, y: point.y)
          case .vertical: CGPoint(x: point.x, y: size.height - point.y)
          }
        }
        return mirrored
      }
      return .brush(mask)

    case .invert(let node):
      return .invert(node.mirroringStamps(across: axis, in: size))

    case .feather(var feather):
      feather.input = feather.input.mirroringStamps(across: axis, in: size)
      return .feather(feather)

    case .union(let nodes):
      return .union(nodes.map { $0.mirroringStamps(across: axis, in: size) })

    case .intersect(let nodes):
      return .intersect(nodes.map { $0.mirroringStamps(across: axis, in: size) })

    case .subtract(var subtract):
      subtract.base = subtract.base.mirroringStamps(across: axis, in: size)
      subtract.removing = subtract.removing.mirroringStamps(across: axis, in: size)
      return .subtract(subtract)
    }
  }
}
