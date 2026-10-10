//
//  MoveGenTests.swift
//  The safety net under `CardSet.swift`. The rules are defined once, in `Play.swift`,
//  and `PlayFinder` walks every combination to apply them. `MoveGen` is only a faster
//  way to ask the same question, so these tests hold the two against each other on
//  random hands — the generator is never allowed to be the authority.
//

@testable import BigTwoKit
import Testing

struct MoveGenTests {

  /// Deal `size` cards off a seeded shuffle, so a failure is reproducible.
  func hand(seed: UInt64, size: Int = 13) -> [Card] {
    var rng = SeededGenerator(seed: seed)
    return Array(Card.deck.shuffled(using: &rng).prefix(size)).sorted()
  }

  /// The cards, the kind and the strength of every play, sorted. Two generators agree
  /// when these match exactly — and a play emitted twice shows up as a diff, not a crash.
  func signature(_ plays: [Play]) -> [String] {
    plays.map { "\($0.cards.map(\.code).joined(separator: " ")) \($0.kind) \($0.strength)" }.sorted()
  }

  func signature(_ moves: [Move]) -> [String] {
    signature(moves.map(\.play))
  }

  @Test(arguments: [RuleSet.standard, RuleSet.hongKong])
  func findsEveryPlayPlayFinderFinds(_ rules: RuleSet) {
    for seed in UInt64(1)...60 {
      let mine = hand(seed: seed)
      let expected = signature(PlayFinder.plays(in: mine, rules: rules))
      let actual = signature(MoveGen.moves(in: CardSet(mine), rules: rules))
      #expect(actual == expected, "seed \(seed): \(mine.map(\.code).joined(separator: " "))")
    }
  }

  @Test(arguments: [RuleSet.standard, RuleSet.hongKong])
  func findsEveryAnswerPlayFinderFinds(_ rules: RuleSet) {
    for seed in UInt64(1)...10 {
      let mine = hand(seed: seed)
      // Every play the *rest* of the deck can make is a target worth answering; a
      // thirteenth of them keeps the whole deck covered without a minute of brute force.
      let theirs = Card.deck.filter { !mine.contains($0) }
      let targets = PlayFinder.plays(in: Array(theirs.prefix(13)), rules: rules)
      for target in stride(from: 0, to: targets.count, by: 13).map({ targets[$0] }) {
        let expected = signature(PlayFinder.plays(in: mine, beating: target, rules: rules))
        let actual = signature(MoveGen.moves(in: CardSet(mine), beating: MoveTarget(target),
                                         rules: rules))
        #expect(actual == expected, "seed \(seed) against \(target.label)")
      }
    }
  }

  @Test func honoursMustInclude() throws {
    let mine = try cards("3d 3c 4d 5d 6d 7d 9s 2s")
    let moves = MoveGen.moves(in: CardSet(mine), mustInclude: .threeOfDiamonds)
    #expect(signature(moves) == signature(PlayFinder.plays(in: mine, mustInclude: .threeOfDiamonds)))
    #expect(moves.allSatisfy { $0.cards.contains(.threeOfDiamonds) })
  }

  @Test func answersCanBeatTheSameWayPlayFinderDoes() {
    for seed in UInt64(1)...30 {
      let mine = hand(seed: seed, size: 6)
      let theirs = Card.deck.filter { !mine.contains($0) }
      for target in PlayFinder.plays(in: Array(theirs.prefix(13))).prefix(40) {
        let expected = !PlayFinder.plays(in: mine, beating: target).isEmpty
        #expect(PlayFinder.canBeat(target, with: mine, rules: .standard) == expected,
                "seed \(seed) against \(target.label)")
      }
    }
  }

  /// ⚠️ `Planner` feeds its moves to a DP and then to `min(by:)`, which keeps the first
  /// of several equal candidates — so the order has to be the one the combination walk
  /// produced, or the bot can pick a different (equally rated) play and every benchmark
  /// moves. This is the test that pins it.
  @Test func sortsBackIntoTheOrderTheCombinationWalkProduced() {
    for seed in UInt64(1)...20 {
      let mine = hand(seed: seed)
      var expected: [String] = []
      for size in [1, 2, 3, 5] where size <= mine.count {
        for combo in PlayFinder.combinations(mine, size) where Play(combo) != nil {
          expected.append(combo.map(\.code).joined(separator: " "))
        }
      }
      let actual = MoveGen.moves(in: CardSet(mine)).sorted(by: MoveGen.lexBefore)
        .map { $0.cards.map(\.code).joined(separator: " ") }
      #expect(actual == expected, "seed \(seed)")
    }
  }

  @Test func aSetIsItsCardsBothWays() throws {
    let mine = try cards("3d 7c Th As 2s")
    let set = CardSet(mine)
    #expect(set.cards == mine)
    #expect(set.count == 5)
    #expect(set.contains(.threeOfDiamonds))
    #expect(!set.subtracting(CardSet([Card.threeOfDiamonds])).contains(.threeOfDiamonds))
  }
}
