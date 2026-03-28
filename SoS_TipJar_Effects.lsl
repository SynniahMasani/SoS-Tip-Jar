// SoS Tip Jar v1.2 - Effects Script
// Handles: particles, glow, fill prim, hover text, VIP badge
// Receives triggers via llMessageLinked from Core script
// Place this script inside the tip jar object alongside Core, Menu, LovenseClub

// ---------------------------------------------------------------
// LINK MESSAGE CONSTANTS  (must match Core, Menu, LovenseClub)
// ---------------------------------------------------------------
integer LM_PLAY_SMALL    = 201;  // Core -> Effects: small particle burst
integer LM_PLAY_BIG      = 202;  // Core -> Effects: big particle burst
integer LM_UPDATE_HT     = 203;  // Core -> Effects: refresh hover text
integer LM_RESET_EFFECTS = 204;  // Core -> Effects: session reset
integer LM_VIS_CHANGED   = 205;  // Core -> Effects: str = new visual mode

// ---------------------------------------------------------------
// LINKSET DATA KEYS  (written by Core, read here)
// ---------------------------------------------------------------
string K_MODE            = "mode";
string K_PARTICLES_ON    = "particles_on";
string K_VISUAL_MODE     = "visual_mode";
string K_SESSION_TOTAL   = "session_total";
string K_SESSION_COUNT   = "session_count";
string K_GOAL_AMOUNT     = "goal_amount";
string K_CLUB_MODE       = "club_mode";
string K_SESSION_TOP_KEY   = "session_top_key";
string K_SESSION_TOP_NAME  = "session_top_name";
string K_SESSION_TOP_TOTAL = "session_top_total";
string K_ACTIVE_DANCER_KEY  = "active_dancer_key";
string K_ACTIVE_DANCER_NAME = "active_dancer_name";

// ---------------------------------------------------------------
// GLOW STATE  (local to Effects)
// ---------------------------------------------------------------
float g_currentGlow = 0.0;
float GLOW_MAX      = 0.25;
float GLOW_PER_TIP  = 0.01;

// ---------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------
integer ldInt(string k) { return (integer)llLinksetDataRead(k); }
string  ldStr(string k) { return llLinksetDataRead(k); }

float getFillPercent()
{
    integer goal;
    integer total;
    float   pct;
    goal  = ldInt(K_GOAL_AMOUNT);
    total = ldInt(K_SESSION_TOTAL);
    if (goal <= 0) return 0.0;
    pct = (float)total / (float)goal;
    if (pct > 1.0) pct = 1.0;
    return pct;
}

updateFillPrim()
{
    float pct;
    float sz;
    pct = getFillPercent();
    sz  = 0.01 + pct * 0.98;
    llSetLinkPrimitiveParamsFast(2, [PRIM_SIZE, <0.1, 0.1, sz>]);
}

