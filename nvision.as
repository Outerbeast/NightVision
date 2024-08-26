/* Opposing Force NightVision Version 1.6
    This script brings the Opposing Force style NightVision view mode to your map, which can used with standard flash light key.
    If you want a plugin version to use as a server addon, see Nero's Custom NightVision Flashlight plugin: https://github.com/Neyami/Custom-Nightvision-Flashlight.
    
    Installation:-
    - Add the script file to "scripts/maps/opfor"
    - To enable it in your map, either do:               
    "map_script opfor/nvision" in your map's cfg file
    OR
    #include "opfor/nvision"
    in your map's main script header
    OR
    Make a trigger_script entity in your map with the keyvalue "m_iszScriptFile" "opfor/nvision"

    Usage:-
    Once you have the suit equipped (and `mp_flashlight` is set to `1`), simply use the standard flash light key to switch the OF NightVision view mode on and off.
    You can use the console command `nvision_mode` to switch between night vision and normal flashlight.

    Customisation:-
    The night vision colour is the standard green colour as featured in Opposing Force, but it is possible to customise the colour using the cvar "nvision_color" in the map cfg:
    "as_command nvision_color 255 0 0"
- Outerbeast
*/
namespace NightVision
{

enum NVMode
{
    NONE = -2,
    FLASHLIGHT_ONLY,
    OFF,
    ON
};

array<NVMode> NV_PLAYERS;

bool
    blEnabled,
    blPrecache = PrecacheDefault(),
    blInfoNVisionRegistered = InfoNVisionRegister(),
    blIllumBoost = true;

uint8
    iLife       = 2,
    iDecay      = 1,
    iFadeAlpha  = 64;

float
    flVolume    = 0.8f,
    flFadeTime  = 0.01f,
    flFadeHold  = 0.5f;

Vector vecOriginOffset;
RGBA rgbaNVColour = RGBA_GREEN;

string
    strNVOnSnd = "player/hud_nightvision.wav",
    strNVOffSnd = "items/flashlight2.wav",
    cBaseIllum = "m";

EHandle hInfoNVision;

CClientCommand@ cmdSetMode;
CCVar cvarNVColour( "nvision_color", RGBA_GREEN.ToString( false ), "Set the nightvision colour", ConCommandFlag::AdminOnly );
CScheduledFunction@ fnInit = g_Scheduler.SetTimeout( "Init", 0.1f );

bool PrecacheDefault()
{
    g_SoundSystem.PrecacheSound( "player/hud_nightvision.wav" );
    g_SoundSystem.PrecacheSound( "items/flashlight2.wav" );

    return true;
}

bool InfoNVisionRegister()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "NightVision::info_nvision", "info_nvision" );
    return g_CustomEntityFuncs.IsCustomEntity( "info_nvision" );
}

void PrecacheCustom()
{
    if( strNVOnSnd == "" || strNVOffSnd == "" )
        return;

    if( strNVOnSnd != "player/hud_nightvision.wav" )
        g_SoundSystem.PrecacheSound( strNVOnSnd );

    if( strNVOffSnd != "items/flashlight2.wav" )
        g_SoundSystem.PrecacheSound( strNVOffSnd );
}

void Init()
{
    if( blEnabled ) 
        return;

    g_Utility.StringToRGBA( rgbaNVColour, cvarNVColour.GetString() );
    Config( rgbaNVColour );
}

void Config(RGBA rgbaNVColourCustom, string strNVOnSndCustom = "player/hud_nightvision.wav", string strNVOffSndCustom = "items/flashlight2.wav")
{
    if( blEnabled )
        return;

    if( rgbaNVColourCustom != RGBA_BLACK )
        rgbaNVColour = rgbaNVColourCustom;

    if( rgbaNVColour.a < 1 || rgbaNVColour.a > 254 )
        rgbaNVColour.a = 40;// default radius of the nightvision

    strNVOnSnd = strNVOnSndCustom;
    strNVOffSnd = strNVOffSndCustom;
    PrecacheCustom();

    NV_PLAYERS = array<NVMode>( g_Engine.maxClients + 1 );

    blEnabled =
        g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, PlayerPreThink ) &&
        g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, PlayerJoinLeave ) &&
        g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, PlayerJoinLeave ) &&
        g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, PlayerKilled );

    if( blEnabled )
        @cmdSetMode = CClientCommand( "nvision_mode", "Toggles night vision on/off", SetMode );
}

