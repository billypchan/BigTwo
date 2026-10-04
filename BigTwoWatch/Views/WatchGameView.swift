//
//  WatchGameView.swift
//  Big Two on the watch, in the phone's shape: the navy title and the deal counter share
//  the top row with the system clock, the four player rows and your hand fill the middle,
//  and Lead/Play, Clear, Sort and Pass sit along the bottom edge. Only the 320×320 square
//  is dropped — a wrist has no room for it — so the hand is a grid, seven to a row until
//  the second row is gone, when the remaining cards widen to fill it.
//
//  ⚠️ The title is the first row of the table, not a toolbar item. A top-bar item sits on
//  the clock's row and then reserves a second band under it that nothing draws in — that
//  is the empty felt above the first player. Hiding the navigation bar and drawing the
//  title here gives that band back without a negative padding: three builds that clawed
//  the band back with a guessed inset raised the first row off a real watch. The clock
//  still draws trailing, so the title keeps a fixed trailing reserve.
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
  /// Seven to a row while two rows are needed. Once the second row is gone the grid uses
  /// one column per card, so the ones left widen instead of sitting in the left seventh.
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

  private func handColumns(count: Int) -> [GridItem] {
    let n = max(1, min(count, Self.columnsPerRow))
    return Array(repeating: GridItem(.flexible(), spacing: Self.cardSpacing), count: n)
  }

  /// One row of cards has the width, and the felt the second row used to take, so the
  /// rank can grow. Two rows stay on the step's font — seven across a 40mm cannot.
  private func handFont(_ metrics: WatchMetrics, count: Int) -> CGFloat {
    count <= Self.columnsPerRow ? metrics.handFont * 1.35 : metrics.handFont
  }

  private var seat: Int { game.humanSeat ?? 1 }
  private var hand: [Card] {
    (game.preferences.sortBySuit ? HandSort.bySuit : .byRank).sorted(game.seats[seat].hand)
  }
  private var isYourTurn: Bool { game.turn == seat && game.isHumanTurn && game.result == nil }
  /// Play order starting from you, as on the phone.
  private var rowOrder: [Int] { (0..<4).map { (seat + $0) % 4 } }

  var body: some View {
    // ⚠️ Navigation stack stays, for the bottom bar only. The title is not a toolbar item:
    // that placement reserves a band under the clock (the empty felt above Bill), and
    // taking it back with a negative padding raised the first row off a real watch.
    // Hiding the navigation bar means the band is never reserved. The title is the first
    // row of `table`, with a trailing reserve so it does not run under the clock.
    NavigationStack {
      table
        .background(Color.felt.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
          ToolbarItemGroup(placement: .bottomBar) { controls }
        }
    }
    .onChange(of: game.seats[seat].hand) {
      selection = []
      message = nil
    }
    .sheet(item: Binding(get: { game.result }, set: { _ in })) { result in
      WatchScoreView(result: result, seats: game.seats, gameOver: game.gameOver,
                     showCardsLeft: game.preferences.showCardsLeft) {
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
        table(.giant)
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
        // The title is the first row of the table now, so the menu starts under it.
        // ⚠️ `.fixedSize()` is not optional — a stack proposes its whole height to
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
        .padding(.top, Self.titleHeight)
        .fixedSize()
      }
    }
    .padding(.horizontal, 2)
    // The title shares the clock's row. No negative inset: the navigation bar is hidden,
    // so the band under the clock is not reserved, and this edge is the only one ignored.
    .ignoresSafeArea(edges: .top)
    .padding(.top, 1)
    // ⚠️ The bottom bar draws taller than it reserves — measured on a 46mm, it takes 53pt
    // of a 248pt screen at the bottom and draws the discs over the top of that, and the
    // hand's last row came up behind them without this. It is a property of the bar and
    // the buttons rather than of the screen, so it is the same number on every watch —
    // but it has to be re-checked on a 40mm whenever the buttons change size.
    .padding(.bottom, 6)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  /// The table at one size step. ⚠️ The `Spacer` has `minLength: 0` on purpose: that is
  /// what gives this view a definite ideal height for `ViewThatFits` to compare against,
  /// while still letting the hand drop to the bottom edge once a step has been chosen.
  private func table(_ metrics: WatchMetrics) -> some View {
    VStack(spacing: 0) {
      titleBar
        .padding(.leading, Self.titleLeading)
        .padding(.trailing, Self.clockReserve)
        .frame(height: Self.titleHeight, alignment: .bottom)
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

      // Two rows stay seven across. One row uses a column per card so the ones left
      // fill the width the empty columns used to waste, and a larger face.
      LazyVGrid(columns: hand.count <= Self.columnsPerRow
                  ? handColumns(count: hand.count) : Self.columns,
                spacing: Self.cardSpacing) {
        ForEach(hand) { card in
          WatchCardView(card: card, selected: selection.contains(card),
                        font: handFont(metrics, count: hand.count))
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

  /// Play, Clear, Sort and Pass. Play and Pass hide when it is not your turn, as on the
  /// phone; Clear and Sort stay, because both are things you do while you wait. Clear is
  /// the empty-box button from the phone, drawn as a cross so a disc still reads.
  @ViewBuilder private var controls: some View {
    if isYourTurn {
      WatchPalmIconView(systemImage: "checkmark", enabled: !selection.isEmpty) { play() }
        // Apple's Double Tap (pinch twice) plays the selection without touching the
        // screen — the one action on this screen worth reaching without a free hand.
        .primaryActionHandGesture(isYourTurn && !selection.isEmpty)
        .accessibilityLabel(L10n.string(game.table == nil ? "Lead" : "Play"))
        .accessibilityIdentifier("button_play")
    }
    WatchPalmIconView(systemImage: "xmark", enabled: !selection.isEmpty) {
      selection = []
      message = nil
    }
    .accessibilityLabel(L10n.string("Clear selection"))
    .accessibilityIdentifier("button_clear")
    // Sort sits between Clear and Pass, and is the one that never hides. The glyph is
    // the order a tap switches *to*, as on the phone.
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
  /// flush — otherwise the pair or triple of that rank. Same rule as the phone. A pair
  /// or triple does not clear a pair or triple already chosen: that is how a full house
  /// is picked, two double taps, without the second wiping the first.
  private func selectSuitOrPair(_ card: Card) {
    let cards = game.seats[seat].hand
    let ofSuit = cards.filter { $0.suit == card.suit }
    if ofSuit.count >= 5 {
      selection = Set(ofSuit)
      message = nil
      return
    }
    let ofRank = cards.filter { $0.rank == card.rank }
    guard ofRank.count >= 2 else { return }
    if selection.count == 2 || selection.count == 3 {
      selection.formUnion(ofRank)
    } else {
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
