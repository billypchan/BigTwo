//
//  ExpertSearch.swift
//  BigTwoKit — Expert's second opinion: play the candidate that scores best over a
//  few dozen deals the table could be hiding.
//
//  Perfect-information Monte Carlo. `Belief` says what the other three can be
//  holding; this samples whole deals out of it, plays each candidate to the end with
//  `PlayoutPolicy`, and keeps the one with the best average points. The objective is
//  **points**, not tricks and not win rate — a deal is scored by what is left in the
//  hand, and that is what the search is allowed to care about.
//
//  ⚠️ Deterministic. The seed comes from the position, so the same table always gives
//  the same answer: UI tests, the game record and a bug report all stay reproducible.
//
//  ⚠️ The policy keeps the tie. The search only moves off `StrongBot.decide` when a
//  candidate is strictly better over every sample — a wash is left to the hand-written
//  policy, which is the thing that was actually measured.
//

import Foundation

enum ExpertSearch {

  /// ⚠️ The watch samples half as many deals. It is the same code on a much smaller
  /// power budget, and halving the samples is the one knob that costs nothing else.
  #if os(watchOS)
  static let samples = 24
  #else
  static let samples = 48
  #endif

  /// At most this many candidates, so the work is bounded by `samples * cap`.
  static let cap = 10

  static func choose(_ c: BotContext, belief: Belief, planner: Planner,
                     samples: Int = ExpertSearch.samples) -> Play? {
    let policy = StrongBot.decide(c, planner: planner, reading: true)
    let options = planner.choices(beating: c.table, mustInclude: c.mustInclude)
    guard !options.isEmpty else { return nil }
    // Emptying the hand wins the deal — there is nothing to search.
    if options.contains(where: { $0.play.count == c.hand.count }) { return policy }
    let plays = candidates(options, policy: policy)
    let canPass = c.table != nil
    guard plays.count > 1 || (canPass && !plays.isEmpty) else { return policy }

    let mine = CardSet(c.hand).bits
    var totals = Array(repeating: 0, count: plays.count)
    var passTotal = 0
    var rng = SeededGenerator(seed: seed(c))
    for _ in 0..<samples {
      var hands = belief.sample(using: &rng)
      hands[c.seat] = mine
      for (i, play) in plays.enumerated() {
        totals[i] += run(hands, c, play: play)
      }
      if canPass { passTotal += run(hands, c, play: nil) }
    }

    // The policy's own move is the one to beat, and it keeps every tie.
    var bestIndex = plays.firstIndex { play in policy.map { $0.cards == play.cards } ?? false }
    var bestIsPass = policy == nil
    var bestScore = bestIndex.map { totals[$0] } ?? (bestIsPass ? passTotal : Int.min)
    for (i, total) in totals.enumerated() where total > bestScore {
      bestScore = total
      bestIndex = i
      bestIsPass = false
    }
    if canPass, passTotal > bestScore { bestIsPass = true }
    return bestIsPass ? nil : (bestIndex.map { plays[$0] } ?? policy)
  }

  /// One sampled deal, one candidate, played to the end.
  private static func run(_ hands: [UInt64], _ c: BotContext, play: Play?) -> Int {
    var sim = Playout(hands: hands, turn: c.seat, target: c.table.map(MoveTarget.init),
                      owner: c.tableOwner ?? c.seat, rules: c.rules)
    if let play {
      let move = Move(mask: CardSet(play.cards).bits, kind: play.kind, strength: play.strength)
      if let winner = sim.apply(move) { return Playout.points(sim.hands, winner: winner)[c.seat] }
    } else {
      sim.applyPass()
    }
    return sim.finish()[c.seat]
  }

  /// A handful of genuinely different plays rather than all of them. A thirteen-card
  /// lead has hundreds of legal moves and most are the same idea with another card in
  /// it: the extremes of each shape are what the search can actually tell apart.
  static func candidates(_ options: [Choice], policy: Play?) -> [Play] {
    var picked: [Play] = []
    func add(_ play: Play?) {
      guard let play, !picked.contains(where: { $0.cards == play.cards }) else { return }
      picked.append(play)
    }
    add(policy)
    var shapes: [Int: [Choice]] = [:]
    for option in options { shapes[option.play.count * 16 + option.play.kind.rawValue, default: []].append(option) }
    for key in shapes.keys.sorted() {
      guard let group = shapes[key] else { continue }
      add(group.min { StrongBot.weaker($0.play, $1.play) }?.play)
      add(group.min { StrongBot.stronger($0.play, $1.play) }?.play)
      add(group.max { StrongBot.penalty($0.play) < StrongBot.penalty($1.play) }?.play)
    }
    guard picked.count > cap else { return picked }
    // Over the cap: keep the policy's move and the ones that cost the plan least.
    let rank = Dictionary(options.map { ($0.play.cards, $0.damage) }, uniquingKeysWith: min)
    let head = picked.prefix(1)
    let rest = picked.dropFirst().sorted { (rank[$0.cards] ?? 9) < (rank[$1.cards] ?? 9) }
    return Array(head) + rest.prefix(cap - head.count)
  }

  /// ⚠️ Position in, seed out — never the system generator. `discarded` and the
  /// history length move every turn, so two different turns never share a sample.
  static func seed(_ c: BotContext) -> UInt64 {
    var h: UInt64 = 0x9E3779B97F4A7C15
    func mix(_ value: UInt64) {
      h ^= value &+ 0x9E3779B97F4A7C15 &+ (h << 6) &+ (h >> 2)
    }
    mix(UInt64(c.seat))
    mix(CardSet(c.hand).bits)
    mix(UInt64(c.discarded.count))
    mix(UInt64(c.history.count))
    mix(UInt64(bitPattern: Int64(c.table.map { $0.strength } ?? -1)))
    return h
  }
}
