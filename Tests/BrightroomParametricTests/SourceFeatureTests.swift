import CoreImage
import Foundation
import Testing

@testable import BrightroomParametric

struct SourceFeatureTests {

  /// A source feature that makes its input transparent, keeping the extent.
  private struct ClearFeature: SourceFeatureType {
    var id = FeatureID()
    var isEnabled = true

    func apply(to image: CIImage, context: FeatureEvaluationContext) throws -> CIImage {
      CIImage(color: .clear).cropped(to: image.extent)
    }
  }

  private static let crop = CropFeature(cropRect: CGRect(x: 0, y: 0, width: 1, height: 1))

  @Test func `leading source features stop at the first crop`() {
    let first = ClearFeature()
    let afterCrop = ClearFeature()
    let tree = MainTree(features: [
      .domain(first),
      .domain(MirrorFeature(isMirroredHorizontally: true)),
      .domain(Self.crop),
      .domain(afterCrop),
    ])

    let ids = tree.leadingSourceFeatures.map(\.id)
    #expect(ids.count == 2)
    #expect(ids.first == first.id)
    #expect(ids.contains(afterCrop.id) == false)
  }

  @Test func `disabled source features are skipped`() {
    let tree = MainTree(features: [.domain(ClearFeature(isEnabled: false))])
    #expect(tree.leadingSourceFeatures.isEmpty)
  }

  @Test func `applying leading source features keeps the extent`() {
    let input = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 4, height: 3))
    let tree = MainTree(features: [.domain(ClearFeature())])
    let output = tree.applyingLeadingSourceFeatures(to: input)
    #expect(output.extent == input.extent)
  }
}
