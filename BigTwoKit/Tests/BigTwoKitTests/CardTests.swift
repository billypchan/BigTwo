import BigTwoKit
import Testing

struct CardTests {
  @Test func deckIsFiftyTwoDistinctCards() {
    #expect(Card.deck.count == 52)
    #expect(Set(Card.deck).count == 52)
  }

  @Test func threeOfDiamondsIsLowestAndTwoOfSpadesHighest() throws {
    #expect(Card.deck.min() == Card.threeOfDiamonds)
    #expect(Card.deck.max() == (try card("2s")))
  }

  @Test func rankBeatsSuit() throws {
    #expect(try card("3s") < card("4d"))
    #expect(try card("Ks") < card("Ad"))
    #expect(try card("Ad") < card("2d"))
  }

  @Test func suitOrderDiamondClubHeartSpade() throws {
    #expect(try card("7d") < card("7c"))
    #expect(try card("7c") < card("7h"))
    #expect(try card("7h") < card("7s"))
  }

  @Test func penaltyRunsOneToThirteen() {
    #expect(Rank.three.penalty == 1)
    #expect(Rank.ace.penalty == 12)
    #expect(Rank.two.penalty == 13)
  }

  @Test func sortBySuitGroupsSuitsThenRanks() throws {
    let sorted = HandSort.bySuit.sorted(try cards("2s 3s 4d Kd 5h"))
    #expect(sorted == (try cards("4d Kd 5h 3s 2s")))
  }

  @Test func seededGeneratorIsDeterministic() {
    var a = SeededGenerator(seed: 7)
    var b = SeededGenerator(seed: 7)
    #expect(Card.deck.shuffled(using: &a) == Card.deck.shuffled(using: &b))
  }
}
