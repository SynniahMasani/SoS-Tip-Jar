// SoS Tip Jar v1.2 - LovenseClub Script
// Handles: LoveBridge/Lovense integration, Club Mode clock in/out
// Receives triggers via llMessageLinked from Core and Menu scripts

// ---------------------------------------------------------------
// LINK MESSAGE CONSTANTS  (must match Core, Menu, Effects)
// ---------------------------------------------------------------
integer LM_UPDATE_HT     = 203;  // -> Effects: refresh hover text

integer LM_TIP_TRIGGER   = 301;  // Core -> here: num = tip amount
integer LM_CLOCK_IN      = 302;  // Core -> here: str = dancer key
integer LM_CLOCK_OUT_REQ = 303;  // Menu -> here: str = dancer key (force out)
integer LM_LV_CMD        = 304;  // Menu -> here: str = command string
integer LM_SET_CLUB_MODE = 305;  // Menu -> here: num = 0/1
integer LM_SET_CLUB_PCT  = 306;  // Menu -> here: num = new pct
integer LM_ADD_DANCER_TIP = 307; // Core -> here: str = amount (increment dancer total)

integer LM_DANCER_IN     = 311;  // here -> Core: str = "key|pct"
integer LM_DANCER_OUT    = 312;  // here -> Core (no payload)

// ---------------------------------------------------------------
// LINKSET DATA KEYS
// ---------------------------------------------------------------
string K_LOVENSE_ON      = "lovense_on";
string K_CLUB_MODE       = "club_mode";
string K_CLUB_SPLIT_PCT  = "club_split_pct";
string K_SPLIT_ENABLED   = "split_enabled";
string K_SPLIT_PARTNER   = "split_partner";
string K_SPLIT_PERCENT   = "split_percent";
string K_ACTIVE_DANCER_KEY  = "active_dancer_key";
string K_ACTIVE_DANCER_NAME = "active_dancer_name";

// ---------------------------------------------------------------
// LOVEBRIDGE / LOVENSE GLOBALS
// ---------------------------------------------------------------
integer LB_CHAN          = -4257001;
integer g_lovenseOn      = FALSE;
key     g_lovenseTarget  = NULL_KEY;
integer g_vibeActive     = FALSE;
float   g_vibeStopTime   = 0.0;

// ---------------------------------------------------------------
// CLUB MODE GLOBALS
// ---------------------------------------------------------------
integer g_clubMode           = FALSE;
integer g_clubSplitPct       = 50;
key     g_activeDancerKey    = NULL_KEY;
string  g_activeDancerName   = "";
integer g_dancerSessionTotal = 0;

// ---------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------
integer ldInt(string k) { return (integer)llLinksetDataRead(k); }
string  ldStr(string k) { return llLinksetDataRead(k); }
setInt(string k, integer v)  { llLinksetDataWrite(k, (string)v); }
setKey(string k, key v)      { llLinksetDataWrite(k, (string)v); }
setStr(string k, string v)   { llLinksetDataWrite(k, v); }

// ---------------------------------------------------------------
// LOVEBRIDGE FUNCTIONS
// ---------------------------------------------------------------
lbSend(string cmd)
{
    if (g_lovenseTarget == NULL_KEY) return;
    llRegionSayTo(g_lovenseTarget, LB_CHAN,
        (string)g_lovenseTarget + "|" + cmd);
}

lbStop()
{
    if (g_lovenseTarget == NULL_KEY) return;
    llRegionSayTo(g_lovenseTarget, LB_CHAN,
        (string)g_lovenseTarget + "|vibrate|0");
    g_vibeActive   = FALSE;
    g_vibeStopTime = 0.0;
}

