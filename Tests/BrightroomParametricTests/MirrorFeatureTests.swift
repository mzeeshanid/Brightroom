import CoreImage
import Foundation
import Testing

@testable import BrightroomParametric

struct MirrorFeatureTests {

  private static let context = CIContext()

  /// A 2×1 image: red on the left, blue on the right.
  private static func redBlue() -> CIImage {
    let red = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let blue = CIImage(color: .blue).cropped(to: CGRect(x: 1, y: 0, width: 1, height: 1))
    return blue.composited(over: red)
  }

  private static func pixel(_ image: CIImage, x: Int, y: Int) -> (red: UInt8, blue: UInt8) {
    var bytes = [UInt8](repeating: 0, count: 4)
    context.render(
      image,
      toBitmap: &bytes,
      rowBytes: 4,
      bounds: CGRect(x: x, y: y, width: 1, height: 1),
      format: .RGBA8,
      colorSpace: nil
    )
    return (bytes[0], bytes[2])
  }

  @Test func `horizontal mirror swaps left and right and keeps the extent`() throws {
    let input = Self.redBlue()
    let output = try MirrorFeature(isMirroredHorizontally: true)
      .apply(to: input, context: FeatureEvaluationContext())

    #expect(output.extent == input.extent)
    #expect(Self.pixel(output, x: 0, y: 0).blue == 255)
    #expect(Self.pixel(output, x: 1, y: 0).red == 255)
  }

  @Test func `identity mirror returns the input unchanged`() throws {
    let input = Self.redBlue()
    let output = try MirrorFeature().apply(to: input, context: FeatureEvaluationContext())

    #expect(output === input)
  }

  @Test func `toggling an axis twice restores identity`() {
    var mirror = MirrorFeature()
    mirror.toggle(.vertical)
    #expect(mirror.isMirrored(.vertical))
    #expect(mirror.isIdentity == false)

    mirror.toggle(.vertical)
    #expect(mirror.isIdentity)
  }

  @Test func `transform maps an offset extent onto itself`() {
    let extent = CGRect(x: 10, y: 20, width: 100, height: 50)
    let transform = MirrorFeature(isMirroredHorizontally: true, isMirroredVertically: true)
      .transform(in: extent)

    #expect(extent.applying(transform) == extent)
    #expect(CGPoint(x: 10, y: 20).applying(transform) == CGPoint(x: 110, y: 70))
  }
}
