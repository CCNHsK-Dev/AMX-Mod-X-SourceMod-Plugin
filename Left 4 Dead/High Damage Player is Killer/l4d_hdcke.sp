
/* 
			Left 4 Dead / Left 4 Dead 2
			High Damage Player is Killer
			以傷害計算殺敵
				Version: 1.0 - 9/7/2012
						 1.1 - 27/7/2019
						 	* Support Lastly Version SMX
			
					HsK-Dev Blog By CCN
			
			http://ccnhsk-dev.blogspot.com/
*/

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "[L4D/L4D2] High Damage Player is Killer",
	author = "HsK-Dev Blog By CCN",
	description = "High Damage Player is Killer",
	version = "1.1",
	url = "http://ccnhsk-dev.blogspot.com/"
};

new bool:m_modeStart = true;
new g_damage[MAXPLAYERS+1][MAXPLAYERS+1];

public OnPluginStart()
{
	m_modeStart = true;
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName,"left4dead",false) && !StrEqual(ModName,"left4dead2",false))
	{
		SetFailState("This plugin is for Left 4 Dead/Left 4 Dead 2 only.");
		m_modeStart = false;
	}

	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("player_death", Event_Player_death);
	HookEvent("player_hurt", Event_player_hurt);
}

stock remove_damage (client)
{
	for (new i = 1; i <= GetMaxClients (); i++)
		g_damage[client][i] = 0;
}

public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Spawn Player Remove Damage

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If Spawn Entity is not 'Player' break;
	if (client > 18)
		return;
	
	remove_damage (client); // New Player / Spawn Player Remove old Damage Data
}

public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!m_modeStart)
		return;

	new victim = GetClientOfUserId(GetEventInt(event, "userid")); 
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!victim || !attacker || victim > 18 || attacker > 18)
		return;

	// Attacker is human and Victim is Zombie
	if (GetClientTeam (attacker) == 2 && GetClientTeam (victim) == 3)
		g_damage[victim][attacker] += GetEventInt(event,"dmg_health");
}

public Action:Event_Player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!m_modeStart)
		return Plugin_Continue;

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	// Victim is not 'player zombie'
	if (!victim || victim > 18 || GetClientTeam (victim) != 3)
		return Plugin_Continue;

	// Get Top Damage Player
	new maxDamageClient = -1;
	for (new i = 1; i <= 18; i++)
	{
		if (!IsClientConnected (i) || GetClientTeam (i) != 2)
			continue;

		if (maxDamageClient == -1)
		{
			if (g_damage[victim][i] > 0)
				maxDamageClient = i;
			continue;
		}

		if (g_damage[victim][i] > g_damage[victim][maxDamageClient])
			maxDamageClient = i; 
	}

	remove_damage (victim); // Remove Damage Data

	if (maxDamageClient == -1) // If Not Top Damage Player
		return Plugin_Continue;

	new String:Weapon[32];
	GetEventString (event, "weapon", Weapon, 31);

	// New player_death Event Call
	new Handle:newevent = CreateEvent("player_death")
	SetEventInt(newevent, "userid", GetClientUserId(victim))
	SetEventInt(newevent, "attacker", GetClientUserId (maxDamageClient));
	SetEventString(newevent, "weapon", Weapon);
	SetEventBool(newevent, "headshot", GetEventBool(event, "headshot"));
	FireEvent(newevent);

	return Plugin_Handled;
}
