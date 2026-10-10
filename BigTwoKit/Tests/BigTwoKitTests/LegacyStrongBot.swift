//
//  LegacyStrongBot.swift
//  The Strong policy as it shipped in 1.3, kept as a yardstick — the same job
//  `GreedyBot` does for the Palm bots. A change to `StrongBot` that does not beat
//  this over a set of seeded games is not an improvement, whatever the intent.
//
//  Only the *policy* is copied. `Planner`, `Reader` and `Choice` are shared with the
//  live bot on purpose: they are infrastructure the new bot extends rather than
//  replaces, so the comparison stays about the decisions.
//

@testable import BigTwoKit

enum LegacyStrongBot {

  static func choose(_ c: BotContext) -> Play? {
    let hand = c.hands[c.seat]
    guard !hand.isEmpty else { return nil }
    let counts = StrongBot.opponentCounts(c)
    let planner = Planner(hand: hand, rules: c.rules,
                          unseen: StrongBot.unseenCards(c), maxHold: counts.max() ?? 0)
    let options = planner.choices(beating: c.table, mustInclude: c.mustInclude)
    guard !options.isEmpty else { return nil }
    if let out = options.first(where: { $0.play.count == hand.count }) { return out.play }
    let leading = c.table == nil
    let weak = planner.weak(leading: leading)
    if leading { return lead(options, counts, weak: weak) }
    guard let table = c.table else { return lead(options, counts, weak: weak) }
    return follow(options, counts, table, handCount: hand.count, weak: weak)
  }

  // MARK: - Lead

  static func lead(_ options: [Choice], _ counts: [Int], weak: Bool) -> Play? {
    let short = counts.contains { $0 <= 2 }
    return options.min { betterLead($0, $1, counts: counts, short: short, weak: weak) }?.play
  }

  static func betterLead(_ a: Choice, _ b: Choice, counts: [Int], short: Bool, weak: Bool) -> Bool {
    if a.opensSweep != b.opensSweep { return a.opensSweep }
    if a.opensSweep && b.opensSweep {
      if a.play.count != b.play.count { return a.play.count > b.play.count }
      return StrongBot.weaker(a.play, b.play)
    }
    let aCover = covers(a, counts), bCover = covers(b, counts)
    if aCover != bCover { return aCover }
    if aCover && bCover {
      if a.control != b.control { return !a.control }
      if a.play.count != b.play.count { return a.play.count > b.play.count }
    }
    if a.damage != b.damage { return a.damage < b.damage }
    if counts.contains(1), a.play.count == 1, b.play.count == 1 {
      return StrongBot.stronger(a.play, b.play)
    }
    if a.control != b.control { return !a.control }
    if weak, StrongBot.highGroup(a.play) != StrongBot.highGroup(b.play) {
      return !StrongBot.highGroup(a.play)
    }
    if a.play.count != b.play.count { return a.play.count > b.play.count }
    if short { return StrongBot.stronger(a.play, b.play) }
    return StrongBot.weaker(a.play, b.play)
  }

  // MARK: - Follow

  static func follow(_ options: [Choice], _ counts: [Int], _ table: Play,
                     handCount: Int, weak: Bool) -> Play? {
    if let sweep = shed(options.filter(\.restSweeps)) { return sweep }
    let oneLeft = counts.contains(1)
    if counts.contains(table.count) || oneLeft {
      if let lock = shed(options.filter(\.unbeatable)) { return lock }
      if counts.contains(table.count) {
        return options.min { StrongBot.stronger($0.play, $1.play) }?.play
      }
    }
    if table.count == 5,
       let five = shed(options.filter { $0.play.count == 5 && $0.damage <= 0 }) {
      return five
    }
    if let free = shed(options.filter { casual($0, table, weak: weak) && $0.damage == 0 }) {
      return free
    }
    if let cracked = shed(options.filter { casual($0, table, weak: weak) && $0.damage <= 1 }) {
      return cracked
    }
    guard worthControl(table, counts, handCount: handCount, weak: weak) else { return nil }
    if let clean = shed(options.filter { $0.damage == 0 }) { return clean }
    if !weak, let split = shed(options.filter { $0.damage <= 1 }) { return split }
    if counts.contains(where: { $0 <= 2 }) || oneLeft || handCount <= 2 { return shed(options) }
    return nil
  }

  static func casual(_ choice: Choice, _ table: Play, weak: Bool) -> Bool {
    if choice.control { return false }
    guard weak, choice.play.count == 1,
          let card = choice.play.cards.first, let shown = table.cards.first else { return true }
    return card.rank.rawValue - shown.rank.rawValue <= 5
  }

  static func worthControl(_ table: Play, _ counts: [Int], handCount: Int, weak: Bool) -> Bool {
    if handCount <= 3 || counts.contains(where: { $0 <= 2 }) { return true }
    if weak { return false }
    return StrongBot.tableIsHigh(table)
  }

  static func covers(_ c: Choice, _ counts: [Int]) -> Bool {
    if c.control && c.play.count < 5 { return false }
    let danger = counts.filter { $0 <= 3 }
    guard !danger.isEmpty else { return false }
    return danger.allSatisfy { $0 < c.play.count }
  }

  static func shed(_ options: [Choice]) -> Play? {
    options.min { StrongBot.weaker($0.play, $1.play) }?.play
  }
}
