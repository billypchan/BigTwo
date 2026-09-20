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

**Strong** does **not** peek — only its own hand and the public `left: N` counts — and
it fights every seat, including the other bots. It goes out when the whole hand is a
play, leads a combo (or its highest single) when someone is on one card, will not lead
a pair when someone has two, and will beat a fellow bot's king instead of letting it
stand. Bombs and twos stay back until someone is short.

The test `palmBotsOutscoreTheGreedyBot` keeps a greedy bot in the test target as a
yardstick: over 8 seeded games the greedy seat finished at −719 against Classic.
`oneStrongBotOutscoresThreeGreedyBots` keeps one Strong seat ahead of greedy.

## License

MIT — see [LICENSE](LICENSE). The Palm original is GPL and none of its code is used.
Privacy: [PRIVACY.md](PRIVACY.md).

## Credits

Big Two for Palm OS © Woo Kok Tong 1999, © Bill Chan 2006, GPL —
https://bigtwo-palmos.sourceforge.net
