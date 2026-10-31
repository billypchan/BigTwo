import BigTwoKit
import Testing

struct HandSelectionTests {
  @Test func doubleTapOnAPairReplacesAnEmptySelection() throws {
    let hand = try cards("3d 8h 8s 6h")
    let next = HandSelection.doubleTap(try card("8h"), in: hand, selection: [try card("8h")])
    #expect(next == Set(try cards("8h 8s")))
  }

  @Test func doubleTapOnAThreeReplacesAnEmptySelection() throws {
    let hand = try cards("Kh Kc Kd 3d")
    let next = HandSelection.doubleTap(try card("Kc"), in: hand, selection: [])
    #expect(next == Set(try cards("Kh Kc Kd")))
  }

  @Test func aSingleDoesNotChangeTheSelection() throws {
    let hand = try cards("6h 8h 8s")
    let six = try card("6h")
    let next = HandSelection.doubleTap(six, in: hand, selection: [six])
    #expect(next == [six])
  }

  @Test func fiveOfASuitReplacesASelectedThree() throws {
    let hand = try cards("4c 9c Tc Jc Qc 2c 8h 8s 8d")
    let three = Set(try cards("8h 8s 8d"))
    let next = HandSelection.doubleTap(try card("Qc"), in: hand, selection: three)
    #expect(next == Set(try cards("4c 9c Tc Jc Qc 2c")))
  }

  @Test func aSelectedThreeStaysWhenTheShortcutTakesAPair() throws {
    let hand = try cards("Kh Kc Kd 9h 9s 3d")
    let three = Set(try cards("Kh Kc Kd"))
    let pair = Set(try cards("9h 9s"))
    let watch = HandSelection.doubleTap(try card("9h"), in: hand, selection: three)
    let phone = HandSelection.doubleTap(try card("9h"), in: hand,
                                        selection: three.union([try card("9h")]))
    #expect(watch == three.union(pair))
    #expect(phone == three.union(pair))
  }

  @Test func aSelectedPairStaysWhenTheShortcutTakesAThree() throws {
    let hand = try cards("Kh Kc Kd 9h 9s 3d")
    let three = Set(try cards("Kh Kc Kd"))
    let pair = Set(try cards("9h 9s"))
    let watch = HandSelection.doubleTap(try card("Kh"), in: hand, selection: pair)
    let phone = HandSelection.doubleTap(try card("Kh"), in: hand,
                                        selection: pair.union([try card("Kh")]))
    #expect(watch == three.union(pair))
    #expect(phone == three.union(pair))
  }

  @Test func anotherThreeReplacesTheOneAlreadySelected() throws {
    let hand = try cards("Kh Kc Kd 9h 9c 9d")
    let kings = Set(try cards("Kh Kc Kd"))
    let next = HandSelection.doubleTap(try card("9h"), in: hand, selection: kings)
    #expect(next == Set(try cards("9h 9c 9d")))
  }

  @Test func anotherPairReplacesTheOneAlreadySelected() throws {
    let hand = try cards("Kh Kc 9h 9s 3d")
    let kings = Set(try cards("Kh Kc"))
    let next = HandSelection.doubleTap(try card("9h"), in: hand, selection: kings)
    #expect(next == Set(try cards("9h 9s")))
  }

  @Test func fourOfAKindStillReplacesASelectedThree() throws {
    let hand = try cards("Kh Kc Kd 9h 9c 9d 9s")
    let kings = Set(try cards("Kh Kc Kd"))
    let next = HandSelection.doubleTap(try card("9h"), in: hand, selection: kings)
    #expect(next == Set(try cards("9h 9c 9d 9s")))
  }

  @Test func aStrayCardMeansThisIsNotAFullHouse() throws {
    let hand = try cards("Kh Kc Kd 9h 9s 3d 4d")
    let held = Set(try cards("Kh Kc Kd 3d"))
    let next = HandSelection.doubleTap(try card("9h"), in: hand, selection: held)
    #expect(next == Set(try cards("9h 9s")))
  }

  /// Seat 1 is the second block of 13. Seed 2 is the suite's lead; seed 25 leads
  /// too, and holds three kings plus a pair of sixes. 6♦ sits in five diamonds,
  /// so the UI test double-taps 6♠ — that suit is short, and the shortcut takes
  /// the pair.
  @Test func seed25DealsTheHumanAThreeAndAPair() {
    #expect(Set(dealt(seed: 2)) == ["3d", "4c", "6h", "8h", "8s", "9c", "9s", "Tc", "Jd", "Jc", "Qc", "Ad", "2c"])
    #expect(dealt(seed: 25) == ["2c", "2d", "3d", "6d", "6s", "7h", "8d", "Ad", "Js", "Kc", "Kd", "Ks", "Ts"])
  }

  private func dealt(seed: UInt64) -> [String] {
    var generator = SeededGenerator(seed: seed)
    let deck = Card.deck.shuffled(using: &generator)
    return deck[13..<26].map(\.code).sorted()
  }
}
