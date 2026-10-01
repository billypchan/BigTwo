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

  //TODO: these const should be depends on watch size?
  /// Seven to a row, as the phone's hand reads — and never more, however many you hold,
  /// so a card does not change size as the deal goes on.
  private static let columnsPerRow = 7
  private static let cardSpacing: CGFloat = 2
  private static let topInset: CGFloat = 2
  private static let titleHeight: CGFloat = 22
  private static let barHeight: CGFloat = 28
  /// How far the pills stay off the curved glass at the bottom.
  private static let barLift: CGFloat = 4
  /// The glass curves hardest at the very top, where the title row is, so that row keeps
  /// further off the leading edge than the rest of the screen does.
  private static let titleLeading: CGFloat = 6
  /// ⚠️ The system draws the clock at the trailing end of the title's row and will not say
  /// how wide it is. Without this the deal counter ran under it on a 40mm.
  private static let clockReserve: CGFloat = 52

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
    // ⚠️ The navigation stack is back, for the toolbar alone — that is how watchOS 10
    // wants the title put on the clock's row and the actions put in a bottom bar, and
    // both bars are then the system's to place. Nothing reaches into either: the raise
    // bug was never the stack, it was the `.padding(.top, -22)` that used to claw back
    // the band under the clock. The table sizes itself to whatever is left instead.
    NavigationStack {
      table
        .background(Color.felt.ignoresSafeArea())
        .toolbar {
          ToolbarItem(placement: .topBarLeading) { titleBar }
          ToolbarItemGroup(placement: .bottomBar) { controls }
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

  /// The title tab and the deal counter, on the clock's own row.
  private var titleBar: some View {
    WatchTitleBarView(deal: game.deal, dealsPerGame: game.rules.dealsPerGame) {
      menuShown = true
    }
  }

  private var table: some View {
    // ⚠️ This is the whole of the watch's layout arithmetic: build the table at each size
    // step, largest first, and let SwiftUI lay out the first one that fits. A 46mm takes
    // `.huge` and fills the screen; a 40mm falls through to `.small` and still shows all
    // thirteen cards. Nothing is measured, so nothing can be guessed wrong — and the two
    // system bars cost whatever they cost without anyone having to know the number.
    ZStack(alignment: .topLeading) {
      ViewThatFits(in: .vertical) {
        table(.huge)
        table(.large)
        table(.medium)
        table(.small)
        table(.tiny)
      }
      if menuShown {
        // A clear layer swallows the tap that dismisses the menu, so nothing behind it
        // is picked by accident.
        Color.clear.contentShape(Rectangle()).onTapGesture { menuShown = false }
        // The menu's top is the top of the content, which is the bottom of the title bar:
        // the navigation bar is what divides them, and neither side has to know how deep
        // it is. ⚠️ `.fixedSize()` is not optional — a stack proposes its whole height to
        // the menu, and `WatchMenuView`'s white face is then painted over all of it, with
        // the one item floating in a white column that reaches the top of the screen.
        WatchMenuView(items: [
          .init(id: "new_game", title: L10n.string("New Game")) {
            game.startGame()
            selection = []
            message = nil
            menuShown = false
          }
        ])
        .fixedSize()
      }
    }
    .padding(.horizontal, 2)
    // Clear of the title's rule: the navigation bar leaves nothing between them on a 40mm.
    .padding(.top, 3)
    // ⚠️ The bottom bar draws taller than it reserves — measured on a 46mm, it takes 53pt
    // of a 248pt screen at the bottom and puts the 40pt discs in it, and the hand's last
    // row came up behind them on a 40mm. This is the difference, and it is a property of
    // the bar and the buttons rather than of the screen, so it is the same number on every
    // watch — but it has to be re-checked on a 40mm whenever the buttons change size.
    .padding(.bottom, 30)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  /// The table at one size step. ⚠️ The `Spacer` has `minLength: 0` on purpose: that is
  /// what gives this view a definite ideal height for `ViewThatFits` to compare against,
  /// while still letting the hand drop to the bottom edge once a step has been chosen.
  private func table(_ metrics: WatchMetrics) -> some View {
    VStack(spacing: 0) {
      VStack(spacing: 1) {
        ForEach(rowOrder, id: \.self) { s in
          WatchPlayerRowView(player: game.seats[s], action: game.lastActions[s],
                             isTurn: game.turn == s && game.result == nil, metrics: metrics)
        }
        Text(verbatim: message ?? prompt)
          .font(.palm(metrics.promptFont, .heavy))
          .foregroundColor(.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityIdentifier("prompt")
      }

      // Your hand runs along the bottom edge, as it does on the phone.
      Spacer(minLength: 0)

      // A card is as wide as its seventh of the row and as tall as its own text asks for.
      LazyVGrid(columns: Self.columns, spacing: Self.cardSpacing) {
        ForEach(hand) { card in
          WatchCardView(card: card, selected: selection.contains(card),
                        font: metrics.handFont)
            // ⚠️ The two-tap gesture has to be attached *before* the one-tap one, or
            // the single tap swallows the event and the double never fires.
            .onTapGesture(count: 2) { selectSuitOrPair(card) }
            .onTapGesture { toggle(card) }
            .onLongPressGesture { selectAll(sameRankAs: card) }
            .accessibilityIdentifier("hand_\(card.code)")
        }
      }
    }
  }

  /// Lead/Play and Pass are hidden when it is not your turn, as on the phone; the sort
  /// toggle is not, because re-ordering your hand is something you do while you wait.
  /// The bar keeps its height either way, so the hand does not jump when a bot moves.
  @ViewBuilder private var controls: some View {
    if isYourTurn {
      WatchPalmIconView(systemImage: "checkmark", enabled: !selection.isEmpty) { play() }
        // Apple's Double Tap (pinch twice) plays the selection without touching the
        // screen — the one action on this screen worth reaching without a free hand.
        .primaryActionHandGesture(isYourTurn && !selection.isEmpty)
        .accessibilityLabel(L10n.string(game.table == nil ? "Lead" : "Play"))
        .accessibilityIdentifier("button_play")
    }
    // Sort sits in the middle, and is the one that never hides: re-ordering your hand is
    // something you do while you wait. The glyph is the order a tap switches *to*, as on
    // the phone.
    WatchPalmIconView(glyph: game.preferences.sortBySuit ? "2" : "♠") {
      game.preferences.sortBySuit.toggle()
    }
    .accessibilityLabel(L10n.string(game.preferences.sortBySuit ? "Sort by rank" : "Sort by suit"))
    .accessibilityIdentifier("button_sort")
    if isYourTurn {
      WatchPalmIconView(systemImage: "forward.fill", enabled: game.table != nil) {
        message = nil
        game.pass(from: seat)
      }
      .accessibilityLabel(L10n.string("Pass"))
      .accessibilityIdentifier("button_pass")
    }
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
