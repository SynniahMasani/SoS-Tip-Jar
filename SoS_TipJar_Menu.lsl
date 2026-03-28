// SoS Tip Jar v1.2 - Menu Script
// Handles: all owner dialogs, chat commands (delegated from Core),
//          timer for menu timeout, top-10 display, TY message setup
// Communicates via llMessageLinked to Core, Effects, LovenseClub

// ---------------------------------------------------------------
// LINK MESSAGE CONSTANTS  (must match Core, Effects, LovenseClub)
// ---------------------------------------------------------------
// Core -> Menu
integer LM_OPEN_MAIN_MENU  = 101;
integer LM_TOP10_REPORT    = 102;
integer LM_TOP10_CSV       = 103;
integer LM_SHOW_CLOCKOUT   = 104;  // str = "key|name|sessionTotal"
integer LM_SHOW_TY_MENU    = 105;

// Menu -> Core
integer LM_SET_MODE        = 111;
integer LM_SET_VISUAL      = 112;
integer LM_SET_GOAL        = 113;
integer LM_DO_RESET        = 114;
integer LM_SET_PARTICLES   = 115;
integer LM_SET_SOUNDS      = 116;
integer LM_SET_PUBLIC      = 117;
integer LM_SET_SPLIT_ON    = 118;
integer LM_SET_SPLIT_OFF   = 119;
integer LM_REQ_TOP10_RPT   = 120;
integer LM_REQ_TOP10_CSV   = 121;

// Menu -> Effects
integer LM_UPDATE_HT       = 203;

// Menu -> LovenseClub
integer LM_CLOCK_OUT_REQ   = 303;
integer LM_LV_CMD          = 304;
integer LM_SET_CLUB_MODE   = 305;
integer LM_SET_CLUB_PCT    = 306;

// ---------------------------------------------------------------
// LINKSET DATA KEYS  (read here for building menu text)
// ---------------------------------------------------------------
string K_MODE            = "mode";
string K_GOAL_AMOUNT     = "goal_amount";
string K_SESSION_TOTAL   = "session_total";
string K_SESSION_COUNT   = "session_count";
string K_PARTICLES_ON    = "particles_on";
string K_SOUNDS_ON       = "sounds_on";
string K_PUBLIC_MESSAGES = "public_messages";
string K_SPLIT_ENABLED   = "split_enabled";
string K_SPLIT_PARTNER   = "split_partner";
string K_SPLIT_PERCENT   = "split_percent";
string K_VISUAL_MODE     = "visual_mode";
string K_LOVENSE_ON      = "lovense_on";
string K_CLUB_MODE       = "club_mode";
string K_CLUB_SPLIT_PCT  = "club_split_pct";
string K_SESSION_TOP_KEY   = "session_top_key";
string K_SESSION_TOP_NAME  = "session_top_name";
string K_SESSION_TOP_TOTAL = "session_top_total";
string K_ACTIVE_DANCER_KEY  = "active_dancer_key";
string K_ACTIVE_DANCER_NAME = "active_dancer_name";

// ---------------------------------------------------------------
// CUSTOM TY MESSAGE CHANNELS
// ---------------------------------------------------------------
integer DCHAN_TYMSG_PICK = -882001;
integer DCHAN_TYMSG_TEXT = -882002;
integer g_listenTyPick   = 0;
integer g_listenTyText   = 0;
key     g_pendingTyKey   = NULL_KEY;

// ---------------------------------------------------------------
// OWNER MENU DIALOG CHANNELS
// ---------------------------------------------------------------
integer DCHAN_MAIN     = -883001;
integer DCHAN_MODE     = -883002;
integer DCHAN_VISUAL   = -883003;
integer DCHAN_SETTINGS = -883004;
integer DCHAN_SPLIT    = -883005;
integer DCHAN_TOP10    = -883006;
integer DCHAN_GOAL     = -883007;
integer DCHAN_RESET    = -883008;

integer g_listenMain     = 0;
integer g_listenMode     = 0;
integer g_listenVisual   = 0;
integer g_listenSettings = 0;
integer g_listenSplit    = 0;
integer g_listenTop10    = 0;
integer g_listenGoal     = 0;
integer g_listenReset    = 0;

// ---------------------------------------------------------------
// SPLIT DIALOG CHANNELS
// ---------------------------------------------------------------
integer DCHAN_SPLIT_KEY  = -883009;
integer DCHAN_SPLIT_PCT  = -883010;
integer g_listenSplitKey = 0;
integer g_listenSplitPct = 0;
string  g_pendingSplitKey = "";

