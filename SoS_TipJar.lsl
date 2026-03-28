// SoS Tip Jar v1.2
// Synner or Saynt - Second Life tip jar script

// --- VERSION -----------------------------------------------------
string VERSION = "1.2";

// --- PERSONALITY MODE CONSTANTS ----------------------------------
string MODE_RNB      = "RNB";
string MODE_STANDARD = "STANDARD";
string MODE_HYPE     = "HYPE";
string MODE_TRAP     = "TRAP";

// --- TOP 10 LIST STRIDE ------------------------------------------
integer TOP_STRIDE = 3;
integer TOP_MAX    = 10;

// --- LINKSET DATA KEYS -------------------------------------------
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
string K_LOVENSE_ON      = "lovense_on";
string K_CLUB_MODE       = "club_mode";
string K_CLUB_SPLIT_PCT  = "club_split_pct";
string K_ALL_TIME_TOP    = "all_time_top_tip";
string K_ALL_TIME_NAME   = "all_time_top_name";

// --- OWNER / SESSION GLOBALS -------------------------------------
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

integer g_goalAmount = 0;
list    g_top10          = [];
list    g_sessionTippers = [];

integer g_allTimeTopTip  = 0;
string  g_allTimeTopName = "";

// Anti-spam: list of [key, float timestamp] pairs, stride 2
list    g_spamList       = [];
float   SPAM_COOLDOWN    = 4.0;

string  g_mode = "STANDARD";

integer g_particlesOn    = TRUE;
integer g_soundsOn       = TRUE;
integer g_publicMessages = TRUE;

// --- SPLIT GLOBALS -----------------------------------------------
integer g_splitEnabled    = FALSE;
key     g_splitPartnerKey = NULL_KEY;
integer g_splitPercent    = 0;

// --- VISUAL FEEDBACK GLOBALS -------------------------------------
string  g_visualMode  = "GLOW";
float   g_currentGlow = 0.0;
float   GLOW_MAX      = 0.25;
float   GLOW_PER_TIP  = 0.01;

// --- CUSTOM TY MESSAGE CHANNELS ----------------------------------
integer DCHAN_TYMSG_PICK = -882001;
integer DCHAN_TYMSG_TEXT = -882002;
integer g_listenTyPick   = 0;
integer g_listenTyText   = 0;
key     g_pendingTyKey   = NULL_KEY;

// --- OWNER MENU DIALOG CHANNELS ----------------------------------
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

// --- SPLIT DIALOG CHANNELS ---------------------------------------
integer DCHAN_SPLIT_KEY  = -883009;
integer DCHAN_SPLIT_PCT  = -883010;
integer g_listenSplitKey = 0;
integer g_listenSplitPct = 0;
string  g_pendingSplitKey = "";

// --- CLUB MODE GLOBALS -------------------------------------------
integer g_clubMode           = FALSE;
integer g_clubSplitPct       = 50;
key     g_activeDancerKey    = NULL_KEY;
string  g_activeDancerName   = "";
integer g_dancerSessionTotal = 0;

integer DCHAN_CLUB      = -883011;
integer DCHAN_CLUB_PCT  = -883012;
integer DCHAN_CLOCKOUT  = -883013;
integer g_listenClub     = 0;
integer g_listenClubPct  = 0;
integer g_listenClockOut = 0;

// --- LOVENSE / LOVEBRIDGE GLOBALS --------------------------------
integer LB_CHAN          = -4257001;
integer g_lovenseOn      = FALSE;
key     g_lovenseTarget  = NULL_KEY;
integer g_vibeActive     = FALSE;
float   g_vibeStopTime   = 0.0;

integer DCHAN_LOVENSE      = -884001;
integer DCHAN_LOVENSE_VIBE = -884002;
integer g_listenLovense     = 0;
integer g_listenLovenseVibe = 0;

// --- LINKSET DATA HELPERS ----------------------------------------
setInt(string k, integer v)
{
    llLinksetDataWrite(k, (string)v);
}

setStr(string k, string v)
{
    llLinksetDataWrite(k, v);
}

setKey(string k, key v)
{
    llLinksetDataWrite(k, (string)v);
}

setFloat(string k, float v)
{
    llLinksetDataWrite(k, (string)v);
}

integer getInt(string k)
{
    return (integer)llLinksetDataRead(k);
}

string getStr(string k)
{
    return llLinksetDataRead(k);
}

key getKey(string k)
{
    return (key)llLinksetDataRead(k);
}

float getFloat(string k)
{
    return (float)llLinksetDataRead(k);
}

string keyTyMsg(key av)
{
    return "tymsg_" + (string)av;
}

// --- FILL / VISUAL FEEDBACK --------------------------------------
float getFillPercent()
{
    float pct;
    if (g_goalAmount <= 0) return 0.0;
    pct = (float)g_sessionTotal / (float)g_goalAmount;
    if (pct > 1.0) pct = 1.0;
    return pct;
}

updateFillPrim()
{
    float pct = getFillPercent();
    float sz  = 0.01 + pct * 0.98;
    llSetLinkPrimitiveParamsFast(2, [
        PRIM_SIZE, <0.1, 0.1, sz>
    ]);
}

