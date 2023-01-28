
/* Game Msg for L4D & L4D2
  15/4/2011
  CCN_HsK */

#include <sourcemod>

new game_mod;
new Handle:HudMessage = INVALID_HANDLE;
new g_THeal[MAXPLAYERS+1], g_PRevive[MAXPLAYERS+1], g_PHeal[MAXPLAYERS+1];
new g_KZombie[MAXPLAYERS+1], g_KWitch[MAXPLAYERS+1], g_KTank[MAXPLAYERS+1], g_KHunter[MAXPLAYERS+1], g_KSmoker[MAXPLAYERS+1], g_KBoomer[MAXPLAYERS+1];
new g_KSurvivor[MAXPLAYERS+1], g_SMPull[MAXPLAYERS+1], g_HUPounce[MAXPLAYERS+1];

new g_KJockey[MAXPLAYERS+1], g_KSpitter[MAXPLAYERS+1], g_KCharger[MAXPLAYERS+1];
new g_JORide[MAXPLAYERS+1], g_CHCharge[MAXPLAYERS+1];
new g_PUsepills[MAXPLAYERS+1], g_PUseadRE[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Game Msg [L4D1/2]",
	author = "HsK",
	description = "Kill Zombie MsG!!",
	version = "1.0",
	url = "http://www.youtube.com/user/mikeg234bbq"  /* This is my youtube acc */
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName,"left4dead",false) && !StrEqual(ModName,"left4dead2",false))
		SetFailState("This plugin is for left4dead or left4dead2 only.");

	if (StrEqual(ModName,"left4dead2",false)) game_mod = 2;
	else game_mod = 1;

	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_incapacitated_start", Event_IncapStart);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("tongue_grab", Event_TongueGrab);
	HookEvent("pounce_end", Event_PounceEnd);
	HookEvent("pills_used", Event_PillsUsed);

	if (game_mod == 2)
	{
		HookEvent("jockey_ride", Event_JockeyRide);
		HookEvent("charger_charge_end", Event_ChargerCharge)
		HookEvent("adrenaline_used", Event_AdrenalineUsed);
	}

	HudMessage = CreateHudSynchronizer();
}

public OnClientPutInServer(client)
{
	CreateTimer(5.0, L4D_MSG, client);
}

public Action:L4D_MSG(Handle:timer, any:value)
{
	new client = value, Handle:RankPanel = CreatePanel(), String:Value[64];

	if (!client || !IsClientConnected(client)) return;

	if (get_user_bot(client)) return;

	Format(Value, sizeof(Value), " !L4D MSG By'HsK!");
	SetPanelTitle(RankPanel, Value);

	if (GetClientTeam(client) == 2)
	{
		Format(Value, sizeof(Value), " [Kill] Zombie:%d | Witch:%d", g_KZombie[client], g_KWitch[client]);
		DrawPanelText(RankPanel, Value);

		Format(Value, sizeof(Value), " Tank:%d | Hunter:%d | Smoker:%d | Boomer:%d", 
		g_KTank[client], g_KHunter[client], g_KSmoker[client], g_KBoomer[client]);
		DrawPanelText(RankPanel, Value);

		if (game_mod == 2) {
			Format(Value, sizeof(Value), " Jockey:%d | Spitter:%d | Charger:%d", 
			g_KJockey[client], g_KSpitter[client], g_KCharger[client]);
			DrawPanelText(RankPanel, Value);
		}

		DrawPanelText(RankPanel, " ");

		Format(Value, sizeof(Value), " [Help Team] Heal:%d | Revive:%d", g_THeal[client], g_PRevive[client]);
		DrawPanelText(RankPanel, Value);

		Format(Value, sizeof(Value), " [USE] Heal:%d | Pills:%d", g_PHeal[client]-g_THeal[client], g_PUsepills[client]);
		if (game_mod == 2)
			Format(Value, sizeof(Value), "%s | Adrenaline:%d", Value, g_PUseadRE[client]);

		DrawPanelText(RankPanel, Value);
	}
	else if (GetClientTeam(client) == 3)  // zombie
	{
		Format(Value, sizeof(Value), " [Kill] Survivor:%d", g_KSurvivor[client]);
		DrawPanelText(RankPanel, Value);

		Format(Value, sizeof(Value), " [SKill] Hunter Pounce:%d | Smoker Tongue:%d", g_HUPounce[client], g_SMPull[client]);
		DrawPanelText(RankPanel, Value);

		if (game_mod == 2) { 
			Format(Value, sizeof(Value), " Jockey Ride:%d | Charger Charge:%d", g_JORide[client], g_CHCharge[client]);
			DrawPanelText(RankPanel, Value);
		}
	}

	SendPanelToClient(RankPanel, client, RankPanelHandler, 7);
	CloseHandle(RankPanel);

	CreateTimer(5.0, L4D_MSG, client);
}

