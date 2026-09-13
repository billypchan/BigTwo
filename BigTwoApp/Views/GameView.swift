//
//  GameView.swift
//  Big Two — the Palm screen: a 320×320 square (title tab, a row per player, Play/Pass,
//  your hand along the bottom) with the card tracker below it where the Palm's portrait
//  screen had its input area. Menus and dialogs are Palm forms drawn inside the square.
//

import BigTwoKit
import SwiftUI

struct GameView: View {
  @ObservedObject var game: BigTwoGame
  @State private var selection: Set<Card> = []
  @State private var message: String?
  @State private var dialog: Dialog?

  enum Dialog { case menu, preferences, history, about }

  /// Palm units below the square for the tracker.
  private static let trackerHeight: CGFloat = 100
  private static let trackerGap: CGFloat = 6

  private var seat: Int { game.humanSeat ?? 1 }
  private var hand: [Card] {
    (game.preferences.sortBySuit ? HandSort.bySuit : .byRank).sorted(game.seats[seat].hand)
  }
  private var isYourTurn: Bool { game.turn == seat && game.isHumanTurn && game.result == nil }
  /// Play order starting from you, as on the Palm: Bill, Carl, Dean, Adam.
  private var rowOrder: [Int] { (0..<4).map { (seat + $0) % 4 } }
  private var played: Set<Card> { Set(Card.deck).subtracting(game.seats.flatMap(\.hand)) }

  var body: some View {
    GeometryReader { geo in
      let side = min(geo.size.width,
                     (geo.size.height - Self.trackerGap) / (1 + Self.trackerHeight / 320))
      let u = side / 320
      VStack(spacing: Self.trackerGap) {
        screen(u).frame(width: side, height: side)
        CardTrackerView(played: played).frame(width: side, height: Self.trackerHeight * u)
      }
      .environment(\.palmUnit, u)
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .background(Color.bezel.ignoresSafeArea())
    .statusBar(hidden: true)
    // Your hand only changes when you play (selection already cleared) or on a
    // redeal / new game — never carry a selection into a fresh hand.
    .onChange(of: game.seats[seat].hand) { _ in
      selection = []
      message = nil
    }
  }

  // MARK: - The square

  private func screen(_ u: CGFloat) -> some View {
    ZStack(alignment: .topLeading) {
      VStack(spacing: 0) {
        TitleBarView(deal: game.deal, dealsPerGame: game.rules.dealsPerGame) { dialog = .menu }
          .frame(height: 24 * u)
        ZStack(alignment: .bottomTrailing) {
          VStack(spacing: 0) {
            ForEach(rowOrder, id: \.self) { s in
              PlayerRowView(player: game.seats[s], action: game.lastActions[s],
                            isTurn: game.turn == s && game.result == nil)
            }
          }
          controls(u).padding(.trailing, 2 * u)
        }
        .frame(height: 200 * u, alignment: .top)
        Text(prompt)
          .font(.palm(13 * u, .heavy))
          .foregroundColor(.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 4 * u)
          .frame(height: 30 * u)
          .accessibilityIdentifier("prompt")
        CardRowView(cards: hand, height: 62 * u, selection: selection, idPrefix: "hand",
                    onTap: { toggle($0) },
                    onDoubleTap: { selectAll(sameSuitAs: $0) },
                    onLongPress: { selectAll(sameRankAs: $0) })
          .padding(.horizontal, 2 * u)
          .frame(height: 66 * u, alignment: .top)
      }
      overlay(u)
    }
    .background(Color.felt)
    .clipped()
  }

  private func controls(_ u: CGFloat) -> some View {
    VStack(alignment: .trailing, spacing: 0) {
      HStack(spacing: 2 * u) {
        // Hidden, not disabled, when it isn't your turn (Palm v0.3).
        if isYourTurn {
          PalmButtonView(title: game.table == nil ? "Lead" : "Play",
                         enabled: !selection.isEmpty) { play() }
            .accessibilityIdentifier("button_play")
        }
        PalmIconView(glyph: "", enabled: !selection.isEmpty) { selection = [] }
          .accessibilityLabel("Clear selection")
          .accessibilityIdentifier("button_clear")
      }
      HStack(spacing: 2 * u) {
        if isYourTurn {
          PalmButtonView(title: "Pass", enabled: game.table != nil) {
            message = nil
            game.pass(from: seat)
          }
          .accessibilityIdentifier("button_pass")
        }
        // Shows the order a tap switches to.
        PalmIconView(glyph: game.preferences.sortBySuit ? "2" : "♠") {
          game.preferences.sortBySuit.toggle()
        }
        .accessibilityLabel(game.preferences.sortBySuit ? "Sort by rank" : "Sort by suit")
        .accessibilityIdentifier("button_sort")
      }
    }
  }

  private var prompt: String {
    if let message { return message }
    if game.mustPlayThreeOfDiamonds && isYourTurn { return "Lead with the 3♦" }
    if isYourTurn { return game.table == nil ? "Your Lead" : "Your Play" }
    if game.result != nil { return "" }
    return "\(game.seats[game.turn].name) is thinking…"
  }

  // MARK: - Menu and dialogs

  @ViewBuilder
  private func overlay(_ u: CGFloat) -> some View {
    if let result = game.result {
      modal(u) { ScoreDialogView(game: game, result: result) }
    } else if let dialog {
      switch dialog {
      case .menu:
        ZStack(alignment: .topLeading) {
          // A tap anywhere else closes the menu, as on the Palm.
          Color.clear.contentShape(Rectangle()).onTapGesture { self.dialog = nil }
          PalmMenuView(items: menuItems)
            .padding(.top, 22 * u)
            .padding(.leading, 2 * u)
        }
      case .preferences:
        modal(u) {
          PreferencesDialogView(preferences: $game.preferences) { self.dialog = nil }
        }
      case .history:
        modal(u) {
          HistoryDialogView(deal: game.deal, text: game.historyText) { self.dialog = nil }
        }
      case .about:
        modal(u) { AboutDialogView { self.dialog = nil } }
      }
    }
  }

  /// A Palm form is modal: taps outside it go nowhere.
  private func modal<Content: View>(_ u: CGFloat, @ViewBuilder _ content: () -> Content) -> some View {
    ZStack {
      Color.clear.contentShape(Rectangle()).onTapGesture {}
      content().padding(.horizontal, 6 * u)
    }
  }

  private var menuItems: [PalmMenuView.Item] {
    [
      .init(id: "new_game", title: "New Game") {
        game.startGame()
        dialog = nil
      },
      .init(id: "preferences", title: "Preferences") { dialog = .preferences },
      .init(id: "history", title: "Game History") { dialog = .history },
      .init(id: "about", title: "About") { dialog = .about },
    ]
  }

  // MARK: - Actions

  private func toggle(_ card: Card) {
    if selection.contains(card) { selection.remove(card) } else { selection.insert(card) }
  }

  private func selectAll(sameRankAs card: Card) {
    selection = Set(game.seats[seat].hand.filter { $0.rank == card.rank })
  }

  /// Double tap — the Palm's "hold DOWN". The first tap has already toggled the card.
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