updateVisualFeedback()
{
    float   intensity;
    integer burstCount;
    if (g_visualMode == "FILL")
    {
        updateFillPrim();
    }
    else if (g_visualMode == "GLOW")
    {
        g_currentGlow = g_currentGlow + GLOW_PER_TIP;
        if (g_currentGlow > GLOW_MAX)
        {
            g_currentGlow = GLOW_MAX;
        }
        llSetLinkPrimitiveParamsFast(LINK_ROOT, [
            PRIM_GLOW, ALL_SIDES, g_currentGlow
        ]);
    }
    else if (g_visualMode == "PARTICLES")
    {
        intensity  = (float)g_sessionTipCount * 0.05;
        if (intensity > 1.0) intensity = 1.0;
        burstCount = 2 + (integer)(intensity * 8.0);
        llParticleSystem([
            PSYS_SRC_PATTERN,          PSYS_SRC_PATTERN_ANGLE_CONE,
            PSYS_PART_START_COLOR,     <1.0, 0.85, 0.2>,
            PSYS_PART_END_COLOR,       <1.0, 0.5, 0.0>,
            PSYS_PART_START_ALPHA,     0.4,
            PSYS_PART_END_ALPHA,       0.0,
            PSYS_PART_START_SCALE,     <0.03, 0.03, 0.0>,
            PSYS_PART_END_SCALE,       <0.07, 0.07, 0.0>,
            PSYS_SRC_BURST_PART_COUNT, burstCount,
            PSYS_SRC_BURST_RATE,       0.5,
            PSYS_SRC_BURST_SPEED_MIN,  0.05,
            PSYS_SRC_BURST_SPEED_MAX,  0.15,
            PSYS_PART_MAX_AGE,         2.0,
            PSYS_SRC_ACCEL,            <0.0, 0.0, 0.08>
        ]);
    }
}

displayVIPBadge()
{
    string badge;
    if (g_sessionTopKey == NULL_KEY) return;
    badge =
        "* VIP OF THE NIGHT *\n" +
        g_sessionTopName + "\n" +
        "L$" + (string)g_sessionTopTotal + " tipped tonight";
    llSetLinkPrimitiveParamsFast(LINK_ROOT, [
        PRIM_TEXT, badge, <1.0, 0.85, 0.0>, 1.0
    ]);
}

updateHoverText()
{
    string  line1 = "SoS Tip Jar";
    string  line2 = "Session: L$" + (string)g_sessionTotal;
    string  line3 = "";
    integer pct;
    if (g_sessionTopKey != NULL_KEY)
    {
        displayVIPBadge();
        return;
    }

    if (g_clubMode)
    {
        if (g_activeDancerKey != NULL_KEY)
            line3 = "On stage: " + g_activeDancerName;
        else
            line3 = "Club Mode - Waiting for performer";
    }
    else if (g_goalAmount > 0)
    {
        pct   = (integer)(getFillPercent() * 100.0 + 0.5);
        line3 = "Goal: L$" + (string)g_goalAmount + " (" + (string)pct + "%)";
    }
    else
    {
        line3 = "Touch to tip!";
    }

    llSetText(line1 + "\n" + line2 + "\n" + line3, <0.9, 0.8, 0.2>, 1.0);
}

// --- PARTICLES ---------------------------------------------------
playSmallParticles()
{
    if (!g_particlesOn) return;

    if (g_mode == MODE_RNB)
    {
        llParticleSystem([
            PSYS_SRC_PATTERN,          PSYS_SRC_PATTERN_ANGLE_CONE,
            PSYS_PART_START_COLOR,     <0.8, 0.4, 0.9>,
            PSYS_PART_END_COLOR,       <0.4, 0.2, 0.6>,
            PSYS_PART_START_ALPHA,     0.5,
            PSYS_PART_END_ALPHA,       0.0,
            PSYS_PART_START_SCALE,     <0.04, 0.04, 0.0>,
            PSYS_PART_END_SCALE,       <0.08, 0.08, 0.0>,
            PSYS_SRC_BURST_PART_COUNT, 6,
            PSYS_SRC_BURST_RATE,       0.2,
            PSYS_SRC_BURST_SPEED_MIN,  0.05,
            PSYS_SRC_BURST_SPEED_MAX,  0.15,
            PSYS_SRC_MAX_AGE,          0.6,
            PSYS_PART_MAX_AGE,         1.5,
            PSYS_SRC_ACCEL,            <0.0, 0.0, 0.1>
        ]);
    }
    else if (g_mode == MODE_HYPE)
    {
        llParticleSystem([
            PSYS_SRC_PATTERN,          PSYS_SRC_PATTERN_ANGLE_CONE,
            PSYS_PART_START_COLOR,     <1.0, 1.0, 0.1>,
            PSYS_PART_END_COLOR,       <1.0, 0.4, 0.0>,
            PSYS_PART_START_ALPHA,     1.0,
            PSYS_PART_END_ALPHA,       0.0,
            PSYS_PART_START_SCALE,     <0.06, 0.06, 0.0>,
            PSYS_PART_END_SCALE,       <0.14, 0.14, 0.0>,
            PSYS_SRC_BURST_PART_COUNT, 15,
            PSYS_SRC_BURST_RATE,       0.05,
            PSYS_SRC_BURST_SPEED_MIN,  0.2,
            PSYS_SRC_BURST_SPEED_MAX,  0.5,
            PSYS_SRC_MAX_AGE,          0.4,
            PSYS_PART_MAX_AGE,         1.0,
            PSYS_SRC_ACCEL,            <0.0, 0.0, 0.4>
        ]);
    }
    else if (g_mode == MODE_TRAP)
    {
        llParticleSystem([
            PSYS_SRC_PATTERN,          PSYS_SRC_PATTERN_ANGLE_CONE,
            PSYS_PART_START_COLOR,     <0.1, 0.9, 0.1>,
            PSYS_PART_END_COLOR,       <0.0, 0.4, 0.0>,
            PSYS_PART_START_ALPHA,     0.9,
            PSYS_PART_END_ALPHA,       0.0,
            PSYS_PART_START_SCALE,     <0.05, 0.05, 0.0>,
            PSYS_PART_END_SCALE,       <0.10, 0.10, 0.0>,
            PSYS_SRC_BURST_PART_COUNT, 12,
            PSYS_SRC_BURST_RATE,       0.08,
            PSYS_SRC_BURST_SPEED_MIN,  0.1,
            PSYS_SRC_BURST_SPEED_MAX,  0.3,
            PSYS_SRC_MAX_AGE,          0.5,
            PSYS_PART_MAX_AGE,         1.2,
            PSYS_SRC_ACCEL,            <0.0, 0.0, 0.2>
        ]);
    }
    else
    {
        llParticleSystem([
            PSYS_SRC_PATTERN,          PSYS_SRC_PATTERN_ANGLE_CONE,
            PSYS_PART_START_COLOR,     <1.0, 1.0, 0.3>,
            PSYS_PART_END_COLOR,       <1.0, 0.8, 0.2>,
            PSYS_PART_START_ALPHA,     0.8,
            PSYS_PART_END_ALPHA,       0.0,
            PSYS_PART_START_SCALE,     <0.05, 0.05, 0.0>,
            PSYS_PART_END_SCALE,       <0.1, 0.1, 0.0>,
            PSYS_SRC_BURST_PART_COUNT, 10,
            PSYS_SRC_BURST_RATE,       0.1,
            PSYS_SRC_BURST_SPEED_MIN,  0.1,
            PSYS_SRC_BURST_SPEED_MAX,  0.3,
            PSYS_SRC_MAX_AGE,          0.5,
            PSYS_PART_MAX_AGE,         1.0,
            PSYS_SRC_ACCEL,            <0.0, 0.0, 0.2>
        ]);
    }
}

