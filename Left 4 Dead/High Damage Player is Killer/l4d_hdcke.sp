
/* 
			Left 4 Dead / Left 4 Dead 2
			High Damage Player is Killer
			以傷害計算殺敵
				9/7/2012 (Version: 1.0)
			
					HsK-Dev Blog By CCN
			
			http://ccnhsk-dev.blogspot.com/
*/

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "[L4D/L4D2] High Damage Player is Killer",
	author = "HsK-Dev Blog By CCN",
	description = "High Damage Player is Killer",
	version = "1.0",
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
	HookEvent("player_death", Event_Player_death, EventHookMode_Pre);
	HookEvent("player_hurt", Event_player_hurt_Post, EventHookMode_Post);
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

	remove_damage (client);
}

public Event_player_hurt_Post(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!m_modeStart)
		return;

	new victim = GetClientOfUserId(GetEventInt(event, "userid")); // Victim player
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker")); // Attacker player

	// If Victim or attacker is not 'player' break;
	if (!victim || !attacker || victim > 18 || attacker > 18)
		return;

	// Attacker is human and Victim is Zombie
	if (GetClientTeam (attacker) != 2 || GetClientTeam (victim) != 3)
		return;

	g_damage[victim][attacker] += GetEventInt(event,"dmg_health");

	// Save Player Damage....
}

public Action:Event_Player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!m_modeStart)
		return;

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	// Victim is 'player' and Zombie
	if (!victim || victim > 18)
		return Plugin_Continue;

	if (GetClientTeam (victim) != 3)
		return Plugin_Continue;

	// Get who give vicitm high damage
	new maxDamageClient = -1;
	for (new i = 1; i <= 18; i++)
	{
		if (!IsClientConnected (i))
			continue;

		if (GetClientTeam (i) != 2)
			continue;

		if (maxDamageClient == -1)
		{
			if (g_damage[victim][i] > 0)
				maxDamageClient = i;
			continue;
		}

		if (g_damage[victim][i] > g_damage[victim][maxDamageClient])
			maxDamageClient = i;  // high damage player
	}

	remove_damage (victim); // Now can Remove damage

	if (maxDamageClient == -1) // Have not player damage Zombie
		return Plugin_Continue;

	new String:Weapon[32];
	GetEventString (event, "weapon", Weapon, 31); // Get Attacker Weapon

	// New player_death Event Call
	new Handle:newevent = CreateEvent("player_death")
	SetEventInt(newevent, "userid", GetClientUserId(victim))
	SetEventInt(newevent, "attacker", GetClientUserId (maxDamageClient));
	SetEventString(newevent, "weapon", Weapon);
	SetEventBool(newevent, "headshot", GetEventBool(event, "headshot"));
	FireEvent(newevent);

	return Plugin_Handled; // Block old Event

	/* I cannot use _Changed.... */
}
