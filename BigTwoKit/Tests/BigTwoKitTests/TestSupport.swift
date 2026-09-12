import BigTwoKit
import Testing

/// "Td" → 10♦. Ranks 3-9 T J Q K A 2, suits d c h s.
func card(_ s: String) throws -> Card {
  let ranks = ["3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A", "2"]
  let suits: [Character] = ["d", "c", "h", "s"]
  let r = try #require(ranks.firstIndex(of: String(s.dropLast())).flatMap { Rank(rawValue: $0) })
  let u = try #require(s.last.flatMap { suits.firstIndex(of: $0) }.flatMap { Suit(rawValue: $0) })
  return Card(rank: r, suit: u)
}

func cards(_ s: String) throws -> [Card] {
  try s.split(separator: " ").map { try card(String($0)) }
}

func play(_ s: String, _ rules: RuleSet = .standard) throws -> Play {
  try #require(Play(try cards(s), rules: rules), "\(s) should be a legal play")
}