playBigParticles()
{
    if (!g_particlesOn) return;

    if (g_mode == MODE_RNB)
    {
        llParticleSystem([
            PSYS_SRC_PATTERN,          PSYS_SRC_PATTERN_EXPLODE,
            PSYS_PART_START_COLOR,     <0.9, 0.6, 1.0>,
            PSYS_PART_END_COLOR,       <0.5, 0.2, 0.8>,
            PSYS_PART_START_ALPHA,     0.8,
            PSYS_PART_END_ALPHA,       0.0,
            PSYS_PART_START_SCALE,     <0.08, 0.08, 0.0>,
            PSYS_PART_END_SCALE,       <0.18, 0.18, 0.0>,
            PSYS_SRC_BURST_PART_COUNT, 20,
            PSYS_SRC_BURST_RATE,       0.05,
            PSYS_SRC_BURST_SPEED_MIN,  0.15,
            PSYS_SRC_BURST_SPEED_MAX,  0.35,
            PSYS_SRC_MAX_AGE,          0.8,
            PSYS_PART_MAX_AGE,         1.8,
            PSYS_SRC_ACCEL,            <0.0, 0.0, 0.2>
        ]);
    }
    else if (g_mode == MODE_HYPE)
    {
        llParticleSystem([
            PSYS_SRC_PATTERN,          PSYS_SRC_PATTERN_EXPLODE,
            PSYS_PART_START_COLOR,     <1.0, 0.3, 0.1>,
            PSYS_PART_END_COLOR,       <1.0, 1.0, 0.2>,
            PSYS_PART_START_ALPHA,     1.0,
            PSYS_PART_END_ALPHA,       0.0,
            PSYS_PART_START_SCALE,     <0.12, 0.12, 0.0>,
            PSYS_PART_END_SCALE,       <0.25, 0.25, 0.0>,
            PSYS_SRC_BURST_PART_COUNT, 50,
            PSYS_SRC_BURST_RATE,       0.03,
            PSYS_SRC_BURST_SPEED_MIN,  0.5,
            PSYS_SRC_BURST_SPEED_MAX,  1.0,
            PSYS_SRC_MAX_AGE,          0.5,
            PSYS_PART_MAX_AGE,         1.2,
            PSYS_SRC_ACCEL,            <0.0, 0.0, 0.8>
        ]);
    }
    else if (g_mode == MODE_TRAP)
    {
        llParticleSystem([
            PSYS_SRC_PATTERN,          PSYS_SRC_PATTERN_EXPLODE,
            PSYS_PART_START_COLOR,     <0.0, 1.0, 0.2>,
            PSYS_PART_END_COLOR,       <0.8, 1.0, 0.0>,
            PSYS_PART_START_ALPHA,     1.0,
            PSYS_PART_END_ALPHA,       0.0,
            PSYS_PART_START_SCALE,     <0.10, 0.10, 0.0>,
            PSYS_PART_END_SCALE,       <0.22, 0.22, 0.0>,
            PSYS_SRC_BURST_PART_COUNT, 35,
            PSYS_SRC_BURST_RATE,       0.04,
            PSYS_SRC_BURST_SPEED_MIN,  0.3,
            PSYS_SRC_BURST_SPEED_MAX,  0.7,
            PSYS_SRC_MAX_AGE,          0.6,
            PSYS_PART_MAX_AGE,         1.4,
            PSYS_SRC_ACCEL,            <0.0, 0.0, 0.5>
        ]);
    }
    else
    {
        llParticleSystem([
            PSYS_SRC_PATTERN,          PSYS_SRC_PATTERN_EXPLODE,
            PSYS_PART_START_COLOR,     <1.0, 0.3, 0.3>,
            PSYS_PART_END_COLOR,       <1.0, 1.0, 0.3>,
            PSYS_PART_START_ALPHA,     1.0,
            PSYS_PART_END_ALPHA,       0.0,
            PSYS_PART_START_SCALE,     <0.1, 0.1, 0.0>,
            PSYS_PART_END_SCALE,       <0.2, 0.2, 0.0>,
            PSYS_SRC_BURST_PART_COUNT, 30,
            PSYS_SRC_BURST_RATE,       0.05,
            PSYS_SRC_BURST_SPEED_MIN,  0.3,
            PSYS_SRC_BURST_SPEED_MAX,  0.6,
            PSYS_SRC_MAX_AGE,          0.6,
            PSYS_PART_MAX_AGE,         1.2,
            PSYS_SRC_ACCEL,            <0.0, 0.0, 0.5>
        ]);
    }
}

