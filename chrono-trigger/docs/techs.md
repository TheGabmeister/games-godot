# Chrono Trigger — Tech Data Tables

Referenced from [SPEC.md §2.2](../SPEC.md). SNES original names used throughout.

**TP is cumulative** — a character earning 400 total TP unlocks every tech up to and including the 400 threshold. TP is not spent.

**MP in Dual/Triple Techs** — each character pays their own MP cost. The "Total MP" column is the sum.

**Spekkio techs** — the 3rd tech for Crono (Lightning), Marle (Ice), Lucca (Fire), and Frog (Water) is granted free by Spekkio at the End of Time, not earned via TP.

---

## Single Techs

### Crono

| # | Tech | TP | MP | Element | Target | Effect |
|---|------|---:|---:|---------|--------|--------|
| 1 | Cyclone | 5 | 2 | None | circle around self | spin-slash nearby enemies |
| 2 | Slash | 90 | 2 | None | line | dash-slash enemies in a line |
| 3 | Lightning | Spekkio | 2 | Lightning | single enemy | bolt of lightning |
| 4 | Spincut | 160 | 4 | None | single enemy | leap-slash |
| 5 | Life | 400 | 10 | None | single ally | revive KO'd ally (partial HP) |
| 6 | Lightning 2 | 500 | 8 | Lightning | all enemies | lightning on all |
| 7 | Confuse | 800 | 12 | None | single enemy | multi-hit dash-slash; inflicts Chaos status |
| 8 | Luminaire | 1000 | 20 | Lightning | all enemies | massive lightning sphere |

### Marle

| # | Tech | TP | MP | Element | Target | Effect |
|---|------|---:|---:|---------|--------|--------|
| 1 | Aura | 10 | 1 | None | single ally | small HP restore |
| 2 | Provoke | 50 | 1 | None | single enemy | inflicts Chaos |
| 3 | Ice | Spekkio | 2 | Water | single enemy | ice shard |
| 4 | Cure | 150 | 2 | None | single ally | moderate HP restore |
| 5 | Haste | 250 | 6 | None | single ally | doubles ATB fill rate |
| 6 | Ice 2 | 400 | 8 | Water | all enemies | ice shards on all |
| 7 | Cure 2 | 600 | 5 | None | all allies | party HP restore |
| 8 | Life 2 | 900 | 15 | None | single ally | revive with full HP |

### Lucca

| # | Tech | TP | MP | Element | Target | Effect |
|---|------|---:|---:|---------|--------|--------|
| 1 | Flame Toss | 10 | 1 | Fire | line | burn enemies in a line |
| 2 | Hypno Wave | 60 | 1 | None | all enemies | attempt Sleep on all |
| 3 | Fire | Spekkio | 2 | Fire | circle | fire on enemies in a circle |
| 4 | Napalm | 160 | 3 | Fire | circle | fire bomb on area |
| 5 | Protect | 250 | 6 | None | single ally | raise magic defense |
| 6 | Fire 2 | 400 | 8 | Fire | all enemies | flames on all |
| 7 | Mega Bomb | 600 | 15 | Fire | circle | large fire explosion on area |
| 8 | Flare | 1000 | 20 | Fire | single enemy | massive fire blast |

### Robo

| # | Tech | TP | MP | Element | Target | Effect |
|---|------|---:|---:|---------|--------|--------|
| 1 | Rocket Punch | 5 | 1 | None | single enemy | launch fist |
| 2 | Cure Beam | 5 | 2 | None | single ally | heal one ally |
| 3 | Laser Spin | 5 | 3 | None | circle around self | spin-attack nearby enemies |
| 4 | Robo Tackle | 150 | 4 | None | single enemy | charge and slam |
| 5 | Heal Beam | 400 | 3 | None | all allies | party HP restore |
| 6 | Uzzi Punch | 600 | 12 | None | single enemy | rapid multi-hit |
| 7 | Area Bomb | 800 | 14 | None | all enemies | explosive attack on all |
| 8 | Shock | 1000 | 17 | Shadow | all enemies | electrical shock wave |

Robo does not visit Spekkio. All his techs are TP-learned.

