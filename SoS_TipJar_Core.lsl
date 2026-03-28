// SoS Tip Jar v1.2 - Core Script
// Handles: money events, session tracking, top-10, state save/load,
//          thank-you messages, milestone announcements
// Communicates via llMessageLinked to Menu, Effects, LovenseClub

// ---------------------------------------------------------------
// LINK MESSAGE CONSTANTS  (must match Menu, Effects, LovenseClub)
// ---------------------------------------------------------------
// Core -> Menu
integer LM_OPEN_MAIN_MENU  = 101;  // ask Menu to show main menu
integer LM_TOP10_REPORT    = 102;  // Core -> Menu: str = formatted report
integer LM_TOP10_CSV       = 103;  // Core -> Menu: str = CSV of top10 list
integer LM_SHOW_CLOCKOUT   = 104;  // Core -> Menu: str = "key|name|sessionTotal"
integer LM_SHOW_TY_MENU    = 105;  // Core -> Menu: show TY msg menu

// Menu -> Core (settings changes)
integer LM_SET_MODE        = 111;
integer LM_SET_VISUAL      = 112;
integer LM_SET_GOAL        = 113;  // str = new goal integer
integer LM_DO_RESET        = 114;
integer LM_SET_PARTICLES   = 115;  // str = "0" or "1"
integer LM_SET_SOUNDS      = 116;
integer LM_SET_PUBLIC      = 117;
integer LM_SET_SPLIT_ON    = 118;  // str = "key|pct"
integer LM_SET_SPLIT_OFF   = 119;
integer LM_REQ_TOP10_RPT   = 120;  // Menu -> Core: request report
integer LM_REQ_TOP10_CSV   = 121;  // Menu -> Core: request CSV

// Core -> Effects
integer LM_PLAY_SMALL      = 201;
integer LM_PLAY_BIG        = 202;
integer LM_UPDATE_HT       = 203;
integer LM_RESET_EFFECTS   = 204;
integer LM_VIS_CHANGED     = 205;

// Core -> LovenseClub
integer LM_TIP_TRIGGER     = 301;
integer LM_CLOCK_IN        = 302;  // str = dancer key
integer LM_ADD_DANCER_TIP  = 307;  // str = amount

// LovenseClub -> Core
integer LM_DANCER_IN       = 311;  // str = "key|pct"
integer LM_DANCER_OUT      = 312;

// ---------------------------------------------------------------
// VERSION
// ---------------------------------------------------------------
string VERSION = "1.2";

// ---------------------------------------------------------------
// PERSONALITY MODE CONSTANTS
// ---------------------------------------------------------------
string MODE_RNB      = "RNB";
string MODE_STANDARD = "STANDARD";
string MODE_HYPE     = "HYPE";
string MODE_TRAP     = "TRAP";

// ---------------------------------------------------------------
// TOP 10 STRIDE
// ---------------------------------------------------------------
integer TOP_STRIDE = 3;
integer TOP_MAX    = 10;

// ---------------------------------------------------------------
// LINKSET DATA KEYS
// ---------------------------------------------------------------
string K_MODE            = "mode";
string K_GOAL_AMOUNT     = "goal_amount";
string K_SESSION_TOTAL   = "session_total";
string K_SESSION_COUNT   = "session_count";
string K_LIFETIME_TOTAL  = "lifetime_total";
string K_TOP10           = "top10";
string K_PARTICLES_ON    = "particles_on";
string K_SOUNDS_ON       = "sounds_on";
string K_PUBLIC_MESSAGES = "public_messages";
string K_SPLIT_ENABLED   = "split_enabled";
string K_SPLIT_PARTNER   = "split_partner";
string K_SPLIT_PERCENT   = "split_percent";
string K_VISUAL_MODE     = "visual_mode";
string K_CLUB_MODE       = "club_mode";
string K_CLUB_SPLIT_PCT  = "club_split_pct";
string K_ALL_TIME_TOP    = "all_time_top_tip";
string K_ALL_TIME_NAME   = "all_time_top_name";
// Extra keys written for Effects hover text
string K_SESSION_TOP_KEY   = "session_top_key";
string K_SESSION_TOP_NAME  = "session_top_name";
string K_SESSION_TOP_TOTAL = "session_top_total";
string K_ACTIVE_DANCER_KEY  = "active_dancer_key";
string K_ACTIVE_DANCER_NAME = "active_dancer_name";

