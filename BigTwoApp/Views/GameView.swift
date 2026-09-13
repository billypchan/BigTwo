//
//  GameView.swift
//  Big Two — the screen. Palm layout kept: title bar, card history strip,
//  green table, your hand along the bottom, sort / clear / pass / play.
//

import BigTwoKit
import SwiftUI

struct GameView: View {
  @ObservedObject var game: BigTwoGame
  @State private var selection: Set<Card> = []
  @State private var sort: HandSort = .byRank
  @State private var message: String?
  @State private var showMenu = false
  @State private var lastTap: (card: Card, time: Date)?

  private var seat: Int { game.humanSeat ?? 1 }
  private var hand: [Card] { sort.sorted(game.seats[seat].hand) }
  private var isYourTurn: Bool { game.turn == seat && game.isHumanTurn }

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
    .sheet(isPresented: $showMenu) { MenuSheetView(game: game) }
    // Read-only binding: only the sheet's OK button may move on to the next deal.
    .sheet(item: Binding(get: { game.result }, set: { _ in })) { result in
      ScoreSheetView(game: game, result: result)
        .interactiveDismissDisabled()
        .presentationDetents([.medium])
        .palmSheetBackground()
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
      Text("Big Two").font(.palm(17, .heavy))
      Spacer()
      Text("Deal \(game.deal)/\(game.rules.dealsPerGame)")
        .font(.palm(12))
        .accessibilityIdentifier("deal_label")
      Button { showMenu = true } label: {
        Image(systemName: "line.3.horizontal")
          .font(.palm(15))
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .accessibilityLabel("Menu")
      .accessibilityIdentifier("menu_button")
    }
    .foregroundColor(.ink)
    .padding(.leading, 12)
    .padding(.trailing, 2)
    .background(Color.chrome)
    .overlay(Rectangle().frame(height: 1).foregroundColor(.ink), alignment: .bottom)
  }

  /// The old Dynamic Input Area: the last two things that happened.
  private var historyStrip: some View {
    Text(game.history.suffix(2).joined(separator: "   ·   "))
      .font(.palm(11, .regular))
      .foregroundColor(.feltText)
      .lineLimit(1)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 12)
      .padding(.vertical, 5)
      .background(Color.feltDeep.opacity(0.6))
      .accessibilityIdentifier("history_strip")
  }

  private var opponents: some View {
    HStack(spacing: 8) {
      ForEach(game.seats.filter { $0.id != seat }) { player in
        VStack(spacing: 2) {
          Text(player.name).font(.palm(12))
          Text("\(player.hand.count) cards").font(.palm(10, .regular))
          Text("\(player.score)").font(.palm(11))
        }
        .foregroundColor(.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.chrome.opacity(0.9)))
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .strokeBorder(Color.ink, lineWidth: game.turn == player.id ? 2 : 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(player.name), \(player.hand.count) cards, score \(player.score)")
        .accessibilityIdentifier("seat_\(player.id)")
      }
    }
    .padding(12)
  }

  private var table: some View {
    VStack(spacing: 8) {
      if let play = game.table, let owner = game.tableOwner {
        Text("\(game.seats[owner].name) · \(play.kind.name)")
          .font(.palm(12))
          .foregroundColor(.feltText)
          .accessibilityIdentifier("table_owner")
        CardRowView(cards: play.cards, height: 66, idPrefix: "table")
          .frame(maxWidth: 260)
      } else {
        Text("— new trick —")
          .font(.palm(12))
          .foregroundColor(.feltTextDim)
          .accessibilityIdentifier("table_owner")
      }
      Spacer(minLength: 0)
      Text(prompt)
        .font(.palm(15, .heavy))
        .foregroundColor(.feltText)
        .accessibilityIdentifier("prompt")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 12)
  }

  private var prompt: String {
    if let message { return message }
    if game.mustPlayThreeOfDiamonds && isYourTurn { return "Lead with the 3♦" }
    if isYourTurn { return game.table == nil ? "Your Lead" : "Your Play" }
    return "\(game.seats[game.turn].name) is thinking…"
  }

  private var handArea: some View {
    VStack(spacing: 4) {
      CardRowView(cards: hand, height: 82, selection: selection, idPrefix: "hand",
                  onTap: { tapped($0) },
                  onLongPress: { selectAll(sameRankAs: $0) })
        .padding(.horizontal, 10)

      HStack(spacing: 2) {
        PalmButtonView(title: "2") { sort = .byRank }
          .accessibilityLabel("Sort by rank")
          .accessibilityIdentifier("button_sort_rank")
        PalmButtonView(title: "♠") { sort = .bySuit }
          .accessibilityLabel("Sort by suit")
          .accessibilityIdentifier("button_sort_suit")
        PalmButtonView(title: "Clear", enabled: !selection.isEmpty) { selection = [] }
          .accessibilityIdentifier("button_clear")
        Spacer()
        // Hidden, not disabled, when it isn't your turn (Palm v0.3).
        if isYourTurn {
          PalmButtonView(title: "Pass", enabled: game.table != nil) {
            message = nil
            game.pass(from: seat)
          }
          .accessibilityIdentifier("button_pass")
          PalmButtonView(title: game.table == nil ? "Lead" : "Play",
                         wide: true,
                         enabled: !selection.isEmpty) { play() }
            .accessibilityIdentifier("button_play")
        }
      }
      .padding(.horizontal, 6)
      .padding(.bottom, 4)
    }
    .background(Color.feltDeep.opacity(0.35))
  }

  // MARK: - Actions

  /// Tap toggles at once; a second tap on the same card within 0.3s selects its whole suit
  /// (the Palm's "hold DOWN"). A SwiftUI double-tap gesture would delay every single tap.
  private func tapped(_ card: Card) {
    let now = Date()
    if let last = lastTap, last.card == card, now.timeIntervalSince(last.time) < 0.3 {
      lastTap = nil
      selectAll(sameSuitAs: card)
    } else {
      lastTap = (card, now)
      toggle(card)
    }
  }

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
    if let error = game.submit(Array(selection), from: seat) {
      message = error
    } else {
      message = nil
      selection = []
    }
  }
}

#Preview {
  GameView(game: BigTwoGame(seed: 2))
}
