import BigTwoKit
import Testing

struct PlayTests {

  // MARK: - Straights

  static let ladder = [
    "Ad 2c 3h 4s 5d", "2d 3c 4h 5s 6d", "3d 4c 5h 6s 7d", "4d 5c 6h 7s 8d", "5d 6c 7h 8s 9d",
    "6d 7c 8h 9s Td", "7d 8c 9h Ts Jd", "8d 9c Th Js Qd", "9d Tc Jh Qs Kd", "Td Jc Qh Ks Ad",
  ]

  @Test func straightLadderA2345ToTJQKA() throws {
    let plays = try Self.ladder.map { try play($0) }
    for p in plays { #expect(p.kind == .straight, "\(p.label)") }
    for (lower, higher) in zip(plays, plays.dropFirst()) {
      #expect(higher.beats(lower), "\(higher.label) should beat \(lower.label)")
      #expect(!lower.beats(higher), "\(lower.label) should not beat \(higher.label)")
    }
  }

  @Test(arguments: ["Jd Qc Kh As 2d", "Qd Kc Ah 2s 3d", "Kd Ac 2h 3s 4d"])
  func wraparoundIsNotAStraight(_ hand: String) throws {
    #expect(Play(try cards(hand)) == nil)
  }

  @Test func sequenceTieBrokenByHighestSequenceCard() throws {
    #expect(try play("3d 4c 5h 6s 7s").beats(play("3s 4s 5s 6d 7h")))
    // A2345's top is the 5, TJQKA's top is the ace — not the highest *card*.
    #expect(try play("Ad 2c 3h 4s 5s").beats(play("As 2s 3s 4d 5h")))
    #expect(try play("Td Jc Qh Ks As").beats(play("Ts Js Qs Kd Ah")))
  }

  @Test func hongKongMakes23456TheLargestStraight() throws {
    let hk = RuleSet.hongKong
    #expect(try play("2d 3c 4h 5s 6d", hk).beats(play("Td Jc Qh Ks As", hk)))
    #expect(!(try play("Td Jc Qh Ks As", hk).beats(play("2d 3c 4h 5s 6d", hk))))
    #expect(try play("3d 4c 5h 6s 7d", hk).beats(play("Ad 2c 3h 4s 5d", hk)), "A2345 stays lowest")
  }

  // MARK: - Five-card kinds

  @Test func fiveCardKindLadder() throws {
    let kinds = try [
      play("9d Tc Jh Qs Ks"),  // straight
      play("3h 5h 7h 9h Jh"),  // flush
      play("3d 3c 4h 4s 4d"),  // full house
      play("3d 5c 5h 5s 5d"),  // four of a kind
      play("3c 4c 5c 6c 7c"),  // straight flush
    ]
    #expect(kinds.map(\.kind) == [.straight, .flush, .fullHouse, .fourOfAKind, .straightFlush])
    for (lower, higher) in zip(kinds, kinds.dropFirst()) {
      #expect(higher.beats(lower) && !lower.beats(higher), "\(higher.kind.name) > \(lower.kind.name)")
    }
  }

  @Test func flushComparedOnHighestCardRankThenSuit() throws {
    #expect(try play("3s 5s 7s 9s Ks").beats(play("3d 5d 7d 9d Kd")))
    #expect(try play("3d 5d 7d 9d Ad").beats(play("6s 8s Ts Js Qs")))
  }

  @Test func fullHouseRankedOnTheTriple() throws {
    #expect(try play("3d 3c 4h 4s 4d").beats(play("Kd Kc 3h 3s 3c")))
  }

  @Test func fourOfAKindRankedOnTheQuad() throws {
    #expect(try play("3d 4c 4h 4s 4d").beats(play("Ad 3c 3h 3s 3d")))
  }

  // MARK: - Singles, pairs, triples

  @Test func pairRankFirstThenHighestSuit() throws {
    #expect(try play("Kd Ks").beats(play("Kc Kh")))
    #expect(try play("2d 2c").beats(play("As Ah")))
  }

  @Test func differentCountsNeverMeet() throws {
    #expect(!(try play("2s 2h").beats(play("3d"))))
    #expect(!(try play("3d").beats(play("3c 3h"))))
  }

  @Test(arguments: ["3d 4d", "3d 3c 3h 3s", "3d 3c 4h", "3d 4c 5h 6s 8d", "3d 3d"])
  func illegalCombinationsRejected(_ hand: String) throws {
    #expect(Play(try cards(hand)) == nil)
  }

  // MARK: - PlayFinder

  @Test func finderReturnsCheapestFirstAndOnlyAnswers() throws {
    let hand = try cards("3d 3c 5h 9s 2s")
    let answers = PlayFinder.plays(in: hand, beating: try play("4d"))
    #expect(answers.map(\.label) == ["5♥", "9♠", "2♠"])
  }

  @Test func finderHonoursMustInclude() throws {
    let hand = try cards("3d 3c 4d 5d 6d 7d")
    let opening = PlayFinder.plays(in: hand, mustInclude: .threeOfDiamonds)
    #expect(!opening.isEmpty)
    #expect(opening.allSatisfy { $0.cards.contains(.threeOfDiamonds) })
    #expect(opening.contains { $0.kind == .straightFlush })
  }
}
