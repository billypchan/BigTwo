//
//  GameView.swift
//  Big Two — the screen. Palm layout kept: title bar, card history strip,
//  green table, your hand along the bottom, sort / clear / pass / play.
//

import SwiftUI

// MARK: - Palette (00cc00 table, as of v2.0.a)

extension Color {
    static let felt      = Color(red: 0.00, green: 0.80, blue: 0.00)
    static let feltDeep  = Color(red: 0.00, green: 0.55, blue: 0.00)
    static let chrome    = Color(red: 0.80, green: 0.85, blue: 0.80)
    static let ink       = Color.black
    static let cardFace  = Color(white: 0.99)
    static let suitRed   = Color(red: 0.80, green: 0.00, blue: 0.00)
}

private func palmFont(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
    .system(size: size, weight: weight, design: .default)
}

// MARK: - Card

struct CardView: View {
    let card: Card
    var selected = false
    var height: CGFloat = 76

    var body: some View {
        let w = height * 0.66
        ZStack {
            RoundedRectangle(cornerRadius: 3).fill(Color.cardFace)
            RoundedRectangle(cornerRadius: 3).strokeBorder(Color.ink, lineWidth: selected ? 2 : 1)
            VStack(spacing: 0) {
                HStack(spacing: 1) {
                    Text(card.rank.label)
                        .font(palmFont(height * 0.24, .heavy))
                    Spacer(minLength: 0)
                }
                Text(card.suit.symbol)
                    .font(palmFont(height * 0.34, .regular))
                Spacer(minLength: 0)
                HStack {
                    Spacer(minLength: 0)
                    Text(card.suit.symbol).font(palmFont(height * 0.18, .regular))
                }
            }
            .foregroundColor(card.suit.isRed ? .suitRed : .ink)
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
        }
        .frame(width: w, height: height)
        .offset(y: selected ? -14 : 0)
    }
}

/// Overlapping row of cards that always fits the width it is given.
struct CardRow: View {
    let cards: [Card]
    var height: CGFloat = 76
    var selection: Set<Card> = []
    var onTap: ((Card) -> Void)? = nil
    var onLongPress: ((Card) -> Void)? = nil
    var onDoubleTap: ((Card) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let w = height * 0.66
            let step = cards.count > 1
                ? min(w + 4, max(14, (geo.size.width - w) / CGFloat(cards.count - 1)))
                : 0
            ZStack(alignment: .leading) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    CardView(card: card, selected: selection.contains(card), height: height)
                        .offset(x: CGFloat(index) * step)
                        .zIndex(Double(index))
                        .onTapGesture(count: 2) { onDoubleTap?(card) }
                        .onTapGesture { onTap?(card) }
                        .onLongPressGesture(minimumDuration: 0.35) { onLongPress?(card) }
                }
            }
            .frame(width: step * CGFloat(max(cards.count - 1, 0)) + w, height: height + 16,
                   alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .frame(height: height + 16)
    }
}

// MARK: - Palm-flavoured button

struct PalmButton: View {
    let title: String
    var wide = false
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(palmFont(14))
                .foregroundColor(.ink)
                .padding(.horizontal, wide ? 18 : 10)
                .frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.chrome))
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.ink, lineWidth: 1))
        }
        .opacity(enabled ? 1 : 0.4)
        .disabled(!enabled)
    }
}

// MARK: - Game screen

struct GameView: View {
    @StateObject private var game = BigTwoGame()
    @State private var selection: Set<Card> = []
    @State private var sort: HandSort = .byRank
    @State private var message: String?
    @State private var showMenu = false

