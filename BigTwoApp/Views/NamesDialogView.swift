//
//  NamesDialogView.swift
//  Big Two — Palm v2.0.11 editable player names.
//

import SwiftUI

struct NamesDialogView: View {
  @Binding var names: [String]
  let placeholders: [String]
  /// Seat that belongs to the person holding the phone — its number is inverted,
  /// the same "this one is you" mark the table's name button uses.
  var humanSeat: Int?
  /// First launch only. The menu's Names item leaves this off.
  var intro: Bool = false
  let onOK: () -> Void

  @Environment(\.palmUnit) private var u

  var body: some View {
    PalmDialogView(title: L10n.string("Player names")) {
      VStack(alignment: .leading, spacing: 4 * u) {
        if intro {
          Text(L10n.string("Enter your name. The dark row is you. Leave a row blank to keep its name."))
            .font(.palm(12 * u))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("name_intro")
        }
        ForEach(0..<4, id: \.self) { i in
          HStack(spacing: 6 * u) {
            number(i)
            TextField(placeholder(i), text: binding(i))
              .font(.palm(13 * u))
              .disableAutocorrection(true)
              .textFieldStyle(PlainTextFieldStyle())
              .padding(.horizontal, 4 * u)
              .frame(height: 22 * u)
              .background(Color.cardFace)
              .overlay(Rectangle().strokeBorder(Color.ink, lineWidth: max(1, u)))
              .accessibilityIdentifier("pref_name_\(i)")
          }
        }
      }
      .padding(.bottom, 6 * u)
    } buttons: {
      PalmButtonView(title: L10n.string("OK"), width: 40, action: onOK)
        .accessibilityIdentifier("names_ok")
    }
  }

  private func number(_ i: Int) -> some View {
    let you = i == humanSeat
    return Text("\(i + 1).")
      .font(.palm(13 * u))
      .foregroundColor(you ? .cardFace : .ink)
      .padding(.trailing, 2 * u)
      .frame(width: 18 * u, height: 18 * u, alignment: .trailing)
      .background(RoundedRectangle(cornerRadius: 2 * u).fill(you ? Color.ink : Color.clear))
      .accessibilityLabel(you ? L10n.string("Player %d, you", i + 1) : "\(i + 1)")
      .accessibilityIdentifier(you ? "names_you" : "names_seat_\(i)")
  }

  private func placeholder(_ i: Int) -> String {
    i < placeholders.count ? placeholders[i] : PlayerNames.keys[i]
  }

  private func binding(_ i: Int) -> Binding<String> {
    Binding(
      get: { i < names.count ? names[i] : "" },
      set: { newValue in
        if names.count < 4 { names = (names + ["", "", "", ""]).prefix(4).map { $0 } }
        names[i] = newValue
      }
    )
  }
}

#Preview {
  NamesDialogView(names: .constant(["", "", "", ""]), placeholders: PlayerNames.keys,
                  humanSeat: 1, onOK: {})
    .padding()
    .background(Color.felt)
}