void NVSwitch(EHandle hPlayer, NVMode mode)
{
    if( !hPlayer )
        return;

    CBasePlayer@ pPlayer = cast <CBasePlayer@>( hPlayer.GetEntity() );

    if( pPlayer is null || !pPlayer.IsConnected() )
        return;

    mode = NVMode( Math.clamp( NVMode::NONE, NVMode::ON, mode ) );

    switch( mode )
    {
        case NVMode::ON:
        {
            if( NV_PLAYERS[pPlayer.entindex()] != NVMode::OFF || pPlayer.m_iFlashBattery < 1 )
                break;

            g_PlayerFuncs.ScreenFade( pPlayer, Vector( rgbaNVColour.r, rgbaNVColour.g, rgbaNVColour.b ), flFadeTime, flFadeHold, iFadeAlpha, FFADE_OUT | FFADE_STAYOUT );
            g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, strNVOnSnd, flVolume, ATTN_NORM, 0, PITCH_NORM );
            NVFX( pPlayer );
            g_EntityFuncs.FireTargets( "nvision_trigger_on", pPlayer, pPlayer, USE_TOGGLE );

            break;
        }

        default:
        {
            if( NV_PLAYERS[pPlayer.entindex()] != NVMode::ON )
                break;

            g_PlayerFuncs.ScreenFade( pPlayer, Vector( rgbaNVColour.r, rgbaNVColour.g, rgbaNVColour.b ), flFadeTime, flFadeHold, iFadeAlpha, FFADE_IN );
            g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, strNVOffSnd, flVolume, ATTN_NORM, 0, PITCH_NORM );
            g_EntityFuncs.FireTargets( "nvision_trigger_off", pPlayer, pPlayer, USE_TOGGLE );
        }
    }
    // Change light style to boost overall illumination of world
    if( blIllumBoost )
    {
        NetworkMessage boost( MSG_ONE_UNRELIABLE, NetworkMessages::NetworkMessageType( 12 ), pPlayer.edict() );
        boost.WriteByte( 0 );
        boost.WriteString( mode > NVMode::OFF ? "z" : cBaseIllum );
        boost.End();
    }

    if( NV_PLAYERS[pPlayer.entindex()] != mode )
        

    NV_PLAYERS[pPlayer.entindex()] = mode;
}

void NVFX(EHandle hPlayer)
{
    if( !hPlayer )
        return;

    CBasePlayer@ pPlayer = cast <CBasePlayer@>( hPlayer.GetEntity() );

    if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
        return;

    const Vector vecPosition = pPlayer.pev.origin + vecOriginOffset;

    NetworkMessage nvfx( MSG_ONE_UNRELIABLE, NetworkMessages::SVC_TEMPENTITY, pPlayer.edict() );
        nvfx.WriteByte( TE_DLIGHT );

        nvfx.WriteCoord( vecPosition.x );
        nvfx.WriteCoord( vecPosition.y );
        nvfx.WriteCoord( vecPosition.z );

        nvfx.WriteByte( rgbaNVColour.a );// radius of nvfx
        nvfx.WriteByte( rgbaNVColour.r );
        nvfx.WriteByte( rgbaNVColour.g );
        nvfx.WriteByte( rgbaNVColour.b );

        nvfx.WriteByte( iLife );
        nvfx.WriteByte( iDecay );
    nvfx.End();
}

HookReturnCode PlayerPreThink(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    if( pPlayer is null || !pPlayer.IsAlive() || NV_PLAYERS[pPlayer.entindex()] <= NVMode::FLASHLIGHT_ONLY )
        return HOOK_CONTINUE;

    if( pPlayer.FlashlightIsOn() )
    {
        if( NV_PLAYERS[pPlayer.entindex()] == NVMode::OFF )
            NVSwitch( pPlayer, NVMode::ON );
        else if( NV_PLAYERS[pPlayer.entindex()] == NVMode::ON )
            NVFX( pPlayer );
    }
    else if( NV_PLAYERS[pPlayer.entindex()] == NVMode::ON )
        NVSwitch( pPlayer, NVMode::OFF );

    return HOOK_CONTINUE;
}

HookReturnCode PlayerJoinLeave(CBasePlayer@ pPlayer)
{
    if( pPlayer !is null )
        NVSwitch( pPlayer, NVMode::OFF );

    return HOOK_CONTINUE;
}

HookReturnCode PlayerKilled(CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib)
{
    if( pPlayer !is null )
        NVSwitch( pPlayer, NVMode::OFF );

    return HOOK_CONTINUE;
}

void SetMode(const CCommand@ cmdArgs)
{
    CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

    if( pPlayer is null )
        return;

    NVMode newmode = NV_PLAYERS[pPlayer.entindex()] == NVMode::FLASHLIGHT_ONLY ? NVMode::OFF : NVMode::FLASHLIGHT_ONLY;

    if( cmdArgs.ArgC() != 1 )
        newmode = NVMode( Math.clamp( -1, 0, atoui( cmdArgs[1] ) - 1 ) );

    NVSwitch( pPlayer, newmode );
    const string strMsg = NV_PLAYERS[pPlayer.entindex()] == NVMode::OFF ? "night vision" : "flashlight only";
    g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "NightVision mode set to: " + strMsg + "\n" );
}