// ---------------------------------------------------------------
// CLUB MODE CHANNELS
// ---------------------------------------------------------------
integer DCHAN_CLUB      = -883011;
integer DCHAN_CLUB_PCT  = -883012;
integer DCHAN_CLOCKOUT  = -883013;
integer g_listenClub     = 0;
integer g_listenClubPct  = 0;
integer g_listenClockOut = 0;

// ---------------------------------------------------------------
// LOVENSE CHANNELS
// ---------------------------------------------------------------
integer DCHAN_LOVENSE = -884001;
integer g_listenLovense = 0;

// ---------------------------------------------------------------
// TOP 10 CACHE (received from Core via LM_TOP10_CSV)
// ---------------------------------------------------------------
integer TOP_STRIDE         = 3;
list    g_top10Cache       = [];
integer g_waitingTyMenu    = FALSE;  // pending TY picker after top10 arrives

// ---------------------------------------------------------------
// OWNER KEY
// ---------------------------------------------------------------
key g_ownerKey;

// ---------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------
string ldStr(string k) { return llLinksetDataRead(k); }
integer ldInt(string k) { return (integer)llLinksetDataRead(k); }

// ---------------------------------------------------------------
// CLOSE ALL MENUS
// ---------------------------------------------------------------
closeAllMenus()
{
    if (g_listenMain)       { llListenRemove(g_listenMain);       g_listenMain       = 0; }
    if (g_listenMode)       { llListenRemove(g_listenMode);       g_listenMode       = 0; }
    if (g_listenVisual)     { llListenRemove(g_listenVisual);     g_listenVisual     = 0; }
    if (g_listenSettings)   { llListenRemove(g_listenSettings);   g_listenSettings   = 0; }
    if (g_listenSplit)      { llListenRemove(g_listenSplit);      g_listenSplit      = 0; }
    if (g_listenTop10)      { llListenRemove(g_listenTop10);      g_listenTop10      = 0; }
    if (g_listenGoal)       { llListenRemove(g_listenGoal);       g_listenGoal       = 0; }
    if (g_listenReset)      { llListenRemove(g_listenReset);      g_listenReset      = 0; }
    if (g_listenSplitKey)   { llListenRemove(g_listenSplitKey);   g_listenSplitKey   = 0; }
    if (g_listenSplitPct)   { llListenRemove(g_listenSplitPct);   g_listenSplitPct   = 0; }
    if (g_listenClub)       { llListenRemove(g_listenClub);       g_listenClub       = 0; }
    if (g_listenClubPct)    { llListenRemove(g_listenClubPct);    g_listenClubPct    = 0; }
    if (g_listenClockOut)   { llListenRemove(g_listenClockOut);   g_listenClockOut   = 0; }
    if (g_listenLovense)    { llListenRemove(g_listenLovense);    g_listenLovense    = 0; }
}

// ---------------------------------------------------------------
// MENU DISPLAY FUNCTIONS
// ---------------------------------------------------------------
showMainMenu()
{
    string mode;
    string vm;
    string status;
    string topKey;
    string topName;
    integer sessionTotal;
    integer sessionCount;

    closeAllMenus();
    mode         = ldStr(K_MODE);
    vm           = ldStr(K_VISUAL_MODE);
    sessionTotal = ldInt(K_SESSION_TOTAL);
    sessionCount = ldInt(K_SESSION_COUNT);
    topKey       = ldStr(K_SESSION_TOP_KEY);
    topName      = ldStr(K_SESSION_TOP_NAME);

    status = "Mode: " + mode + "  Visual: " + vm;
    if (topKey != "" && (key)topKey != NULL_KEY)
        status += "\nVIP: " + topName;

    g_listenMain = llListen(DCHAN_MAIN, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== SoS TIP JAR ===\n" +
        "Session: L$" + (string)sessionTotal +
        "  Tips: " + (string)sessionCount + "\n" +
        status,
        ["Mode", "Visual", "Goal",
         "VIP", "Top 10", "TY Msg",
         "Split", "Settings", "Reset",
         "Club", "Lovense"],
        DCHAN_MAIN);
    llSetTimerEvent(30.0);
}

showModeMenu()
{
    closeAllMenus();
    g_listenMode = llListen(DCHAN_MODE, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== PERSONALITY MODE ===\n" +
        "Current: " + ldStr(K_MODE) + "\n\n" +
        "RNB      - Smooth and soulful\n" +
        "Standard - Balanced\n" +
        "Hype     - High energy\n" +
        "Trap     - Street/hood",
        ["RNB", "Standard", "Hype", "Trap", "Back"],
        DCHAN_MODE);
    llSetTimerEvent(30.0);
}

