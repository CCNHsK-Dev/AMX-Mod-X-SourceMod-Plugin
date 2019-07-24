
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "[L4D2] Yet another Zombie feel in L4D",
	author = "HsK",
	description = "Yet another Zombie feel in L4D",
	version = "1.0",
	url = "http://www.youtube.com/user/mikeg234bbq"  /* This is my youtube acc */
};

new g_ActiveWeaponOffset;
new g_killZombie;
new g_CallZombie;

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName,"left4dead2",false))
		SetFailState("This plugin is for left4dead2 only.");

	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("weapon_reload",Event_ReloadAmmo);

	HookEvent("player_death", Event_PlayerDeath);

	HookEvent("create_panic_event", Event_CreatePanicEvent);

	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDK_TakeDamage);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "infected"))
		SDKHook(entity, SDKHook_TraceAttack, SDK_TraceAttack);
}

public Action:Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Recepient = GetClientOfUserId(GetEventInt(event, "subject"));
	new Giver = GetClientOfUserId(GetEventInt(event, "userid"));
	new Amount = GetEventInt(event, "health_restored");

	if (Recepient == Giver) return;

	new giverNewHealth = (Amount/10)*(GetRandomInt(5, 10));
	giverNewHealth += GetClientHealth(Giver);
	if (giverNewHealth > 100) giverNewHealth = 100;

	SendMsg(Giver, 2, "You Heal %N %d Health, So you will have %d Health", Recepient, Amount, giverNewHealth);
	SendMsg(Recepient, 2, "Player[%N] heal your health %d", Giver, Amount);
	SetEntityHealth(Giver, giverNewHealth);
}

public Action:Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Savior = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "subject"));

	new giverNewHealth = 90;
	if (GetClientHealth (Savior) > 90)
		giverNewHealth = GetClientHealth (Savior);

	SendMsg(Savior, 2, "you help %N revivem,  So you will have %d Health!", Victim, giverNewHealth);
	SendMsg(Victim, 2, "Player[%N] help you revive!", Savior);

	SetEntityHealth(Savior, giverNewHealth);
}

public Action:Event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_CallZombie == 0)
		g_CallZombie = 20;

	g_killZombie++;
	if (g_killZombie >= g_CallZombie)
	{
		g_killZombie = 0;
		w0w_Zombie();
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!client || !attacker) return;

	if (GetClientTeam(attacker) == 2 && GetClientTeam(client) == 3)
	{
		if (GetEntProp(client, Prop_Send, "m_zombieClass"))
		{
			SendMsg(-1, 2, "Wow! %N kill Tank [%N]!!", attacker, client);
			SendMsg(attacker, 2, "So Good, You have 100 Health Now!!!");
			SetEntityHealth(attacker, 100);
			return;
		}

		SendMsg(attacker, 2, "You Kill %N, You will have %d Health!", client, GetClientHealth(attacker)+10);
		SetEntityHealth(attacker, GetClientHealth(attacker)+10);
	}
}

public Action:Event_ReloadAmmo(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client) return;

	new cheatsoff = GetCommandFlags("give");
	SetCommandFlags("give", cheatsoff & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give ammo");
	SetCommandFlags("give",cheatsoff|FCVAR_CHEAT);
}

public w0w_Zombie()
{
	SetConVarInt(FindConVar("director_build_up_min_interval"), 0);
	SetConVarInt(FindConVar("director_sustain_peak_min_time"), 0);
	SetConVarInt(FindConVar("director_sustain_peak_max_time"), 0);

	SetConVarInt(FindConVar("director_panic_forever"), 1);

	SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), 0);
	SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), 0);

	g_CallZombie = 50;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) != 2)
		{
			g_CallZombie /= 2;

			if (g_CallZombie <= 20)
			{
				g_CallZombie = 20;
				break;
			}
		}
	}

	SetConVarInt(FindConVar("z_common_limit"), g_CallZombie);
	SetConVarInt(FindConVar("z_mega_mob_size"), g_CallZombie);

	if (IsClientConnected(1))
	{
		new String:command[] = "director_force_panic_event";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(1, command);
		SetCommandFlags(command, flags);
	}
}

public Event_CreatePanicEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
			StopSound(i, SNDCHAN_STATIC, "npc/mega_mob/mega_mob_incoming.wav");
	}
}

public Action:SDK_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (!attacker || attacker > 18)
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2)
		return Plugin_Continue;

	new Attack_Weapon = GetEntDataEnt2(attacker, g_ActiveWeaponOffset);
	if (IsValidEntity(Attack_Weapon))
	{
		new String:Weapon_Name[32];
		GetEdictClassname(Attack_Weapon, Weapon_Name, sizeof(Weapon_Name));

		if (StrEqual(Weapon_Name, "weapon_melee"))
		{
			new Float:vigor = GetClientHealth(attacker)*1.0;
			vigor /= 100;  vigor *= 0.6;

			if (hitgroup == 1)
			{
				damage *= vigor;

				if (damage < 50 && GetRandomInt(0, 2) != 1)
					damage = 0.0;
			}
			else damage *= 0.01;

			return Plugin_Changed;
		}
	}

	if (hitgroup == 1) damage *= 50.0;
	else damage *= 0.01;

	return Plugin_Changed;
}

public Action:SDK_TakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!attacker || victim > 18 || !victim) return Plugin_Continue;

	if (attacker > 18)
	{
		new String:Class_Name[32];
		GetEdictClassname(attacker, Class_Name, sizeof(Class_Name));
		if (StrEqual(Class_Name, "infected"))
		{
			if (!get_user_bot(victim))
				damage *= 2.0;
			else 
				damage *= 1.5;

			if (damage > 15.0)
				damage = 15.0;

			return Plugin_Changed;
		}

		return Plugin_Continue;
	}

	if (GetClientTeam(victim) == GetClientTeam(attacker) && GetClientTeam(attacker) == 2)
		return Plugin_Stop;

	return Plugin_Continue;
}

stock SendMsg(client, Tc, const String:format[], any:...)
{
	decl String:buffer[192];
	VFormat(buffer, sizeof(buffer), format, 4);

	if (client == -1)
	{
		for(client=1; client<=GetMaxClients(); client++)
			SendMsg(client, Tc, buffer);

		return;
	}

	if (!client || !IsClientConnected(client)) return;

	switch(Tc)
	{
		case 1: PrintHintText(client, buffer);
		case 2: PrintToChat(client, "\x04%s\x03", buffer);
		case 3: PrintCenterText(client, buffer);
		case 4:
		{
			PrintHintText(client, buffer);
			PrintToChat(client, buffer);
		}
	}
}

stock get_user_bot(client)
{
	if (!client || !IsClientConnected(client)) return false;

	new String:SteamID[50];
	GetClientAuthString(client, SteamID, sizeof(SteamID));

	if (StrEqual(SteamID, "BOT")) return true;
	else return false;
}