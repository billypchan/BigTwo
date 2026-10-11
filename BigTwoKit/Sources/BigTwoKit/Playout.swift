//
//  Playout.swift
//  BigTwoKit — a whole deal played to the end, fast enough to sample thousands of.
//
//  ⚠️ An endgame playout search was measured and dropped once already (CLAUDE.md
//  § Strong bots). It lost because the playout policy was "everybody takes the
//  cheapest thing that works, nobody ever passes", which is not how the deal goes:
//  it never keeps a stopper, so every sampled line hands the trick back and the
//  evaluation was biased in a direction the planner already beat.
//
//  This policy passes. It keeps control back while the trick is cheap, spends it
//  when a seat is nearly out, and empties the hand when it can. It is deliberately
//  *not* `StrongBot` — that costs 0.5 ms a decision and a deal is forty of them —
//  but it is no longer a strawman.
//
//  Everything here is `UInt64` and `Move`: no `Play`, no `[Card]`, no allocation
//  beyond the one move list per turn.
//

import Foundation

/// One deal in progress, played out by `PlayoutPolicy` from whatever position it
/// is handed. Deterministic: with a sampled deal fixed, the line is fixed, so the
/// only randomness in the search is which deal was sampled.
struct Playout {
  var hands: [UInt64]
  var turn: Int
  var target: MoveTarget?
  var owner: Int
  var passes: Int
  let rules: RuleSet

  init(hands: [UInt64], turn: Int, target: MoveTarget?, owner: Int, rules: RuleSet) {
    self.hands = hands
    self.turn = turn
    self.target = target
    self.owner = owner
    self.passes = 0
    self.rules = rules
  }

  /// Plays `move` from the seat to move. Returns the winner if that emptied a hand.
  @discardableResult
  mutating func apply(_ move: Move) -> Int? {
    hands[turn] &= ~move.mask
    if hands[turn] == 0 { return turn }
    target = MoveTarget(move)
    owner = turn
    passes = 0
    turn = (turn + 1) % hands.count
    return nil
  }

  mutating func applyPass() {
    passes += 1
    if passes >= hands.count - 1 {
      target = nil
      passes = 0
      turn = owner
    } else {
      turn = (turn + 1) % hands.count
    }
  }

  /// Runs to the end and scores the deal: a card left costs its rank, doubled at
  /// ten or more, and the winner collects all three penalties — `BigTwoGame.endDeal`.
  mutating func finish() -> [Int] {
    while true {
      let hand = CardSet(bits: hands[turn])
      let moves = MoveGen.moves(in: hand, beating: target, rules: rules)
      if let move = PlayoutPolicy.choose(moves, hand: hand, target: target,
                                         counts: hands.map(\.nonzeroBitCount), seat: turn) {
        if let winner = apply(move) { return Playout.points(hands, winner: winner) }
      } else {
        applyPass()
      }
    }
  }

  static func points(_ hands: [UInt64], winner: Int) -> [Int] {
    var points = Array(repeating: 0, count: hands.count)
    for seat in hands.indices where seat != winner {
      var cost = 0
      var rest = hands[seat]
      while rest != 0 {
        cost += Card.deck[rest.trailingZeroBitCount].rank.penalty
        rest &= rest - 1
      }
      if hands[seat].nonzeroBitCount >= 10 { cost *= 2 }
      points[seat] = -cost
      points[winner] += cost
    }
    return points
  }
}

/// The cheap policy every seat plays inside a playout.
enum PlayoutPolicy {

  /// A two, a bomb, or an ace that takes the lead on its own — the cards a hand
  /// does not spend on a cheap trick. Same idea as `StrongBot.isControl`, read off
  /// the mask instead of a `Play`.
  static func isControl(_ move: Move) -> Bool {
    if move.kind.isBomb { return true }
    if move.mask & CardSet.rankMasks[Rank.two.rawValue] != 0 { return true }
    if move.count <= 3, move.mask & CardSet.rankMasks[Rank.ace.rawValue] != 0 { return true }
    return false
  }

  static func weakest(_ moves: [Move]) -> Move? { moves.min { $0.mask < $1.mask } }

  /// Nothing here is tuned. It is the shape of a competent hand: go out when you
  /// can, answer with something you were going to throw away anyway, fight when a
  /// seat is nearly out or the trick is expensive, and otherwise keep the stopper.
  static func choose(_ moves: [Move], hand: CardSet, target: MoveTarget?,
                     counts: [Int], seat: Int) -> Move? {
    guard !moves.isEmpty else { return nil }
    let size = hand.count
    // Playing the last cards wins the deal outright.
    if let out = moves.first(where: { $0.count == size }) { return out }
    let others = counts.indices.filter { $0 != seat }.map { counts[$0] }
    let nearlyOut = others.contains { $0 <= 2 }

    guard let target else { return lead(moves, size: size, nearlyOut: nearlyOut) }

    // A seat about to go out has to be stopped now — after their turn is too late.
    if others.contains(1) {
      return moves.max { $0.strength < $1.strength } ?? moves.first
    }
    let spare = moves.filter { !isControl($0) }
    if let cheap = weakest(spare) { return cheap }
    // Only stoppers answer this one. Spend one when the trick is worth it, the
    // hand is nearly done, or somebody is about to run out; otherwise hold it.
    if nearlyOut || size <= 4 || expensive(target) { return weakest(moves) }
    return nil
  }

  /// Lead the longest cheap thing — five cards gone is five cards gone — and keep
  /// the twos and aces for the tricks that cost something.
  static func lead(_ moves: [Move], size: Int, nearlyOut: Bool) -> Move? {
    let spare = moves.filter { !isControl($0) }
    let pool = spare.isEmpty ? moves : spare
    // Against a seat on two cards a long play is the only thing they cannot answer.
    return pool.min { a, b in
      if a.count != b.count { return a.count > b.count }
      return a.mask < b.mask
    } ?? moves.first
  }

  /// A trick worth spending a stopper on: a high single, or any five-card hand
  /// above a straight. The same line `StrongBot.worthAStopper` draws.
  static func expensive(_ target: MoveTarget) -> Bool {
    if target.count == 1 { return target.strength / 4 >= Rank.ten.rawValue }
    if target.count >= 5 { return target.kind >= .fullHouse }
    return target.strength / 4 >= Rank.king.rawValue
  }
}
