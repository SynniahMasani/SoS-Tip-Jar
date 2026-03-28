# SoS Tip Jar v1.2

**Synner or Saynt** — Second Life tip jar script with personality modes, visual feedback, club mode, and Lovense integration.

---

## Features

### Personality Modes
Four modes that change thank-you message style and particle effects:
| Mode | Vibe | Particles |
|------|------|-----------|
| **RNB** | Smooth and soulful | Purple/soft cone |
| **Standard** | Balanced (default) | Gold cone |
| **Hype** | High energy | Fire/explosive |
| **Trap** | Street/hood | Green/money |

### Visual Feedback Modes
Three ways the jar responds visually to tips:
| Mode | Effect |
|------|--------|
| **GLOW** (default) | Root prim glow increases with each tip |
| **PARTICLES** | Ambient particles grow in intensity |
| **FILL** | Child prim scales up toward goal amount |

### Dialog Menu System
Owner touch opens a full dialog HUD — no chat commands required (though all `!sos` commands still work too).

**Main Menu → 11 buttons:**
- **Mode** — Set personality mode
- **Visual** — Set visual feedback mode
- **Goal** — Set/clear session tip goal
- **VIP** — Announce VIP of the night publicly
- **Top 10** — View or publicly announce leaderboard
- **TY Msg** — Set custom thank-you per tipper
- **Split** — Configure tip split (2-step UUID + % flow)
- **Settings** — Toggle particles, sounds, public messages
- **Reset** — Session reset with confirm dialog
- **Club** — Club Mode settings
- **Lovense** — LoveBridge settings

### Tip Split
- Enable via menu (paste UUID, then enter %) or chat: `!sos split on <uuid> <percent>`
- Disable via menu or chat: `!sos split off`
- Requires PERMISSION_DEBIT granted to object

### Club Mode
Group-based hands-off performer system:
- Owner sets default split % once
- Any group member can **touch the jar to clock in** — split auto-configures
- Active dancer touches again to **clock out** (confirm dialog)
- Owner can force clock out via Club menu
- Hover text shows active dancer name
- Dancer receives earnings summary on clock out
- Owner receives clock in/out notifications

### VIP Badge
- Top tipper of the session displayed as floating PRIM_TEXT on root prim
- Updates automatically after each tip
- Manually announce with VIP menu button or `!sos vip`

### Custom TY Messages
- Set a unique thank-you message per tipper via the TY Msg menu
- Supports `{name}` and `{amount}` placeholders

### Top 10 Leaderboard
- All-time leaderboard, persisted in llLinksetData
- View privately (owner only) or announce to local chat

### LoveBridge (Lovense Integration)
Completely independent system — no connection to modes or other features.
- Requires LoveBridge HUD worn by the clocked-in dancer
- Only fires when a dancer is clocked in AND Lovense is ON
- Minimum L$500 tip to activate

| Tip Amount | Pattern | Duration |
|------------|---------|----------|
| L$500–999 | Wave (pattern 2) | 5s |
| L$1,000–4,999 | Fireworks (pattern 3) | 8s |
| L$5,000+ | Full power custom | 12s |

Commands sent via `llRegionSayTo` on channel `-4257001`.
Format: `recipientKey|command`

---

## Chat Commands

All commands prefixed with `!sos` in local chat (owner only):

```
!sos mode rnb|standard|hype|trap
!sos goal <amount>
!sos reset
!sos top10
!sos top10 public
!sos vip
!sos visual fill|glow|particles
!sos tymsg
!sos split on <uuid> <percent>
!sos split off
```

---

## Setup

1. Rez the jar in-world
2. Grant PERMISSION_DEBIT when prompted (required for tip split payouts)
3. Touch the jar to open the owner menu
4. Set your preferred mode, visual, and goal
5. For Club Mode: enable it via the Club menu and set your default dancer split %
6. For Lovense: enable it via the Lovense menu (dancer must have LoveBridge HUD)

---

## LSL Technical Notes

- Uses `llLinksetData` for persistent storage across restarts
- No `void` return types (LSL compliance)
- No ternary operators
- All float literals include decimal points
- All dialog listener handles properly cleaned up on timer timeout via `closeAllMenus()`
- `state` keyword never used as variable name

---

## File

- `SoS_TipJar.lsl` — full script, drop into object root prim

---

## Version History

| Version | Notes |
|---------|-------|
| 1.2 | Full rewrite: dialog menus, Club Mode, Lovense, 4 modes, visual feedback, VIP badge |
| 1.1 | Particles, split, top 10, custom TY messages |
| 1.0 | Initial release |