// ---------------------------------------------------------------
// OWNER / SESSION GLOBALS
// ---------------------------------------------------------------
key     g_ownerKey;
string  g_ownerName;
integer g_hasDebitPerms  = FALSE;

integer g_sessionTotal    = 0;
integer g_sessionTipCount = 0;
integer g_lifetimeTotal   = 0;

key     g_sessionTopKey    = NULL_KEY;
string  g_sessionTopName   = "";
integer g_sessionTopTotal  = 0;
integer g_sessionTopSingle = 0;

integer g_goalAmount     = 0;
list    g_top10          = [];
list    g_sessionTippers = [];

integer g_allTimeTopTip  = 0;
string  g_allTimeTopName = "";

// Anti-spam: [key, float timestamp] stride-2
list    g_spamList    = [];
float   SPAM_COOLDOWN = 4.0;

string  g_mode           = "STANDARD";
string  g_visualMode     = "GLOW";
integer g_particlesOn    = TRUE;
integer g_soundsOn       = TRUE;
integer g_publicMessages = TRUE;

// ---------------------------------------------------------------
// SPLIT GLOBALS
// ---------------------------------------------------------------
integer g_splitEnabled    = FALSE;
key     g_splitPartnerKey = NULL_KEY;
integer g_splitPercent    = 0;

// ---------------------------------------------------------------
// CLUB MODE (cached - owned by LovenseClub, mirrored here)
// ---------------------------------------------------------------
integer g_clubMode        = FALSE;
key     g_activeDancerKey = NULL_KEY;

// ---------------------------------------------------------------
// LINKSET DATA HELPERS
// ---------------------------------------------------------------
setInt(string k, integer v) { llLinksetDataWrite(k, (string)v); }
setStr(string k, string v)  { llLinksetDataWrite(k, v); }
setKey(string k, key v)     { llLinksetDataWrite(k, (string)v); }

integer getInt(string k)    { return (integer)llLinksetDataRead(k); }
string  getStr(string k)    { return llLinksetDataRead(k); }
key     getKey(string k)    { return (key)llLinksetDataRead(k); }

string keyTyMsg(key av)     { return "tymsg_" + (string)av; }

// ---------------------------------------------------------------
// THANK YOU MESSAGES
// ---------------------------------------------------------------
string getModeTyTemplate()
{
    if (g_mode == MODE_RNB)
        return "Thank you, {name}. L${amount} is appreciated, love.";
    if (g_mode == MODE_HYPE)
        return "{name} just SLID IN with L${amount}! Let's go!";
    if (g_mode == MODE_TRAP)
        return "{name} dropped L${amount}. Real ones show love.";
    return "Thanks for the L${amount}, {name}!";
}

string getModeReturnTemplate()
{
    if (g_mode == MODE_RNB)
        return "Welcome back, {name}. L${amount} more  -  you are too kind, love.";
    if (g_mode == MODE_HYPE)
        return "{name} IS BACK WITH L${amount}! They can't stop, won't stop!";
    if (g_mode == MODE_TRAP)
        return "{name} came back with L${amount}. Loyalty hits different.";
    return "Welcome back, {name}! Another L${amount}  -  you are amazing!";
}

sayThankYou(key tipper, string tipperName, integer amount, integer isReturn)
{
    string customMsg;
    string tmpl;
    string msg;
    customMsg = llLinksetDataRead(keyTyMsg(tipper));
    if (customMsg != "")
        tmpl = customMsg;
    else if (isReturn)
        tmpl = getModeReturnTemplate();
    else
        tmpl = getModeTyTemplate();

    msg = llDumpList2String(
        llParseString2List(tmpl, ["{name}"], []), tipperName);
    msg = llDumpList2String(
        llParseString2List(msg, ["{amount}"], []), (string)amount);

    if (g_publicMessages)
        llSay(0, msg);
    else
        llRegionSayTo(tipper, 0, msg);
}

