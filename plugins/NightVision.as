/* NightVision server addon
Frontend for enabling NightVision globally
By Outerbeast
Base script "nvision" by Neo, updates by Outerbeast
*/
#include "../maps/opfor/nvision"
// These maps already have nightvision enabled via mapscript or shouldn't use nightivision
string strBlackList = "aomdc;ast;of_utbm;ss;evasion;htc;nw;shadv;bootsquad;want;sc5x_bonus;zombie_nights_;shitty_pubg";
Vector vecCustomColor = Vector( 0, 255, 0 );

CCVar cvarNVDisable( "nvision_disable", 0, "Disable nightivision", ConCommandFlag::AdminOnly );

void PluginInit()
{
   g_Module.ScriptInfo.SetAuthor( "Neo & Outerbeast" );
   g_Module.ScriptInfo.SetContactInfo( "Sven Co-op Discord" );
}

void MapInit()
{
   if( cvarNVDisable.GetInt() > 0 )
      return;

   const array<string> STR_BLACKLIST = strBlackList.Split( ";" );
   bool blShouldEnable = true;

   for( uint i = 0; i < STR_BLACKLIST.length(); i++ )
   {
      if( STR_BLACKLIST[i] == "" )
         continue;

      if( string( g_Engine.mapname ).Find( STR_BLACKLIST[i], 0, String::CaseInsensitive ) != String::INVALID_INDEX )
      {
         blShouldEnable = false;
         break;
      }
   }

   if( blShouldEnable )
      NightVision::Enable( vecCustomColor );
   else
   {
      g_EngineFuncs.ServerPrint( "NightVision: this map (" + g_Engine.mapname + ") is blacklisted!\n" );
      NightVision::Disable();
   }
}
