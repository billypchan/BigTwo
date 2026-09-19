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
  @State private var nameDraft = ["", "", "", ""]

  enum Dialog { case menu, preferences, names, history, about }

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
    .onAppear { game.applyDisplayNames(PlayerNames.defaults) }
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
          .frame(height: max(24 * u, PalmMetrics.minTouch), alignment: .top)
        ZStack(alignment: .bottomTrailing) {
          VStack(spacing: 0) {
            ForEach(rowOrder, id: \.self) { s in
              PlayerRowView(player: game.seats[s], action: game.lastActions[s],
                            isTurn: game.turn == s && game.result == nil,
                            trailingReserve: controlsWidth(u) + 16 * u)
            }
          }
          controls(u).padding(.trailing, 2 * u)
        }
        .frame(height: 224 * u - max(24 * u, PalmMetrics.minTouch), alignment: .top)
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
                    onDoubleTap: { selectSuitOrPair($0) },
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
        if isYourTurn {
          PalmButtonView(title: L10n.string(game.table == nil ? "Lead" : "Play"),
                         enabled: !selection.isEmpty) { play() }
            .accessibilityIdentifier("button_play")
        }
        PalmIconView(glyph: "", enabled: !selection.isEmpty) { selection = [] }
          .accessibilityLabel(L10n.string("Clear selection"))
          .accessibilityIdentifier("button_clear")
      }
      HStack(spacing: 2 * u) {
        if isYourTurn {
          PalmButtonView(title: L10n.string("Pass"), enabled: game.table != nil) {
            message = nil
            game.pass(from: seat)
          }
          .accessibilityIdentifier("button_pass")
        }
        PalmIconView(glyph: game.preferences.sortBySuit ? "2" : "♠") {
          game.preferences.sortBySuit.toggle()
        }
        .accessibilityLabel(L10n.string(game.preferences.sortBySuit ? "Sort by rank" : "Sort by suit"))
        .accessibilityIdentifier("button_sort")
      }
    }
  }

  private var prompt: String {
    if let message { return message }
    if game.mustPlayThreeOfDiamonds && isYourTurn { return L10n.string("Lead with the 3♦") }
    if isYourTurn { return L10n.string(game.table == nil ? "Your Lead" : "Your Play") }
    if game.result != nil { return "" }
    return L10n.string("%@ is thinking…", game.seats[game.turn].name)
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
          Color.clear.contentShape(Rectangle()).onTapGesture { self.dialog = nil }
          PalmMenuView(items: menuItems)
            .padding(.top, 24 * u)
            .padding(.leading, 2 * u)
        }
      case .preferences:
        modal(u) {
          PreferencesDialogView(preferences: $game.preferences) { self.dialog = nil }
        }
      case .names:
        modal(u) {
          NamesDialogView(names: $nameDraft, placeholders: PlayerNames.defaults) {
            game.applyNames(nameDraft, defaults: PlayerNames.defaults)
            self.dialog = nil
          }
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

  private func modal<Content: View>(_ u: CGFloat, @ViewBuilder _ content: () -> Content) -> some View {
    ZStack {
      Color.clear.contentShape(Rectangle()).onTapGesture {}
      content().padding(.horizontal, 6 * u)
    }
  }

  private var menuItems: [PalmMenuView.Item] {
    [
      .init(id: "new_game", title: L10n.string("New Game")) {
        game.startGame()
        dialog = nil
      },
      .init(id: "preferences", title: L10n.string("Preferences")) { dialog = .preferences },
      .init(id: "names", title: L10n.string("Names")) {
        nameDraft = (0..<4).map { i in
          i < game.preferences.playerNames.count ? game.preferences.playerNames[i] : ""
        }
        dialog = .names
      },
      .init(id: "history", title: L10n.string("Game History")) { dialog = .history },
      .init(id: "about", title: L10n.string("About")) { dialog = .about },
    ]
  }

  // MARK: - Actions

  private func toggle(_ card: Card) {
    if selection.contains(card) { selection.remove(card) } else { selection.insert(card) }
  }

  private func selectAll(sameRankAs card: Card) {
    selection = Set(game.seats[seat].hand.filter { $0.rank == card.rank })
  }

  private func controlsWidth(_ u: CGFloat) -> CGFloat {
    max(50 * u, PalmMetrics.minTouch) + 2 * u + max(20 * u, PalmMetrics.minTouch)
  }

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
  }

  private func play() {
    if let error = game.submit(Array(selection), from: seat) {
      message = L10n.playError(error)
    } else {
      message = nil
      selection = []
    }
  }
}

#Preview {
  GameView(game: BigTwoGame(seed: 2))
}