### Frog

| # | Tech | TP | MP | Element | Target | Effect |
|---|------|---:|---:|---------|--------|--------|
| 1 | Slurp | 10 | 1 | None | single ally | small heal |
| 2 | Slurp Cut | 100 | 2 | None | single enemy | tongue-lash slash |
| 3 | Water | Spekkio | 2 | Water | single enemy | water bubble |
| 4 | Heal | 150 | 2 | None | all allies | heal all + cure status |
| 5 | Leap Slash | 250 | 4 | None | single enemy | leaping sword strike |
| 6 | Water 2 | 400 | 8 | Water | all enemies | water surge on all |
| 7 | Cure 2 | 600 | 5 | None | all allies | large party HP restore |
| 8 | Frog Squash | 1000 | 15 | None | all enemies | body slam; **damage scales inversely with Frog's current HP** |

### Ayla

| # | Tech | TP | MP | Element | Target | Effect |
|---|------|---:|---:|---------|--------|--------|
| 1 | Kiss | 10 | 1 | None | single ally | small heal + cure status |
| 2 | Rollo Kick | 60 | 2 | None | single enemy | jump-kick |
| 3 | Cat Attack | 100 | 3 | None | single enemy | claw attack |
| 4 | Rock Throw | 200 | 4 | None | single enemy | grab + lob enemy at another |
| 5 | Charm | 400 | 4 | None | single enemy | steal item (see §6.5) |
| 6 | Tail Spin | 600 | 10 | None | circle around self | spin-strike nearby |
| 7 | Dino Tail | 800 | 15 | None | all enemies | **damage scales inversely with Ayla's HP** |
| 8 | Triple Kick | 1000 | 20 | None | single enemy | three consecutive kicks |

Ayla does not visit Spekkio. All techs are physical.

### Magus

| # | Tech | TP | MP | Element | Target | Effect |
|---|------|---:|---:|---------|--------|--------|
| 1 | Lightning 2 | * | 8 | Lightning | all enemies | ~30% stronger than Crono's |
| 2 | Ice 2 | * | 8 | Water | all enemies | ~30% stronger than Marle's |
| 3 | Fire 2 | * | 8 | Fire | all enemies | ~30% stronger than Lucca's |
| 4 | Dark Bomb | 400 | 8 | Shadow | circle | shadow explosion on area |
| 5 | Magic Wall | 400 | 8 | None | all allies | party-wide Barrier (M.Def up) |
| 6 | Dark Mist | 400 | 10 | Shadow | all enemies | shadow damage on all |
| 7 | Black Hole | 900 | 15 | Shadow | all enemies | attempt instant KO on all |
| 8 | Dark Matter | 900 | 20 | Shadow | all enemies | massive shadow damage |

\* Magus joins with all 8 techs already learned. Lightning 2, Ice 2, Fire 2 require no TP. He never visits Spekkio.

---

## Dual Techs

Magus has **no** standard Dual Techs in the SNES original. His only combo involvement is via Rock-accessory Triple Techs.

### Crono + Marle

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Aura Whirl | Cyclone (2) + Aura (1) | 3 | None | all allies | small party heal |
| Ice Sword | Spincut (4) + Ice (2) | 6 | Water | single | ice-enchanted blade |
| Ice Sword 2 | Confuse (12) + Ice 2 (8) | 20 | Water | circle | multi-hit ice blade |

### Crono + Lucca

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Fire Whirl | Cyclone (2) + Flame Toss (1) | 3 | Fire | circle | fire spin |
| Fire Sword | Spincut (4) + Fire (2) | 6 | Fire | single | fire-enchanted blade |
| Fire Sword 2 | Confuse (12) + Fire 2 (8) | 20 | Fire | circle | multi-hit fire blade |

### Crono + Robo

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Rocket Roll | Cyclone (2) + Laser Spin (3) | 5 | None | all enemies | combined spin |
| Max Cyclone | Spincut (4) + Laser Spin (3) | 7 | None | single | powerful combined slash |
| Super Volt | Lightning 2 (8) + Shock (17) | 25 | Lightning | all enemies | massive electrical discharge |

