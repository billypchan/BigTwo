//
//  WatchGameView.swift
//  Big Two on the watch, in the phone's shape: the navy title and the deal counter share
//  the top bar with the system clock, the four player rows and your hand fill the middle,
//  and Lead/Play and Pass sit in the bottom safe area. The square itself cannot come
//  along — a wrist has no room for 320×320 — so the hand is a grid under the Digital
//  Crown rather than a strip along the bottom edge.
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
    // The top bar only exists inside a navigation stack; it is what puts the title on
    // the clock's own row instead of costing a strip of the screen below it.
    NavigationStack { table }
  }

  private var table: some View {
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
              // ⚠️ The two-tap gesture has to be attached *before* the one-tap one, or
              // the single tap swallows the event and the double never fires.
              .onTapGesture(count: 2) { selectSuitOrPair(card) }
              .onTapGesture { toggle(card) }
              .onLongPressGesture { selectAll(sameRankAs: card) }
              .accessibilityIdentifier("hand_\(card.code)")
          }
        }
      }
      .padding(.horizontal, 2)
      // The navigation bar reserves a band under the clock that nothing draws in. Taking
      // it back is what keeps the whole hand on one screen once the played cards grew.
      .padding(.top, -22)
    }
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        WatchTitleBarView(deal: game.deal, dealsPerGame: game.rules.dealsPerGame)
          // The toolbar drops its item below the clock's baseline; this lifts the tab
          // back onto the clock's own row, which is where the phone puts the title.
          .offset(y: -8)
      }
    }
    // The buttons stay put while 13 cards scroll, so a turn is never missed scrolling back.
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

  /// Lead/Play and Pass are hidden when it is not your turn, as on the phone; the sort
  /// toggle is not, because re-ordering your hand is something you do while you wait.
  /// The bar keeps its height either way, so the hand does not jump when a bot moves.
  private var controls: some View {
    HStack(spacing: 4) {
      if isYourTurn {
        WatchPalmButtonView(title: L10n.string(game.table == nil ? "Lead" : "Play"),
                            enabled: !selection.isEmpty) { play() }
          // Apple's Double Tap (pinch twice) plays the selection without touching the
          // screen — the one action on this screen worth reaching without a free hand.
          .primaryActionHandGesture(isYourTurn && !selection.isEmpty)
          .accessibilityIdentifier("button_play")
        WatchPalmButtonView(title: L10n.string("Pass"), enabled: game.table != nil) {
          message = nil
          game.pass(from: seat)
        }
        .accessibilityIdentifier("button_pass")
      } else {
        Spacer(minLength: 0)
      }
      // The glyph is the order a tap switches *to*, as on the phone.
      WatchPalmIconView(glyph: game.preferences.sortBySuit ? "2" : "♠") {
        game.preferences.sortBySuit.toggle()
      }
      .accessibilityLabel(L10n.string(game.preferences.sortBySuit ? "Sort by rank" : "Sort by suit"))
      .accessibilityIdentifier("button_sort")
    }
    // Wider side margins and a little lift than the rest of the screen uses: this bar
    // now sits in the curved glass, where the rounded corners bite into the corners of a
    // full-width pill.
    .padding(.horizontal, 10)
    .padding(.bottom, 6)
    .frame(maxWidth: .infinity)
    .frame(height: 32)
    // The bar sits over the scroll view; without an opaque fill the hand scrolls through
    // it and the buttons read as ghosts.
    .background(Color.felt)
    // A watch reserves a deep bottom safe area for the curved glass. Keeping out of it
    // left a thick empty band under the buttons and cost the hand a row, so the bar
    // takes it back — the pills are still well inside the rounded corners.
    .ignoresSafeArea(.container, edges: .bottom)
  }

  private var prompt: String {
    guard game.result == nil else { return "" }
    if isYourTurn {
      return L10n.string(game.table == nil ? "Your Lead" : "Your Play")
    }
    return L10n.string("%@, to play", game.seats[game.turn].name)
  }

  /// Double tap: the whole suit when you hold five or more of it — the makings of a
  /// flush — otherwise the pair or triple of that rank. Same rule as the phone.
  private func selectSuitOrPair(_ card: Card) {
    let cards = game.seats[seat].hand
    let ofSuit = cards.filter { $0.suit == card.suit }
    if ofSuit.count >= 5 {
      selection = Set(ofSuit)
      return
    }
    let ofRank = cards.filter { $0.rank == card.rank }
    if ofRank.count >= 2 {
      selection = Set(ofRank)
    }
    message = nil
  }

  /// Long press: every card of that rank.
  private func selectAll(sameRankAs card: Card) {
    selection = Set(game.seats[seat].hand.filter { $0.rank == card.rank })
    message = nil
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
