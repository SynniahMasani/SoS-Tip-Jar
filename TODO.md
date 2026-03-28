# SoS Tip Jar v1.2 — Build TODO

## Status Legend
- [ ] Not started
- [~] In progress
- [x] Complete

---

## Change 1 — Remove all void return types
- [x] Remove `void` from setInt()
- [x] Remove `void` from setStr()
- [x] Remove `void` from setKey()
- [x] Remove `void` from setFloat()
- [x] Remove `void` from updateFillPrim()
- [x] Remove `void` from updateHoverText()
- [x] Remove `void` from playSmallParticles()
- [x] Remove `void` from playBigParticles()
- [x] Remove `void` from sayThankYou()
- [x] Remove `void` from announceMilestone()
- [x] Remove `void` from announceVIP()
- [x] Remove `void` from announceAllTimeRecord()
- [x] Remove `void` from loadState()
- [x] Remove `void` from saveState()
- [x] Remove `void` from handleOwnerCommand()

---

## Change 2 — Expand personality modes
- [x] Replace MODE_CHILL with MODE_RNB
- [x] Add MODE_TRAP constant
- [x] Update getModeTyTemplate() for 4 modes
- [x] Update !sos mode command to accept rnb/standard/hype/trap
- [x] Update owner help text (mode line)

---

## Change 3 — Mode-based particles
- [x] playSmallParticles() — RNB branch (purple/soft)
- [x] playSmallParticles() — HYPE branch (fire)
- [x] playSmallParticles() — TRAP branch (green)
- [x] playSmallParticles() — STANDARD fallback (gold)
- [x] playBigParticles() — RNB branch
- [x] playBigParticles() — HYPE branch
- [x] playBigParticles() — TRAP branch
- [x] playBigParticles() — STANDARD fallback

---

## Change 4 — Visual mode system
- [x] Add g_visualMode global (default "GLOW")
- [x] Add g_currentGlow, GLOW_MAX, GLOW_PER_TIP globals
- [x] Add K_VISUAL_MODE linkset data key
- [x] Write updateVisualFeedback() (FILL / GLOW / PARTICLES branches)
- [x] Replace all updateFillPrim() calls with updateVisualFeedback()
- [x] Add !sos visual command to handleOwnerCommand()
- [x] Add glow reset to !sos reset
- [x] Save K_VISUAL_MODE in saveState()
- [x] Load K_VISUAL_MODE in loadState()
- [x] Add visual mode to owner help text

---

## Change 5 — Custom TY messages via dialog
- [x] Add DCHAN_TYMSG_PICK / DCHAN_TYMSG_TEXT globals
- [x] Add g_listenTyPick / g_listenTyText / g_pendingTyKey globals
- [x] Write showTyMsgMenu()
- [x] Handle DCHAN_TYMSG_PICK in listen event
- [x] Handle DCHAN_TYMSG_TEXT in listen event
- [x] Add !sos tymsg command
- [x] Add TY msg listener cleanup in timer event

---

## Change 6 — VIP badge floating text
- [x] Write displayVIPBadge()
- [x] Call displayVIPBadge() from announceVIP()
- [x] Update updateHoverText() to defer to displayVIPBadge() when VIP exists
- [x] Add !sos vip command
- [x] Add vip to owner help text

---

## Change 7 — Public top 10 announce
- [x] Update !sos top10 to accept "public" argument
- [x] Add top10 public to owner help text

---

## Change 8 — Reset clears VIP badge
- [x] Add g_sessionTopKey = NULL_KEY to reset block
- [x] Add g_sessionTopName = "" to reset block
- [x] Call updateHoverText() after reset

---

## Change 9 — Dialog menu system (replaces touch_start text dump)
- [x] Add DCHAN_MAIN through DCHAN_RESET globals (8 channels)
- [x] Add g_listenMain through g_listenReset handle globals
- [x] Write closeAllMenus()
- [x] Write showMainMenu()
- [x] Write showModeMenu()
- [x] Write showVisualMenu()
- [x] Write showSettingsMenu()
- [x] Write showSplitMenu()
- [x] Write showTop10Menu()
- [x] Write showGoalMenu() (uses llTextBox)
- [x] Write showResetConfirm()
- [x] Replace touch_start with menu-opening version
- [x] Handle DCHAN_MAIN in listen event
- [x] Handle DCHAN_MODE in listen event
- [x] Handle DCHAN_VISUAL in listen event
- [x] Handle DCHAN_SETTINGS in listen event (re-opens settings after each toggle)
- [x] Handle DCHAN_SPLIT in listen event
- [x] Handle DCHAN_TOP10 in listen event
- [x] Handle DCHAN_GOAL in listen event
- [x] Handle DCHAN_RESET in listen event
- [x] Call closeAllMenus() at start of timer event
- [x] Non-owner touch returns owner identity message

