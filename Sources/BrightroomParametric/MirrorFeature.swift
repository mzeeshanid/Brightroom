import CoreGraphics
import CoreImage

/// An axis an image can be mirrored across.
public enum MirrorAxis: Equatable, Sendable, CaseIterable {

  /// Mirrors left and right.
  case horizontal

  /// Mirrors top and bottom.
  case vertical
}

/// Mirrors the current image domain in place.
///
/// The output keeps the input's extent, so features after this one keep
/// addressing the same coordinate space: only the pixels under it move.
public struct MirrorFeature: SourceFeatureType, Codable {

  /// The stable identity of this mirror.
  public var id: FeatureID

  /// A Boolean value indicating whether this mirror participates in rendering.
  public var isEnabled: Bool

  /// Whether the image is mirrored left to right.
  public var isMirroredHorizontally: Bool

  /// Whether the image is mirrored top to bottom.
  public var isMirroredVertically: Bool

  /// Creates a mirror feature.
  public init(
    id: FeatureID = .init(),
    isEnabled: Bool = true,
    isMirroredHorizontally: Bool = false,
    isMirroredVertically: Bool = false
  ) {
    self.id = id
    self.isEnabled = isEnabled
    self.isMirroredHorizontally = isMirroredHorizontally
    self.isMirroredVertically = isMirroredVertically
  }

  /// Whether the feature mirrors along neither axis.
  public var isIdentity: Bool {
    isMirroredHorizontally == false && isMirroredVertically == false
  }

  /// Whether the feature mirrors across `axis`.
  public func isMirrored(_ axis: MirrorAxis) -> Bool {
    switch axis {
    case .horizontal: isMirroredHorizontally
    case .vertical: isMirroredVertically
    }
  }

  /// Flips the mirror state across `axis`.
  public mutating func toggle(_ axis: MirrorAxis) {
    switch axis {
    case .horizontal: isMirroredHorizontally.toggle()
    case .vertical: isMirroredVertically.toggle()
    }
  }

  /// The transform that mirrors `extent` onto itself.
  public func transform(in extent: CGRect) -> CGAffineTransform {
    CGAffineTransform(
      a: isMirroredHorizontally ? -1 : 1,
      b: 0,
      c: 0,
      d: isMirroredVertically ? -1 : 1,
      tx: isMirroredHorizontally ? extent.minX + extent.maxX : 0,
      ty: isMirroredVertically ? extent.minY + extent.maxY : 0
    )
  }

  public func apply(to image: CIImage, context: FeatureEvaluationContext) throws -> CIImage {
    let extent = image.extent
    guard isIdentity == false, extent.isInfinite == false, extent.isEmpty == false else {
      return image
    }
    return image.transformed(by: transform(in: extent)).cropped(to: extent)
  }
}