// ---------------------------------------------------------------
// MILESTONE ANNOUNCEMENTS
// ---------------------------------------------------------------
announceMilestone(integer amount, string name)
{
    string msg;
    msg = "";
    if (!g_publicMessages) return;

    if (amount >= 50000)
    {
        if (g_mode == MODE_RNB)
            msg = "L$50,000... " + name + " just wrote history tonight. Pure royalty.";
        else if (g_mode == MODE_HYPE)
            msg = "FIFTY THOUSAND LINDENBUCKS FROM " + name + "!!! THE BUILDING IS ON FIRE!!!";
        else if (g_mode == MODE_TRAP)
            msg = name + " dropped L$50K. Stack so tall it touched the ceiling. Legendary.";
        else
            msg = "*** L$50,000 from " + name + "! An absolutely legendary tip! ***";
    }
    else if (amount >= 25000)
    {
        if (g_mode == MODE_RNB)
            msg = name + " graced us with L$25,000. Exquisite. Simply exquisite.";
        else if (g_mode == MODE_HYPE)
            msg = "TWENTY FIVE K FROM " + name + "!! WE ARE NOT WORTHY!!!";
        else if (g_mode == MODE_TRAP)
            msg = name + " just slid L$25,000. No cap, that's a whole check.";
        else
            msg = "*** L$25,000 from " + name + "! Absolutely incredible! ***";
    }
    else if (amount >= 10000)
    {
        if (g_mode == MODE_RNB)
            msg = name + " came through with L$10,000. That is love on another level.";
        else if (g_mode == MODE_HYPE)
            msg = "TEN THOUSAND from " + name + "!! THIS IS INSANE!! THE CROWD GOES WILD!!";
        else if (g_mode == MODE_TRAP)
            msg = name + " blessed the jar with L$10K. Big money moves only.";
        else
            msg = "** WOW! L$10,000 from " + name + "! That is beyond generous! **";
    }
    else if (amount >= 5000)
    {
        if (g_mode == MODE_RNB)
            msg = "L$5,000 from " + name + ". That kind of generosity warms the soul.";
        else if (g_mode == MODE_HYPE)
            msg = "FIVE THOUSAND LINDENS from " + name + "!! SOMEBODY STOP THEM!!";
        else if (g_mode == MODE_TRAP)
            msg = name + " just put L$5,000 in the jar. Real ones do real things.";
        else
            msg = "* L$5,000 from " + name + "! You are absolutely amazing! *";
    }
    else if (amount >= 2500)
    {
        if (g_mode == MODE_RNB)
            msg = name + " tipped L$2,500. Smooth and generous, just like the vibe.";
        else if (g_mode == MODE_HYPE)
            msg = name + " just dropped L$2,500!! We see you and we LOVE you!!";
        else if (g_mode == MODE_TRAP)
            msg = name + " hit it with L$2,500. Racks on racks.";
        else
            msg = name + " just tipped L$2,500! Unbelievably generous, thank you!";
    }
    else if (amount >= 1000)
    {
        if (g_mode == MODE_RNB)
            msg = name + " brought L$1,000 to the floor tonight. Appreciate you.";
        else if (g_mode == MODE_HYPE)
            msg = name + " just hit L$1,000!! LET'S GOOO!!";
        else if (g_mode == MODE_TRAP)
            msg = name + " slid in with a band. L$1,000. Respect.";
        else
            msg = "WOW! " + name + " just tipped L$1,000! You are incredible!";
    }
    else if (amount >= 500)
    {
        if (g_mode == MODE_RNB)
            msg = name + " tipped L$500. Classy move. Truly appreciated.";
        else if (g_mode == MODE_HYPE)
            msg = name + " came in with L$500! The energy is UP!!";
        else if (g_mode == MODE_TRAP)
            msg = name + " dropped L$500. That is how we do.";
        else
            msg = name + " tipped L$500! Amazing, thank you so much!";
    }

    if (msg != "")
        llSay(0, msg);
}

announceAllTimeRecord(string name, integer amount)
{
    if (!g_publicMessages) return;
    llSay(0, "NEW ALL-TIME RECORD! " + name + " with L$" + (string)amount + "!");
}