---

## Change 10 — Full split setup via dialog menu
- [x] Add DCHAN_SPLIT_KEY / DCHAN_SPLIT_PCT globals
- [x] Add g_listenSplitKey / g_listenSplitPct / g_pendingSplitKey globals
- [x] Add split key/pct listeners to closeAllMenus()
- [x] Replace showSplitMenu() with Enable/Off/Back version
- [x] Handle DCHAN_SPLIT Enable Split → opens Step 1 text box
- [x] Handle DCHAN_SPLIT_KEY — validate UUID, proceed to Step 2
- [x] Handle DCHAN_SPLIT_PCT — clamp 1–100, save, request debit perms
- [x] Clear g_pendingSplitKey on timer timeout

---

## Change 11 — Club Mode
- [x] Add g_clubMode, g_clubSplitPct, g_activeDancerKey globals
- [x] Add g_activeDancerName, g_dancerSessionTotal globals
- [x] Add K_CLUB_MODE, K_CLUB_SPLIT_PCT linkset keys
- [x] Add DCHAN_CLUB, DCHAN_CLUB_PCT, DCHAN_CLOCKOUT globals
- [x] Add g_listenClub, g_listenClubPct, g_listenClockOut globals
- [x] Add club listeners to closeAllMenus()
- [x] Save club mode in saveState()
- [x] Load club mode in loadState()
- [x] Write dancerClockIn() — sets split, notifies dancer + owner
- [x] Write dancerClockOut() — resets split, sends earnings summary
- [x] Write showClubMenu()
- [x] Add Club button to showMainMenu()
- [x] Handle DCHAN_CLUB in listen event
- [x] Handle DCHAN_CLUB_PCT in listen event
- [x] Handle DCHAN_CLOCKOUT in listen event
- [x] Update touch_start — group member clock in/out
- [x] Track g_dancerSessionTotal in money() event
- [x] Update updateHoverText() to show dancer name

---

## Change 12 — LoveBridge Lovense Integration
- [x] Add LB_CHAN = -4257001
- [x] Add g_lovenseOn, g_lovenseTarget, g_vibeActive, g_vibeStopTime globals
- [x] Add K_LOVENSE_ON linkset key
- [x] Add DCHAN_LOVENSE, DCHAN_LOVENSE_VIBE globals
- [x] Add g_listenLovense, g_listenLovenseVibe globals
- [x] Add Lovense listeners to closeAllMenus()
- [x] Save Lovense state in saveState()
- [x] Load Lovense state in loadState()
- [x] Write lbSend()
- [x] Write lbStop()
- [x] Write lbTipTrigger() — 3 tier mapping (500/1000/5000)
- [x] Write showLovenseMenu()
- [x] Handle DCHAN_LOVENSE in listen event (ON/OFF/Test/Stop/Back)
- [x] Add Lovense button to showMainMenu()
- [x] Set g_lovenseTarget in dancerClockIn()
- [x] Call lbStop() + clear g_lovenseTarget in dancerClockOut()
- [x] Call lbTipTrigger(amount) at end of money() event
- [x] Check g_vibeStopTime in timer() event, call lbStop() when expired

---

## Final Review Checklist
- [ ] No `void` keyword anywhere in script
- [ ] No ternary operators anywhere
- [ ] No float literals missing decimal points
- [ ] Four modes: RNB, STANDARD, HYPE, TRAP
- [ ] playSmallParticles() has four mode branches
- [ ] playBigParticles() has four mode branches
- [ ] g_visualMode exists, default "GLOW"
- [ ] updateVisualFeedback() replaces all updateFillPrim() calls
- [ ] showTyMsgMenu() opens dialog picker
- [ ] DCHAN_TYMSG_PICK and DCHAN_TYMSG_TEXT handled in listen
- [ ] displayVIPBadge() sets PRIM_TEXT on LINK_ROOT
- [ ] updateHoverText() defers to displayVIPBadge() when VIP exists
- [ ] K_VISUAL_MODE saved and loaded
- [ ] closeAllMenus() cleans up all 15 listeners
- [ ] showMainMenu() opens on owner touch
- [ ] 9 submenus all functional
- [ ] Settings menu re-opens after each toggle
- [ ] Goal uses llTextBox
- [ ] Reset shows confirm dialog
- [ ] Split Enable opens 2-step text box flow
- [ ] UUID validated before proceeding
- [ ] Percentage clamped 1–100
- [ ] Club Mode: clock in/out via group touch
- [ ] g_listenClockOut is global (not local scope)
- [ ] dancerClockIn() sets g_lovenseTarget
- [ ] dancerClockOut() calls lbStop()
- [ ] lbTipTrigger() called at end of money()
- [ ] timer() stops Lovense when duration expires
- [ ] llDialog button lists under 512 chars on all menus
- [ ] All !sos chat commands still work
