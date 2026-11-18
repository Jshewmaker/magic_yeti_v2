# Commander Expert Consult — Friend Head-to-Head Stats

Working doc. Claude (feature owner) asks; `commander-expert` answers in-file.

---

## Round 1 — Claude → commander-expert

### The feature

Magic Yeti tracks Commander pods. Users have a friends list. When you play on one device, each seat can be linked to a friend's account. I'm building: **tap a friend → see stats about the games the two of us have played together.** Head-to-head / rivalry stats, not their global stats.

I need you to tell me which stats are actually *fun and revealing to a Commander playgroup*, and which are noise.

### Exactly what data I have

Per finished game (`GameModel`):

| Field | Type | Notes |
|---|---|---|
| `players` | `List<Player>` | the whole pod |
| `startTime` / `endTime` | `DateTime` | |
| `durationInSeconds` | `int` | wall-clock game length |
| `winnerId` | `String` | matches `Player.id` (per-game UUID) |
| `startingPlayerId` | `String` | who went first |
| `roomId` | `String` | 4-char game code |
| `hostId` | `String` | account that saved the game |

Per `Player` inside a game:

| Field | Type | Notes |
|---|---|---|
| `firebaseId` | `String?` | **the account link** — null if the seat is unlinked. This is how I identify "me" and "my friend" |
| `id` | `String` | per-game UUID |
| `name` | `String` | display name typed at the table |
| `commander` | `Commander?` | has `oracleId`, `name`, `colors`, `colorIdentity`, `typeLine`, `edhrecRank`, `imageUrl` |
| `partner` | `Commander?` | second *attacking* commander, own 21-damage clock |
| `background` | `Commander?` | Background enchantment — color identity only, no clock |
| `playerNumber` | `int` | seat index |
| `lifePoints` | `int` | **final** life at game end (only meaningful for the survivor; everyone else is ≤0) |
| `placement` | `int` | 1 = win. Every player in a saved game has one |
| `timeOfDeath` | `int` | epoch millis when eliminated. Winner gets one too (game end) |
| `opponents` | `List<Opponent>?` | commander damage **dealt TO this player, keyed by the DEALING player's `id`** |

`Opponent { playerId, List<CommanderDamage> damages }`, `CommanderDamage { DamageType (commander\|partner), int amount }`.

**Critical:** `opponents` gives me a full directed damage graph. For any pair I know exactly how much commander damage A dealt to B and vice versa. `timeOfDeath` + `placement` gives me full elimination ordering and timing. `startTime` + `timeOfDeath` gives me *how far into the game* someone died.

I do **not** have: who dealt the killing blow via non-commander damage, life total history over time, turn count, mana/cards, deck lists, archetype tags.

### Constraints

- **Sample size is small.** A playgroup plays maybe 4–12 games/month, and this is filtered to *games with this specific friend in them*. Many friend pairs will have 3–15 shared games, ever. Stats needing 30+ games are dead on arrival.
- Pod size varies (3–5). I know pod size per game via `players.length`.
- Historical games mostly have **unlinked seats** (`firebaseId == null`) because the friends list is new — I'm also building a backfill flow to retro-tag a friend into old games.

### My questions

1. **Rank the stats.** Given the data above, what are the ~8–12 stats you'd actually put on this screen, ranked? What's the single best "headline" stat at the top?
2. **What would you cut** that sounds good but is noise at 10 games?
3. **The rivalry angle.** `opponents` gives me a directed commander-damage graph and `timeOfDeath` gives me elimination order. What's the most interesting thing to extract from those two for a *pair* of players? I'm thinking things like "who outlives whom" and "how much commander damage flows each way" — but tell me what's actually good.
4. **Framing.** In a 4-player pod, is "my win rate vs their win rate in shared games" even meaningful, or do I need to normalize against pod baseline (1/N)? How would you present a win rate so it isn't misread?
5. **Naming.** Give me punchy, format-authentic labels for your picks. The app's existing stats use short titles like "Nemesis", "Best Commander", "Win Rate When First".
6. **Minimum samples.** For each stat you recommend, what's the minimum shared-game count before showing a number instead of "Need more games"?

Answer in-file below.

---

## Round 1 — commander-expert → Claude

I read the models before answering, not just your table. Five things in the code change my answers, so they come first.

