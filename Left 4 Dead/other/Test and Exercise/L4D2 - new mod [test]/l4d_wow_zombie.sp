
/*
普通喪屍 血量更改成 500-600.. 速度80-100.. (比原先慢2陪左右)

殺死一定數量普通喪屍會叫出大量普通喪屍

救人/幫人加血後, 自己加10-30血

普通喪屍 攻擊傷害 4陪 (bot = 1.5陪)

除去隊友傷害

近戰武器 攻擊普通喪屍 傷害更改:
    爆頭傷害: 原先傷害* ((血量/100) * 0.6)
    不爆頭傷害: 原先傷害* (0.1*((血量/100) * 0.6))

槍械 攻擊普通喪屍 傷害更改:
    爆頭傷害: 原先傷害*5.0
    不爆頭傷害: 原先傷害*0.3
*/

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

new g_Czombie = 200, g_Kzombie = 0;

new g_ActiveWeaponOffset;

public Plugin:myinfo = 
{
	name = "[L4D2] w0w Zombie Mod",
	author = "HsK",
	description = "w0w Zombie Mod",
	version = "1.0",
	url = "http://www.youtube.com/user/mikeg234bbq"  /* This is my youtube acc */
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName,"left4dead2",false))
		SetFailState("This plugin is for left4dead2 only.");

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("create_panic_event", Event_CreatePanicEvent);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("revive_success", Event_ReviveSuccess);

	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDK_TakeDamage);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "infected"))
	{
		SetConVarInt(FindConVar("z_health"), GetRandomInt(500, 600));
		SetConVarInt(FindConVar("z_speed"), GetRandomInt(80, 100));

		SDKHook(entity, SDKHook_TraceAttack, SDK_TraceAttack);
	}
}

public w0w_Zombie()
{
	SetConVarInt(FindConVar("director_build_up_min_interval"), 0);
	SetConVarInt(FindConVar("director_sustain_peak_min_time"), 0);
	SetConVarInt(FindConVar("director_sustain_peak_max_time"), 0);

	SetConVarInt(FindConVar("director_panic_forever"), 1);

	SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), 0);
	SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), 0);

	if (g_Czombie > 400) g_Czombie = 400;
	else if (g_Czombie < 150) g_Czombie = 150;

	SetConVarInt(FindConVar("z_common_limit"), (g_Czombie+20)/3);
	SetConVarInt(FindConVar("z_mega_mob_size"), (g_Czombie+20)/3);

	if (IsClientConnected(1))
	{
		new String:command[] = "director_force_panic_event";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(1, command);
		SetCommandFlags(command, flags);

		g_Czombie -= 20;
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client) return;

	if (GetClientTeam(client) != 3) return;

	if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
		g_Czombie += 800;
	else 
		g_Czombie += 30;

	w0w_Zombie();
	SendMsg(-1, 2, "***%N死時的叫聲呼叫了大量喪屍***", client);
}

public Action:Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new witch = GetEventInt(event, "witchid");

	if (GetClientTeam(attacker) == 2 && witch && IsClientConnected(attacker)) g_Czombie += 125;

	w0w_Zombie();
	SendMsg(-1, 2, "***Witch 死時的叫聲呼叫了大量喪屍***");
}

public Action:Event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_Kzombie++;
	if (g_Kzombie >= 40)
	{
		g_Kzombie = 0;
		w0w_Zombie();
		SendMsg(-1, 2, "***血腥氣味吸引了大量喪屍***");
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

public Action:Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Recepient = GetClientOfUserId(GetEventInt(event, "subject"));
	new Giver = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Recepient == Giver) return;

	SetEntityHealth(Giver, GetClientHealth(Giver)+GetRandomInt(10, 30));
}

public Action:Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Savior = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "subject"));

	SetEntityHealth(Victim, 60);
	SetEntityHealth(Savior, GetClientHealth(Savior)+GetRandomInt(10, 30));
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
				damage *= 4.0;
			else 
				damage *= 1.5;

			return Plugin_Changed;
		}

		return Plugin_Continue;
	}

	if (GetClientTeam(victim) == GetClientTeam(attacker) && GetClientTeam(attacker) == 2)
		return Plugin_Stop;

	return Plugin_Continue;
}

public Action:SDK_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
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

			if (hitgroup == 1) damage *= vigor;
			else damage *= (0.1*vigor);
			return Plugin_Changed;
		}
	}

	if (hitgroup == 1) damage *= 5.0;
	else damage *= 0.3;

	return Plugin_Changed;
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