lbTipTrigger(integer amount)
{
    string cmd;
    float  duration;
    if (!g_lovenseOn)                return;
    if (g_lovenseTarget == NULL_KEY) return;
    if (amount < 500)                return;

    if (amount >= 5000)
    {
        cmd      = "cpatt|150|20,20,18,20,20,0,20,20,18,20,20,0,20,20,20";
        duration = 12.0;
    }
    else if (amount >= 1000)
    {
        cmd      = "pattern|3";
        duration = 8.0;
    }
    else
    {
        cmd      = "pattern|2";
        duration = 5.0;
    }

    lbSend(cmd);
    g_vibeActive   = TRUE;
    g_vibeStopTime = llGetTime() + duration;
    llSetTimerEvent(duration + 0.5);
}

// ---------------------------------------------------------------
// CLUB MODE FUNCTIONS
// ---------------------------------------------------------------
dancerClockIn(key dancer)
{
    key     ownerKey;
    integer pct;
    ownerKey = llGetOwner();
    pct      = g_clubSplitPct;

    g_lovenseTarget      = dancer;
    g_activeDancerKey    = dancer;
    g_activeDancerName   = llGetDisplayName(dancer);
    g_dancerSessionTotal = 0;

    setInt(K_SPLIT_ENABLED, TRUE);
    setKey(K_SPLIT_PARTNER, dancer);
    setInt(K_SPLIT_PERCENT, pct);
    setStr(K_ACTIVE_DANCER_KEY,  (string)dancer);
    setStr(K_ACTIVE_DANCER_NAME, g_activeDancerName);
    llLinksetDataWrite("dancer_session_total", "0");

    llRegionSayTo(dancer, 0,
        "Welcome to the stage, " + g_activeDancerName + "! " +
        "You are now clocked in. Tips will be split " +
        (string)pct + "% your way. Good luck!");

    llRegionSayTo(ownerKey, 0,
        "[SoS Club] " + g_activeDancerName + " clocked in. " +
        "Split: " + (string)pct + "%.");

    // Notify Core to update split state and refresh hover text
    llMessageLinked(LINK_SET, LM_DANCER_IN,
        (string)dancer + "|" + (string)pct, dancer);
    llMessageLinked(LINK_SET, LM_UPDATE_HT, "", NULL_KEY);
}

dancerClockOut(key dancer)
{
    key ownerKey;
    if (dancer != g_activeDancerKey) return;
    ownerKey = llGetOwner();

    llRegionSayTo(dancer, 0,
        "Great set, " + g_activeDancerName + "! " +
        "You earned L$" + (string)g_dancerSessionTotal +
        " in tips this session. See you next time!");

    llRegionSayTo(ownerKey, 0,
        "[SoS Club] " + g_activeDancerName + " clocked out. " +
        "They earned L$" + (string)g_dancerSessionTotal + " this session.");

    lbStop();
    g_lovenseTarget      = NULL_KEY;
    g_activeDancerKey    = NULL_KEY;
    g_activeDancerName   = "";
    g_dancerSessionTotal = 0;

    setInt(K_SPLIT_ENABLED, FALSE);
    setKey(K_SPLIT_PARTNER, NULL_KEY);
    setInt(K_SPLIT_PERCENT, 0);
    setStr(K_ACTIVE_DANCER_KEY,  "");
    setStr(K_ACTIVE_DANCER_NAME, "");
    llLinksetDataWrite("dancer_session_total", "0");

    // Notify Core to clear split state and refresh hover text
    llMessageLinked(LINK_SET, LM_DANCER_OUT, "", NULL_KEY);
    llMessageLinked(LINK_SET, LM_UPDATE_HT, "", NULL_KEY);
}

