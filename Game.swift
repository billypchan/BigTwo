//
//  Game.swift
//  Big Two — table state, turn order and scoring.
//
//  Scoring, as on the Palm: a card left in hand costs its rank (3 = 1 ... 2 = 13),
//  doubled if you are holding 10 cards or more. The winner collects the lot.
//  After `dealsPerGame` deals the game is over and the score goes to the high scores.
//

import Foundation

struct Seat: Identifiable {
    let id: Int
    var name: String
    var isHuman: Bool
    var hand: [Card] = []
    var score: Int = 0
}

struct DealResult {
    var winner: Int
    var cardsLeft: [Int]
    var points: [Int]        // what each seat gained (+) or paid (-) this deal
}

@MainActor
final class BigTwoGame: ObservableObject {

    @Published var seats: [Seat]
    @Published var rules: RuleSet
    @Published var turn = 0
    @Published var table: Play?          // the play to beat; nil means you lead
    @Published var tableOwner: Int?
    @Published var deal = 1
    @Published var history: [String] = []
    @Published var result: DealResult?   // non-nil while the score sheet is up
    @Published var gameOver = false

    /// Preferences
    @Published var autopass = true            // 1, 2 and 3 card turns
    @Published var autopassFiveCard = false   // "Enable autopass for 5-card turn for a faster pace"
    @Published var showCardsLeft = true

    private var passes = 0
    private var lastWinner: Int?
    private var openingPlay = false           // the 3♦ must be in the first play of a deal
    private var botTask: Task<Void, Never>?

    init(rules: RuleSet = .standard) {
        self.rules = rules
        self.seats = [
            Seat(id: 0, name: "Adam", isHuman: false),
            Seat(id: 1, name: "Bill", isHuman: true),
            Seat(id: 2, name: "Carl", isHuman: false),
            Seat(id: 3, name: "Dean", isHuman: false),
        ]
        startGame()
    }

    var you: Seat { seats.first { $0.isHuman } ?? seats[1] }
    var isYourTurn: Bool { seats[turn].isHuman }
    var mustPlayThreeOfDiamonds: Bool { openingPlay }

    // MARK: - Setup

    func startGame() {
        deal = 1
        lastWinner = nil
        gameOver = false
        for i in seats.indices { seats[i].score = 0 }
        newDeal()
    }

    func newDeal() {
        var shuffled = Card.deck.shuffled()
        for i in seats.indices {
            seats[i].hand = HandSort.byRank.sorted(Array(shuffled.prefix(13)))
            shuffled.removeFirst(13)
        }
        table = nil
        tableOwner = nil
        passes = 0
        result = nil
        history = ["— Deal \(deal) —"]

        // HK rules: the winner of the last deal leads. Otherwise 3♦ leads and must be played.
        if rules.hongKong, let winner = lastWinner {
            turn = winner
            openingPlay = false
        } else {
            turn = seats.firstIndex { $0.hand.contains(.threeOfDiamonds) } ?? 0
            openingPlay = true
        }
        scheduleBot()
    }

    // MARK: - Turns

    func legalPlays(for seat: Int) -> [Play] {
        PlayFinder.plays(in: seats[seat].hand,
                         beating: table,
                         rules: rules,
                         mustInclude: openingPlay ? .threeOfDiamonds : nil)
    }

    /// Returns nil on success, or why the play was rejected.
    @discardableResult
    func submit(_ cards: [Card], from seat: Int) -> String? {
        guard seat == turn else { return "Not your turn" }
        guard cards.allSatisfy({ seats[seat].hand.contains($0) }) else { return "Not your cards" }
        guard let play = Play(cards, rules: rules) else { return "Not a legal combination" }
        if openingPlay && !cards.contains(.threeOfDiamonds) { return "First play must include 3♦" }
        if let table, !play.beats(table) { return "That does not beat \(table.label)" }

        seats[seat].hand.removeAll { cards.contains($0) }
        table = play
        tableOwner = seat
        passes = 0
        openingPlay = false
        log("\(seats[seat].name): \(play.label)")

        if seats[seat].hand.isEmpty {
            endDeal(winner: seat)
        } else {
            advance()
        }
        return nil
    }

    func pass(from seat: Int) {
        guard seat == turn, table != nil else { return }
        log("\(seats[seat].name): pass")
        passes += 1
        if passes >= 3 {                    // everyone else folded — new trick
            turn = tableOwner ?? turn
            table = nil
            tableOwner = nil
            passes = 0
            log("— \(seats[turn].name) leads —")
            scheduleBot()
        } else {
            advance()
        }
    }

    private func advance() {
        turn = (turn + 1) % 4
        // Autopass: skip a seat that cannot answer.
        if let table, autopass, table.count < 5 || autopassFiveCard,
           !PlayFinder.canBeat(table, with: seats[turn].hand, rules: rules) {
            pass(from: turn)
            return
        }
        scheduleBot()
    }

    private func scheduleBot() {
        botTask?.cancel()
        guard !seats[turn].isHuman, result == nil, !gameOver else { return }
        let seat = turn
        botTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled, let self, self.turn == seat else { return }
            self.playBotTurn(seat)
        }
    }

    private func playBotTurn(_ seat: Int) {
        let options = legalPlays(for: seat)
        if let choice = BotPlayer.choose(from: options,
                                         table: table,
                                         hand: seats[seat].hand,
                                         opponentCounts: seats.enumerated()
                                            .filter { $0.offset != seat }
                                            .map { $0.element.hand.count }) {
            submit(choice.cards, from: seat)
        } else {
            pass(from: seat)
        }
    }

    // MARK: - Scoring

    private func endDeal(winner: Int) {
        var points = [0, 0, 0, 0]
        var left = [0, 0, 0, 0]

        for i in seats.indices where i != winner {
            left[i] = seats[i].hand.count
            var cost = seats[i].hand.reduce(0) { $0 + $1.rank.penalty }
            if seats[i].hand.count >= 10 { cost *= 2 }      // DOUBLE!
            points[i] = -cost
            points[winner] += cost
        }
        for i in seats.indices { seats[i].score += points[i] }

        lastWinner = winner
        result = DealResult(winner: winner, cardsLeft: left, points: points)
        log("*** \(seats[winner].name) WINS! ***")
        gameOver = deal >= rules.dealsPerGame
    }

    /// Called when the score sheet is dismissed.
    func continueAfterScore() {
        result = nil
        if gameOver { startGame() } else { deal += 1; newDeal() }
    }

    // MARK: - History ("export the history to Memo pad")

    private func log(_ line: String) { history.append(line) }

    var historyText: String {
        var text = history.joined(separator: "\n")
        if showCardsLeft, let result {
            text += "\n" + seats.indices.map {
                "\(seats[$0].name): \(result.cardsLeft[$0]) left, \(points(result.points[$0]))"
            }.joined(separator: "\n")
        }
        return text
    }

    private func points(_ n: Int) -> String { n > 0 ? "+\(n)" : "\(n)" }
}