showVisualMenu()
{
    closeAllMenus();
    g_listenVisual = llListen(DCHAN_VISUAL, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== VISUAL FEEDBACK ===\n" +
        "Current: " + ldStr(K_VISUAL_MODE) + "\n\n" +
        "Glow      - Jar glows with tips\n" +
        "Particles - Ambient particles grow\n" +
        "Fill      - Prim scales to goal",
        ["Glow", "Particles", "Fill", "Back"],
        DCHAN_VISUAL);
    llSetTimerEvent(30.0);
}

showSettingsMenu()
{
    string partBtn;
    string sndBtn;
    string pubBtn;
    closeAllMenus();
    if (ldInt(K_PARTICLES_ON))    partBtn = "Particles: ON";
    else                           partBtn = "Particles: OFF";
    if (ldInt(K_SOUNDS_ON))        sndBtn  = "Sounds: ON";
    else                           sndBtn  = "Sounds: OFF";
    if (ldInt(K_PUBLIC_MESSAGES))  pubBtn  = "Public: ON";
    else                           pubBtn  = "Public: OFF";

    g_listenSettings = llListen(DCHAN_SETTINGS, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== SETTINGS ===\n" +
        "Toggle each option:",
        [partBtn, sndBtn, pubBtn, "Back"],
        DCHAN_SETTINGS);
    llSetTimerEvent(30.0);
}

showSplitMenu()
{
    string splitStatus;
    string partnerKey;
    closeAllMenus();
    partnerKey = ldStr(K_SPLIT_PARTNER);
    if (ldInt(K_SPLIT_ENABLED) && partnerKey != "" &&
        (key)partnerKey != NULL_KEY)
    {
        splitStatus = "ON - " + llGetDisplayName((key)partnerKey) +
                      " gets " + ldStr(K_SPLIT_PERCENT) + "%";
    }
    else
    {
        splitStatus = "OFF";
    }

    g_listenSplit = llListen(DCHAN_SPLIT, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== TIP SPLIT ===\n" +
        "Status: " + splitStatus + "\n\n" +
        "Enable: use menu (paste UUID)\n" +
        "or type in chat:\n" +
        "!sos split on <uuid> <pct>",
        ["Enable Split", "Split OFF", "Back"],
        DCHAN_SPLIT);
    llSetTimerEvent(60.0);
}

showTop10Menu()
{
    closeAllMenus();
    g_listenTop10 = llListen(DCHAN_TOP10, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== TOP 10 ===\n" +
        "View privately or announce\n" +
        "to local chat?",
        ["View Private", "Announce", "Back"],
        DCHAN_TOP10);
    llSetTimerEvent(30.0);
}

showGoalMenu()
{
    string current;
    integer goal;
    closeAllMenus();
    goal = ldInt(K_GOAL_AMOUNT);
    if (goal > 0)
        current = "Current goal: L$" + (string)goal;
    else
        current = "No goal set.";

    g_listenGoal = llListen(DCHAN_GOAL, "", g_ownerKey, "");
    llTextBox(g_ownerKey,
        "=== SET GOAL ===\n" +
        current + "\n\n" +
        "Type the new L$ goal amount.\n" +
        "Type 0 to clear the goal.",
        DCHAN_GOAL);
    llSetTimerEvent(60.0);
}

showResetConfirm()
{
    closeAllMenus();
    g_listenReset = llListen(DCHAN_RESET, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== RESET SESSION ===\n\n" +
        "Clears session total, tip count,\n" +
        "VIP of the night, and glow.\n\n" +
        "Lifetime totals and top 10\n" +
        "are NOT affected.\n\n" +
        "Are you sure?",
        ["Yes Reset", "Cancel"],
        DCHAN_RESET);
    llSetTimerEvent(30.0);
}

