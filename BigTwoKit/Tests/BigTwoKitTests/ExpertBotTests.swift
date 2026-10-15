//
//  ExpertBotTests.swift
//  Expert is Strong's policy plus `Belief`. These pin what the reading buys — and,
//  first of all, that it is still reading only what the table showed.
//

@testable import BigTwoKit
import Testing

struct ExpertBotTests {

  /// ⚠️ Unlike `StrongBotTests`, this fixture has to **add up**. `unseen` is exactly
  /// the union of the three other hands, so every card that is not mine and has not
  /// been played is dealt out — otherwise the belief is being asked to spread the
  /// opponents' cards over a pile that is bigger than their hands, and no answer it
  /// gives can be right. In a real deal that is automatic: `BigTwoGame` discards every
  /// card that leaves a hand. What is *not* realistic here is the hand sizes, and
  /// nothing below depends on them.
  func context(_ hand: String, table: String? = nil, owner: Int? = nil,
               gone: String? = nil,
               history: [PublicAction] = []) throws -> BotContext {
    let mine = try cards(hand)
    var out = Set(mine)
    if let gone { out.formUnion(try cards(gone)) }
    if let table { out.formUnion(try play(table).cards) }
    for action in history {
      if case .played(_, let played) = action { out.formUnion(played.cards) }
    }
    var spare = Card.deck.filter { !out.contains($0) }
    var hands = [mine]
    for seat in 0..<3 {
      let size = (spare.count - seat) / (3 - seat) + ((spare.count - seat) % (3 - seat) > 0 ? 1 : 0)
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

  func choice(_ c: BotContext) -> String? {
    ExpertBot.choose(c).map { $0.cards.map(\.code).joined(separator: " ") }
  }

  // MARK: - It still does not peek

  /// ⚠️ The Classic bots see every hand. Expert must not — move a card between two
  /// opponents' hands, which changes nothing the table showed, and the answer cannot
  /// move. (The card has to be *moved*, not replaced: replacing it would change what
  /// has been played, and that is public.)
  @Test func expertIgnoresOtherPlayersHoleCards() throws {
    let mine = try cards("4c 9h Ad")
    let shown = try play("4s")
    let pool = try cards("5s 2s 6d 7c 8h Td Jc Qh Kd 3h 5c")
    func seated(_ human: [Card]) -> BotContext {
      let rest = pool.filter { !human.contains($0) }
      let hands = [mine, human, Array(rest.prefix(5)), Array(rest.suffix(5))]
      let held = Set(hands.flatMap { $0 })
      return BotContext(seat: 0, hands: hands, isHuman: [false, true, false, false],
                        table: shown, tableOwner: 3, mustInclude: nil, rules: .standard,
                        prefersFiveCards: false,
                        discarded: Card.deck.filter { !held.contains($0) })
    }
    let a = seated([try card("5s")])
    let b = seated([try card("2s")])
    #expect(choice(a) == choice(b))
    #expect(choice(a) != nil)
  }

  // MARK: - What a pass gives away

  /// Seat 1 passed on the 9♦ and has shown nothing since, so the jack is now a
  /// stopper against them. Strong cannot work this out: `Reader` only asks whether
  /// *any* unseen card beats a jack, and plenty do.
  @Test func readsAPassAsMissingCards() throws {
    let lead: [PublicAction] = [.played(seat: 3, play: try play("9d"))]
    let passed = lead + [.passed(seat: 1), .passed(seat: 2), .passed(seat: 0)]
    // The control has to have seen the same card played, or the two are not reading
    // the same deal and the chances are not comparable.
    let belief = Belief(try context("3c 4d Jh", history: passed))
    let quiet = Belief(try context("3c 4d Jh", history: lead))
    #expect(belief.chance(try card("Ks"), at: 1) < quiet.chance(try card("Ks"), at: 1))
    #expect(belief.chance(try card("4s"), at: 1) > quiet.chance(try card("4s"), at: 1),
            "the cards it can still hold have to take up the slack")
  }

  /// The same pass, but seat 1 later led a king — so the pass was a choice, not a
  /// shortage, and it says nothing. ⚠️ This bot's own `defend` gear passes on low
  /// cards while holding a king, so without this the reading would be wrong against
  /// every Strong seat at the table.
  @Test func ignoresAPassThatWasAChoice() throws {
    let base: [PublicAction] = [
      .played(seat: 3, play: try play("9d")),
      .passed(seat: 1), .passed(seat: 2), .passed(seat: 0),
    ]
    let four = base + [.played(seat: 3, play: try play("4s")), .passed(seat: 0)]
    let kept = four + [.passed(seat: 1), .played(seat: 2, play: try play("Ks"))]
    let shown = four + [.played(seat: 1, play: try play("Ks"))]
    // Both have seen 9♦, 4♠ and K♠ played — the only difference is who showed the king.
    let honest = Belief(try context("3c 4d Jh", history: kept))
    let noisy = Belief(try context("3c 4d Jh", history: shown))
    let ace = try card("As")
    #expect(noisy.chance(ace, at: 1) > honest.chance(ace, at: 1))
  }

  @Test func everyUnseenCardIsInExactlyOneHand() throws {
    let belief = Belief(try context("3c 4d Jh 2s",
                                    history: [.played(seat: 2, play: try play("Td")),
                                              .passed(seat: 3)]))
    for card in belief.unseen {
      let total = belief.others.reduce(0.0) { $0 + belief.chance(card, at: $1) }
      #expect(abs(total - 1) < 0.001, "\(card.code) adds up to \(total)")
    }
  }

  // MARK: - What the reading changes

  /// The predicate `spareCard` actually asks. A card that would hold the lead is a
  /// stopper worth keeping; one that would not is spare, whatever its rank.
  /// ⚠️ `Reader` cannot tell these apart — it answers "could any unseen card beat
  /// this", and for both of them the answer is yes.
  @Test func tellsAStopperFromAHighCard() throws {
    let gone = "Kd Kc Kh Ks Ad Ac Ah As 2d 2c 2h 2s"
    let late = Belief(try context("3c Qh Jd", gone: gone))
    #expect(late.survival(of: try play("Qh")) >= Belief.worthKeeping, "nothing beats it now")
    #expect(late.survival(of: try play("Jd")) < Belief.worthKeeping, "three queens are out")
  }

  /// Nothing in this hand is within five ranks of the three on the table, so Strong
  /// passes and hands the lead on. Expert works out that a nine is not a stopper
  /// against a full table and answers with it.
  @Test func answersWithACardThatWasNeverAStopper() throws {
    let c = try context("9s 9d Jc Jd Qh Qs", table: "3d", owner: 3)
    #expect(StrongBot.choose(c) == nil, "five ranks is the rule it has")
    #expect(choice(c) == "9d")
  }

  /// And it does not simply answer everything: a card that would hold the lead stays
  /// in the hand, which is what separates this from deleting the rule.
  @Test func stillKeepsTheCardThatWouldHoldTheLead() throws {
    let gone = "Kd Kc Kh Ks Ad Ac Ah As 2d 2c 2h 2s Qd Qc Qs"
    let c = try context("4c 6d 8h Qh", table: "3d", owner: 3, gone: gone)
    #expect(choice(c) == "4c", "the queen is the only stopper left and it is not spare")
  }
}
