//
//  ExpertSearchTests.swift
//  The layer on top of `Belief`: sample whole deals, play each candidate to the end,
//  keep the one worth the most points. These pin the sampling (it has to produce a
//  deal that could really be on the table), the determinism, and two decisions the
//  hand-written policy gets wrong.
//

@testable import BigTwoKit
import Testing

struct ExpertSearchTests {

  /// Late in a deal: `gone` sets how many cards the other three still hold, and every
  /// one of them is dealt out, so `unseen` is exactly the union of their hands.
  func context(_ hand: String, table: String? = nil, owner: Int? = nil, gone: String,
               sizes: [Int]? = nil, history: [PublicAction] = []) throws -> BotContext {
    let mine = try cards(hand)
    var out = Set(mine)
    out.formUnion(try cards(gone))
    if let table { out.formUnion(try play(table).cards) }
    var spare = Card.deck.filter { !out.contains($0) }
    var hands = [mine]
    for seat in 0..<3 {
      let size = sizes?[seat]
        ?? ((spare.count - seat) / (3 - seat) + ((spare.count - seat) % (3 - seat) > 0 ? 1 : 0))
      hands.append(Array(spare.prefix(size)))
      spare.removeFirst(min(size, spare.count))
    }
    let held = Set(hands.flatMap { $0 })
    return BotContext(seat: 0, hands: hands, isHuman: [false, true, false, false],
                      table: try table.map { try play($0) }, tableOwner: owner,
                      mustInclude: nil, rules: .standard, prefersFiveCards: false,
                      discarded: Card.deck.filter { !held.contains($0) },
                      history: history)
  }

  func search(_ c: BotContext, samples: Int = ExpertSearch.samples) -> String? {
    let belief = Belief(c)
    let planner = Planner(hand: c.hand, rules: c.rules, unseen: StrongBot.unseenCards(c),
                          maxHold: StrongBot.opponentCounts(c).max() ?? 0, reading: belief)
    return ExpertSearch.choose(c, belief: belief, planner: planner, samples: samples)
      .map { $0.cards.map(\.code).joined(separator: " ") }
  }

  func policy(_ c: BotContext) -> String? {
    StrongBot.choose(c, reading: Belief(c)).map { $0.cards.map(\.code).joined(separator: " ") }
  }

  // MARK: - The deals it samples have to be deals

  /// ⚠️ A sampled deal that does not add up poisons every rollout taken from it: a
  /// seat with the wrong number of cards goes out at the wrong time, and the points
  /// the search is comparing are points from a game nobody is playing.
  @Test func everySampledDealIsOneTheTableCouldBeHiding() throws {
    let c = try context("3c 7d Jh 2s", gone: "4d 4c 4h 5s 6d 8c 9h Td Qc Ks Ad 2d 2c 2h")
    let belief = Belief(c)
    let unseen = Set(belief.unseen.map(\.id))
    var rng = SeededGenerator(seed: 99)
    for _ in 0..<200 {
      var hands = belief.sample(using: &rng)
      hands[0] = 0
      var seen = Set<Int>()
      for seat in 1..<4 {
        #expect(hands[seat].nonzeroBitCount == c.hands[seat].count,
                "seat \(seat) was dealt \(hands[seat].nonzeroBitCount), holds \(c.hands[seat].count)")
        for card in CardSet(bits: hands[seat]).cards {
          #expect(unseen.contains(card.id), "\(card.code) was never unseen")
          #expect(seen.insert(card.id).inserted, "\(card.code) was dealt twice")
        }
      }
      #expect(seen.count == unseen.count, "every unseen card has to be somewhere")
    }
  }

  /// ⚠️ Seeded off the position, never the system generator: a recorded game has to
  /// replay to the same cards, and a UI test has to see the same table twice.
  @Test func theSameTableAlwaysGivesTheSameAnswer() throws {
    let c = try context("3c 7d Jh 2s", table: "9s", owner: 3,
                        gone: "4d 4c 4h 5s 6d 8c 9h Td Qc Ks Ad 2d 2c")
    #expect(search(c) == search(c))
    #expect(ExpertBot.choose(c)?.cards == ExpertBot.choose(c)?.cards)
  }

  @Test func theCandidateListAlwaysKeepsThePolicysOwnMove() throws {
    let c = try context("3c 5d 5c 7d Jh Qs 2s", gone: "4d 4c 4h 6d 8c 9h Td Kc")
    let belief = Belief(c)
    let planner = Planner(hand: c.hand, rules: c.rules, unseen: StrongBot.unseenCards(c),
                          maxHold: StrongBot.opponentCounts(c).max() ?? 0, reading: belief)
    let mine = StrongBot.decide(c, planner: planner, reading: true)
    let options = planner.choices(beating: c.table, mustInclude: c.mustInclude)
    let list = ExpertSearch.candidates(options, policy: mine)
    #expect(list.count <= ExpertSearch.cap)
    #expect(list.contains { $0.cards == mine?.cards }, "the move it has to beat has to be in the list")
  }

  // MARK: - A playout is a deal

  /// The rollout has to score the way `BigTwoGame.endDeal` does, or the search is
  /// optimising a different game: zero sum, and the winner collects.
  @Test func aPlayoutEndsTheDealAndScoresItTheWayTheGameDoes() throws {
    var rng = SeededGenerator(seed: 5)
    let deck = Card.deck.shuffled(using: &rng)
    let hands = (0..<4).map { CardSet(deck[($0 * 13)..<($0 * 13 + 13)]).bits }
    var sim = Playout(hands: hands, turn: 0, target: nil, owner: 0, rules: .standard)
    let points = sim.finish()
    #expect(points.reduce(0, +) == 0, "the deal is zero sum")
    #expect(points.filter { $0 > 0 }.count == 1, "exactly one winner collects")
    #expect(sim.hands.filter { $0 == 0 }.count == 1, "exactly one hand is empty")
  }

  // MARK: - What the search changes

  /// Half a king pair beats the king on the table, and the policy spends it: a trick
  /// now, and a broken stopper for the rest of the deal. Played out to the end, the
  /// pair is worth more than the trick — and this is the kind of decision no amount
  /// of reading the deal reaches, because `Belief` is asked about *this* play, not
  /// about what the hand looks like afterwards.
  @Test func keepsThePairRatherThanWinTheTrickWithHalfOfIt() throws {
    let c = try context("Qh Kd Kh", table: "Kc", owner: 3,
                        gone: "3d 3c 3h 3s 4d 4c 4h 4s 5d 5c 5h 5s 6d 6c 6h 6s 7d 7c 7h 7s 8d 8c 8h 8s 9d 9c 9h",
                        sizes: [6, 6, 6])
    #expect(policy(c) == "Kh", "the policy takes the trick with half the pair")
    #expect(search(c) == nil, "the search would rather still have a pair of kings")
  }
}
