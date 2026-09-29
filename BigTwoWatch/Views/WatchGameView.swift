//
//  WatchGameView.swift
//  Big Two on the watch, in the phone's shape: the navy title in the top safe area, the
//  four player rows and your hand in the middle, Lead/Play and Pass in the bottom safe
//  area. The square itself cannot come along — a wrist has no room for 320×320 — so the
//  hand is a grid under the Digital Crown rather than a strip along the bottom edge.
//

import BigTwoKit
import SwiftUI

struct WatchGameView: View {
  @ObservedObject var game: BigTwoGame
  @State private var selection: Set<Card> = []
  @State private var message: String?

  private static let handCardHeight: CGFloat = 34

  private var seat: Int { game.humanSeat ?? 1 }
  private var hand: [Card] {
    (game.preferences.sortBySuit ? HandSort.bySuit : .byRank).sorted(game.seats[seat].hand)
  }
  private var isYourTurn: Bool { game.turn == seat && game.isHumanTurn && game.result == nil }
  /// Play order starting from you, as on the phone.
  private var rowOrder: [Int] { (0..<4).map { (seat + $0) % 4 } }

  private let columns = [
    GridItem(.adaptive(minimum: WatchGameView.handCardHeight * WatchCardView.aspect), spacing: 2)
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 1) {
        ForEach(rowOrder, id: \.self) { s in
          WatchPlayerRowView(player: game.seats[s], action: game.lastActions[s],
                             isTurn: game.turn == s && game.result == nil)
        }
        Text(verbatim: message ?? prompt)
          .font(.palm(12, .heavy))
          .foregroundColor(.ink)
          .lineLimit(2)
          .minimumScaleFactor(0.7)
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityIdentifier("prompt")
        LazyVGrid(columns: columns, spacing: 2) {
          ForEach(hand) { card in
            WatchCardView(card: card, selected: selection.contains(card),
                          height: Self.handCardHeight)
              .onTapGesture { toggle(card) }
              .accessibilityIdentifier("hand_\(card.code)")
          }
        }
      }
      .padding(.horizontal, 2)
    }
    // Chrome in the safe areas, table in the middle: the title and the buttons stay put
    // while 13 cards scroll, so a turn is never missed scrolling back up.
    .safeAreaInset(edge: .top, spacing: 0) {
      WatchTitleBarView(deal: game.deal, dealsPerGame: game.rules.dealsPerGame)
    }
    .safeAreaInset(edge: .bottom, spacing: 0) { controls }
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

  /// Hidden when it is not your turn, as on the phone — but the bar keeps its height so
  /// the hand does not jump every time a bot moves.
  private var controls: some View {
    HStack(spacing: 4) {
      if isYourTurn {
        WatchPalmButtonView(title: L10n.string(game.table == nil ? "Lead" : "Play"),
                            enabled: !selection.isEmpty) { play() }
          .accessibilityIdentifier("button_play")
        WatchPalmButtonView(title: L10n.string("Pass"), enabled: game.table != nil) {
          message = nil
          game.pass(from: seat)
        }
        .accessibilityIdentifier("button_pass")
      }
    }
    .padding(.horizontal, 4)
    .padding(.bottom, 2)
    .frame(maxWidth: .infinity)
    .frame(height: 32)
    // The bar sits over the scroll view; without an opaque fill the hand scrolls through
    // it and the buttons read as ghosts.
    .background(Color.felt)
  }

  private var prompt: String {
    guard game.result == nil else { return "" }
    if isYourTurn {
      return L10n.string(game.table == nil ? "Your Lead" : "Your Play")
    }
    return L10n.string("%@, to play", game.seats[game.turn].name)
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