// --- THANK YOU MESSAGES ------------------------------------------
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
    string customMsg = llLinksetDataRead(keyTyMsg(tipper));
    string tmpl;
    string msg;
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

showTyMsgMenu()
{
    list    buttons = [];
    integer i;
    integer maxIdx  = llGetListLength(g_top10);
    key     av;
    string  shortName;
    if (g_listenTyPick) llListenRemove(g_listenTyPick);
    if (maxIdx > TOP_STRIDE * 9) maxIdx = TOP_STRIDE * 9;
    for (i = 0; i < maxIdx; i += TOP_STRIDE)
    {
        av        = llList2Key(g_top10, i);
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

// --- MILESTONES / ANNOUNCE ---------------------------------------
announceMilestone(integer amount, string name)
{
    string msg = "";
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

announceVIP()
{
    string msg;
    if (g_sessionTopKey == NULL_KEY) return;
    msg = "* Current VIP: " + g_sessionTopName +
                 " - L$" + (string)g_sessionTopTotal + " tipped! *";
    if (g_publicMessages)
        llSay(0, msg);
    else
        llOwnerSay(msg);
    displayVIPBadge();
}

announceAllTimeRecord(string name, integer amount)
{
    if (!g_publicMessages) return;
    llSay(0, "NEW ALL-TIME RECORD! " + name + " with L$" + (string)amount + "!");
}

// --- TOP 10 ------------------------------------------------------
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
                tmp = llList2List(g_top10, i, i + TOP_STRIDE - 1);
                g_top10  = llListReplaceList(g_top10,
                    llList2List(g_top10, i + TOP_STRIDE, i + TOP_STRIDE * 2 - 1),
                    i, i + TOP_STRIDE - 1);
                g_top10  = llListReplaceList(g_top10, tmp,
                    i + TOP_STRIDE, i + TOP_STRIDE * 2 - 1);
                didSwap  = TRUE;
            }
        }
    }

    if (llGetListLength(g_top10) > TOP_STRIDE * TOP_MAX)
        g_top10 = llList2List(g_top10, 0, TOP_STRIDE * TOP_MAX - 1);
}

string getTop10Report()
{
    string  report = "=== SoS TOP 10 ===\n";
    integer i;
    integer rank   = 1;
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

// --- STATE SAVE / LOAD -------------------------------------------
saveState()
{
    setStr(K_MODE,            g_mode);
    setInt(K_GOAL_AMOUNT,     g_goalAmount);
    setInt(K_SESSION_TOTAL,   g_sessionTotal);
    setInt(K_SESSION_COUNT,   g_sessionTipCount);
    setInt(K_LIFETIME_TOTAL,  g_lifetimeTotal);
    setInt(K_PARTICLES_ON,    g_particlesOn);
    setInt(K_SOUNDS_ON,       g_soundsOn);
    setInt(K_PUBLIC_MESSAGES, g_publicMessages);
    setInt(K_SPLIT_ENABLED,   g_splitEnabled);
    setKey(K_SPLIT_PARTNER,   g_splitPartnerKey);
    setInt(K_SPLIT_PERCENT,   g_splitPercent);
    setStr(K_VISUAL_MODE,     g_visualMode);
    setInt(K_LOVENSE_ON,      g_lovenseOn);
    setInt(K_CLUB_MODE,       g_clubMode);
    setInt(K_CLUB_SPLIT_PCT,  g_clubSplitPct);
    setInt(K_ALL_TIME_TOP,    g_allTimeTopTip);
    setStr(K_ALL_TIME_NAME,   g_allTimeTopName);
    llLinksetDataWrite(K_TOP10, llList2CSV(g_top10));
}

loadState()
{
    string m       = getStr(K_MODE);
    string vm      = getStr(K_VISUAL_MODE);
    string atn     = getStr(K_ALL_TIME_NAME);
    string top10csv;
    if (m != "") g_mode = m;

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

    if (vm != "") g_visualMode = vm;

    g_lovenseOn    = getInt(K_LOVENSE_ON);
    g_clubMode     = getInt(K_CLUB_MODE);
    g_clubSplitPct = getInt(K_CLUB_SPLIT_PCT);
    if (g_clubSplitPct == 0) g_clubSplitPct = 50;

    g_allTimeTopTip = getInt(K_ALL_TIME_TOP);
    if (atn != "") g_allTimeTopName = atn;

    top10csv = llLinksetDataRead(K_TOP10);
    if (top10csv != "")
        g_top10 = llCSV2List(top10csv);
}

// --- CLOSE ALL MENUS ---------------------------------------------
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
    if (g_listenLovenseVibe){ llListenRemove(g_listenLovenseVibe);g_listenLovenseVibe= 0; }
}

