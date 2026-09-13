//
//  PalmChrome.swift
//  Big Two — keeps system chrome flat.
//

import SwiftUI

extension View {
  /// iOS 26 draws a partial-height sheet as translucent glass, so the table bleeds through
  /// the dialog. The Palm had no blur: paint the sheet solid.
  @ViewBuilder
  func palmSheetBackground() -> some View {
    if #available(iOS 16.4, *) {
      presentationBackground(Color.chrome)
    } else {
      background(Color.chrome)
    }
  }
}
