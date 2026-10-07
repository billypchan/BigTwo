//
//  BannerAdView.swift
//  Big Two — the AdMob banner that sits in the bezel below the card tracker.
//  It never overlaps the 320×320 square: GameView takes its height out of the
//  space the square is sized against.
//

import GoogleMobileAds
import SwiftUI

/// The banner's height in points. `AdSizeBanner` is 320×50, which is also the
/// smallest AdMob serves — the square is laid out against whatever is left.
enum BannerAd {
  static let height: CGFloat = 50
}

struct BannerAdView: UIViewRepresentable {
  /// Kept so a width change can re-evaluate the view; the size itself is fixed.
  let width: CGFloat

  func makeUIView(context: Context) -> BannerView {
    // A fixed 320×50 banner, not an anchored adaptive one: adaptive returns a height
    // that follows the screen (up to 15% of it) and would be clipped by the 50pt strip
    // the layout reserves — or push the square if the strip followed it.
    let view = BannerView(adSize: AdSizeBanner)
    view.adUnitID = AdUnits.banner
    view.delegate = context.coordinator
    // A banner needs the view controller it will present its click-through from.
    view.rootViewController = Self.rootViewController
    view.load(Request())
    return view
  }

  func updateUIView(_ view: BannerView, context: Context) {
    // The size never changes (portrait only, fixed 320×50), so a layout pass must not
    // load again — every load is an impression.
  }

  func makeCoordinator() -> Coordinator { Coordinator() }

  /// The key window's root — UIApplication.shared.windows is gone on iOS 15+.
  private static var rootViewController: UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }?
      .rootViewController
  }

  final class Coordinator: NSObject, BannerViewDelegate {
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
      // No ad is not an error the player can do anything about: the strip stays
      // empty and the game is unaffected.
      print("[BigTwo] banner failed: \(error.localizedDescription)")
    }
  }
}

#Preview {
  BannerAdView(width: 320)
    .frame(width: 320, height: BannerAd.height)
    .background(Color.bezel)
}