// --- MAIN MENU ---------------------------------------------------
showMainMenu()
{
    string status;
    closeAllMenus();
    status = "Mode: " + g_mode + "  Visual: " + g_visualMode;
    if (g_sessionTopKey != NULL_KEY)
        status += "\nVIP: " + g_sessionTopName;

    g_listenMain = llListen(DCHAN_MAIN, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== SoS TIP JAR ===\n" +
        "Session: L$" + (string)g_sessionTotal +
        "  Tips: " + (string)g_sessionTipCount + "\n" +
        status,
        ["Mode", "Visual", "Goal",
         "VIP", "Top 10", "TY Msg",
         "Split", "Settings", "Reset",
         "Club", "Lovense"],
        DCHAN_MAIN);
    llSetTimerEvent(30.0);
}

// --- MODE MENU ---------------------------------------------------
showModeMenu()
{
    closeAllMenus();
    g_listenMode = llListen(DCHAN_MODE, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== PERSONALITY MODE ===\n" +
        "Current: " + g_mode + "\n\n" +
        "RNB      - Smooth and soulful\n" +
        "Standard - Balanced\n" +
        "Hype     - High energy\n" +
        "Trap     - Street/hood",
        ["RNB", "Standard", "Hype", "Trap", "Back"],
        DCHAN_MODE);
    llSetTimerEvent(30.0);
}

// --- VISUAL MENU -------------------------------------------------
showVisualMenu()
{
    closeAllMenus();
    g_listenVisual = llListen(DCHAN_VISUAL, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== VISUAL FEEDBACK ===\n" +
        "Current: " + g_visualMode + "\n\n" +
        "Glow      - Jar glows with tips\n" +
        "Particles - Ambient particles grow\n" +
        "Fill      - Prim scales to goal",
        ["Glow", "Particles", "Fill", "Back"],
        DCHAN_VISUAL);
    llSetTimerEvent(30.0);
}

// --- SETTINGS MENU -----------------------------------------------
showSettingsMenu()
{
    string partBtn;
    string sndBtn;
    string pubBtn;
    closeAllMenus();
    if (g_particlesOn)    partBtn = "Particles: ON";
    else                  partBtn = "Particles: OFF";
    if (g_soundsOn)       sndBtn  = "Sounds: ON";
    else                  sndBtn  = "Sounds: OFF";
    if (g_publicMessages) pubBtn  = "Public: ON";
    else                  pubBtn  = "Public: OFF";

    g_listenSettings = llListen(DCHAN_SETTINGS, "", g_ownerKey, "");
    llDialog(g_ownerKey,
        "=== SETTINGS ===\n" +
        "Toggle each option:",
        [partBtn, sndBtn, pubBtn, "Back"],
        DCHAN_SETTINGS);
    llSetTimerEvent(30.0);
}

