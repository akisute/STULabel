// Copyright 2018 Stephan Tolksdorf

import STULabel.DynamicTypeFontScaling

import XCTest

@available(iOS 10, tvOS 10, *)
private class LabelWithOverridePreferredContentSizeCategory: UILabel {
  var preferredContentSizeCategory: UIContentSizeCategory = .unspecified {
    didSet {
      traitCollectionDidChange(UITraitCollection(traitsFrom: [
        super.traitCollection, UITraitCollection(preferredContentSizeCategory: oldValue)
      ]))
    }
  }

  override var traitCollection: UITraitCollection {
    return UITraitCollection(traitsFrom: [
             super.traitCollection,
             UITraitCollection(preferredContentSizeCategory: preferredContentSizeCategory)
           ])
  }
}

class DynamicTypeFontScalingTests: XCTestCase {

  func testAdjustedFontForContentSizeCategory() { if #available(iOS 10, tvOS 10, *) {
    let fixedFont = UIFont.systemFont(ofSize: 16)

    XCTAssertEqual(fixedFont, fixedFont.stu_fontAdjusted(forContentSizeCategory: .extraLarge))
    // The second call tests a different code path.
    XCTAssertEqual(fixedFont, fixedFont.stu_fontAdjusted(forContentSizeCategory: .extraLarge))

    XCTAssertEqual(fixedFont, fixedFont.stu_fontAdjusted(forContentSizeCategory:
                                                 UIContentSizeCategory(rawValue: "doesn't exist")))

    let preferredFont = UIFont.preferredFont(
                          forTextStyle: .caption2,
                          compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
    let label = LabelWithOverridePreferredContentSizeCategory()
    label.adjustsFontForContentSizeCategory = true
    label.preferredContentSizeCategory = .large
    label.font = preferredFont
    label.preferredContentSizeCategory = .extraExtraLarge
    XCTAssertNotEqual(label.font, preferredFont)
    XCTAssertEqual(label.font, preferredFont.stu_fontAdjusted(forContentSizeCategory: .extraExtraLarge))
    XCTAssertEqual(label.font, preferredFont.stu_fontAdjusted(forContentSizeCategory: .extraExtraLarge))
    label.preferredContentSizeCategory = .extraSmall
    XCTAssertEqual(label.font, preferredFont.stu_fontAdjusted(forContentSizeCategory: .extraSmall))

    // If a preferred font's size is changed after it is created, the new font is not scalable
    // on iOS < 12 and the new size is ignored when the font is scaled on iOS 12:
    let preferredFont2 = UIFont.preferredFont(
                          forTextStyle: .body,
                          compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
    let preferredFont3 = preferredFont2.withSize(32)
    label.preferredContentSizeCategory = .large
    label.font = preferredFont3
    label.preferredContentSizeCategory = .extraSmall
    XCTAssertEqual(label.font, preferredFont3.stu_fontAdjusted(forContentSizeCategory: .extraSmall))

    if #available(iOS 12, tvOS 12, *) {
      XCTAssertNotEqual(label.font, preferredFont3)
      XCTAssertEqual(label.font, preferredFont2.stu_fontAdjusted(forContentSizeCategory: .extraSmall))
      label.preferredContentSizeCategory = .large
      XCTAssertEqual(label.font, preferredFont2)
    } else {
      label.preferredContentSizeCategory = .large
      XCTAssertEqual(label.font, preferredFont3)
    }

    // UILabel doesn't scale preferred fonts with a changed symbolic trait...
    let italicPreferredFont = UIFont(descriptor: preferredFont2.fontDescriptor
                                                 .withSymbolicTraits([.traitItalic])!,
                                     size: preferredFont2.pointSize)
    label.font = italicPreferredFont
    label.preferredContentSizeCategory = .extraSmall
    XCTAssertEqual(label.font, italicPreferredFont)
    // ..but we do (when the changed trait is fully encoded into the font's textStyle).
    XCTAssertEqual(italicPreferredFont.stu_fontAdjusted(forContentSizeCategory: .extraSmall),
                   UIFont.preferredFont(forTextStyle: italicPreferredFont.fontDescriptor
                                                      .object(forKey: .textStyle)
                                                      as! UIFont.TextStyle,
                                        compatibleWith: UITraitCollection(
                                                          preferredContentSizeCategory: .extraSmall)))

    if #available(iOS 11, tvOS 11, *) {
      let scaledPreferredFont =
          UIFontMetrics(forTextStyle: .body)
          .scaledFont(for: preferredFont2, maximumPointSize: 25,
                      compatibleWith: UITraitCollection(preferredContentSizeCategory: .extraSmall))

      label.preferredContentSizeCategory = .extraSmall
      label.font = scaledPreferredFont
      label.preferredContentSizeCategory = .large
      XCTAssertEqual(label.font, preferredFont2)
      XCTAssertEqual(preferredFont2, scaledPreferredFont.stu_fontAdjusted(forContentSizeCategory: .large))
      label.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
      XCTAssertEqual(label.font.pointSize, 25)
      XCTAssertEqual(label.font,
                     scaledPreferredFont.stu_fontAdjusted(forContentSizeCategory: .large)
                                        .stu_fontAdjusted(forContentSizeCategory:
                                                            .accessibilityExtraExtraExtraLarge))

      label.preferredContentSizeCategory = .large
      
      let helvetica = UIFont(name: "HelveticaNeue", size: 20)!
      let scaledHelvetica = UIFontMetrics(forTextStyle: .headline)
                            .scaledFont(for: helvetica,
                                        compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
      XCTAssertEqual(scaledHelvetica.pointSize, 20)
      label.font = scaledHelvetica

      label.font = scaledHelvetica
      label.preferredContentSizeCategory = .extraExtraLarge
      XCTAssertNotEqual(label.font, scaledHelvetica)
      XCTAssertEqual(label.font, scaledHelvetica.stu_fontAdjusted(forContentSizeCategory: .extraExtraLarge))
      XCTAssertEqual(label.font, scaledHelvetica.stu_fontAdjusted(forContentSizeCategory: .extraExtraLarge))

      label.preferredContentSizeCategory = .large

      let scaledHelvetica2 = UIFontMetrics(forTextStyle: .headline)
                             .scaledFont(for: helvetica, maximumPointSize: 22,
                                         compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
      XCTAssertEqual(scaledHelvetica2.pointSize, 20)

      // UIFont isEqual doesn't compare the text style and maximum point size
      // (which is problematic), but UILabel uses it to optimize invalidation when assigning to the
      // font property (which is arguably a bug), so we set the font first to some unequal value.
      label.font = fixedFont;
      label.font = scaledHelvetica2
      label.preferredContentSizeCategory = .extraExtraExtraLarge
      XCTAssertNotEqual(label.font, scaledHelvetica2)
      XCTAssertEqual(label.font.pointSize, 22)
      XCTAssertEqual(label.font, scaledHelvetica2.stu_fontAdjusted(forContentSizeCategory: .extraExtraExtraLarge))
      XCTAssertEqual(label.font, scaledHelvetica2.stu_fontAdjusted(forContentSizeCategory: .extraExtraExtraLarge))

      label.preferredContentSizeCategory = .small
      label.font = fixedFont
      label.font = scaledHelvetica
      label.preferredContentSizeCategory = .extraExtraLarge
      XCTAssertNotEqual(label.font, scaledHelvetica)
      XCTAssertEqual(label.font, scaledHelvetica.stu_fontAdjusted(forContentSizeCategory: .extraExtraLarge))
      label.font = nil
    }
  } }

  func testAttributedStringFontAdjustmentForContentSizeCategory() { if #available(iOS 10, tvOS 10, *) {
    let category: UIContentSizeCategory = .extraSmall
    let traitCollection = UITraitCollection(preferredContentSizeCategory: category)
    let font1 = UIFont.preferredFont(forTextStyle: .body)
    let scaledFont1 = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
    let font2 = UIFont.preferredFont(forTextStyle: .title1)
    let scaledFont2 = UIFont.preferredFont(forTextStyle: .title1, compatibleWith: traitCollection)
    let fixedFont = UIFont.systemFont(ofSize: 16)

    let string1 = NSAttributedString()
    XCTAssert(string1 === string1.stu_copyWithFontsAdjusted(forContentSizeCategory: category))
    let string2 = NSAttributedString(string: "test")
    XCTAssert(string2 === string2.stu_copyWithFontsAdjusted(forContentSizeCategory: category))
    let string3 = NSAttributedString(string: "test", attributes:[.font: fixedFont])
    XCTAssert(string3 === string3.stu_copyWithFontsAdjusted(forContentSizeCategory: category))

    XCTAssertEqual(NSAttributedString(string: "Test", attributes: [.font: font1])
                   .stu_copyWithFontsAdjusted(forContentSizeCategory: category),
                   NSAttributedString(string: "Test", attributes: [.font: scaledFont1]))

    let string = NSMutableAttributedString()
    XCTAssert(string !== string.stu_copyWithFontsAdjusted(forContentSizeCategory: category))
    string.stu_adjustFonts(in: NSRange(), forContentSizeCategory: category)

    string.append(NSAttributedString(string: "a", attributes:[.font: fixedFont]))
    string.append(NSAttributedString(string: "b", attributes:[.font: fixedFont,
                                                              .foregroundColor: UIColor.red]))
    let string4 = string.copy() as! NSAttributedString
    XCTAssert(string4 === string4.stu_copyWithFontsAdjusted(forContentSizeCategory: category))
    string.stu_adjustFonts(in: NSRange(0..<string.length), forContentSizeCategory: category)
    XCTAssertEqual(string, string4)

    string.append(NSAttributedString(string: "c", attributes:[.font: font1]))
    string.append(NSAttributedString(string: "d", attributes:[.font: font2]))
    string.append(NSAttributedString(string: "e", attributes:[.font: font2,
                                                              .foregroundColor: UIColor.red]))
    string.append(NSAttributedString(string: "f"))

    string.stu_adjustFonts(in: NSRange(2..<6), forContentSizeCategory: category)
    XCTAssertEqual(string.string, "abcdef")
    XCTAssertEqual(string.attribute(.font, at: 2, effectiveRange: nil) as! UIFont, scaledFont1)
    XCTAssertEqual(string.attribute(.font, at: 3, effectiveRange: nil) as! UIFont, scaledFont2)
    XCTAssertEqual(string.attributes(at: 4, effectiveRange: nil) as NSObject,
                   ([.font: scaledFont2, .foregroundColor: UIColor.red] as StringAttributes) as NSObject)
    XCTAssertEqual(string.attributes(at: 5, effectiveRange: nil) as NSObject,
                   ([:] as StringAttributes) as NSObject)

  } }
}
