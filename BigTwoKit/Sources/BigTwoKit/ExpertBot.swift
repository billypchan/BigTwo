//
//  ExpertBot.swift
//  BigTwoKit — Preferences → Bots: Expert.
//
//  Two things Strong does not have:
//
//    `Belief`       — what the table says the other three are holding: cards left,
//                     cards played, and every pass this deal. Never a hole card.
//    `ExpertSearch` — a few dozen whole deals sampled out of that belief, each
//                     candidate played to the end, scored in points.
//
//  The hand-written policy is still underneath, and still decides most turns: the
//  search only moves off it when a candidate is strictly better over every sample.
//  ⚠️ That is deliberate. The policy is the thing that was measured deal by deal;
//  the search is a second opinion with a noisy estimate behind it, and letting it
//  win ties gave away most of its own edge.
//

import Foundation

public enum ExpertBot {
  public static func choose(_ c: BotContext) -> Play? {
    guard !c.hand.isEmpty else { return nil }
    let belief = Belief(c)
    let planner = Planner(hand: c.hand, rules: c.rules,
                          unseen: StrongBot.unseenCards(c),
                          maxHold: StrongBot.opponentCounts(c).max() ?? 0,
                          reading: belief)
    return ExpertSearch.choose(c, belief: belief, planner: planner)
  }
}
