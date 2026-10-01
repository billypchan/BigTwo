//
//  WatchGameView.swift
//  Big Two on the watch, in the phone's shape: the navy title and the deal counter share
//  the top bar with the system clock, the four player rows and your hand fill the middle,
//  and Lead/Play and Pass sit in the band the watch keeps at the bottom. The square itself cannot come
//  along — a wrist has no room for 320×320 — so the hand is a grid, and its cards are
//  sized to whatever space is left so that nothing ever has to be scrolled to.
//

import BigTwoKit
import SwiftUI

struct WatchGameView: View {
  @ObservedObject var game: BigTwoGame
  @State private var selection: Set<Card> = []
  @State private var message: String?
  @State private var menuShown = false
  /// Where the navy title tab ends, in screen coordinates — see `table(raise:sink:)`.
  /// It starts at infinity so that until it has been measured the content is not raised
  /// at all: a wrong guess here is what pushes the player rows off the top of the screen.
  @State private var titleBottom: CGFloat = .greatestFiniteMagnitude

  /// Seven to a row, as the phone's hand reads — and never more, however many you hold,
  /// so a card does not change size as the deal goes on.
  private static let columnsPerRow = 7
  private static let cardSpacing: CGFloat = 2
  /// The hand's cards are sized to the space that is left, between these two.
  private static let maxCardHeight: CGFloat = 30
  private static let minCardHeight: CGFloat = 12
  /// The pinned button bar: how tall it is, and how far its pills stay off the glass.
  private static let barHeight: CGFloat = 32
  private static let barLift: CGFloat = 2

  private var seat: Int { game.humanSeat ?? 1 }
  private var hand: [Card] {
    (game.preferences.sortBySuit ? HandSort.bySuit : .byRank).sorted(game.seats[seat].hand)
  }
  private var isYourTurn: Bool { game.turn == seat && game.isHumanTurn && game.result == nil }
  /// Play order starting from you, as on the phone.
  private var rowOrder: [Int] { (0..<4).map { (seat + $0) % 4 } }

  var body: some View {
    // The top bar only exists inside a navigation stack; it is what puts the title on
    // the clock's own row instead of costing a strip of the screen below it.
    NavigationStack {
      // ⚠️ The band's depth is read live, in the same layout pass that uses it. Stashed
      // in `@State` from an `onAppear` it looked identical on every simulator here and
      // was wrong on a real watch: the first value a paged `TabView` hands out is not the
      // one the page settles at, and a bar sunk by a depth that is too large walks off
      // the bottom of the screen.
      GeometryReader { geo in
        // The navigation bar reserves a band under the clock that nothing draws in. How
        // deep it is, is the gap between where the title tab ends and where this content
        // area begins — both read in screen coordinates, so it is the same arithmetic on
        // every watch. ⚠️ It used to be a flat `-22`, which is what it measures on the
        // watches here and is *not* what it measures on every watch: too large, and the
        // first player rows are pulled up off the top of the screen.
        table(raise: max(geo.frame(in: .global).minY - titleBottom, 0),
              sink: max(geo.safeAreaInsets.bottom - Self.barLift, 0))
      }
    }
  }

  private func table(raise: CGFloat, sink: CGFloat) -> some View {
    // A plain stack, not `safeAreaInset`: the whole thing is pushed down into the system's
    // bottom band, and an inset bar leaves the content laid out over it — the hand's last
    // row came back clipped.
    VStack(spacing: 0) {
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
        // ⚠️ Nothing scrolls any more. A hand that does not fit is the whole bug: a
        // watchOS UI test cannot scroll, the Digital Crown has no XCUITest API, and on a
        // real watch the table came up already scrolled, with the player rows above the
        // fold — a smaller screen than any simulator here reproduced it on. A
        // GeometryReader in a stack takes exactly what is left, so the cards are sized to
        // it instead.
        GeometryReader { space in
          let height = fittedCardHeight(in: space.size)
          LazyVGrid(columns: Self.columns, spacing: Self.cardSpacing) {
            ForEach(hand) { card in
              WatchCardView(card: card, selected: selection.contains(card), height: height)
                // ⚠️ The two-tap gesture has to be attached *before* the one-tap one, or
                // the single tap swallows the event and the double never fires.
                .onTapGesture(count: 2) { selectSuitOrPair(card) }
                .onTapGesture { toggle(card) }
                .onLongPressGesture { selectAll(sameRankAs: card) }
                .accessibilityIdentifier("hand_\(card.code)")
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
      }
      .padding(.horizontal, 2)
      controls
    }
    // Taking the band back is also what puts the rule against the bottom of the tab: the
    // raise *is* the gap between them, so closing it leaves none.
    .padding(.top, -raise)
    // The system keeps a deep band at the bottom for the curved glass — 26pt on a 40mm,
    // 36pt on a 46mm. Left alone it is an empty strip under the buttons and costs the
    // hand a row; the screen has no room to give it away. ⚠️ `.ignoresSafeArea` does not
    // take it back: on watchOS 11 the modifier is a no-op there at every level (the bar,
    // the scroll view, the navigation stack, the TabView — all four measured), and it
    // only began working in watchOS 27. A negative padding does reach into it on both,
    // unclipped. ⚠️ `ToolbarItemGroup(placement: .bottomBar)` is not the answer either:
    // measured on a 46mm it leaves the content 204×133 of a 208×248 screen — 53pt at the
    // bottom — and still draws the pills taller than it reserved, so the hand's last row
    // ends up under them unless the cards shrink to about 20pt, which cannot be read.
    .padding(.bottom, -sink)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        WatchTitleBarView(deal: game.deal, dealsPerGame: game.rules.dealsPerGame) {
          menuShown = true
        }
          // The toolbar drops its item below the clock's baseline; this lifts the tab
          // back onto the clock's own row, which is where the phone puts the title.
          .offset(y: -8)
          // Measured *after* the offset, so it is where the tab really ends. A background
          // is used rather than an overlay so nothing is drawn over the title.
          .background(titleProbe)
      }
    }
    .background(Color.felt.ignoresSafeArea())
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
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity)
    .frame(height: Self.barHeight)
    // The bar reaches below the scroll view into the band; without an opaque fill the
    // felt behind it is a different shade and the strip reads as a seam.
    .background(Color.felt)
  }

  private static let columns = Array(repeating: GridItem(.flexible(), spacing: cardSpacing),
                                     count: columnsPerRow)

  /// The largest card height that fits `size` both ways: a column is a seventh of the
  /// width, and `aspect` turns that into the tallest card that fills one; the rows the
  /// hand needs then have to fit the height as well.
  private func fittedCardHeight(in size: CGSize) -> CGFloat {
    let columns = CGFloat(Self.columnsPerRow)
    let columnWidth = (size.width - (columns - 1) * Self.cardSpacing) / columns
    let rows = CGFloat(max((hand.count + Self.columnsPerRow - 1) / Self.columnsPerRow, 1))
    let byHeight = (size.height + Self.cardSpacing) / rows - Self.cardSpacing
    return max(min(Self.maxCardHeight, columnWidth / WatchCardView.aspect, byHeight),
               Self.minCardHeight)
  }

  /// Reports the bottom of the title tab in screen coordinates. ⚠️ If it never reports,
  /// `titleBottom` stays at infinity and the content is simply not raised — a gap under
  /// the title, which is the harmless way for this to fail.
  private var titleProbe: some View {
    GeometryReader { title in
      Color.clear
        .onAppear { titleBottom = title.frame(in: .global).maxY }
        .onChange(of: title.frame(in: .global).maxY) { _, bottom in titleBottom = bottom }
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