### Crono + Frog

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| X Strike | Slash (2) + Slurp Cut (2) | 4 | None | single | cross-slash from both sides |
| Sword Stream | Spincut (4) + Water 2 (8) | 12 | Water | single | water-blade strike |
| Spire | Lightning 2 (8) + Leap Slash (4) | 12 | Lightning | single | lightning-charged leap |

### Crono + Ayla

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Drill Kick | Cyclone (2) + Rollo Kick (2) | 4 | None | single | spinning kick |
| Volt Bite | Lightning 2 (8) + Cat Attack (3) | 11 | Lightning | single | lightning claw |
| Falcon Hit | Spincut (4) + Rock Throw (4) | 8 | None | single | Crono launched at enemy |

### Marle + Lucca

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Antipode | Ice (2) + Fire (2) | 4 | Shadow | circle | fire-ice explosion |
| Antipode 2 | Ice 2 (8) + Fire 2 (8) | 16 | Shadow | circle | stronger fire-ice |
| Antipode 3 | Ice 2 (8) + Flare (20) | 28 | Shadow | all enemies | massive fire-ice blast |

### Marle + Robo

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Aura Beam | Aura (1) + Cure Beam (2) | 3 | None | all allies | moderate party heal |
| Ice Tackle | Ice (2) + Robo Tackle (4) | 6 | Water | single | ice-encased charge |
| Cure Touch | Cure 2 (5) + Heal Beam (3) | 8 | None | all allies | full party HP restore |

### Marle + Frog

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Ice Water | Ice (2) + Water (2) | 4 | Water | all enemies | ice-water blast |
| Glacier | Ice 2 (8) + Water 2 (8) | 16 | Water | single | massive ice-water |
| Double Cure | Cure 2 (5) + Cure 2 (5) | 10 | None | all allies | full party HP restore |

### Marle + Ayla

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Twin Charm | Provoke (1) + Charm (4) | 5 | None | single | improved steal attempt |
| Ice Toss | Ice (2) + Rock Throw (4) | 6 | Water | single | lob ice-encased enemy |
| Cube Toss | Ice 2 (8) + Rock Throw (4) | 12 | Water | circle | lob giant ice cube |

### Lucca + Robo

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Fire Punch | Fire (2) + Rocket Punch (1) | 3 | Fire | single | fire-engulfed punch |
| Fire Tackle | Fire 2 (8) + Robo Tackle (4) | 12 | Fire | single | blazing charge |
| Double Bomb | Mega Bomb (15) + Area Bomb (14) | 29 | Fire | all enemies | dual explosive barrage |

### Lucca + Frog

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Red Pin | Fire (2) + Leap Slash (4) | 6 | Fire | single | fire-charged leap slash |
| Line Bomb | Mega Bomb (15) + Leap Slash (4) | 19 | Fire | line | fire bomb across a line |
| Frog Flare | Flare (20) + Frog Squash (15) | 35 | Fire | all enemies | devastating fire + squash |

### Lucca + Ayla

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Flame Kick | Fire (2) + Rollo Kick (2) | 4 | Fire | single | fiery kick |
| Fire Whirl | Fire 2 (8) + Tail Spin (10) | 18 | Fire | circle | fire tornado |
| Blaze Kick | Fire 2 (8) + Triple Kick (20) | 28 | Fire | single | triple fire kick |

### Robo + Frog

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Blade Toss | Laser Spin (3) + Slurp Cut (2) | 5 | None | single | Robo hurls Frog for spinning slash |
| Bubble Hit | Robo Tackle (4) + Water (2) | 6 | Water | single | drop Robo in water bubble |
| Cure Wave | Heal Beam (3) + Cure 2 (5) | 8 | None | all allies | full party HP restore |

### Robo + Ayla

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Boogie | Laser Spin (3) + Rollo Kick (2) | 5 | None | all enemies | inflict Stop |
| Spin Kick | Robo Tackle (4) + Triple Kick (20) | 24 | None | single | combined spin + triple kick |
| Beast Toss | Uzzi Punch (12) + Rock Throw (4) | 16 | None | single | hurl Robo at enemy |