public RankPanelHandler(Handle:menu, MenuAction:action, param1, param2) { 
}

public Action:Event_TongueGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new smoker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	g_SMPull[smoker] += 1;

	SendMsg(smoker, 2, "Your tongue grab %N..", victim);
	SendMsg(victim, 2, "%N tongue grab you..", smoker);
}

public Action:Event_PounceEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!attacker || !victim || !IsClientConnected(attacker) || !IsClientConnected(victim)) return;

	if (!l4d_get_user_hunter(attacker) || GetClientTeam(victim) != 2) return;

	g_HUPounce[attacker] += 1;

	SendMsg(attacker, 2, "You pounce %N..", victim);
	SendMsg(victim, 2, "%N pounce you..", attacker);
}

public Action:Event_JockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (game_mod == 1 || !attacker || !victim || !IsClientConnected(attacker) || !IsClientConnected(victim)) return;

	g_JORide[attacker] += 1;

	SendMsg(attacker, 2, "You ride %N..", victim);
	SendMsg(victim, 2, "%N ride you..", attacker);
}

public Action:Event_ChargerCharge(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (game_mod == 1 || !attacker || !victim || !IsClientConnected(attacker) || !IsClientConnected(victim)) return;

	g_CHCharge[attacker] += 1;

	SendMsg(attacker, 2, "You charge %N..", victim);
	SendMsg(victim, 2, "%N charge you..", attacker);
}

public Action:Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Recepient = GetClientOfUserId(GetEventInt(event, "subject"));
	new Giver = GetClientOfUserId(GetEventInt(event, "userid"));
	new Amount = GetEventInt(event, "health_restored");

	g_PHeal[Giver] += 1;

	if (Recepient == Giver) return;

	g_THeal[Giver] += 1;

	SendMsg(Giver, 2, "You Heal %N %d Health", Recepient, Amount);
	SendMsg(Recepient, 2, "Player[%N] heal your health %d", Giver, Amount);
}

public Action:Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Savior = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "subject"));

	g_PRevive[Savior] += 1;

	SendMsg(Savior, 2, "you help %N revive", Victim);
	SendMsg(Victim, 2, "Player[%N] help you revive!", Savior);
}

public Action:Event_PillsUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"subject"));

	g_PUsepills[client] += 1;
}

public Action:Event_AdrenalineUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	g_PUseadRE[client] += 1;
}

public Action:Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new witch = GetEventInt(event, "witchid");

	if (GetClientTeam(attacker) == 2 && witch && IsClientConnected(attacker))
	{
		g_KWitch[attacker] += 1;
		SendMsg(attacker, 2, "Kill Witch!! You Kill [%d] Witch!!", g_KWitch[attacker]);

		SendMsg(-1, 2, "Player [%N] Kill [Witch]", attacker);
	}
}

public Action:Event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!attacker) return;

	new attacker_team = GetClientTeam(attacker);

	if (attacker_team != 2) return;

	g_KZombie[attacker] += 1;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!client || !IsClientConnected(attacker)) return;

	new attacker_team = GetClientTeam(attacker);