showClubMenu()
{
    string status;
    string dancerKey;
    string dancerName;
    integer clubMode;
    integer clubPct;
    closeAllMenus();
    clubMode   = ldInt(K_CLUB_MODE);
    clubPct    = ldInt(K_CLUB_SPLIT_PCT);
    dancerKey  = ldStr(K_ACTIVE_DANCER_KEY);
    dancerName = ldStr(K_ACTIVE_DANCER_NAME);

    if (clubMode)
    {
        if (dancerKey != "" && (key)dancerKey != NULL_KEY)
            status = "ON - Active: " + dancerName;
        else
            status = "ON - No dancer clocked in";
    }
    else
    {
        status = "OFF";
    }

    g_listenClub = llListen(DCHAN_CLUB, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== CLUB MODE ===\n" +
        "Status: " + status + "\n" +
        "Default split: " + (string)clubPct + "%\n\n" +
        "Group members can clock in\n" +
        "and out at any time.",
        ["Club ON", "Club OFF", "Set Split %",
         "Clock Out Now", "Back"],
        DCHAN_CLUB);
    llSetTimerEvent(30.0);
}

showLovenseMenu()
{
    string lvStatus;
    string target;
    string targetKey;
    closeAllMenus();
    lvStatus  = "OFF";
    target    = "None";
    targetKey = ldStr(K_ACTIVE_DANCER_KEY);
    if (ldInt(K_LOVENSE_ON)) lvStatus = "ON";
    if (targetKey != "" && (key)targetKey != NULL_KEY)
        target = llGetDisplayName((key)targetKey);

    g_listenLovense = llListen(DCHAN_LOVENSE, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== LOVENSE ===\n" +
        "Status: " + lvStatus + "\n" +
        "Target: " + target + "\n\n" +
        "Requires LoveBridge HUD worn\n" +
        "by the clocked-in dancer.\n" +
        "Min tip to activate: L$500",
        ["LV ON", "LV OFF", "Test Buzz",
         "Test Wave", "Test Fire", "Stop Now",
         "Back"],
        DCHAN_LOVENSE);
    llSetTimerEvent(30.0);
}

// ---------------------------------------------------------------
// TY MESSAGE MENU  (async: requests top10 CSV from Core)
// ---------------------------------------------------------------
requestTyMsgMenu()
{
    g_waitingTyMenu = TRUE;
    llMessageLinked(LINK_SET, LM_REQ_TOP10_CSV, "", NULL_KEY);
}

showTyMsgMenuFromCache()
{
    list    buttons;
    integer i;
    integer maxIdx;
    key     av;
    string  shortName;
    buttons = [];
    maxIdx  = llGetListLength(g_top10Cache);

    if (g_listenTyPick) llListenRemove(g_listenTyPick);
    if (maxIdx > TOP_STRIDE * 9) maxIdx = TOP_STRIDE * 9;

    for (i = 0; i < maxIdx; i += TOP_STRIDE)
    {
        av        = llList2Key(g_top10Cache, i);
        shortName = llGetSubString(llGetDisplayName(av), 0, 10);
        buttons  += shortName;
    }
    buttons += "Cancel";

    if (llGetListLength(buttons) <= 1)
    {
        llOwnerSay("SoS: no tippers recorded yet.");
        return;
    }

    g_listenTyPick = llListen(DCHAN_TYMSG_PICK, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== CUSTOM TY MESSAGE ===\n" +
        "Pick a tipper to set a custom\n" +
        "thank you message for:",
        buttons,
        DCHAN_TYMSG_PICK);
    llSetTimerEvent(30.0);
}