### Frog + Ayla

| Dual Tech | Prereqs (MP each) | Total MP | Element | Target | Effect |
|---|---|---:|---|---|---|
| Slurp Kiss | Slurp (1) + Kiss (1) | 2 | None | all allies | party heal + cure status (very MP-efficient) |
| Bubble Burst | Water (2) + Rollo Kick (2) | 4 | Water | single | water bubble strike |
| Drop Kick | Leap Slash (4) + Triple Kick (20) | 24 | None | single | combined leap-kick |

---

## Triple Techs

### Standard (all require Crono)

| Triple Tech | Characters | Prereqs (MP each) | Total MP | Element | Target |
|---|---|---|---:|---|---|
| Delta Force | Crono + Marle + Lucca | Lightning 2 (8) + Ice 2 (8) + Fire 2 (8) | 24 | Shadow | all enemies |
| Lifeline | Crono + Marle + Robo | Life (10) + Life 2 (15) + Laser Spin (3) | 28 | None | all allies |
| Arc Impulse | Crono + Marle + Frog | Spincut (4) + Ice 2 (8) + Leap Slash (4) | 16 | Water | single |
| Final Kick | Crono + Marle + Ayla | Lightning 2 (8) + Ice 2 (8) + Triple Kick (20) | 36 | None | single |
| Fire Zone | Crono + Lucca + Robo | Spincut (4) + Fire 2 (8) + Laser Spin (3) | 15 | Fire | circle |
| Delta Storm | Crono + Lucca + Frog | Lightning 2 (8) + Fire 2 (8) + Water 2 (8) | 24 | Shadow | all enemies |
| Gatling Kick | Crono + Lucca + Ayla | Lightning 2 (8) + Fire 2 (8) + Triple Kick (20) | 36 | None | single |
| Triple Attack | Crono + Robo + Frog | Spincut (4) + Robo Tackle (4) + Leap Slash (4) | 12 | None | single |
| Twister | Crono + Robo + Ayla | Cyclone (2) + Laser Spin (3) + Tail Spin (10) | 15 | None | all enemies |
| 3D Attack | Crono + Frog + Ayla | Cyclone (2) + Slurp Cut (2) + Triple Kick (20) | 24 | None | single |

### Rock-accessory Triple Techs

| Triple Tech | Characters | Prereqs (MP each) | Total MP | Element | Target | Rock |
|---|---|---|---:|---|---|---|
| Spin Strike | Frog + Robo + Ayla | Leap Slash (4) + Robo Tackle (4) + Tail Spin (10) | 18 | None | single | Silver Rock |
| Poyozo Dance | Marle + Lucca + Ayla | Provoke (1) + Hypno Wave (1) + Triple Kick (20) | 22 | None | all enemies | White Rock |
| Grand Dream | Marle + Frog + Robo | Life 2 (15) + Frog Squash (15) + Heal Beam (3) | 33 | None | all enemies | Gold Rock |
| Omega Flare | Lucca + Robo + Magus | Flare (20) + Laser Spin (3) + Dark Bomb (8) | 31 | None | all enemies | Blue Rock |
| Dark Eternal | Marle + Lucca + Magus | Ice 2 (8) + Fire 2 (8) + Dark Matter (20) | 36 | Shadow | all enemies | Black Rock |

---

## Sources

- [StrategyWiki — Chrono Trigger/Techniques](https://strategywiki.org/wiki/Chrono_Trigger/Techniques)
- [Thonky — Chrono Trigger Techs](https://www.thonky.com/chrono-trigger/techs)
- [GameFAQs — Technique FAQ (MostSeriousness)](https://gamefaqs.gamespot.com/ds/950181-chrono-trigger/faqs/55096)
- [GameFAQs — Technique Checklist (PFritz21)](https://gamefaqs.gamespot.com/snes/563538-chrono-trigger/faqs/11022)
- [Chrono Trigger Wiki — Techs](https://chronotrigger.wiki.gg/wiki/Techs)
- [Almar's Guides — Abilities](https://www.almarsguides.com/retro/walkthroughs/snes/games/ChronoTrigger/Misc/Lists/Abilities/)