/*
	new class = GetEntProp(client, Prop_Send, "m_zombieClass");
	SendMsg(-1, 2, "zombie class %d", class);  Test l4d zombie class id/.\ */

	if (attacker_team == 2)
	{
		decl String:zombie_name[10];

		if (l4d_get_user_tank(client))
		{
			g_KTank[attacker] += 1;
			SendMsg(attacker, 2, "Kill TANK!! You Kill [%d] Tank!!", g_KTank[attacker]);
			VFormat(zombie_name, sizeof(zombie_name), "Tank", 4);
		}
		if (l4d_get_user_hunter(client))
		{
			g_KHunter[attacker] += 1;
			SendMsg(attacker, 2, "Kill Hunter!! You Kill [%d] Hunter!!", g_KHunter[attacker]);
			VFormat(zombie_name, sizeof(zombie_name), "Hunter", 4);
		}
		if (l4d_get_user_smoker(client))
		{
			g_KSmoker[attacker] += 1;
			SendMsg(attacker, 2, "Kill Smoker!! You Kill [%d] Smoker!!", g_KSmoker[attacker]);
			VFormat(zombie_name, sizeof(zombie_name), "Smoker", 4);
		}
		if (l4d_get_user_boomer(client))
		{
			g_KBoomer[attacker] += 1;
			SendMsg(attacker, 2, "Kill Boomer!! You Kill [%d] Boomer!!", g_KBoomer[attacker]);
			VFormat(zombie_name, sizeof(zombie_name), "Boomer", 4);
		}
		
		if (l4d_get_user_jockey(client))
		{
			g_KJockey[attacker] += 1;
			SendMsg(attacker, 2, "Kill Jockey!! You Kill [%d] Jockey!!", g_KJockey[attacker]);
			VFormat(zombie_name, sizeof(zombie_name), "Jockey", 4);
		}

		if (l4d_get_user_charger(client))
		{
			g_KCharger[attacker] += 1;
			SendMsg(attacker, 2, "Kill Charger!! You Kill [%d] Charger!!", g_KCharger[attacker]);
			VFormat(zombie_name, sizeof(zombie_name), "Charger", 4);
		}

		if (l4d_get_user_spitter(client))
		{
			g_KSpitter[attacker] += 1;
			SendMsg(attacker, 2, "Kill Spitter!! You Kill [%d] Spitter!!", g_KSpitter[attacker]);
			VFormat(zombie_name, sizeof(zombie_name), "Spitter", 4);
		}

		SendMsg(-1, 2, "Player [%N] Kill [%N - Class: %s]", attacker, client, zombie_name);
	}
	else if (attacker_team == 3)
	{
		if (GetClientTeam(client) == attacker_team) return;
		g_KSurvivor[attacker] += 1;
		SendMsg(attacker, 2, "Kill Survivor!! You Kill [%d] Survivor!!", g_KSurvivor[attacker]);

		SendMsg(-1, 2, "Zombie [%N] Kill [%N]", attacker, client);
	}
	else
	{
		if (GetClientTeam(client) != 2) return;

		SendMsg(-1, 2, "Player [%N] death", client);
	}
}

public Event_IncapStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!client) return;
	
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if (!IsClientConnected(i)) continue;

		if (i == client)
		{
			SendMsg(i, 1, "Now.. you Incapacitated!"); continue;
		}

		if (GetClientTeam(i) == 2)
			SendMsg(i, 1, "Player [%N] Incapacitated now..!! Go help!!", client);
		else if (GetClientTeam(i) == 3)
			SendMsg(i, 1, "Player [%N] Incapacitated now..!! Go Kill He!!", client);
	}
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

	SetHudTextParams(0.04, 0.4, 2.0, 255, 128, 0, 255);
	ShowSyncHudText(client, HudMessage, buffer);

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

stock l4d_get_user_boomer(client)
{
	if (!client || !IsClientConnected(client)) return false;

	if (GetEntProp(client, Prop_Send, "m_zombieClass") == 2) return true;
	return false;
}

stock l4d_get_user_hunter(client)
{
	if (!client || !IsClientConnected(client)) return false;

	if (GetEntProp(client, Prop_Send, "m_zombieClass") == 3) return true;
	return false;
}

stock l4d_get_user_smoker(client)
{
	if (!client || !IsClientConnected(client)) return false;

	if (GetEntProp(client, Prop_Send, "m_zombieClass") == 1) return true;
	return false;
}

stock l4d_get_user_tank(client)
{
	if (!client || !IsClientConnected(client)) return false;
 
	if (game_mod == 1 && GetEntProp(client, Prop_Send, "m_zombieClass") == 5) return true;

	if (game_mod == 2 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8) return true;

	return false;
}

stock l4d_get_user_spitter(client)
{
	if (game_mod == 1 || !client || !IsClientConnected(client)) return false;

	if  (GetEntProp(client, Prop_Send, "m_zombieClass") == 4) return true;

	return false;
}

stock l4d_get_user_jockey(client)
{
	if (game_mod == 1 || !client || !IsClientConnected(client)) return false;

	if  (GetEntProp(client, Prop_Send, "m_zombieClass") == 5) return true;

	return false;
}

stock l4d_get_user_charger(client)
{
	if (game_mod == 1 || !client || !IsClientConnected(client)) return false;

	if  (GetEntProp(client, Prop_Send, "m_zombieClass") == 6) return true;

	return false;
}

get_user_bot(client)
{
	if (!client || !IsClientConnected(client)) return false;

	new String:SteamID[50];
	GetClientAuthString(client, SteamID, sizeof(SteamID));

	if (StrEqual(SteamID, "BOT")) return true;
	else return false;
}
