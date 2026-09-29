# Big Two — iOS

Remake of Big Two v2.2.8 for Palm OS (鋤大弟). SwiftUI, iOS 15+, iPhone, no third-party
dependencies.

UI follows the phone language:

- English — Big Two
- Traditional Chinese — 鋤大弟
- Simplified Chinese — 大老二
- Bahasa Indonesia — Capsa Banting
- Filipino — Pusoy Dos
- Bahasa Melayu — Big Two
- Tiếng Việt — Big Two

## Build

```bash
xcodegen generate                      # only after editing project.yml
open BigTwo.xcodeproj                  # scheme "BigTwo"
swift test --package-path BigTwoKit    # rules engine, no simulator
```

Project layout, conventions and the test workflow are in [CLAUDE.md](CLAUDE.md).

## Rules kept verbatim from the Palm version

- Straights: `A2345 < 23456 < 34567 < … < TJQKA`, `JQKA2` not a straight. Sequence ties
  broken by the suit of the highest sequence card.
- Five-card ranking: straight < flush < full house < four of a kind < straight flush.
- Flush compared on highest card (rank then suit); full house on the triple; four of a
  kind on the quad.
- Scoring: 3 costs 1 … 2 costs 13, doubled at 10+ cards left, winner collects the other three.
- 10 deals per game, then reset.
- Hong Kong rule set: last deal's winner leads, and 23456 becomes the largest straight.
- Autopass, separately toggleable for 5-card turns.
- "I will not play with real money" when every score is zero.

## Palm gestures, mapped to touch

| Palm | iOS |
| --- | --- |
| Tap card | Tap card |
| Press DOWN — select same rank | Long press a card |
| Hold DOWN — select same suit | Double tap a card (pair if fewer than 5 of that suit) |
| Sort icons `2` / `♠` | Same two buttons, bottom left |
| Export history to Memo Pad | Menu → Copy history |

## The bots

You sit as Bill. Adam, Carl and Dean default to **Strong** (Preferences → Bots). **Classic**
is the 1999 handheld style, rewritten from a description of that behaviour, not from the
GPL source.

**Classic** **sees every hand**. That is how the originals played (they peeked), and
turning it off makes the game easier. They also **let a fellow bot's king, ace or two
stand** as a single: they will not fight each other for the trick, but they will still
beat a human's.

Each turn they set aside the cards they want to keep (straights they are guarding, and
often flushes, full houses and four of a kind), then play the **cheapest** legal thing
that is left. "Cheapest" means the lowest-ranking play of that kind; a straight with a
two (A2345) is treated as dearer than 34567.

When they **lead**, they try five-card hands first, then triples, then pairs, then a
single. Exception: if you are down to two cards, they lead a single before a pair, so
they do not dump a pair and leave you the trick.

When someone is **nearly out** (two cards or fewer), they stop saving. They will spend
aces and twos in a full house, play their biggest pair, and — if they themselves are on
one or two unbeatable cards — take the trick. If the next player (or you, if the next
bot cannot stop you) is on **one card**, they block with their highest card.

Each deal they flip a coin: some deals they protect every five-card combination, others
only straights (and they will not break a pair to make a high straight). Triples never
include a two while they still have more than four cards; pairs drop the twos until the
end is near.

**Strong** does **not** peek, and it fights every seat, including the other bots. It
sees its own hand, each seat's `left: N`, and the cards already played — the same ones
the tracker shows. It does not know who holds a card that is still out, so it assumes
the seat with the most cards might hold the best answer.

It first splits the hand into as few legal plays as possible. A pair of fives, a nine
and a king is three plays; breaking that pair into singles is four, and it treats the
broken hand as worse. If the whole hand is already one play, it plays it. The last
card wins the moment it is played — there is no chance to beat it afterwards.

Twos, a single ace, four of a kind and a straight flush are control cards. It keeps
them to take the lead back. Leading a two first spends the card that would have won
the lead later.

When it **leads**:

- If every play left in the hand is unbeatable, it sheds the bigger, lower ones and
  runs them out.
- If someone has three cards or fewer, it plays a size they cannot answer: a five
  when they have three, and not a single when they have one. A lone two does not
  count as that safe play.
- Otherwise it leads a combo that does not break the plan — five cards before a pair,
  a pair before a single — and the low one.
- If someone has one card and it only has singles left, it leads the highest, two
  included. That card wins the deal as soon as they play it.
- If someone has one or two cards and a single is the only lead, it leads a higher
  single rather than a low one.

When it **follows**:

- If winning the trick lets it empty the rest of the hand, it takes the trick, even
  with a two.
- If someone's count equals the size of the trick, they would go out by playing. It
  answers with its strongest play, or the cheapest one that nothing left can beat.
- If someone has one card, it tries to take the trick so that seat does not get the
  lead.
- Otherwise it follows with the smallest card that does not break a combo and is not
  a control card.
- If it has no such card, it will break one pair to follow a low card rather than
  pass the lead away.
- It spends a two or an ace when the table is a king, ace or two, or a full house or
  better, or someone has one or two cards, or it is itself down to two cards.
- A spare two — another control card still in hand — can be spent to buy the lead.
  The last two is not spent on a low card.
- Otherwise it passes.

The test `palmBotsOutscoreTheGreedyBot` keeps a greedy bot in the test target as a
yardstick: over 8 seeded games the greedy seat finished at −719 against Classic.
`oneStrongBotOutscoresThreeGreedyBots` is one Strong seat against three greedy; on
2026-09-26 that seat finished at +344 (the test requires more than 200).

## License

MIT — see [LICENSE](LICENSE). The Palm original is GPL and none of its code is used.
Privacy: [PRIVACY.md](PRIVACY.md).

## Credits

Big Two for Palm OS © Woo Kok Tong 1999, © Bill Chan 2006, GPL —
https://bigtwo-palmos.sourceforge.net