updateVisualFeedback()
{
    string  vm;
    integer tipCount;
    float   intensity;
    integer burstCount;
    vm = ldStr(K_VISUAL_MODE);
    if (vm == "FILL")
    {
        updateFillPrim();
    }
    else if (vm == "GLOW")
    {
        g_currentGlow = g_currentGlow + GLOW_PER_TIP;
        if (g_currentGlow > GLOW_MAX)
            g_currentGlow = GLOW_MAX;
        llSetLinkPrimitiveParamsFast(LINK_ROOT, [
            PRIM_GLOW, ALL_SIDES, g_currentGlow
        ]);
    }
    else if (vm == "PARTICLES")
    {
        tipCount   = ldInt(K_SESSION_COUNT);
        intensity  = (float)tipCount * 0.05;
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

updateHoverText()
{
    string  sessionTopKey;
    string  sessionTopName;
    integer sessionTopTotal;
    integer sessionTotal;
    integer goalAmount;
    integer clubMode;
    string  activeDancerKey;
    string  activeDancerName;
    string  line1;
    string  line2;
    string  line3;
    string  badge;
    integer pct;

    sessionTopKey   = ldStr(K_SESSION_TOP_KEY);
    sessionTopName  = ldStr(K_SESSION_TOP_NAME);
    sessionTopTotal = ldInt(K_SESSION_TOP_TOTAL);
    sessionTotal    = ldInt(K_SESSION_TOTAL);
    goalAmount      = ldInt(K_GOAL_AMOUNT);
    clubMode        = ldInt(K_CLUB_MODE);
    activeDancerKey = ldStr(K_ACTIVE_DANCER_KEY);
    activeDancerName = ldStr(K_ACTIVE_DANCER_NAME);

    line1 = "SoS Tip Jar";
    line2 = "Session: L$" + (string)sessionTotal;
    line3 = "";

    if (sessionTopKey != "" && (key)sessionTopKey != NULL_KEY)
    {
        badge =
            "* VIP OF THE NIGHT *\n" +
            sessionTopName + "\n" +
            "L$" + (string)sessionTopTotal + " tipped tonight";
        llSetLinkPrimitiveParamsFast(LINK_ROOT, [
            PRIM_TEXT, badge, <1.0, 0.85, 0.0>, 1.0
        ]);
        return;
    }

    if (clubMode)
    {
        if (activeDancerKey != "" && (key)activeDancerKey != NULL_KEY)
            line3 = "On stage: " + activeDancerName;
        else
            line3 = "Club Mode - Waiting for performer";
    }
    else if (goalAmount > 0)
    {
        pct   = (integer)(getFillPercent() * 100.0 + 0.5);
        line3 = "Goal: L$" + (string)goalAmount + " (" + (string)pct + "%)";
    }
    else
    {
        line3 = "Touch to tip!";
    }

    llSetText(line1 + "\n" + line2 + "\n" + line3, <0.9, 0.8, 0.2>, 1.0);
}

// ---------------------------------------------------------------
// PARTICLES - SMALL (on tips < L$500)
// ---------------------------------------------------------------
playSmallParticles()
{
    string  mode;
    integer particlesOn;
    mode        = ldStr(K_MODE);
    particlesOn = ldInt(K_PARTICLES_ON);
    if (!particlesOn) return;

    if (mode == "RNB")
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
    else if (mode == "HYPE")
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
    else if (mode == "TRAP")
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

// ---------------------------------------------------------------
// PARTICLES - BIG (on tips >= L$500)
// ---------------------------------------------------------------
playBigParticles()
{
    string  mode;
    integer particlesOn;
    mode        = ldStr(K_MODE);
    particlesOn = ldInt(K_PARTICLES_ON);
    if (!particlesOn) return;

    if (mode == "RNB")
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
    else if (mode == "HYPE")
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
    else if (mode == "TRAP")
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

// ---------------------------------------------------------------
// DEFAULT STATE
// ---------------------------------------------------------------
default
{
    state_entry()
    {
        updateHoverText();
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (num == LM_PLAY_SMALL)
        {
            playSmallParticles();
            updateVisualFeedback();
        }
        else if (num == LM_PLAY_BIG)
        {
            playBigParticles();
            updateVisualFeedback();
        }
        else if (num == LM_UPDATE_HT)
        {
            updateHoverText();
        }
        else if (num == LM_RESET_EFFECTS)
        {
            g_currentGlow = 0.0;
            llSetLinkPrimitiveParamsFast(LINK_ROOT,
                [PRIM_GLOW, ALL_SIDES, 0.0]);
            llParticleSystem([]);
            updateHoverText();
        }
        else if (num == LM_VIS_CHANGED)
        {
            // str = new visual mode
            if (str != "PARTICLES") llParticleSystem([]);
            if (str != "GLOW")
            {
                g_currentGlow = 0.0;
                llSetLinkPrimitiveParamsFast(LINK_ROOT,
                    [PRIM_GLOW, ALL_SIDES, 0.0]);
            }
        }
    }

    on_rez(integer param)
    {
        llResetScript();
    }
}