    private var seat: Int { game.seats.firstIndex(where: \.isHuman) ?? 1 }
    private var hand: [Card] { sort.sorted(game.seats[seat].hand) }

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            historyStrip
            opponents
            table
            handArea
        }
        .background(
            LinearGradient(colors: [.felt, .feltDeep], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .sheet(isPresented: $showMenu) { MenuSheet(game: game) }
        .sheet(item: $game.result) { result in
            ScoreSheet(game: game, result: result)
                .interactiveDismissDisabled()     // only OK moves on to the next deal
        }
        // Your hand only changes when you play (selection already cleared) or on a
        // redeal / new game — never carry a selection into a fresh hand.
        .onChange(of: game.seats[seat].hand) { _ in
            selection = []
            message = nil
        }
    }

    private var titleBar: some View {
        HStack {
            Text("Big Two").font(palmFont(17, .heavy))
            Spacer()
            Text("Deal \(game.deal)/\(game.rules.dealsPerGame)").font(palmFont(12))
            Button { showMenu = true } label: {
                Image(systemName: "line.3.horizontal").font(palmFont(15))
            }
        }
        .foregroundColor(.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.chrome)
        .overlay(Rectangle().frame(height: 1).foregroundColor(.ink), alignment: .bottom)
    }

    /// The old Dynamic Input Area: what has been played this trick.
    private var historyStrip: some View {
        Text(game.history.suffix(2).joined(separator: "   ·   "))
            .font(palmFont(11, .regular))
            .foregroundColor(.white)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color.feltDeep.opacity(0.6))
    }

    private var opponents: some View {
        HStack(spacing: 8) {
            ForEach(game.seats.filter { !$0.isHuman }) { player in
                VStack(spacing: 2) {
                    Text(player.name).font(palmFont(12))
                    Text("\(player.hand.count) cards").font(palmFont(10, .regular))
                    Text("\(player.score)").font(palmFont(11))
                }
                .foregroundColor(.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.chrome.opacity(0.9)))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.ink, lineWidth: game.turn == player.id ? 2 : 1)
                )
            }
        }
        .padding(12)
    }

    private var table: some View {
        VStack(spacing: 8) {
            if let play = game.table, let owner = game.tableOwner {
                Text("\(game.seats[owner].name) · \(play.kind.name)")
                    .font(palmFont(12)).foregroundColor(.white)
                CardRow(cards: play.cards, height: 66)
                    .frame(maxWidth: 260)
            } else {
                Text("— new trick —").font(palmFont(12)).foregroundColor(.white.opacity(0.8))
            }
            Spacer(minLength: 0)
            Text(prompt)
                .font(palmFont(15, .heavy))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
    }

    private var prompt: String {
        if let message { return message }
        if game.mustPlayThreeOfDiamonds && game.isYourTurn { return "Lead with the 3♦" }
        if game.isYourTurn { return game.table == nil ? "Your Lead" : "Your Play" }
        return "\(game.seats[game.turn].name) is thinking…"
    }

    private var handArea: some View {
        VStack(spacing: 8) {
            CardRow(cards: hand, height: 82, selection: selection,
                    onTap: { toggle($0) },
                    onLongPress: { selectAll(sameRankAs: $0) },
                    onDoubleTap: { selectAll(sameSuitAs: $0) })
                .padding(.horizontal, 10)

            HStack(spacing: 6) {
                PalmButton(title: "2") { sort = .byRank }        // sort by rank
                PalmButton(title: "♠") { sort = .bySuit }        // sort by suit
                PalmButton(title: "Clear", enabled: !selection.isEmpty) { selection = [] }
                Spacer()
                if game.isYourTurn {
                    PalmButton(title: "Pass", enabled: game.table != nil) {
                        message = nil
                        game.pass(from: seat)
                    }
                    PalmButton(title: game.table == nil ? "Lead" : "Play",
                               wide: true,
                               enabled: !selection.isEmpty) { play() }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
        .background(Color.feltDeep.opacity(0.35))
    }

    // MARK: - Actions

    private func toggle(_ card: Card) {
        if selection.contains(card) { selection.remove(card) } else { selection.insert(card) }
    }

    private func selectAll(sameRankAs card: Card) {
        selection = Set(game.seats[seat].hand.filter { $0.rank == card.rank })
    }

    private func selectAll(sameSuitAs card: Card) {
        selection = Set(game.seats[seat].hand.filter { $0.suit == card.suit })
    }

    private func play() {
        let cards = Array(selection)
        if let error = game.submit(cards, from: seat) {
            message = error
        } else {
            message = nil
            selection = []
        }
    }
}

// MARK: - Score sheet

struct ScoreSheet: View {
    @ObservedObject var game: BigTwoGame
    let result: DealResult

    var body: some View {
        VStack(spacing: 14) {
            Text(game.gameOver ? "Final Score" : "Score").font(palmFont(20, .heavy))
            ForEach(game.seats) { player in
                HStack {
                    Text(player.name).font(palmFont(15))
                    if player.id == result.winner {
                        Text("WIN!").font(palmFont(15, .heavy)).foregroundColor(.suitRed)
                    }
                    if game.showCardsLeft && player.id != result.winner {
                        Text("\(result.cardsLeft[player.id]) left").font(palmFont(12, .regular))
                        if result.cardsLeft[player.id] >= 10 {
                            Text("DOUBLE!").font(palmFont(11, .heavy)).foregroundColor(.suitRed)
                        }
                    }
                    Spacer()
                    Text(result.points[player.id] > 0 ? "+\(result.points[player.id])"
                                                      : "\(result.points[player.id])")
                        .font(palmFont(13, .regular))
                    Text("\(player.score)").font(palmFont(16, .heavy)).frame(width: 52, alignment: .trailing)
                }
            }
            if game.seats.allSatisfy({ $0.score == 0 }) {
                Text("I will not play with real money")
                    .font(palmFont(11, .regular)).foregroundColor(.secondary)
            }
            PalmButton(title: game.gameOver ? "New Game" : "OK", wide: true) {
                game.continueAfterScore()
            }
        }
        .foregroundColor(.ink)
        .padding(24)
    }
}

// MARK: - Menu / Preferences

struct MenuSheet: View {
    @ObservedObject var game: BigTwoGame
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Hong Kong rule set", isOn: Binding(
                        get: { game.rules.hongKong },
                        set: { game.rules.hongKong = $0 }))
                    Toggle("Autopass", isOn: $game.autopass)
                    Toggle("Autopass on 5-card turns", isOn: $game.autopassFiveCard)
                    Toggle("Show cards left in score", isOn: $game.showCardsLeft)
                }
                Section("Game history") {
                    Text(game.historyText)
                        .font(.system(size: 12, design: .monospaced))
                    Button("Copy history") {
                        UIPasteboard.general.string = game.historyText
                    }
                }
                Section {
                    Button("New game", role: .destructive) {
                        game.startGame(); dismiss()
                    }
                }
            }
            .navigationTitle("Big Two")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

// MARK: - sheet(item:) for a non-Identifiable result

extension DealResult: Identifiable {
    var id: Int { winner }
}