// --- SPLIT MENU --------------------------------------------------
showSplitMenu()
{
    string splitStatus;
    closeAllMenus();
    if (g_splitEnabled && g_splitPartnerKey != NULL_KEY)
    {
        splitStatus = "ON - " + llGetDisplayName(g_splitPartnerKey) +
                      " gets " + (string)g_splitPercent + "%";
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

// --- TOP 10 MENU -------------------------------------------------
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

// --- GOAL MENU ---------------------------------------------------
showGoalMenu()
{
    string current;
    closeAllMenus();
    if (g_goalAmount > 0)
        current = "Current goal: L$" + (string)g_goalAmount;
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

// --- RESET CONFIRM -----------------------------------------------
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

// --- CLUB MENU ---------------------------------------------------
showClubMenu()
{
    string status;
    closeAllMenus();
    if (g_clubMode)
    {
        if (g_activeDancerKey != NULL_KEY)
            status = "ON - Active: " + g_activeDancerName;
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
        "Default split: " + (string)g_clubSplitPct + "%\n\n" +
        "Group members can clock in\n" +
        "and out at any time.",
        ["Club ON", "Club OFF", "Set Split %",
         "Clock Out Now", "Back"],
        DCHAN_CLUB);
    llSetTimerEvent(30.0);
}

// --- LOVENSE MENU ------------------------------------------------
showLovenseMenu()
{
    string lvStatus;
    string target;
    closeAllMenus();
    if (g_lovenseOn) lvStatus = "ON";
    else             lvStatus = "OFF";
    if (g_lovenseTarget != NULL_KEY)
        target = llGetDisplayName(g_lovenseTarget);
    else
        target = "None";

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

// --- LOVENSE FUNCTIONS -------------------------------------------
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

// --- CLUB MODE FUNCTIONS -----------------------------------------
dancerClockIn(key dancer)
{
    g_lovenseTarget      = dancer;
    g_activeDancerKey    = dancer;
    g_activeDancerName   = llGetDisplayName(dancer);
    g_dancerSessionTotal = 0;

    g_splitEnabled    = TRUE;
    g_splitPartnerKey = dancer;
    g_splitPercent    = g_clubSplitPct;
    setInt(K_SPLIT_ENABLED, TRUE);
    setKey(K_SPLIT_PARTNER, dancer);
    setInt(K_SPLIT_PERCENT, g_clubSplitPct);

    llRegionSayTo(dancer, 0,
        "Welcome to the stage, " + g_activeDancerName + "! " +
        "You are now clocked in. Tips will be split " +
        (string)g_clubSplitPct + "% your way. Good luck!");

    llRegionSayTo(g_ownerKey, 0,
        "[SoS Club] " + g_activeDancerName + " clocked in. " +
        "Split: " + (string)g_clubSplitPct + "%.");

    updateHoverText();

    if (!g_hasDebitPerms)
        llRequestPermissions(g_ownerKey, PERMISSION_DEBIT);
}

dancerClockOut(key dancer)
{
    if (dancer != g_activeDancerKey) return;

    llRegionSayTo(dancer, 0,
        "Great set, " + g_activeDancerName + "! " +
        "You earned L$" + (string)g_dancerSessionTotal +
        " in tips this session. See you next time!");

    llRegionSayTo(g_ownerKey, 0,
        "[SoS Club] " + g_activeDancerName + " clocked out. " +
        "They earned L$" + (string)g_dancerSessionTotal + " this session.");

    lbStop();
    g_lovenseTarget = NULL_KEY;

    g_activeDancerKey    = NULL_KEY;
    g_activeDancerName   = "";
    g_dancerSessionTotal = 0;

    g_splitEnabled    = FALSE;
    g_splitPartnerKey = NULL_KEY;
    g_splitPercent    = 0;
    setInt(K_SPLIT_ENABLED, FALSE);
    setKey(K_SPLIT_PARTNER, NULL_KEY);
    setInt(K_SPLIT_PERCENT, 0);

    updateHoverText();
}

// --- OWNER CHAT COMMANDS -----------------------------------------
handleOwnerCommand(string raw)
{
    list   parts = llParseString2List(llToLower(raw), [" "], []);
    string cmd;
    string m;
    string report;
    string vipMsg;
    string v;
    string action;
    key    partner;
    integer pct;
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
        updateHoverText();
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
        g_currentGlow      = 0.0;
        llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_GLOW, ALL_SIDES, 0.0]);
        if (!g_particlesOn) llParticleSystem([]);
        saveState();
        updateHoverText();
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
        displayVIPBadge();
    }
    else if (cmd == "visual" && llGetListLength(parts) >= 3)
    {
        v = llToLower(llList2String(parts, 2));
        if (v == "fill" || v == "glow" || v == "particles")
        {
            g_visualMode = llToUpper(v);
            setStr(K_VISUAL_MODE, g_visualMode);
            llOwnerSay("SoS: visual mode set to " + g_visualMode + ".");
            if (g_visualMode != "PARTICLES") llParticleSystem([]);
            if (g_visualMode != "GLOW")
            {
                g_currentGlow = 0.0;
                llSetLinkPrimitiveParamsFast(LINK_ROOT,
                    [PRIM_GLOW, ALL_SIDES, 0.0]);
            }
        }
        else
        {
            llOwnerSay("SoS: valid visual modes are fill, glow, particles.");
        }
    }
    else if (cmd == "tymsg")
    {
        showTyMsgMenu();
        return;
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

// =================================================================
// DEFAULT STATE
// =================================================================
default
{
    state_entry()
    {
        g_ownerKey  = llGetOwner();
        g_ownerName = llGetDisplayName(g_ownerKey);
        loadState();
        llListen(0, "", g_ownerKey, "");
        llRequestPermissions(g_ownerKey, PERMISSION_DEBIT);
        updateHoverText();
        llOwnerSay("SoS Tip Jar v" + VERSION + " ready. Touch to open menu.");
    }

    run_time_permissions(integer perms)
    {
        if (perms & PERMISSION_DEBIT)
            g_hasDebitPerms = TRUE;
    }

    // -- TOUCH ----------------------------------------------------
    touch_start(integer nd)
    {
        key toucher = llDetectedKey(0);

        if (toucher == g_ownerKey)
        {
            showMainMenu();
            return;
        }

        if (g_clubMode && llSameGroup(toucher))
        {
            if (toucher == g_activeDancerKey)
            {
                if (g_listenClockOut)
                {
                    llListenRemove(g_listenClockOut);
                    g_listenClockOut = 0;
                }
                g_listenClockOut = llListen(DCHAN_CLOCKOUT, "", toucher, "");
                llDialog(toucher,
                    "=== CLOCK OUT ===\n\n" +
                    "You earned L$" + (string)g_dancerSessionTotal +
                    " this session.\n\n" +
                    "Are you sure you want to clock out?",
                    ["Clock Out", "Stay On"],
                    DCHAN_CLOCKOUT);
            }
            else if (g_activeDancerKey == NULL_KEY)
            {
                dancerClockIn(toucher);
            }
            else
            {
                llRegionSayTo(toucher, 0,
                    g_activeDancerName + " is currently on stage. " +
                    "Please wait for them to clock out.");
            }
            return;
        }

        llRegionSayTo(toucher, 0,
            "This tip jar belongs to " + g_ownerName + ".");
    }

    // -- MONEY ----------------------------------------------------
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

        // Anti-spam: ignore if this avatar tipped within SPAM_COOLDOWN seconds
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
            g_dancerSessionTotal += amount;

        // Track session total per tipper, detect returning tippers
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

        // All-time biggest single tip record
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
            playBigParticles();
        else
            playSmallParticles();

        updateVisualFeedback();
        updateHoverText();

        if (g_splitEnabled && g_splitPartnerKey != NULL_KEY && g_hasDebitPerms)
        {
            splitAmt = (integer)((float)amount *
                       (float)g_splitPercent / 100.0);
            if (splitAmt > 0)
                llGiveMoney(g_splitPartnerKey, splitAmt);
        }

        lbTipTrigger(amount);
    }

    // -- LISTEN ---------------------------------------------------
    listen(integer channel, string name, key id, string msg)
    {
        integer i;
        integer tlen;
        key     av;
        string  shortName;
        string  vipMsg;
        key     testKey;
        integer pct;
        string  report;
        integer newGoal;
        // Owner chat commands on channel 0
        if (channel == 0 && id == g_ownerKey)
        {
            handleOwnerCommand(msg);
            return;
        }

        // Dancer clock-out confirm
        else if (channel == DCHAN_CLOCKOUT)
        {
            if (g_listenClockOut)
            {
                llListenRemove(g_listenClockOut);
                g_listenClockOut = 0;
            }
            if (msg == "Clock Out")
                dancerClockOut(id);
        }

        // Custom TY message - pick tipper
        else if (channel == DCHAN_TYMSG_PICK)
        {
            if (g_listenTyPick) { llListenRemove(g_listenTyPick); g_listenTyPick = 0; }
            llSetTimerEvent(0.0);
            if (msg == "Cancel") return;

            tlen = llGetListLength(g_top10);
            for (i = 0; i < tlen; i += TOP_STRIDE)
            {
                av        = llList2Key(g_top10, i);
                shortName = llGetSubString(llGetDisplayName(av), 0, 10);
                if (shortName == msg)
                {
                    g_pendingTyKey = av;
                    if (g_listenTyText) llListenRemove(g_listenTyText);
                    g_listenTyText = llListen(DCHAN_TYMSG_TEXT, "", g_ownerKey, "");
                    llTextBox(g_ownerKey,
                        "Type a custom TY message for " + llGetDisplayName(av) + ".\n\n" +
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
            llLinksetDataWrite(keyTyMsg(g_pendingTyKey), msg);
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
                if (g_sessionTopKey == NULL_KEY)
                    llOwnerSay("SoS: no VIP yet this session.");
                else
                {
                    vipMsg = "* VIP OF THE NIGHT: " + g_sessionTopName +
                             " with L$" + (string)g_sessionTopTotal + "! *";
                    llSay(0, vipMsg);
                    displayVIPBadge();
                }
            }
            else if (msg == "Top 10")    showTop10Menu();
            else if (msg == "TY Msg")    showTyMsgMenu();
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

            if (msg == "RNB")            g_mode = MODE_RNB;
            else if (msg == "Standard")  g_mode = MODE_STANDARD;
            else if (msg == "Hype")      g_mode = MODE_HYPE;
            else if (msg == "Trap")      g_mode = MODE_TRAP;

            if (msg != "Back")
            {
                setStr(K_MODE, g_mode);
                llOwnerSay("SoS: mode set to " + g_mode + ".");
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
                g_visualMode = llToUpper(msg);
                setStr(K_VISUAL_MODE, g_visualMode);
                llOwnerSay("SoS: visual set to " + g_visualMode + ".");
                if (g_visualMode != "PARTICLES") llParticleSystem([]);
                if (g_visualMode != "GLOW")
                {
                    g_currentGlow = 0.0;
                    llSetLinkPrimitiveParamsFast(LINK_ROOT,
                        [PRIM_GLOW, ALL_SIDES, 0.0]);
                }
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
                g_particlesOn = !g_particlesOn;
                setInt(K_PARTICLES_ON, g_particlesOn);
                if (!g_particlesOn) llParticleSystem([]);
                if (g_particlesOn)
                    llOwnerSay("SoS: particles ON.");
                else
                    llOwnerSay("SoS: particles OFF.");
                showSettingsMenu();
            }
            else if (msg == "Sounds: ON" || msg == "Sounds: OFF")
            {
                g_soundsOn = !g_soundsOn;
                setInt(K_SOUNDS_ON, g_soundsOn);
                if (g_soundsOn)
                    llOwnerSay("SoS: sounds ON.");
                else
                    llOwnerSay("SoS: sounds OFF.");
                showSettingsMenu();
            }
            else if (msg == "Public: ON" || msg == "Public: OFF")
            {
                g_publicMessages = !g_publicMessages;
                setInt(K_PUBLIC_MESSAGES, g_publicMessages);
                if (g_publicMessages)
                    llOwnerSay("SoS: public messages ON.");
                else
                    llOwnerSay("SoS: public messages OFF.");
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
                g_splitEnabled    = FALSE;
                g_splitPartnerKey = NULL_KEY;
                g_splitPercent    = 0;
                setInt(K_SPLIT_ENABLED, FALSE);
                setKey(K_SPLIT_PARTNER, NULL_KEY);
                setInt(K_SPLIT_PERCENT, 0);
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

            g_splitEnabled    = TRUE;
            g_splitPartnerKey = (key)g_pendingSplitKey;
            g_splitPercent    = pct;
            g_pendingSplitKey = "";

            setInt(K_SPLIT_ENABLED, TRUE);
            setKey(K_SPLIT_PARTNER, g_splitPartnerKey);
            setInt(K_SPLIT_PERCENT, g_splitPercent);

            llOwnerSay("SoS: split enabled! " +
                       llGetDisplayName(g_splitPartnerKey) +
                       " will receive " + (string)g_splitPercent + "% of each tip.");

            if (!g_hasDebitPerms)
            {
                llOwnerSay("SoS: requesting debit permission for split payouts.");
                llRequestPermissions(g_ownerKey, PERMISSION_DEBIT);
            }

            showMainMenu();
        }

        // Top 10 menu
        else if (channel == DCHAN_TOP10)
        {
            if (g_listenTop10) { llListenRemove(g_listenTop10); g_listenTop10 = 0; }
            llSetTimerEvent(0.0);

            report = getTop10Report();
            if (msg == "View Private")
                llOwnerSay(report);
            else if (msg == "Announce")
                llSay(0, report);

            showMainMenu();
        }

        // Goal text box
        else if (channel == DCHAN_GOAL)
        {
            if (g_listenGoal) { llListenRemove(g_listenGoal); g_listenGoal = 0; }
            llSetTimerEvent(0.0);

            newGoal = (integer)msg;
            if (newGoal < 0) newGoal = 0;
            g_goalAmount = newGoal;
            setInt(K_GOAL_AMOUNT, g_goalAmount);

            if (g_goalAmount > 0)
                llOwnerSay("SoS: goal set to L$" + (string)g_goalAmount + ".");
            else
                llOwnerSay("SoS: goal cleared.");

            updateHoverText();
            showMainMenu();
        }

        // Reset confirm
        else if (channel == DCHAN_RESET)
        {
            if (g_listenReset) { llListenRemove(g_listenReset); g_listenReset = 0; }
            llSetTimerEvent(0.0);

            if (msg == "Yes Reset")
            {
                g_sessionTotal     = 0;
                g_sessionTipCount  = 0;
                g_sessionTippers   = [];
                g_sessionTopKey    = NULL_KEY;
                g_sessionTopName   = "";
                g_sessionTopTotal  = 0;
                g_sessionTopSingle = 0;
                g_currentGlow      = 0.0;
                llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_GLOW, ALL_SIDES, 0.0]);
                if (!g_particlesOn) llParticleSystem([]);
                saveState();
                updateHoverText();
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
                g_clubMode = TRUE;
                setInt(K_CLUB_MODE, TRUE);
                llOwnerSay("SoS: Club Mode ON. Group members can now clock in.");
                showClubMenu();
            }
            else if (msg == "Club OFF")
            {
                if (g_activeDancerKey != NULL_KEY)
                    dancerClockOut(g_activeDancerKey);
                g_clubMode = FALSE;
                setInt(K_CLUB_MODE, FALSE);
                llOwnerSay("SoS: Club Mode OFF.");
                showMainMenu();
            }
            else if (msg == "Set Split %")
            {
                if (g_listenClubPct) llListenRemove(g_listenClubPct);
                g_listenClubPct = llListen(DCHAN_CLUB_PCT, "", g_ownerKey, "");
                llTextBox(g_ownerKey,
                    "=== DEFAULT DANCER SPLIT ===\n\n" +
                    "Current: " + (string)g_clubSplitPct + "%\n\n" +
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
                if (g_activeDancerKey != NULL_KEY)
                {
                    dancerClockOut(g_activeDancerKey);
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
            g_clubSplitPct = pct;
            setInt(K_CLUB_SPLIT_PCT, g_clubSplitPct);
            llOwnerSay("SoS: default dancer split set to " +
                       (string)g_clubSplitPct + "%.");
            showClubMenu();
        }

        // Lovense menu
        else if (channel == DCHAN_LOVENSE)
        {
            if (g_listenLovense) { llListenRemove(g_listenLovense); g_listenLovense = 0; }
            llSetTimerEvent(0.0);

            if (msg == "LV ON")
            {
                g_lovenseOn = TRUE;
                setInt(K_LOVENSE_ON, TRUE);
                llOwnerSay("SoS Lovense: ON. Activates on tips of L$500+.");
                showLovenseMenu();
            }
            else if (msg == "LV OFF")
            {
                g_lovenseOn = FALSE;
                setInt(K_LOVENSE_ON, FALSE);
                lbStop();
                llOwnerSay("SoS Lovense: OFF.");
                showLovenseMenu();
            }
            else if (msg == "Test Buzz")
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
                showLovenseMenu();
            }
            else if (msg == "Test Wave")
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
                showLovenseMenu();
            }
            else if (msg == "Test Fire")
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
                showLovenseMenu();
            }
            else if (msg == "Stop Now")
            {
                lbStop();
                llOwnerSay("SoS Lovense: stopped.");
                showLovenseMenu();
            }
            else if (msg == "Back")
            {
                showMainMenu();
            }
        }
    }

    // -- TIMER ----------------------------------------------------
    timer()
    {
        if (g_vibeActive && llGetTime() >= g_vibeStopTime)
        {
            lbStop();
            return;
        }

        closeAllMenus();
        if (g_listenTyPick) { llListenRemove(g_listenTyPick); g_listenTyPick = 0; }
        if (g_listenTyText) { llListenRemove(g_listenTyText); g_listenTyText = 0; }
        g_pendingTyKey    = NULL_KEY;
        g_pendingSplitKey = "";
        llSetTimerEvent(0.0);
    }

    on_rez(integer param)
    {
        llResetScript();
    }
}
