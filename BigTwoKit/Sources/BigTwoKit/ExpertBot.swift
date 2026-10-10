//
//  ExpertBot.swift
//  BigTwoKit — Preferences → Bots: Expert.
//
//  Strong's policy, reading the deal. Everything it decides — the plan, the gear, which
//  cards are spare, whether a stopper is worth spending — goes through `Choice`, and
//  `Belief` is what fills `Choice` in. So this is one line rather than a second bot:
//  the difference between Strong and Expert is not what it wants, it is what it knows.
//
//  What it knows is still only what the table showed: `left: N`, the cards already
//  played, and who passed on what. ⚠️ No hole cards —
//  `expertIgnoresOtherPlayersHoleCards` is the test that keeps it that way.
//

import Foundation

public enum ExpertBot {
  public static func choose(_ c: BotContext) -> Play? {
    StrongBot.choose(c, reading: Belief(c))
  }
}