void Disable()
{
    if( !blEnabled )
        return;

    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
        NVSwitch( g_PlayerFuncs.FindPlayerByIndex( iPlayer ), NVMode::NONE );

    @cmdSetMode = null;
    g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink, PlayerPreThink );
    g_Hooks.RemoveHook( Hooks::Player::ClientPutInServer, PlayerJoinLeave );
    g_Hooks.RemoveHook( Hooks::Player::ClientDisconnect, PlayerJoinLeave );
    g_Hooks.RemoveHook( Hooks::Player::PlayerKilled, PlayerKilled );
    blEnabled = false;

    if( fnInit !is null )
        g_Scheduler.RemoveTimer( fnInit );
}

final class info_nvision : ScriptBaseEntity
{
    private uint
        SF_START_OFF            = 1 << 0,
        SF_ACTIVATOR_ONLY       = 1 << 1,
        SF_DISABLE_CONSOLE_CMD  = 1 << 2,
        SF_DONT_BOOST_ILLUM     = 1 << 3;

    private NVMode startingmode = NVMode::OFF;

    bool KeyValue(const string & in szKey, const string & in szValue)
    {
        if( szKey == "nvmode" )
            startingmode = NVMode( atoui( szValue ) );
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void PreSpawn()
    {// Only one entity of this type is allowed to exist, to prevent conflicts
        if( hInfoNVision )
        {
            g_EntityFuncs.Remove( self );
            return;
        }

        BaseClass.PreSpawn();
    }

    void Spawn()
    {
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        self.pev.effects |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.pev.rendercolor == g_vecZero )
            self.pev.rendercolor = Vector( 0, 255, 0 );

        if( self.pev.view_ofs != g_vecZero )
            vecOriginOffset = self.pev.view_ofs;

        if( self.pev.noise1 == "" )
            self.pev.noise1 = strNVOnSnd;

        if( self.pev.noise2 == "" )
            self.pev.noise2 = strNVOffSnd;

        blIllumBoost = !self.pev.SpawnFlagBitSet( SF_DONT_BOOST_ILLUM );

        g_Scheduler.RemoveTimer( fnInit );
        Config( RGBA( self.pev.rendercolor, int( self.pev.renderamt ) ), self.pev.noise1, self.pev.noise2 );
        // After config the following must be done
        if( self.pev.SpawnFlagBitSet( SF_DISABLE_CONSOLE_CMD ) )
            @cmdSetMode = null;// disable the console cmd for changing the nvmode

        if( self.pev.SpawnFlagBitSet( SF_START_OFF ) && self.GetTargetname() != "" )// !-BUG-!: not working
            self.Use( null, self, USE_OFF );

        hInfoNVision = self;
        self.pev.nextthink = g_Engine.time + 0.5f;

        BaseClass.Spawn();
    }

    void Think()
    {
        RGBA rgbaNewColour = RGBA( self.pev.rendercolor, self.pev.renderamt < 1 || self.pev.renderamt > 254 ? 40 : uint8( self.pev.renderamt ) );

        if( rgbaNewColour != rgbaNVColour )
            rgbaNVColour = rgbaNewColour;

        if( vecOriginOffset != self.pev.view_ofs )
            vecOriginOffset = self.pev.view_ofs;

        self.pev.nextthink = g_Engine.time + 0.5f;
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        NVMode newmode;
        int iPlayer = self.pev.SpawnFlagBitSet( SF_ACTIVATOR_ONLY ) ? pActivator.entindex() : 0;

        switch( useType )
        {
            case USE_OFF:
                newmode = NVMode::FLASHLIGHT_ONLY;
                break;

            case USE_ON:
                newmode = NVMode::OFF;// OFF as in its still available to be turned on manually
                break;

            case USE_TOGGLE:
                newmode = NV_PLAYERS[iPlayer] == NVMode::FLASHLIGHT_ONLY ? NVMode::OFF : NVMode::FLASHLIGHT_ONLY;
                break;

            case USE_KILL:
                g_EntityFuncs.Remove( self );
                break;
        }

        if( self.pev.SpawnFlagBitSet( SF_ACTIVATOR_ONLY ) )
            NVSwitch( cast<CBasePlayer@>( pActivator ), newmode );
        else
        {
            NV_PLAYERS[0] = newmode;

            for( iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
                NVSwitch( g_PlayerFuncs.FindPlayerByIndex( iPlayer ), newmode );
        }

        self.SUB_UseTargets( pActivator, useType, flValue );
    }

    void UpdateOnRemove()
    {
        Disable();
        BaseClass.UpdateOnRemove();
    }
};

}
/* Special thanks:-
Neo - programming initial versions
Nero - Methodology (his own night vision plugin can be found here: https://github.com/Neyami/Custom-Nightvision-Flashlight )
*/