// ---------------------------------------------------------------
// DEFAULT STATE
// ---------------------------------------------------------------
default
{
    state_entry()
    {
        g_ownerKey = llGetOwner();
    }

    link_message(integer sender, integer num, string str, key id)
    {
        list    parts;
        string  dancerKey;
        string  dancerName;
        integer dancerTotal;

        if (num == LM_OPEN_MAIN_MENU)
        {
            g_ownerKey = id;
            showMainMenu();
        }
        else if (num == LM_SHOW_TY_MENU)
        {
            requestTyMsgMenu();
        }
        else if (num == LM_TOP10_CSV)
        {
            // Response from Core with top10 data
            if (str != "")
                g_top10Cache = llCSV2List(str);
            else
                g_top10Cache = [];

            if (g_waitingTyMenu)
            {
                g_waitingTyMenu = FALSE;
                showTyMsgMenuFromCache();
            }
        }
        else if (num == LM_SHOW_CLOCKOUT)
        {
            // str = "key|name|sessionTotal"
            parts       = llParseString2List(str, ["|"], []);
            dancerKey   = llList2String(parts, 0);
            dancerName  = llList2String(parts, 1);
            dancerTotal = (integer)llList2String(parts, 2);

            if (g_listenClockOut)
            {
                llListenRemove(g_listenClockOut);
                g_listenClockOut = 0;
            }
            g_listenClockOut = llListen(DCHAN_CLOCKOUT, "", (key)dancerKey, "");
            llDialog((key)dancerKey,
                "=== CLOCK OUT ===\n\n" +
                "You earned L$" + (string)dancerTotal +
                " this session.\n\n" +
                "Are you sure you want to clock out?",
                ["Clock Out", "Stay On"],
                DCHAN_CLOCKOUT);
        }
    }

    listen(integer channel, string name, key id, string msg)
    {
        integer i;
        integer tlen;
        key     av;
        string  shortName;
        string  vipMsg;
        key     testKey;
        integer pct;
        integer newGoal;

        // Dancer clock-out confirm
        if (channel == DCHAN_CLOCKOUT)
        {
            if (g_listenClockOut)
            {
                llListenRemove(g_listenClockOut);
                g_listenClockOut = 0;
            }
            if (msg == "Clock Out")
                llMessageLinked(LINK_SET, LM_CLOCK_OUT_REQ, (string)id, id);
        }

        // Custom TY message - pick tipper
        else if (channel == DCHAN_TYMSG_PICK)
        {
            if (g_listenTyPick) { llListenRemove(g_listenTyPick); g_listenTyPick = 0; }
            llSetTimerEvent(0.0);
            if (msg == "Cancel") return;

            tlen = llGetListLength(g_top10Cache);
            for (i = 0; i < tlen; i += TOP_STRIDE)
            {
                av        = llList2Key(g_top10Cache, i);
                shortName = llGetSubString(llGetDisplayName(av), 0, 10);
                if (shortName == msg)
                {
                    g_pendingTyKey = av;
                    if (g_listenTyText) llListenRemove(g_listenTyText);
                    g_listenTyText = llListen(DCHAN_TYMSG_TEXT, "", g_ownerKey, "");
                    llTextBox(g_ownerKey,
                        "Type a custom TY message for " +
                        llGetDisplayName(av) + ".\n\n" +
                        "Use {name} for their name and {amount} for tip amount.\n\n" +
                        "Example: Hey {name}! L${amount} means everything, thanks!",
                        DCHAN_TYMSG_TEXT);
                    llSetTimerEvent(60.0);
                    return;
                }
            }
            llOwnerSay("SoS: could not find that tipper.");
        }

        // Custom TY message - save text
        else if (channel == DCHAN_TYMSG_TEXT)
        {
            if (g_listenTyText) { llListenRemove(g_listenTyText); g_listenTyText = 0; }
            llSetTimerEvent(0.0);
            if (g_pendingTyKey == NULL_KEY) return;
            llLinksetDataWrite("tymsg_" + (string)g_pendingTyKey, msg);
            llOwnerSay("SoS: custom TY message saved for " +
                       llGetDisplayName(g_pendingTyKey) + ".");
            g_pendingTyKey = NULL_KEY;
        }

        // Main menu
        else if (channel == DCHAN_MAIN)
        {
            if (g_listenMain) { llListenRemove(g_listenMain); g_listenMain = 0; }
            llSetTimerEvent(0.0);

            if (msg == "Mode")           showModeMenu();
            else if (msg == "Visual")    showVisualMenu();
            else if (msg == "Goal")      showGoalMenu();
            else if (msg == "VIP")
            {
                string topKey  = ldStr(K_SESSION_TOP_KEY);
                string topName = ldStr(K_SESSION_TOP_NAME);
                integer topTot = ldInt(K_SESSION_TOP_TOTAL);
                if (topKey == "" || (key)topKey == NULL_KEY)
                    llOwnerSay("SoS: no VIP yet this session.");
                else
                {
                    vipMsg = "* VIP OF THE NIGHT: " + topName +
                             " with L$" + (string)topTot + "! *";
                    llSay(0, vipMsg);
                    llMessageLinked(LINK_SET, LM_UPDATE_HT, "", NULL_KEY);
                }
            }
            else if (msg == "Top 10")    showTop10Menu();
            else if (msg == "TY Msg")    requestTyMsgMenu();
            else if (msg == "Split")     showSplitMenu();
            else if (msg == "Settings")  showSettingsMenu();
            else if (msg == "Reset")     showResetConfirm();
            else if (msg == "Club")      showClubMenu();
            else if (msg == "Lovense")   showLovenseMenu();
        }

        // Mode menu
        else if (channel == DCHAN_MODE)
        {
            if (g_listenMode) { llListenRemove(g_listenMode); g_listenMode = 0; }
            llSetTimerEvent(0.0);

            if (msg == "RNB")           llMessageLinked(LINK_SET, LM_SET_MODE, "RNB",      NULL_KEY);
            else if (msg == "Standard") llMessageLinked(LINK_SET, LM_SET_MODE, "STANDARD", NULL_KEY);
            else if (msg == "Hype")     llMessageLinked(LINK_SET, LM_SET_MODE, "HYPE",     NULL_KEY);
            else if (msg == "Trap")     llMessageLinked(LINK_SET, LM_SET_MODE, "TRAP",     NULL_KEY);

            if (msg != "Back")
            {
                string newMode = "STANDARD";
                if (msg == "RNB")      newMode = "RNB";
                else if (msg == "Hype") newMode = "HYPE";
                else if (msg == "Trap") newMode = "TRAP";
                llLinksetDataWrite(K_MODE, newMode);
                llOwnerSay("SoS: mode set to " + newMode + ".");
            }
            showMainMenu();
        }

        // Visual menu
        else if (channel == DCHAN_VISUAL)
        {
            if (g_listenVisual) { llListenRemove(g_listenVisual); g_listenVisual = 0; }
            llSetTimerEvent(0.0);

            if (msg == "Glow" || msg == "Particles" || msg == "Fill")
            {
                string newVis = llToUpper(msg);
                llLinksetDataWrite(K_VISUAL_MODE, newVis);
                llMessageLinked(LINK_SET, LM_SET_VISUAL, newVis, NULL_KEY);
                llOwnerSay("SoS: visual set to " + newVis + ".");
            }
            showMainMenu();
        }

        // Settings menu
        else if (channel == DCHAN_SETTINGS)
        {
            if (g_listenSettings) { llListenRemove(g_listenSettings); g_listenSettings = 0; }
            llSetTimerEvent(0.0);

            if (msg == "Particles: ON" || msg == "Particles: OFF")
            {
                integer newVal = !ldInt(K_PARTICLES_ON);
                llLinksetDataWrite(K_PARTICLES_ON, (string)newVal);
                llMessageLinked(LINK_SET, LM_SET_PARTICLES, (string)newVal, NULL_KEY);
                if (newVal) llOwnerSay("SoS: particles ON.");
                else        llOwnerSay("SoS: particles OFF.");
                showSettingsMenu();
            }
            else if (msg == "Sounds: ON" || msg == "Sounds: OFF")
            {
                integer newVal = !ldInt(K_SOUNDS_ON);
                llLinksetDataWrite(K_SOUNDS_ON, (string)newVal);
                llMessageLinked(LINK_SET, LM_SET_SOUNDS, (string)newVal, NULL_KEY);
                if (newVal) llOwnerSay("SoS: sounds ON.");
                else        llOwnerSay("SoS: sounds OFF.");
                showSettingsMenu();
            }
            else if (msg == "Public: ON" || msg == "Public: OFF")
            {
                integer newVal = !ldInt(K_PUBLIC_MESSAGES);
                llLinksetDataWrite(K_PUBLIC_MESSAGES, (string)newVal);
                llMessageLinked(LINK_SET, LM_SET_PUBLIC, (string)newVal, NULL_KEY);
                if (newVal) llOwnerSay("SoS: public messages ON.");
                else        llOwnerSay("SoS: public messages OFF.");
                showSettingsMenu();
            }
            else if (msg == "Back")
            {
                showMainMenu();
            }
        }

        // Split menu
        else if (channel == DCHAN_SPLIT)
        {
            if (g_listenSplit) { llListenRemove(g_listenSplit); g_listenSplit = 0; }
            llSetTimerEvent(0.0);

            if (msg == "Enable Split")
            {
                g_pendingSplitKey = "";
                if (g_listenSplitKey) llListenRemove(g_listenSplitKey);
                g_listenSplitKey = llListen(DCHAN_SPLIT_KEY, "", g_ownerKey, "");
                llTextBox(g_ownerKey,
                    "=== ENABLE SPLIT - Step 1 of 2 ===\n\n" +
                    "Open the avatar's profile,\n" +
                    "click ... then Copy Key,\n" +
                    "and paste their UUID here.",
                    DCHAN_SPLIT_KEY);
                llSetTimerEvent(120.0);
            }
            else if (msg == "Split OFF")
            {
                llLinksetDataWrite(K_SPLIT_ENABLED, "0");
                llMessageLinked(LINK_SET, LM_SET_SPLIT_OFF, "", NULL_KEY);
                llOwnerSay("SoS: split disabled.");
                showMainMenu();
            }
            else if (msg == "Back")
            {
                showMainMenu();
            }
        }

        // Split - UUID text box
        else if (channel == DCHAN_SPLIT_KEY)
        {
            if (g_listenSplitKey) { llListenRemove(g_listenSplitKey); g_listenSplitKey = 0; }
            llSetTimerEvent(0.0);

            testKey = (key)msg;
            if (testKey == NULL_KEY || msg == "")
            {
                llOwnerSay("SoS: that does not look like a valid UUID. Split cancelled.");
                showSplitMenu();
                return;
            }

            g_pendingSplitKey = msg;
            if (g_listenSplitPct) llListenRemove(g_listenSplitPct);
            g_listenSplitPct = llListen(DCHAN_SPLIT_PCT, "", g_ownerKey, "");
            llTextBox(g_ownerKey,
                "=== ENABLE SPLIT - Step 2 of 2 ===\n\n" +
                "Partner: " + llGetDisplayName((key)g_pendingSplitKey) + "\n\n" +
                "Enter the percentage of each tip\n" +
                "to send them (1 to 100).\n\n" +
                "Example: type 30 to send 30%\n" +
                "and keep 70% for yourself.",
                DCHAN_SPLIT_PCT);
            llSetTimerEvent(120.0);
        }

        // Split - percent text box
        else if (channel == DCHAN_SPLIT_PCT)
        {
            if (g_listenSplitPct) { llListenRemove(g_listenSplitPct); g_listenSplitPct = 0; }
            llSetTimerEvent(0.0);

            pct = (integer)msg;
            if (pct < 1)   pct = 1;
            if (pct > 100) pct = 100;

            llLinksetDataWrite(K_SPLIT_ENABLED, "1");
            llLinksetDataWrite(K_SPLIT_PARTNER, g_pendingSplitKey);
            llLinksetDataWrite(K_SPLIT_PERCENT, (string)pct);
            llMessageLinked(LINK_SET, LM_SET_SPLIT_ON,
                g_pendingSplitKey + "|" + (string)pct, NULL_KEY);

            llOwnerSay("SoS: split enabled! " +
                       llGetDisplayName((key)g_pendingSplitKey) +
                       " will receive " + (string)pct + "% of each tip.");

            g_pendingSplitKey = "";
            showMainMenu();
        }

        // Top 10 menu
        else if (channel == DCHAN_TOP10)
        {
            if (g_listenTop10) { llListenRemove(g_listenTop10); g_listenTop10 = 0; }
            llSetTimerEvent(0.0);

            if (msg == "View Private")
                llMessageLinked(LINK_SET, LM_REQ_TOP10_RPT, "private", NULL_KEY);
            else if (msg == "Announce")
                llMessageLinked(LINK_SET, LM_REQ_TOP10_RPT, "public", NULL_KEY);

            showMainMenu();
        }

        // Goal text box
        else if (channel == DCHAN_GOAL)
        {
            if (g_listenGoal) { llListenRemove(g_listenGoal); g_listenGoal = 0; }
            llSetTimerEvent(0.0);

            newGoal = (integer)msg;
            if (newGoal < 0) newGoal = 0;
            llLinksetDataWrite(K_GOAL_AMOUNT, (string)newGoal);
            llMessageLinked(LINK_SET, LM_SET_GOAL, (string)newGoal, NULL_KEY);

            if (newGoal > 0)
                llOwnerSay("SoS: goal set to L$" + (string)newGoal + ".");
            else
                llOwnerSay("SoS: goal cleared.");

            showMainMenu();
        }

        // Reset confirm
        else if (channel == DCHAN_RESET)
        {
            if (g_listenReset) { llListenRemove(g_listenReset); g_listenReset = 0; }
            llSetTimerEvent(0.0);

            if (msg == "Yes Reset")
            {
                llMessageLinked(LINK_SET, LM_DO_RESET, "", NULL_KEY);
                llOwnerSay("SoS: session reset.");
            }
            showMainMenu();
        }

        // Club menu
        else if (channel == DCHAN_CLUB)
        {
            if (g_listenClub) { llListenRemove(g_listenClub); g_listenClub = 0; }
            llSetTimerEvent(0.0);

            if (msg == "Club ON")
            {
                llLinksetDataWrite(K_CLUB_MODE, "1");
                llMessageLinked(LINK_SET, LM_SET_CLUB_MODE, "1", NULL_KEY);
                llOwnerSay("SoS: Club Mode ON. Group members can now clock in.");
                showClubMenu();
            }
            else if (msg == "Club OFF")
            {
                llLinksetDataWrite(K_CLUB_MODE, "0");
                llMessageLinked(LINK_SET, LM_SET_CLUB_MODE, "0", NULL_KEY);
                llOwnerSay("SoS: Club Mode OFF.");
                showMainMenu();
            }
            else if (msg == "Set Split %")
            {
                if (g_listenClubPct) llListenRemove(g_listenClubPct);
                g_listenClubPct = llListen(DCHAN_CLUB_PCT, "", g_ownerKey, "");
                llTextBox(g_ownerKey,
                    "=== DEFAULT DANCER SPLIT ===\n\n" +
                    "Current: " + ldStr(K_CLUB_SPLIT_PCT) + "%\n\n" +
                    "Enter the percentage of each tip\n" +
                    "dancers will receive when they\n" +
                    "clock in (1 to 99).\n\n" +
                    "Example: 60 means dancer gets 60%\n" +
                    "and you keep 40%.",
                    DCHAN_CLUB_PCT);
                llSetTimerEvent(60.0);
            }
            else if (msg == "Clock Out Now")
            {
                string dk = ldStr(K_ACTIVE_DANCER_KEY);
                if (dk != "" && (key)dk != NULL_KEY)
                {
                    llMessageLinked(LINK_SET, LM_CLOCK_OUT_REQ, dk, NULL_KEY);
                    llOwnerSay("SoS: dancer clocked out by owner.");
                }
                else
                {
                    llOwnerSay("SoS: no dancer is currently clocked in.");
                }
                showClubMenu();
            }
            else if (msg == "Back")
            {
                showMainMenu();
            }
        }

        // Club split % text box
        else if (channel == DCHAN_CLUB_PCT)
        {
            if (g_listenClubPct) { llListenRemove(g_listenClubPct); g_listenClubPct = 0; }
            llSetTimerEvent(0.0);

            pct = (integer)msg;
            if (pct < 1)  pct = 1;
            if (pct > 99) pct = 99;
            llLinksetDataWrite(K_CLUB_SPLIT_PCT, (string)pct);
            llMessageLinked(LINK_SET, LM_SET_CLUB_PCT, (string)pct, NULL_KEY);
            llOwnerSay("SoS: default dancer split set to " + (string)pct + "%.");
            showClubMenu();
        }

        // Lovense menu
        else if (channel == DCHAN_LOVENSE)
        {
            if (g_listenLovense) { llListenRemove(g_listenLovense); g_listenLovense = 0; }
            llSetTimerEvent(0.0);

            if (msg == "LV ON")
            {
                llLinksetDataWrite(K_LOVENSE_ON, "1");
                llMessageLinked(LINK_SET, LM_LV_CMD, "on", NULL_KEY);
                showLovenseMenu();
            }
            else if (msg == "LV OFF")
            {
                llLinksetDataWrite(K_LOVENSE_ON, "0");
                llMessageLinked(LINK_SET, LM_LV_CMD, "off", NULL_KEY);
                showLovenseMenu();
            }
            else if (msg == "Test Buzz")
            {
                llMessageLinked(LINK_SET, LM_LV_CMD, "buzz", NULL_KEY);
                showLovenseMenu();
            }
            else if (msg == "Test Wave")
            {
                llMessageLinked(LINK_SET, LM_LV_CMD, "wave", NULL_KEY);
                showLovenseMenu();
            }
            else if (msg == "Test Fire")
            {
                llMessageLinked(LINK_SET, LM_LV_CMD, "fire", NULL_KEY);
                showLovenseMenu();
            }
            else if (msg == "Stop Now")
            {
                llMessageLinked(LINK_SET, LM_LV_CMD, "stop", NULL_KEY);
                showLovenseMenu();
            }
            else if (msg == "Back")
            {
                showMainMenu();
            }
        }
    }

    // -- TIMER: menu timeouts ---------------------------------------
    timer()
    {
        closeAllMenus();
        if (g_listenTyPick) { llListenRemove(g_listenTyPick); g_listenTyPick = 0; }
        if (g_listenTyText) { llListenRemove(g_listenTyText); g_listenTyText = 0; }
        g_pendingTyKey    = NULL_KEY;
        g_pendingSplitKey = "";
        g_waitingTyMenu   = FALSE;
        llSetTimerEvent(0.0);
    }

    on_rez(integer param)
    {
        llResetScript();
    }
}
