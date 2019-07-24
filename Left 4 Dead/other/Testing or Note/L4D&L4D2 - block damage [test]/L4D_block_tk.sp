
/* Block Tk 
 5/11/2011
 CCN_HsK */

#include <sourcemod>

new Handle:cvar_ffdamage = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D1/2] Set Friendly Fire damage",
	author = "HsK",
	description = "Set Friendly Fire damage",
	version = "1.0",
	url = "http://www.youtube.com/user/mikeg234bbq"  /* This is my youtube acc */
};

public OnPluginStart()
{
	cvar_ffdamage = CreateConVar("l4d_ffdamage", "0", "Friendly fire damage [%] [100=100%, 0=0%, 50=50%]", FCVAR_PLUGIN);

	HookEvent("player_hurt", Event_player_hurt_Pre, EventHookMode_Pre);
	HookEvent("friendly_fire", event_FriendlyFire, EventHookMode_Pre);
}


public Action:event_FriendlyFire(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	new Handle:weapon_fire = CreateEvent("weapon_fire");
	new Handle:event_hurt = CreateEvent("player_hurt");

	new Damage = GetEventInt(weapon_fire, "damage"), Damage2 = GetEventInt(event_hurt, "dmg_health")

	PrintToChat(attacker, "damage:%d dmg_health:%d", Damage, Damage2);

	return Plugin_Stop;
}

/* Set new friendly fire damage */
public Action:Event_player_hurt_Pre(Handle:event, const String:name[], bool:dontBroadcast)
{ /*
	if (!(100 >= GetConVarInt(cvar_ffdamage) >= 0)) return Plugin_Continue; // if cvar_ffdamage not is 0.0-1.0.. return!

	new victim = GetClientOfUserId(GetEventInt(event, "userid")); // Victim player
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker")); // Attacker player

	if (GetClientTeam(victim) != GetClientTeam(attacker)) // If not friendly fire... return..
		return Plugin_Continue;

	new dmg = GetEventInt(event,"dmg_health"); // Damage

	dmg *= GetConVarInt(cvar_ffdamage);
	dmg /= 100;

	PrintToChat(attacker, "cvar_ffdamage:%d, new dmg:%d dmg:%d", GetConVarInt(cvar_ffdamage), dmg, GetEventInt(event,"dmg_health"));

	SetEventInt(event, "dmg_health", dmg);

	PrintToChat(attacker, "now dmg:%d", GetEventInt(event,"dmg_health"));

	if (GetConVarInt(cvar_ffdamage) == 0) // 0 Damage
		return Plugin_Stop;

	return Plugin_Changed;
*/
}
