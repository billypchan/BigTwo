//
//  HandSelection.swift
//  Big Two — what a double tap does to the cards already chosen.
//

import Foundation

public enum HandSelection {
  /// Five or more of the tapped suit replace the selection. A pair or three of
  /// that rank does too, unless the rest of the selection is the other half of
  /// a full house: a selected three stays when this takes a pair, and a selected
  /// pair stays when this takes a three.
  ///
  /// ⚠️ On the phone the first tap has already toggled `card`, so `selection`
  /// may already hold one card of the rank being taken. The watch has not
  /// toggled. Drop that rank before deciding what to keep.
  public static func doubleTap(_ card: Card, in hand: [Card], selection: Set<Card>) -> Set<Card> {
    let ofSuit = hand.filter { $0.suit == card.suit }
    if ofSuit.count >= 5 {
      return Set(ofSuit)
    }
    let ofRank = hand.filter { $0.rank == card.rank }
    guard ofRank.count >= 2 else { return selection }
    let adding = Set(ofRank)
    let kept = selection.subtracting(adding)
    if fullHousePartner(kept, adding: ofRank.count) {
      return kept.union(adding)
    }
    return adding
  }

  /// `kept` is one rank: three cards against a pair, or a pair against a three.
  private static func fullHousePartner(_ kept: Set<Card>, adding: Int) -> Bool {
    guard let rank = kept.first?.rank, kept.allSatisfy({ $0.rank == rank }) else { return false }
    switch (kept.count, adding) {
    case (3, 2), (2, 3): return true
    default: return false
    }
  }
}