### 0. Corrections to the brief (read this before the rankings)

**a. The 21-damage clock is per-*commander*, not per-*player*. Your existing global stat gets this wrong.**

`stats_overview_bloc.dart:506` computes "times killed by commander damage" as:

```dart
final totalFromOpponent = opponent.damages.fold<int>(0, (sum, d) => sum + d.amount);
if (totalFromOpponent >= 21) { count++; break; }
```

That sums the `commander` and `partner` entries. **A Partner pair does not share a clock.** 13 from Commander A plus 12 from Partner B is 25 by that math and kills exactly nobody at a real table. The repository already gets this right — `player_repository.dart:136` uses `p.damages.any((d) => d.amount >= 21)`. So the game ends correctly but the stat over-reports.

Every damage stat on the friend screen must use `any(d.amount >= 21)` for *lethality* and `fold(sum)` only for *volume*. They are different questions. (Pre-existing bug, not yours — flagging it so you don't copy the pattern. Worth its own fix.)

**b. Build the head-to-head ordering from `timeOfDeath`, not `placement`.**

`placement` is derived as `totalPlayers - eliminatedPlayers` at death time (`player_repository.dart:146`), and `_checkPlayerDeath` can *revive* a player (life back above 0 → `placement: Value(null)`, active again). That recomputation can collide: A dies (4) → B dies (3) → A revived → A dies again → `eliminatedPlayers` is now 1, so A gets 4 again. Two players hold placement 4, nobody holds 3.

`timeOfDeath` has none of this. It's epoch millis, strictly ordered, ties are essentially impossible, and the winner gets one at game end. It is the better ordering key. Use `placement == 1` for win detection and `timeOfDeath` for everything comparative.

**c. `placement` and `timeOfDeath` are throwing getters.** Both do `_placement!` and are guarded by `if (!state.isEliminated) throw StateError`. Your backfill flow will be feeding this screen legacy documents. One malformed game and the whole friend screen throws. Read through a nullable accessor and drop games that don't parse — don't let one bad row take out the page.

**d. Do not reuse `_findPlayerInGame`.** `stats_overview_bloc.dart:214` falls back to `game.players.first` when no `firebaseId` matches. On a *personal* stats screen that's merely sloppy. On a *friend* screen it is actively wrong: an unlinked seat would silently attribute Player 1's commander, deaths, and damage to your friend. Given you said most historical games have `firebaseId == null`, this fallback would manufacture a fake rivalry out of nothing.

**The shared-game set must be: games where a seat matches my `firebaseId` AND a *different* seat matches theirs.** No fallback, ever. Everything below assumes that filter.

**e. `durationInSeconds` is not wall-clock.** It's `state.elapsedSeconds` from `TimerBloc` (`game_bloc.dart:231`), and the timer cancels on pause. `timeOfDeath`, `startTime`, and `endTime` are all real `DateTime.now()`. So for "how far into the pod did they die," **normalize against `endTime - startTime`, not `durationInSeconds`** — otherwise a paused game yields survival fractions above 1.0.

Also, minor but useful: `opponents` is seeded with an entry for *every* uuid including the player's own (`game_bloc.dart:91`), each with both damage types at 0. So the list is dense, never null on new games, and contains a self-entry you should skip.

---

### 1. The rankings

First, the constraint that determines everything. **At 3–15 shared pods, percentages are a lie.** A win rate over 11 pods has a standard deviation of roughly ±13 points. "You: 27%, Them: 18%" is one game of noise away from reversing, and users will read those two numbers as a fact about who's better. Show **counts**. "4–2 across 11 pods" is the same information, honestly framed, and it's what people actually say out loud at the table.

Second, the insight that should drive the screen's design:

> **Wins are a 25% event. Outlasting is a 50% event.** In 11 shared pods you get ~3 wins to reason about — nothing. But you get **11** answers to "who finished ahead," because that comparison is defined in *every* shared game, and its baseline is 50% regardless of pod size.

That's a 4x denser signal from identical data, and it sidesteps the 1/N normalization problem entirely. Build the screen around it.

| # | Name | What it shows | Why it earns the space |
|---|---|---|---|
| **1** | **The Ledger** *(headline)* | `7–4` — pods where you finished ahead of them vs. behind | The only pairwise stat with a real sample at n=11. Symmetric, pod-size-independent, 50% baseline. This is the argument-starter. |
| **2** | **Pods Won** | `You 3 · Them 2 · Field 6` over 11 pods | The stat people expect. The `Field` column is what stops it being misread — see Q4. |
| **3** | **Time Alive** | `You last 71% of the pod · Them 54%` | The Ledger's magnitude. Ledger says *who*, this says *by how much*. Bounded [0,1] mean, better-behaved than a rate. |
| **4** | **Final Two** | `Last two standing in 4 of 11` | Deeply Commander. Repeatedly being the last two means you're the pod's two threats — or that you never point anything at each other. Baseline is 1/6 in a 4-pod, so 4/11 is loud. |
| **5** | **The Beatdown** | `You've dealt 63 · Taken 19` commander damage | A count, so honest at any n. Directional. Sparse — see caveats. |
| **6** | **21s** | `You've clocked them twice · They've never clocked you` | Rare, unambiguous, and the best story on the page when it fires. Must use `any(d.amount >= 21)` per clock. |
| **7** | **Their Go-To** | `Atraxa (5 pods)` | What they bring to *your* table. A count, and it's about them, which is the point of the screen. |
| **8** | **Pods Together** | `11 pods since Mar 2025` | Header context, not a tile. Frames every number above it. |
| **9** | **Pod Length** | `Your pods average 1h 47m` | Weak — it's a property of the pod, not the pair. Header line at most. |
| **10** | **Focus Fire** | `38% of your commander damage lands on them (even split: 33%)` | The most *interesting* idea here and the least *reliable*. Genuinely measures targeting. First thing I cut. |

**Headline pick: The Ledger.** Hero tile, big, top of screen. `7–4` with the subtitle "you finish ahead in 7 of 11 pods," and Time Alive as its supporting line. It's the only stat on this list that has both a real sample and a real story at 11 games, and "I outlast you and we both know it" is the exact thing playgroups argue about.

**Ship v1 with 1–8. Cut 9 and 10.** Ten tiles of mostly-empty state is worse than six tiles that all say something. Focus Fire needs a baseline explained in the UI to not be misread, and it's blank for half your pairs — that's a lot of design budget for a stat that no-shows.

---

### 2. What I'd cut (sounds great, is noise at 10 pods)

- **Win Rate When First, pairwise.** You already ship this globally, so it's tempting. In 11 shared 4-pods you went first ~2.75 times. It will read "Need more games" *forever*. Hard cut.
- **Best Commander Against Them.** Win-rate-by-commander, pairwise. You need 3+ pods *per commander* and wins are a 25% event. This asks a 10-game sample to support a 6-way split. Dead on arrival. (Ledger-by-commander — "which of your decks outlasts them" — is 4x denser and *almost* viable at 8+. Still wouldn't ship it v1.)
- **Any head-to-head percentage.** Covered above. Counts only.
- **Average Placement, compared.** `placement` is `totalPlayers - eliminatedPlayers`, so 4th in a 4-pod and 4th in a 5-pod mean completely different things. Averaging across mixed pod sizes produces a number that isn't measuring anything. The Ledger answers this properly.
- **Current Streak vs Them.** Streaks over 10 games are pure noise wearing a narrative costume. It'd be the most-screenshotted tile on the page and it would mean nothing. Cut it precisely *because* it's persuasive.
- **Average commander damage taken from them, per game.** A mean of a zero-inflated sparse variable — most pods contribute 0 and one Voltron pod contributes 40. The mean describes neither. The Beatdown's raw totals are strictly better.
- **"Your win rate with them vs. without them."** Very tempting — "does this friend ruin my games?" — but it compares two small noisy samples to each other and doubles the error. At 11 vs 40 games you need an enormous effect to see anything. Cut, and if you ever build it, gate at 25+ shared.
- **Color/archetype breakdowns, pairwise.** Same split-a-tiny-sample problem. These belong on global stats where n is 60+, and they're already there.

---

### 3. The rivalry angle — what's actually good in that graph

You have a **directed commander-damage graph** plus a **total elimination order**. Ranked by what I'd actually extract:

**1. Damage flow, both directions, as raw totals.** "You've put 63 commander damage into them; they've put 19 into you." Directional, count-based, immediately legible. Note that for *volume* you should sum `commander` + `partner` — a Partner deck's two clocks are two real sources of beatdown, they just don't stack toward 21. Background contributes nothing and your model correctly gives it no `DamageType`, which is right.

**2. Final Two.** Cheap to compute (`{myPlacement, theirPlacement} ⊆ {1,2}`, or better, both `timeOfDeath` values are the pod's two largest) and it's the most *Commander* thing on the list. Being the last two standing repeatedly is a real, readable table dynamic and it's invisible to every other stat.

**3. Focus Fire — targeting bias.** The one genuinely novel thing in the graph. Of all the commander damage you deal in these pods, what share lands on this one friend? Baseline is `1/(podSize-1)` ≈ 33% in a 4-pod. Consistently at 55% means you *target* them, and that is what a rivalry actually is. Compute: for each shared game, for each other player `p`, sum `p.opponents.where(o => o.playerId == myGameId)`. Aggregate, present as raw split (`63 to them / 104 to the rest`) rather than a percentage.

**4. 21s.** Games where `friend.opponents[myId].damages.any(d => d.amount >= 21)`. Rare, so it'll usually be 0–0 — only render the tile when the count is ≥1. When it fires it's the best line on the page.

**The honest caveat you need to design around:** commander damage is **archetype-dependent and sparse**. A spellslinger or combo player deals zero commander damage across their entire history. Two such friends get a screen of zeroes. So: **gate every damage tile on total flow ≥ 21** (one clock's worth, ever) and hide the whole damage section otherwise. Don't render "0 – 0" and call it a rivalry.

**What I would *not* bother with:** "who outlives whom when neither wins" (that's the Ledger with a smaller n), and elimination-gap-in-minutes (that's Time Alive, worse).

---

### 4. Framing the win rate

**Your instinct is right — raw win rate needs normalizing — but the fix isn't 1/4.**

The subtlety: because you're comparing two players *inside the same pods*, the comparison is **paired**. Same games, same table, same opponents. So "my 3 wins vs their 2 wins" is genuinely apples-to-apples between you two — pod composition isn't the confound. Two other things are:

1. **Pod size varies (3–5), so the baseline varies per game.** Handle it exactly: `expectedWins = Σ over shared games of (1 / game.players.length)`. Over 11 pods (mostly 4s) that's ≈ 2.75. No approximation needed — you have `players.length` per game.
2. **The reader imports a 50% baseline from every other game they've played.** 30% *looks* like losing. It's a 20% overperformance.

**How to present it so it can't be misread — show where every pod went:**

> **Pods Won** — 11 together
> **You 3 · Them 2 · Rest of table 6**

That single row does all the work. It's counts, not rates. It's self-normalizing — the reader sees six pods went to other people and instantly recalibrates off 50% without being lectured. And it never implies precision the sample can't support.

If you want the comparison sharpened, add one quiet subtitle: *"Even split would be 2.8 each."* That's `expectedWins`, stated in the units of the tile. Don't ship a "performance index" (`actual/expected`) — at n=11 it swings from 0.4 to 1.6 on two games, and a decimal reads as a measurement.

**Rule for the whole screen: never put a `%` next to a number derived from fewer than ~15 pods.** Percentages imply a precision you have to earn, and at this sample you haven't.

---

### 5. Naming

Matching your existing register (`Nemesis`, `Best Commander`, `Win Rate When First`) — short, title case, table vernacular.

| Stat | Name | Alt |
|---|---|---|
| Pairwise finish record *(headline)* | **The Ledger** | *Outlasted* |
| Wins split three ways | **Pods Won** | *The Score* |
| Mean survival fraction | **Time Alive** | *Survival* |
| Both in top 2 | **Final Two** | *Last Ones Standing* |
| Commander damage traded | **The Beatdown** | *Damage Traded* |
| 21-damage kills | **21s** | *Lethal Clocks* |
| Their most-played commander | **Their Go-To** | *What They Bring* |
| Shared pod count + first date | **Pods Together** | — |
| Targeting bias | **Focus Fire** | *Threat Focus* |

`21s` is the one I'd fight for. It's exactly how players say it, it needs no explanation to anyone who plays the format, and it's opaque enough to non-players to feel like an inside joke — which is the right feeling for a playgroup screen.

Note you already have a naming collision worth knowing about: your global **Nemesis** is defined as "opponent who wins the most" (`stats_overview_bloc.dart:449`), not "who kills you." Players will read the word the second way. Don't reuse `Nemesis` on this screen — `The Ledger` is the pairwise concept and it's honestly named.

---

### 6. Minimum samples

The principle: **counts are honest at n=1; rates need n≥15.** That's why almost everything above is a count — it lets the screen turn on at 3 pods instead of nagging until next year. A playgroup hitting 15 shared pods with a *specific* friend is a year of Commander nights.

| Stat | Min to show a number | Why that number |
|---|---|---|
| **Pods Together** | 1 | Pure count. |
| **The Ledger** | **3** | Below 3, it's just the match list with extra steps. At 3 it's a count and it's true. |
| **Pods Won** | **3** | Same. The `Field` column carries the honesty. |
| **The Beatdown** | 1 pod, but gate on **total flow ≥ 21** | Game count is the wrong gate — damage sparsity is the real one. |
| **21s** | Gate on **≥1 occurrence** | 0–0 is not a stat. Hide the tile. |
| **Their Go-To** | **3** | Needs a modal commander to exist; below 3 there isn't one. |
| **Time Alive** | **5** | It's a mean, not a count. Bounded [0,1] so it converges fast, but 3 is too few for an average. |
| **Final Two** | **5** | Baseline is 1/6. Below 5, one occurrence reads as a pattern. |
| **Pod Length** | 4 | If you ship it. |
| **Focus Fire** | **6 pods AND ≥60 damage dealt by you** | Two gates because it's a ratio *and* sparse. Three clocks' worth before it means anything. |
| *Anything with a `%`* | **15** | And I'd still rather show the count. |

Use your existing `'Need 3+ games'` copy for consistency — but note that with this list, at 3 shared pods the screen already lights up **five** tiles (Pods Together, The Ledger, Pods Won, Their Go-To, + Beatdown if anyone swung). That's a real screen on day one, which is the whole point of preferring counts.

---

### Wishlist — stats I want that your data can't currently answer

Ranked by how much I'd pay for the field.

**1. Who actually killed you. `Player.killedBy` (the dealing player's per-game `id`).**
This is the single biggest gap. *"Who kills you most"* is the best stat in Commander — it's the one that starts fights at the table — and you can currently only answer it for commander damage, which is a small and archetype-skewed slice of all eliminations. Most deaths in real pods come from regular combat, burn, or a combo going off. Right now those deaths are attributed to nobody. **One nullable field set at `_checkPlayerDeath` time** unlocks a true `Nemesis` (and its inverse, `Victim`), pairwise, and it's a *count* — meaning it'd be viable at 3 shared pods. If you build one thing off this list, build this.

**2. Concession as distinct from death.** A `PlayerModelState.conceded` or an `eliminationCause` enum. Right now a scoop looks identical to a kill. That's not a rounding error in Commander — conceding a lost position, and kingmaking on the way out, are real and *social*. It also silently pollutes The Ledger: a friend who scoops early when they're out of it will look like someone you're beating.

**3. Turn count.** `durationInSeconds` measures snacks and rules lookups as much as it measures the game — and it's the *paused* timer besides. "Our pods go 14 turns" is a real statement about your playgroup's speed; "our pods go 1h47m" is a statement about how much you talk. A turn counter would make Pod Length worth shipping.

**4. Non-commander damage graph (or life-total history).** Would give you the full threat-assessment picture — who attacks whom, who gets archenemy'd, who's ahead at the halfway mark. Expensive to capture at the table; I'd take #1 and #2 first, since they're both single fields.

**5. Deck tags — archetype and/or bracket.** *"They bring stax to your table 4 pods out of 11"* is a great line and completely unavailable. It also lets you separate deck power from player skill, which is the thing your stats currently conflate. Needs user input, so it's a product cost, not just a schema one.

**One you might already have:** `playerNumber` is a seat index. **If — and only if — it corresponds to physical seating order,** you can compute whether you two tend to sit adjacent, and neighbors attack each other constantly in Commander, so that's a genuine confound for both The Beatdown and Focus Fire. Worth checking whether the app's seat index tracks the real table. If it does, "Neighbors in 8 of 11 pods" is a fun tile *and* a caveat for the damage stats. If it doesn't, ignore this entirely — don't infer seating from an arbitrary index.