// ---------------------------------------------------------------
// TOP 10
// ---------------------------------------------------------------
updateTop10(key tipper, string tipperName, integer amount)
{
    integer found;
    integer i;
    integer len;
    integer newTotal;
    integer didSwap;
    integer a;
    integer b;
    list    tmp;

    found   = -1;
    didSwap = TRUE;
    len     = llGetListLength(g_top10);

    for (i = 0; i < len; i += TOP_STRIDE)
    {
        if (llList2Key(g_top10, i) == tipper)
        {
            found = i;
            i = len;
        }
    }

    if (found >= 0)
    {
        newTotal = llList2Integer(g_top10, found + 2) + amount;
        g_top10  = llListReplaceList(g_top10,
            [tipper, tipperName, newTotal], found, found + 2);
    }
    else
    {
        newTotal = amount;
        g_top10 += [tipper, tipperName, newTotal];
    }

    len = llGetListLength(g_top10);
    while (didSwap)
    {
        didSwap = FALSE;
        for (i = 0; i < len - TOP_STRIDE; i += TOP_STRIDE)
        {
            a = llList2Integer(g_top10, i + 2);
            b = llList2Integer(g_top10, i + TOP_STRIDE + 2);
            if (b > a)
            {
                tmp     = llList2List(g_top10, i, i + TOP_STRIDE - 1);
                g_top10 = llListReplaceList(g_top10,
                    llList2List(g_top10, i + TOP_STRIDE, i + TOP_STRIDE * 2 - 1),
                    i, i + TOP_STRIDE - 1);
                g_top10 = llListReplaceList(g_top10, tmp,
                    i + TOP_STRIDE, i + TOP_STRIDE * 2 - 1);
                didSwap = TRUE;
            }
        }
    }

    if (llGetListLength(g_top10) > TOP_STRIDE * TOP_MAX)
        g_top10 = llList2List(g_top10, 0, TOP_STRIDE * TOP_MAX - 1);
}

string getTop10Report()
{
    string  report;
    integer i;
    integer rank;
    report = "=== SoS TOP 10 ===\n";
    rank   = 1;
    if (llGetListLength(g_top10) == 0)
        return "SoS: no top 10 data yet.";
    for (i = 0; i < llGetListLength(g_top10); i += TOP_STRIDE)
    {
        report += (string)rank + ". " +
                  llList2String(g_top10, i + 1) +
                  " - L$" + (string)llList2Integer(g_top10, i + 2) + "\n";
        rank += 1;
    }
    return report;
}

// ---------------------------------------------------------------
// STATE SAVE / LOAD
// ---------------------------------------------------------------
saveState()
{
    setStr(K_MODE,              g_mode);
    setInt(K_GOAL_AMOUNT,       g_goalAmount);
    setInt(K_SESSION_TOTAL,     g_sessionTotal);
    setInt(K_SESSION_COUNT,     g_sessionTipCount);
    setInt(K_LIFETIME_TOTAL,    g_lifetimeTotal);
    setInt(K_PARTICLES_ON,      g_particlesOn);
    setInt(K_SOUNDS_ON,         g_soundsOn);
    setInt(K_PUBLIC_MESSAGES,   g_publicMessages);
    setInt(K_SPLIT_ENABLED,     g_splitEnabled);
    setKey(K_SPLIT_PARTNER,     g_splitPartnerKey);
    setInt(K_SPLIT_PERCENT,     g_splitPercent);
    setStr(K_VISUAL_MODE,       g_visualMode);
    setInt(K_CLUB_MODE,         g_clubMode);
    setInt(K_ALL_TIME_TOP,      g_allTimeTopTip);
    setStr(K_ALL_TIME_NAME,     g_allTimeTopName);
    llLinksetDataWrite(K_TOP10, llList2CSV(g_top10));
    // Extra keys used by Effects for hover text
    setStr(K_SESSION_TOP_KEY,   (string)g_sessionTopKey);
    setStr(K_SESSION_TOP_NAME,  g_sessionTopName);
    setInt(K_SESSION_TOP_TOTAL, g_sessionTopTotal);
}