// ---------------------------------------------------------------
// DEFAULT STATE
// ---------------------------------------------------------------
default
{
    state_entry()
    {
        g_lovenseOn    = ldInt(K_LOVENSE_ON);
        g_clubMode     = ldInt(K_CLUB_MODE);
        g_clubSplitPct = ldInt(K_CLUB_SPLIT_PCT);
        if (g_clubSplitPct == 0) g_clubSplitPct = 50;

        // Restore active dancer if any (survives script reset)
        string dk = ldStr(K_ACTIVE_DANCER_KEY);
        if (dk != "" && (key)dk != NULL_KEY)
        {
            g_activeDancerKey  = (key)dk;
            g_activeDancerName = ldStr(K_ACTIVE_DANCER_NAME);
            g_lovenseTarget    = g_activeDancerKey;
        }
    }

    timer()
    {
        if (g_vibeActive && llGetTime() >= g_vibeStopTime)
        {
            lbStop();
        }
        llSetTimerEvent(0.0);
    }

    link_message(integer sender, integer num, string str, key id)
    {
        list parts;

        if (num == LM_TIP_TRIGGER)
        {
            lbTipTrigger((integer)str);
        }
        else if (num == LM_ADD_DANCER_TIP)
        {
            if (g_activeDancerKey != NULL_KEY)
            {
                g_dancerSessionTotal += (integer)str;
                llLinksetDataWrite("dancer_session_total",
                    (string)g_dancerSessionTotal);
            }
        }
        else if (num == LM_CLOCK_IN)
        {
            dancerClockIn((key)str);
        }
        else if (num == LM_CLOCK_OUT_REQ)
        {
            dancerClockOut((key)str);
        }
        else if (num == LM_SET_CLUB_MODE)
        {
            g_clubMode = (integer)str;
            setInt(K_CLUB_MODE, g_clubMode);
            if (!g_clubMode && g_activeDancerKey != NULL_KEY)
                dancerClockOut(g_activeDancerKey);
        }
        else if (num == LM_SET_CLUB_PCT)
        {
            g_clubSplitPct = (integer)str;
            if (g_clubSplitPct < 1)  g_clubSplitPct = 1;
            if (g_clubSplitPct > 99) g_clubSplitPct = 99;
            setInt(K_CLUB_SPLIT_PCT, g_clubSplitPct);
        }
        else if (num == LM_LV_CMD)
        {
            // Commands from Lovense menu
            if (str == "on")
            {
                g_lovenseOn = TRUE;
                setInt(K_LOVENSE_ON, TRUE);
                llOwnerSay("SoS Lovense: ON. Activates on tips of L$500+.");
            }
            else if (str == "off")
            {
                g_lovenseOn = FALSE;
                setInt(K_LOVENSE_ON, FALSE);
                lbStop();
                llOwnerSay("SoS Lovense: OFF.");
            }
            else if (str == "stop")
            {
                lbStop();
                llOwnerSay("SoS Lovense: stopped.");
            }
            else if (str == "buzz")
            {
                if (g_lovenseTarget == NULL_KEY)
                {
                    llOwnerSay("SoS Lovense: nobody is clocked in to send to.");
                }
                else
                {
                    lbSend("vibrate|10");
                    g_vibeActive   = TRUE;
                    g_vibeStopTime = llGetTime() + 3.0;
                    llSetTimerEvent(3.5);
                    llOwnerSay("SoS Lovense: test buzz sent to " +
                               llGetDisplayName(g_lovenseTarget) + ".");
                }
            }
            else if (str == "wave")
            {
                if (g_lovenseTarget == NULL_KEY)
                {
                    llOwnerSay("SoS Lovense: nobody is clocked in to send to.");
                }
                else
                {
                    lbSend("pattern|2");
                    g_vibeActive   = TRUE;
                    g_vibeStopTime = llGetTime() + 5.0;
                    llSetTimerEvent(5.5);
                    llOwnerSay("SoS Lovense: wave pattern sent to " +
                               llGetDisplayName(g_lovenseTarget) + ".");
                }
            }
            else if (str == "fire")
            {
                if (g_lovenseTarget == NULL_KEY)
                {
                    llOwnerSay("SoS Lovense: nobody is clocked in to send to.");
                }
                else
                {
                    lbSend("pattern|3");
                    g_vibeActive   = TRUE;
                    g_vibeStopTime = llGetTime() + 5.0;
                    llSetTimerEvent(5.5);
                    llOwnerSay("SoS Lovense: fireworks pattern sent to " +
                               llGetDisplayName(g_lovenseTarget) + ".");
                }
            }
        }
    }

    on_rez(integer param)
    {
        llResetScript();
    }
}
