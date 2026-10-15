//
//  StrongBotBenchmarkTests.swift
//  Whole-game duels. `StrongBotTests` pins single decisions; this says whether the
//  bot actually scores better than what it replaced.
//
//  ⚠️ A scripted "human exploit" seat was tried here too — lead middling singles,
//  hoard the kings and aces — and measured nothing: it lost to both policies by the
//  same amount within noise, because the habit is not a winning strategy on its own.
//  `spendsAnAceOnAKingWhenTheRestOfTheHandIsStillCovered` in `StrongBotTests` pins
//  that defect exactly, with the old policy folding and the new one answering.
//

@testable import BigTwoKit
import Testing

/// How a seat decides, given the game and its seat number.
typealias SeatPolicy = @MainActor (BigTwoGame, Int) -> Play?

enum Duel {

  /// Seat 0 plays `one`, seats 1-3 play `rest`. Returns seat 0's total over the seeds.
  /// Every seat is "human" so nothing runs on a timer; the caller steps each turn.
  @MainActor
  static func run(_ one: SeatPolicy, versus rest: SeatPolicy,
                  seeds: ClosedRange<UInt64>) -> Int {
    var total = 0
    for seed in seeds {
      let game = BigTwoGame(seed: seed, humanSeats: [0, 1, 2, 3], botsMoveThemselves: false)
      while !(game.result != nil && game.gameOver) {
        if game.result != nil { game.continueAfterScore(); continue }
        let seat = game.turn
        let choice = seat == 0 ? one(game, seat) : rest(game, seat)
        if let choice { game.submit(choice.cards, from: seat) } else { game.pass(from: seat) }
      }
      total += game.seats[0].score
    }
    return total
  }

  @MainActor static let strong: SeatPolicy = { game, seat in
    StrongBot.choose(game.botContext(for: seat))
  }
  @MainActor static let legacy: SeatPolicy = { game, seat in
    LegacyStrongBot.choose(game.botContext(for: seat))
  }
  @MainActor static let expert: SeatPolicy = { game, seat in
    ExpertBot.choose(game.botContext(for: seat))
  }
  @MainActor static let greedy: SeatPolicy = { game, seat in
    GreedyBot.choose(in: game, seat: seat)
  }
}

struct StrongBotBenchmarkTests {

  /// Seat 0 against three clones is not a zero-sum coin flip — the position itself
  /// is worth something — so the control is the old policy playing the same seat.
  @MainActor @Test func strongBeatsLegacyStrong() {
    let control = Duel.run(Duel.legacy, versus: Duel.legacy, seeds: 1...8)
    let total = Duel.run(Duel.strong, versus: Duel.legacy, seeds: 1...8)
    print("seat 0 vs three Legacy, 8 games — Legacy: \(control), Strong: \(total)")
    #expect(total > control, "the new policy should outscore the one it replaces")
  }

  /// The same shape one level up: Expert has to outscore Strong in Strong's own seat,
  /// against a table of Strong. Nothing else about the policy changed, so this measures
  /// exactly what reading the deal is worth.
  @MainActor @Test func expertBeatsStrong() {
    let control = Duel.run(Duel.strong, versus: Duel.strong, seeds: 1...8)
    let total = Duel.run(Duel.expert, versus: Duel.strong, seeds: 1...8)
    print("seat 0 vs three Strong, 8 games — Strong: \(control), Expert: \(total)")
    #expect(total > control, "reading the deal should be worth something")
  }

  /// And it must not have bought that by being weaker against a seat that gives the
  /// lead away — the mistake the dumping thresholds were tightened to avoid.
  @MainActor @Test func expertKeepsItsEdgeOverTheGreedyBot() {
    let control = Duel.run(Duel.strong, versus: Duel.greedy, seeds: 1...8)
    let total = Duel.run(Duel.expert, versus: Duel.greedy, seeds: 1...8)
    print("seat 0 vs three greedy, 8 games — Strong: \(control), Expert: \(total)")
    #expect(total > control, "Expert must not fold against a weak table")
  }
}