loadState()
{
    string m;
    string vm;
    string atn;
    string top10csv;
    string dk;

    m   = getStr(K_MODE);
    vm  = getStr(K_VISUAL_MODE);
    atn = getStr(K_ALL_TIME_NAME);
    if (m != "")  g_mode       = m;
    if (vm != "") g_visualMode = vm;

    g_goalAmount      = getInt(K_GOAL_AMOUNT);
    g_sessionTotal    = getInt(K_SESSION_TOTAL);
    g_sessionTipCount = getInt(K_SESSION_COUNT);
    g_lifetimeTotal   = getInt(K_LIFETIME_TOTAL);

    if (llLinksetDataRead(K_PARTICLES_ON) != "")
        g_particlesOn = getInt(K_PARTICLES_ON);
    if (llLinksetDataRead(K_SOUNDS_ON) != "")
        g_soundsOn = getInt(K_SOUNDS_ON);
    if (llLinksetDataRead(K_PUBLIC_MESSAGES) != "")
        g_publicMessages = getInt(K_PUBLIC_MESSAGES);

    g_splitEnabled    = getInt(K_SPLIT_ENABLED);
    g_splitPartnerKey = getKey(K_SPLIT_PARTNER);
    g_splitPercent    = getInt(K_SPLIT_PERCENT);

    g_clubMode        = getInt(K_CLUB_MODE);
    g_allTimeTopTip   = getInt(K_ALL_TIME_TOP);
    if (atn != "") g_allTimeTopName = atn;

    top10csv = llLinksetDataRead(K_TOP10);
    if (top10csv != "")
        g_top10 = llCSV2List(top10csv);

    // Restore active dancer key (set by LovenseClub)
    dk = llLinksetDataRead(K_ACTIVE_DANCER_KEY);
    if (dk != "" && (key)dk != NULL_KEY)
        g_activeDancerKey = (key)dk;
}

