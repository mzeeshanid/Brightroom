import CoreImage

/// A domain feature that works in the oriented source's own coordinates and
/// keeps its input's extent, such as a mirror or a host-supplied mask.
///
/// Source features sit at the front of the main tree, ahead of the first crop.
/// Canvases that draw from a downsampled editing source apply them to that
/// source themselves, so preview and export agree. `apply` therefore has to
/// work on the source at any scale: derive geometry from the input's extent
/// rather than from fixed pixel coordinates.
public protocol SourceFeatureType: DomainFeatureType {}

extension MainTree {

  /// The enabled source features ahead of the first crop, in evaluation order.
  public var leadingSourceFeatures: [any SourceFeatureType] {
    var result: [any SourceFeatureType] = []
    for feature in features {
      guard case let .domain(domain) = feature else {
        continue
      }
      if domain is CropFeature {
        break
      }
      if let source = domain as? any SourceFeatureType, source.isEnabled {
        result.append(source)
      }
    }
    return result
  }

  /// `image` with the leading source features applied, as a canvas would show
  /// it. A feature that fails to evaluate is skipped.
  public func applyingLeadingSourceFeatures(
    to image: CIImage,
    context: FeatureEvaluationContext = .init()
  ) -> CIImage {
    leadingSourceFeatures.reduce(image) { image, feature in
      (try? feature.apply(to: image, context: context)) ?? image
    }
  }
}
