//
//  WatchGameView.swift
//  Big Two on the watch, in the phone's shape: the navy title and the deal counter share
//  the top row with the system clock, the four player rows and your hand fill the middle,
//  and Lead/Play and Pass sit along the bottom edge. Only the 320×320 square is dropped —
//  a wrist has no room for it — so the hand is a grid, seven to a row.
//
//  ⚠️ **No `NavigationStack` and no `GeometryReader`.** The title used to be a toolbar
//  item, which is what put it on the clock's row; but a navigation stack also reserves a
//  band under the clock that nothing draws in, and nothing will tell you how deep it is —
//  inside the stack the top inset reads 0 and outside it reads the whole bar. Three builds
//  tried to take that band back: a flat -22, a measured difference of two insets, and a
//  probe on the title's own frame. Each one was right here and raised the first player
//  rows off the top of the screen on a real watch. Without the stack there is no band, so
//  there is nothing to take back and nothing to guess. The title shares the clock's row by
//  being the first row of a view that ignores the safe area — the clock draws trailing,
//  this draws leading.
//
//  Nothing is measured, so nothing scrolls either: the rows, the prompt and the bar are
//  fixed, a card's height comes from its own text, and the slack between the hand and the
//  buttons is a `Spacer`.
//

import BigTwoKit
import SwiftUI

struct WatchGameView: View {
  @ObservedObject var game: BigTwoGame
  @State private var selection: Set<Card> = []
  @State private var message: String?
  @State private var menuShown = false

  /// Seven to a row, as the phone's hand reads — and never more, however many you hold,
  /// so a card does not change size as the deal goes on.
  private static let columnsPerRow = 7
  private static let cardSpacing: CGFloat = 2
  /// ⚠️ These are a budget, not a taste. Nothing is measured, so the whole table has to
  /// fit the *smallest* watch this ships to — a 40mm is 162×197pt — and every point here
  /// is one the hand does not get. A 46mm has room to spare and spends it on the `Spacer`
  /// between the hand and the buttons.
  private static let titleHeight: CGFloat = 22
  private static let barHeight: CGFloat = 28
  /// How far the pills stay off the curved glass at the bottom.
  private static let barLift: CGFloat = 4

  private static let columns = Array(repeating: GridItem(.flexible(), spacing: cardSpacing),
                                     count: columnsPerRow)

  private var seat: Int { game.humanSeat ?? 1 }
  private var hand: [Card] {
    (game.preferences.sortBySuit ? HandSort.bySuit : .byRank).sorted(game.seats[seat].hand)
  }
  private var isYourTurn: Bool { game.turn == seat && game.isHumanTurn && game.result == nil }
  /// Play order starting from you, as on the phone.
  private var rowOrder: [Int] { (0..<4).map { (seat + $0) % 4 } }

  var body: some View {
    VStack(spacing: 0) {
      // The clock is drawn by the system at the trailing end of this row; the title keeps
      // to the leading end of it.
      WatchTitleBarView(deal: game.deal, dealsPerGame: game.rules.dealsPerGame) {
        menuShown = true
      }
      .frame(height: Self.titleHeight, alignment: .bottom)
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack(spacing: 1) {
        ForEach(rowOrder, id: \.self) { s in
          WatchPlayerRowView(player: game.seats[s], action: game.lastActions[s],
                             isTurn: game.turn == s && game.result == nil)
        }
        Text(verbatim: message ?? prompt)
          .font(.palm(11, .heavy))
          .foregroundColor(.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityIdentifier("prompt")
      }

      // Your hand runs along the bottom edge, as it does on the phone. On a 40mm this
      // spacer is a few points; a 46mm has room to spare and this is where it goes.
      Spacer(minLength: 0)

      // A card is as wide as its seventh of the row and as tall as its own text asks
      // for — no measurement, and the same shape on every watch.
      LazyVGrid(columns: Self.columns, spacing: Self.cardSpacing) {
        ForEach(hand) { card in
          WatchCardView(card: card, selected: selection.contains(card))
            // ⚠️ The two-tap gesture has to be attached *before* the one-tap one, or
            // the single tap swallows the event and the double never fires.
            .onTapGesture(count: 2) { selectSuitOrPair(card) }
            .onTapGesture { toggle(card) }
            .onLongPressGesture { selectAll(sameRankAs: card) }
            .accessibilityIdentifier("hand_\(card.code)")
        }
      }
      controls
    }
    // The glass curves at all four corners once the safe area is ignored, so the content
    // keeps a margin of its own.
    .padding(.horizontal, 6)
    .padding(.top, 2)
    .background(Color.felt)
    // The whole screen, clock row included. Without this the title cannot share that row
    // and the content does not reach the bottom edge.
    .ignoresSafeArea()
    // The menu the title tab drops, as on the phone. A clear layer under it swallows the
    // tap that dismisses it, so nothing behind is picked by accident.
    .overlay(alignment: .topLeading) {
      if menuShown {
        ZStack(alignment: .topLeading) {
          Color.clear.contentShape(Rectangle()).onTapGesture { menuShown = false }
          WatchMenuView(items: [
            .init(id: "new_game", title: L10n.string("New Game")) {
              game.startGame()
              selection = []
              message = nil
              menuShown = false
            }
          ])
          .padding(.leading, 4)
          .padding(.top, Self.titleHeight)
        }
      }
    }
    .onChange(of: game.seats[seat].hand) {
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
    // Wider side margins than the rest of the screen uses: this bar sits in the curved
    // glass, where the rounded corners bite into the corners of a full-width pill.
    .padding(.horizontal, 8)
    .frame(maxWidth: .infinity)
    .frame(height: Self.barHeight)
    .padding(.bottom, Self.barLift)
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