// ---------------------------------------------------------------
// DEFAULT STATE
// ---------------------------------------------------------------
default
{
    state_entry()
    {
        g_ownerKey  = llGetOwner();
        g_ownerName = llGetDisplayName(g_ownerKey);
        loadState();
        llListen(0, "", g_ownerKey, "");
        // Request debit only if split or club mode was already enabled
        if (g_splitEnabled || g_clubMode)
            llRequestPermissions(g_ownerKey, PERMISSION_DEBIT);
        llMessageLinked(LINK_SET, LM_UPDATE_HT, "", NULL_KEY);
        llOwnerSay("SoS Tip Jar v" + VERSION + " ready. Touch to open menu.");
    }

    run_time_permissions(integer perms)
    {
        if (perms & PERMISSION_DEBIT)
            g_hasDebitPerms = TRUE;
    }

    // -- TOUCH ------------------------------------------------------
    touch_start(integer nd)
    {
        key toucher;
        string activeDancerName;
        toucher = llDetectedKey(0);

        if (toucher == g_ownerKey)
        {
            llMessageLinked(LINK_SET, LM_OPEN_MAIN_MENU, "", g_ownerKey);
            return;
        }

        if (g_clubMode && llSameGroup(toucher))
        {
            activeDancerName = llLinksetDataRead(K_ACTIVE_DANCER_NAME);
            if (toucher == g_activeDancerKey)
            {
                // Ask Menu to show clock-out dialog for dancer
                llMessageLinked(LINK_SET, LM_SHOW_CLOCKOUT,
                    (string)toucher + "|" + activeDancerName + "|" +
                    llLinksetDataRead("dancer_session_total"),
                    toucher);
            }
            else if (g_activeDancerKey == NULL_KEY)
            {
                llMessageLinked(LINK_SET, LM_CLOCK_IN, (string)toucher, toucher);
            }
            else
            {
                llRegionSayTo(toucher, 0,
                    activeDancerName + " is currently on stage. " +
                    "Please wait for them to clock out.");
            }
            return;
        }

        llRegionSayTo(toucher, 0,
            "This tip jar belongs to " + g_ownerName + ".");
    }

    // -- MONEY ------------------------------------------------------
    money(key tipper, integer amount)
    {
        float   now;
        integer spamIdx;
        integer si;
        integer slen;
        string  tipperName;
        integer found;
        integer i;
        integer tlen;
        integer isReturn;
        integer tipperSessionTotal;
        integer newRecord;
        integer splitAmt;
        float   lastTime;

        now     = llGetTime();
        spamIdx = -1;
        slen    = llGetListLength(g_spamList);
        for (si = 0; si < slen; si += 2)
        {
            if (llList2Key(g_spamList, si) == tipper)
            {
                spamIdx = si;
                si = slen;
            }
        }
        if (spamIdx >= 0)
        {
            lastTime = llList2Float(g_spamList, spamIdx + 1);
            if ((now - lastTime) < SPAM_COOLDOWN)
                return;
            g_spamList = llListReplaceList(g_spamList,
                [tipper, now], spamIdx, spamIdx + 1);
        }
        else
        {
            g_spamList += [tipper, now];
            if (llGetListLength(g_spamList) > 60)
                g_spamList = llList2List(g_spamList, 2, -1);
        }

        tipperName = llGetDisplayName(tipper);

        g_sessionTotal    += amount;
        g_sessionTipCount += 1;
        g_lifetimeTotal   += amount;

        if (g_clubMode && g_activeDancerKey != NULL_KEY)
            llMessageLinked(LINK_SET, LM_ADD_DANCER_TIP, (string)amount, NULL_KEY);

        found = -1;
        tlen  = llGetListLength(g_sessionTippers);
        for (i = 0; i < tlen; i += 2)
        {
            if (llList2Key(g_sessionTippers, i) == tipper)
            {
                found = i;
                i = tlen;
            }
        }

        if (found >= 0)
        {
            isReturn           = TRUE;
            tipperSessionTotal = llList2Integer(g_sessionTippers, found + 1) + amount;
            g_sessionTippers   = llListReplaceList(g_sessionTippers,
                [tipper, tipperSessionTotal], found, found + 1);
        }
        else
        {
            isReturn           = FALSE;
            tipperSessionTotal = amount;
            g_sessionTippers  += [tipper, tipperSessionTotal];
        }

        if (g_sessionTopKey == NULL_KEY || tipperSessionTotal > g_sessionTopTotal)
        {
            g_sessionTopKey   = tipper;
            g_sessionTopName  = tipperName;
            g_sessionTopTotal = tipperSessionTotal;
        }

        if (amount > g_sessionTopSingle)
            g_sessionTopSingle = amount;

        newRecord = FALSE;
        if (amount > g_allTimeTopTip)
        {
            g_allTimeTopTip  = amount;
            g_allTimeTopName = tipperName;
            newRecord        = TRUE;
        }

        updateTop10(tipper, tipperName, amount);
        saveState();

        sayThankYou(tipper, tipperName, amount, isReturn);
        announceMilestone(amount, tipperName);

        if (newRecord && g_publicMessages)
            announceAllTimeRecord(tipperName, amount);

        if (amount >= 500)
            llMessageLinked(LINK_SET, LM_PLAY_BIG, "", NULL_KEY);
        else
            llMessageLinked(LINK_SET, LM_PLAY_SMALL, "", NULL_KEY);

        llMessageLinked(LINK_SET, LM_TIP_TRIGGER, (string)amount, NULL_KEY);
        llMessageLinked(LINK_SET, LM_UPDATE_HT, "", NULL_KEY);

        if (g_splitEnabled && g_splitPartnerKey != NULL_KEY && g_hasDebitPerms)
        {
            splitAmt = (integer)((float)amount *
                       (float)g_splitPercent / 100.0);
            if (splitAmt > 0)
                llGiveMoney(g_splitPartnerKey, splitAmt);
        }
    }

    // -- OWNER CHAT COMMANDS ----------------------------------------
    listen(integer channel, string name, key id, string msg)
    {
        list    parts;
        string  cmd;
        string  m;
        string  v;
        string  action;
        string  report;
        string  vipMsg;
        key     partner;
        integer pct;

        if (channel != 0 || id != g_ownerKey) return;

        parts = llParseString2List(llToLower(msg), [" "], []);
        if (llList2String(parts, 0) != "!sos") return;

        cmd = llList2String(parts, 1);

        if (cmd == "mode" && llGetListLength(parts) >= 3)
        {
            m = llToLower(llList2String(parts, 2));
            if (m == "rnb")           g_mode = MODE_RNB;
            else if (m == "standard") g_mode = MODE_STANDARD;
            else if (m == "hype")     g_mode = MODE_HYPE;
            else if (m == "trap")     g_mode = MODE_TRAP;
            setStr(K_MODE, g_mode);
            llOwnerSay("SoS: mode set to " + g_mode + ".");
        }
        else if (cmd == "goal" && llGetListLength(parts) >= 3)
        {
            g_goalAmount = (integer)llList2String(parts, 2);
            if (g_goalAmount < 0) g_goalAmount = 0;
            setInt(K_GOAL_AMOUNT, g_goalAmount);
            llOwnerSay("SoS: goal set to L$" + (string)g_goalAmount + ".");
            llMessageLinked(LINK_SET, LM_UPDATE_HT, "", NULL_KEY);
        }
        else if (cmd == "reset")
        {
            g_sessionTotal     = 0;
            g_sessionTipCount  = 0;
            g_sessionTippers   = [];
            g_sessionTopKey    = NULL_KEY;
            g_sessionTopName   = "";
            g_sessionTopTotal  = 0;
            g_sessionTopSingle = 0;
            saveState();
            llMessageLinked(LINK_SET, LM_RESET_EFFECTS, "", NULL_KEY);
            llMessageLinked(LINK_SET, LM_UPDATE_HT, "", NULL_KEY);
            llOwnerSay("SoS: session reset.");
        }
        else if (cmd == "top10")
        {
            report = getTop10Report();
            if (llGetListLength(parts) >= 3 &&
                llToLower(llList2String(parts, 2)) == "public")
                llSay(0, report);
            else
                llOwnerSay(report);
        }
        else if (cmd == "vip")
        {
            if (g_sessionTopKey == NULL_KEY)
            {
                llOwnerSay("SoS: no VIP yet this session.");
                return;
            }
            vipMsg = "* VIP OF THE NIGHT: " + g_sessionTopName +
                     " with L$" + (string)g_sessionTopTotal + " tipped! *";
            llSay(0, vipMsg);
            llMessageLinked(LINK_SET, LM_UPDATE_HT, "", NULL_KEY);
        }
        else if (cmd == "visual" && llGetListLength(parts) >= 3)
        {
            v = llToLower(llList2String(parts, 2));
            if (v == "fill" || v == "glow" || v == "particles")
            {
                g_visualMode = llToUpper(v);
                setStr(K_VISUAL_MODE, g_visualMode);
                llOwnerSay("SoS: visual mode set to " + g_visualMode + ".");
                llMessageLinked(LINK_SET, LM_VIS_CHANGED, g_visualMode, NULL_KEY);
            }
            else
            {
                llOwnerSay("SoS: valid visual modes are fill, glow, particles.");
            }
        }
        else if (cmd == "tymsg")
        {
            llMessageLinked(LINK_SET, LM_SHOW_TY_MENU, "", g_ownerKey);
        }
        else if (cmd == "split" && llGetListLength(parts) >= 3)
        {
            action = llList2String(parts, 2);
            if (action == "on" && llGetListLength(parts) >= 5)
            {
                partner = (key)llList2String(parts, 3);
                pct     = (integer)llList2String(parts, 4);
                if (partner == NULL_KEY)
                {
                    llOwnerSay("SoS: invalid UUID for split partner.");
                    return;
                }
                if (pct < 1)   pct = 1;
                if (pct > 100) pct = 100;
                g_splitEnabled    = TRUE;
                g_splitPartnerKey = partner;
                g_splitPercent    = pct;
                setInt(K_SPLIT_ENABLED, TRUE);
                setKey(K_SPLIT_PARTNER, partner);
                setInt(K_SPLIT_PERCENT, pct);
                llOwnerSay("SoS: split enabled. " + llGetDisplayName(partner) +
                           " gets " + (string)pct + "%.");
                if (!g_hasDebitPerms)
                    llRequestPermissions(g_ownerKey, PERMISSION_DEBIT);
            }
            else if (action == "off")
            {
                g_splitEnabled    = FALSE;
                g_splitPartnerKey = NULL_KEY;
                g_splitPercent    = 0;
                setInt(K_SPLIT_ENABLED, FALSE);
                setKey(K_SPLIT_PARTNER, NULL_KEY);
                setInt(K_SPLIT_PERCENT, 0);
                llOwnerSay("SoS: split disabled.");
            }
        }
    }

    // -- LINK MESSAGES FROM OTHER SCRIPTS ---------------------------
    link_message(integer sender, integer num, string str, key id)
    {
        list parts;

        if (num == LM_SET_MODE)
        {
            g_mode = str;
        }
        else if (num == LM_SET_VISUAL)
        {
            g_visualMode = str;
            llMessageLinked(LINK_SET, LM_VIS_CHANGED, g_visualMode, NULL_KEY);
        }
        else if (num == LM_SET_GOAL)
        {
            g_goalAmount = (integer)str;
            setInt(K_GOAL_AMOUNT, g_goalAmount);
            llMessageLinked(LINK_SET, LM_UPDATE_HT, "", NULL_KEY);
        }
        else if (num == LM_DO_RESET)
        {
            g_sessionTotal     = 0;
            g_sessionTipCount  = 0;
            g_sessionTippers   = [];
            g_sessionTopKey    = NULL_KEY;
            g_sessionTopName   = "";
            g_sessionTopTotal  = 0;
            g_sessionTopSingle = 0;
            saveState();
            llMessageLinked(LINK_SET, LM_RESET_EFFECTS, "", NULL_KEY);
            llMessageLinked(LINK_SET, LM_UPDATE_HT, "", NULL_KEY);
        }
        else if (num == LM_SET_PARTICLES)
        {
            g_particlesOn = (integer)str;
            setInt(K_PARTICLES_ON, g_particlesOn);
        }
        else if (num == LM_SET_SOUNDS)
        {
            g_soundsOn = (integer)str;
            setInt(K_SOUNDS_ON, g_soundsOn);
        }
        else if (num == LM_SET_PUBLIC)
        {
            g_publicMessages = (integer)str;
            setInt(K_PUBLIC_MESSAGES, g_publicMessages);
        }
        else if (num == LM_SET_SPLIT_ON)
        {
            // str = "key|pct"
            parts             = llParseString2List(str, ["|"], []);
            g_splitEnabled    = TRUE;
            g_splitPartnerKey = (key)llList2String(parts, 0);
            g_splitPercent    = (integer)llList2String(parts, 1);
            setInt(K_SPLIT_ENABLED, TRUE);
            setKey(K_SPLIT_PARTNER, g_splitPartnerKey);
            setInt(K_SPLIT_PERCENT, g_splitPercent);
            if (!g_hasDebitPerms)
                llRequestPermissions(g_ownerKey, PERMISSION_DEBIT);
        }
        else if (num == LM_SET_SPLIT_OFF)
        {
            g_splitEnabled    = FALSE;
            g_splitPartnerKey = NULL_KEY;
            g_splitPercent    = 0;
            setInt(K_SPLIT_ENABLED, FALSE);
            setKey(K_SPLIT_PARTNER, NULL_KEY);
            setInt(K_SPLIT_PERCENT, 0);
        }
        else if (num == LM_REQ_TOP10_RPT)
        {
            // str = "private" or "public" - deliver directly here
            string report = getTop10Report();
            if (str == "public")
                llSay(0, report);
            else
                llOwnerSay(report);
        }
        else if (num == LM_REQ_TOP10_CSV)
        {
            llMessageLinked(LINK_SET, LM_TOP10_CSV, llList2CSV(g_top10), NULL_KEY);
        }
        // Dancer clock-in notification from LovenseClub
        else if (num == LM_DANCER_IN)
        {
            // str = "key|pct"
            parts              = llParseString2List(str, ["|"], []);
            g_activeDancerKey  = (key)llList2String(parts, 0);
            g_splitEnabled     = TRUE;
            g_splitPartnerKey  = g_activeDancerKey;
            g_splitPercent     = (integer)llList2String(parts, 1);
            g_clubMode         = TRUE;
            setInt(K_SPLIT_ENABLED, TRUE);
            setKey(K_SPLIT_PARTNER, g_activeDancerKey);
            setInt(K_SPLIT_PERCENT, g_splitPercent);
            setInt(K_CLUB_MODE,     TRUE);
            if (!g_hasDebitPerms)
                llRequestPermissions(g_ownerKey, PERMISSION_DEBIT);
        }
        // Dancer clock-out notification from LovenseClub
        else if (num == LM_DANCER_OUT)
        {
            g_activeDancerKey = NULL_KEY;
            g_splitEnabled    = FALSE;
            g_splitPartnerKey = NULL_KEY;
            g_splitPercent    = 0;
            setInt(K_SPLIT_ENABLED, FALSE);
            setKey(K_SPLIT_PARTNER, NULL_KEY);
            setInt(K_SPLIT_PERCENT, 0);
        }
    }

    on_rez(integer param)
    {
        llResetScript();
    }
}
