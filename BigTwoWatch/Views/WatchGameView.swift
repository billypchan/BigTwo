//
//  WatchGameView.swift
//  Big Two on the watch: deal counter, the play to beat, your hand as a grid, and the
//  two buttons. Everything scrolls under the Digital Crown — 13 cards never fit a watch
//  screen, and a hand that has to be swiped is worse than one that is scrolled.
//

import BigTwoKit
import SwiftUI

struct WatchGameView: View {
  @ObservedObject var game: BigTwoGame
  @State private var selection: Set<Card> = []
  @State private var message: String?

  private var seat: Int { game.humanSeat ?? 1 }
  private var hand: [Card] {
    (game.preferences.sortBySuit ? HandSort.bySuit : .byRank).sorted(game.seats[seat].hand)
  }
  private var isYourTurn: Bool { game.turn == seat && game.isHumanTurn && game.result == nil }

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 4)

  var body: some View {
    ScrollView {
      VStack(spacing: 6) {
        header
        table
        LazyVGrid(columns: columns, spacing: 3) {
          ForEach(hand) { card in
            WatchCardView(card: card, isSelected: selection.contains(card))
              .onTapGesture { toggle(card) }
              .accessibilityIdentifier("hand_\(card.code)")
          }
        }
      }
      .padding(.horizontal, 2)
    }
    // Pinned, not scrolled with the hand: 13 cards push the buttons off a watch screen,
    // and having to scroll back up to play is how a turn gets missed.
    .safeAreaInset(edge: .bottom) { buttons }
    .background(Color.felt.ignoresSafeArea())
    .onChange(of: game.seats[seat].hand) { _ in
      selection = []
      message = nil
    }
    .sheet(item: Binding(get: { game.result }, set: { _ in })) { result in
      WatchScoreView(result: result, seats: game.seats, gameOver: game.gameOver) {
        game.continueAfterScore()
      }
    }
  }

  private var header: some View {
    HStack {
      Text(verbatim: L10n.string("Deal %d/%d", game.deal, game.rules.dealsPerGame))
      Spacer()
      Text(verbatim: L10n.string("left: %d", game.seats[seat].hand.count))
    }
    .font(.system(size: 12, weight: .bold))
    .foregroundColor(.ink)
  }

  /// The play to beat, or whose turn it is — the watch has room for one line, so it
  /// carries whichever the player needs right now.
  private var table: some View {
    VStack(spacing: 2) {
      Text(verbatim: message ?? prompt)
        .font(.system(size: 13, weight: .heavy))
        .foregroundColor(.ink)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("prompt")
      if let play = game.table {
        HStack(spacing: 2) {
          ForEach(play.cards) { WatchCardView(card: $0, isCompact: true) }
        }
      }
    }
  }

  @ViewBuilder private var buttons: some View {
    if isYourTurn {
      HStack(spacing: 4) {
        Button(L10n.string(game.table == nil ? "Lead" : "Play")) { play() }
          .disabled(selection.isEmpty)
          .accessibilityIdentifier("button_play")
        Button(L10n.string("Pass")) {
          message = nil
          game.pass(from: seat)
        }
        .disabled(game.table == nil)
        .accessibilityIdentifier("button_pass")
      }
      .font(.system(size: 13, weight: .bold))
      // The default watch button is a tall capsule; two of them would take a third of
      // the screen away from the hand.
      .controlSize(.mini)
      .frame(maxWidth: .infinity)
      .frame(height: 34)
      .padding(.horizontal, 2)
      .padding(.bottom, 2)
      // The bar is pinned over the scroll view — without an opaque background the hand
      // scrolls through it and the buttons read as ghosts.
      .background(Color.felt)
    }
  }

  private var prompt: String {
    guard game.result == nil else { return "" }
    if isYourTurn {
      return L10n.string(game.table == nil ? "Your Lead" : "Your Play")
    }
    return game.seats[game.turn].name
  }

  private func toggle(_ card: Card) {
    if selection.contains(card) {
      selection.remove(card)
    } else {
      selection.insert(card)
    }
    message = nil
  }

  private func play() {
    let cards = hand.filter(selection.contains)
    if let error = game.submit(cards, from: seat) {
      message = L10n.playError(error)
    } else {
      selection = []
      message = nil
    }
  }
}

#Preview {
  WatchGameView(game: BigTwoGame(seed: 2))
}
