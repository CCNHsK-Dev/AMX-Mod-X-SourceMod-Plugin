
/* 
			DeathMatch: Kill Duty Source - Upgrade 1
				19/2/2018 (Version: 2.0)
			
					HsK-Dev Blog By CCN
			
			http://ccnhsk-dev.blogspot.com/
*/

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "DeathMatch: Kill Duty Source",
	author = "HsK-Dev Blog By CCN",
	description = "Deathmatch: Kill Duty Source",
	version = "2.0.0.33",
	url = "http://ccnhsk-dev.blogspot.com/"
};

#define MODE_TDM                0
#define MODE_DM                 1

// Block hostage and c4 [reference amxx plugin]
new const String:OBJECTIVE_ENTITYS[][] = { "func_vehicleclip", "func_hostage_rescue", "func_bomb_target", 
	"hostage_entity", "info_hostage_rescue", "info_bomb_target", "prop_physics_multiplayer"}

// This order reference [cstrike.inc] 
new const String:WEAPON_CLASSNAME[][] = {  "",  "weapon_p228", "weapon_glock", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", 
	"weapon_c4",  "weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", 
	"weapon_sg550", "weapon_galil",  "weapon_famas", "weapon_usp", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", 
	"weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" } 

new const g_AmmoOffset[] = { 0, 9, 6, 2, 0, 7, 0, 8, 2, 0, 6, 0, 8, 3, 3, 3, 8, 5, 6, 4, 7, 3, 6, 2, 0, 1, 3, 2, 0, 10 }
new const g_BpAmmo[] = { -1, 52, 120, 100, 1, 32, 1, 100, 90, 1, 120, -1, 100, 90, 90, 90, 100, 30,  120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

// Game vars
new g_dmMode = -1; // DM MoD
new bool:g_dmGameStart = false;
new bool:g_dmGameEnd = false;

new Float:g_secondThinkTime; // Second Think
new g_gameTime[2], g_maxGameTime; // Game Time

new g_maxKill, g_maxKillData; // Max Kill
new g_teamCTKill, g_teamTRKill; // CT and TR Kill [tdm]
new g_topKiller; // Top Killer Id
new Float:g_freezeTime, g_freezeTimeData; // Game Freeze Time

new Float:g_spawnTime; // Player Respawn Time
new Float:g_spawnGodTime; // Player Protect Time
new Float:g_enforcementSpawnTime; // Player Enforcement Spawn Time
new Float:g_removeDropWeaponTime; // Remove Dropped Weapon Time
new g_ammoUnlimitbp; // Unlimited Ammo(Magazine)
new g_blockKill; // Block player Suicide
new g_tdmBuyZoneAddHpStart; // TDM Mode BuyZone Add HP On 
new Float:g_tdmBuyZoneAddHpTime; // TDM Mode BuyZone Add HP Time
new g_tdmBuyZoneAddHp; // TDM Mode BuyZone Add HP
new g_dmKillEnemyAddHP; // DM Mode Kill Enemy Add HP

new g_nextMapId, Float:g_changeMapTime; // Map Change

// Maps & Spawn Point
new g_mapsCount, String:g_mapsName[64][128];// Ran MAP set
new Float:g_spawns[128][3], g_spawnCount; // Ran Spawn set

// Weapon Menu 
new g_spawnGetGrenade[3]; // Give Grenade
new g_priweaponNum, g_secweaponNum; // Weapon Menu Num
new g_priweaponID[30], g_secweaponID[30]; // Weapon Menu weapon id
new String:g_priweaponName[30][512], String:g_secweaponName[30][512]; // Weapon Menu weapon name

// Player vars
Menu m_menu[MAXPLAYERS + 1];  // For Player Menu
new m_menuType[MAXPLAYERS + 1]; // For Player Menu
new Float:m_showMsgTime[MAXPLAYERS + 1]; // Show Msg Time
new m_priWeaponID[MAXPLAYERS + 1],  m_secWeaponID[MAXPLAYERS + 1]; // Is Weap set
new bool:m_godMode[MAXPLAYERS + 1], Float:m_godModeTime[MAXPLAYERS + 1]; // Is Protect 
new Float:m_spawnTime[MAXPLAYERS + 1]; // Player Spawn Time
new Float:m_enforcementSpawnTime[MAXPLAYERS + 1]; // Player Enforcement Spawn Time
new bool:m_dmdamage[MAXPLAYERS + 1]; // DM Damage
new m_playerKill[MAXPLAYERS + 1]; // Player Kill [pdm]
new bool:m_inBuyZone[MAXPLAYERS + 1], Float:m_inBuyZoneCheckTime[MAXPLAYERS + 1]; // TDM Mode BuyZone Add HP
new Float:m_inBuyZoneAddHPTime[MAXPLAYERS + 1];

// Game Offset
new g_iAccount;

public OnPluginStart()
{
	LoadTranslations("DeathmatchKD_Source.phrases");

	RegConsoleCmd("say", Command_DmSet);

	HookEvent("round_start", Event_Round_Start, EventHookMode_Post);
	HookEvent("round_freeze_end",Event_RoundFreezeEnd);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);

	AddCommandListener(Command_BlockGameBuyMenu, "buyequip");
	AddCommandListener(Command_BlockGameBuyMenu, "buymenu");
	
	AddCommandListener(Command_Kill, "kill");
	AddCommandListener(Command_ChangeTeam, "autoteam");
	AddCommandListener(Command_ChangeTeam, "jointeam");
	AddCommandListener(Command_ChangeTeam, "chooseteam");
	
	g_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
}


public OnConfigsExecuted()
{
	g_dmMode = -1;
	GameDataReset();
		
	DMBaseSetting();
	LoadDMSettingFile();
	LoadRandomSpawnFile();
	LoadRandomMapsFile();
	
	if (g_mapsCount == 0)
	{
		g_mapsCount++;
		new String:mapName[128];
		GetCurrentMap(mapName, sizeof(mapName));
		Format(g_mapsName[0], sizeof(g_mapsName), "%s", mapName);
	}
	
	if (g_dmMode == MODE_DM && g_spawnCount == 0)
	{
		g_dmMode = MODE_TDM;
		PrintToChatAll("%T", "Have not Spawn Origin In DM");
	}
	
	if (g_freezeTimeData < 5)
		g_freezeTimeData = 5;
		
	if (g_maxGameTime < 5)
		g_maxGameTime = 5;
		
	ServerCommand("mp_freezetime %d", g_freezeTimeData);
	ServerCommand("mp_timelimit 0");
	ServerCommand("sv_hudhint_sound 0");
	
	for (new id = 1; id <= MAX_NAME_LENGTH; id++)
	{
		PlayerDataReset (id);

		SDKUnhook(id, SDKHook_OnTakeDamage, SDK_TakeDamage);
		SDKUnhook(id, SDKHook_OnTakeDamagePost, SDK_TakeDamagePost);
		SDKUnhook(id, SDKHook_PreThink, SDK_PreThink);
	}
}
// ==================================

// DM:KD-S Setting =========
public DMBaseSetting()
{
	g_dmMode = MODE_TDM;
	g_spawnTime = 3.0;
	g_spawnGodTime = 3.0;
	g_enforcementSpawnTime = 8.0;
	g_removeDropWeaponTime = 8.0;
	g_blockKill = 1;
	g_ammoUnlimitbp = 1;
	g_spawnGetGrenade[0] = 0;
	g_spawnGetGrenade[1] = 0;
	g_spawnGetGrenade[2] = 0;
	g_freezeTimeData = 10;
	g_maxKillData = 0;
	g_maxGameTime = 20;
	
	g_tdmBuyZoneAddHpStart = 1;
	g_tdmBuyZoneAddHpTime = 5.0;
	g_tdmBuyZoneAddHp = 10;
	g_dmKillEnemyAddHP = 20;
	
	g_priweaponNum = 3;
	g_priweaponID[0] = get_user_weapon_id("weapon_awp");
	Format(g_priweaponName[0], sizeof(g_priweaponName), "AWP");
	g_priweaponID[1] = get_user_weapon_id("weapon_m4a1");
	Format(g_priweaponName[1], sizeof(g_priweaponName), "M4A1");
	g_priweaponID[2] = get_user_weapon_id("weapon_ak47");
	Format(g_priweaponName[2], sizeof(g_priweaponName), "AK47/CV47");
	
	g_secweaponNum = 3;
	g_secweaponID[0] = get_user_weapon_id("weapon_glock18");
	Format(g_secweaponName[0], sizeof(g_secweaponName), "Glock 18");
	g_secweaponID[1] = get_user_weapon_id("weapon_usp");
	Format(g_secweaponName[1], sizeof(g_secweaponName), "USP");
	g_secweaponID[2] = get_user_weapon_id("weapon_deagle");
	Format(g_secweaponName[2], sizeof(g_secweaponName), "DEAGLE");
}

public LoadDMSettingFile()
{
	new String:path[255];
	Format(path, sizeof(path), "cfg/DmKD-S/DeathmatchKD-S_Setting.cfg");

	new Handle:file = OpenFile(path, "rt");
	if (file == INVALID_HANDLE)
		return;

	new section, String:linedata[512];
	new String:Setting_value[2][256] , String:weapon_get[2][256];

	g_priweaponNum = 0;
	g_secweaponNum = 0;

	while (!IsEndOfFile(file) && ReadFileLine(file, linedata, sizeof(linedata)))
	{
		TrimString(linedata);

		if(!linedata[0] || linedata[0] == ';' || (linedata[0] == '/' && linedata[1] == '/')) continue;

		if (linedata[0] == '[')
		{
			section += 1;
			continue;
		}

		switch(section)
		{
			case 1:
			{
				ExplodeString(linedata, "=", Setting_value, 2, 256);
				TrimString(Setting_value[0]);
				TrimString(Setting_value[1]);

				if(!strcmp(Setting_value[0], "DM MoD", false)) g_dmMode = StringToInt(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Player Respawn Time", false)) g_spawnTime = StringToFloat(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Player Protect Time", false)) g_spawnGodTime = StringToFloat(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Player Enforcement Respawn Time", false)) g_enforcementSpawnTime = StringToFloat(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Remove Dropped Weapon Time", false)) g_removeDropWeaponTime = StringToFloat(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Block Player Suicide", false)) g_blockKill = StringToInt(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Unlimited Ammo", false)) g_ammoUnlimitbp = StringToInt(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Give Grenade (hegrenade, flashbang, smokegrenade)", false)) 
				{
					new String:grenade_class[3][10];
					ExplodeString(Setting_value[1], ",", grenade_class, 3, 10);
					g_spawnGetGrenade[0] = StringToInt(grenade_class[0]);
					g_spawnGetGrenade[1] = StringToInt(grenade_class[1]);
					g_spawnGetGrenade[2] = StringToInt(grenade_class[2]);
				}
				else if(!strcmp(Setting_value[0], "Freeze Time", false)) g_freezeTimeData = StringToInt(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Kill WiN", false)) g_maxKillData = StringToInt(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Round Time", false)) g_maxGameTime = StringToInt(Setting_value[1]);
				
				else if(!strcmp(Setting_value[0], "Buyzone Add HP", false)) g_tdmBuyZoneAddHpStart = StringToInt(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Buyzone Add HP Time", false)) g_tdmBuyZoneAddHpTime = StringToFloat(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Buyzone Add HP Amount", false)) g_tdmBuyZoneAddHp = StringToInt(Setting_value[1]);

				else if(!strcmp(Setting_value[0], "Kill Enemy Add HP", false)) g_dmKillEnemyAddHP = StringToInt(Setting_value[1]);
			}
			case 2: 
			{
				ExplodeString(linedata, ",", weapon_get, 2, 256);
				
				if (g_priweaponNum < 30)
				{
					g_priweaponID[g_priweaponNum] = get_user_weapon_id(weapon_get[0]);
					g_priweaponName[g_priweaponNum] = weapon_get[1];
					g_priweaponNum += 1;
				}
			}
			case 3: 
			{
				ExplodeString(linedata, ",", weapon_get, 2, 256);

				if (g_secweaponNum < 30)
				{
					g_secweaponID[g_secweaponNum] = get_user_weapon_id(weapon_get[0]);
					g_secweaponName[g_secweaponNum] = weapon_get[1];
					g_secweaponNum += 1;
				}
			}
		}
	}
	CloseHandle(file);
}
// ================================

// Ran Spawn Save/Load ====
public LoadRandomSpawnFile()
{
	g_spawnCount = 0;
	for (new i = 0; i < 128; i++)
	{
		g_spawns[i][0] = 0.0;
		g_spawns[i][1] = 0.0;
		g_spawns[i][2] = 0.0;
	}

	new String:path[255], String:mapName[128];
	GetCurrentMap(mapName, sizeof(mapName));
	Format(path, sizeof(path), "cfg/DmKD-S/spawn/%s.cfg", mapName);

	new Handle:file = OpenFile(path, "rt");
	if (file == INVALID_HANDLE)
		return;

	new String:linedata[512];
	new String:spawn_origin[3][64];
	while (!IsEndOfFile(file) && ReadFileLine(file, linedata, sizeof(linedata)))
	{
		ExplodeString(linedata, " ", spawn_origin, 3, 64);

		g_spawns[g_spawnCount][0] = StringToFloat(spawn_origin[0]);
		g_spawns[g_spawnCount][1] = StringToFloat(spawn_origin[1]);
		g_spawns[g_spawnCount][2] = StringToFloat(spawn_origin[2]);

		g_spawnCount++;

		if (g_spawnCount >= sizeof g_spawns) break;
	}

	CloseHandle(file);
}

public SaveRandomSpawn(client)
{
	new String:path[255], String:mapName[128], Float:Player_Origin[3], String:Save_path[254];
	GetCurrentMap(mapName, sizeof(mapName));
	Format(path, sizeof(path), "cfg/DmKD-S/spawn/%s.cfg", mapName);

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Player_Origin);
	Format(Save_path, sizeof(Save_path), "%f %f %f", Player_Origin[0], Player_Origin[1], Player_Origin[2]);

	new Handle:file = OpenFile(path, "at");

	WriteFileLine(file, Save_path);

	CloseHandle(file);
}
// =====================

// Next Maps =========================
public LoadRandomMapsFile()
{
	g_mapsCount = 0;

	new String:path[255];
	Format(path, sizeof(path), "cfg/DmKD-S/maps.cfg");

	new Handle:file = OpenFile(path, "rt");
	if (file == INVALID_HANDLE)
		return;

	new String:linedata[128];

	while (!IsEndOfFile(file) && ReadFileLine(file, linedata, sizeof(linedata)))
	{
		g_mapsName[g_mapsCount] = linedata;
		g_mapsCount++;

		if (g_mapsCount >= sizeof g_mapsName)
			break;
	}

	CloseHandle(file);
}
// =================================

// Connect/Disconnect ==
public OnClientPutInServer(client)
{
	PlayerDataReset (client);

	SDKHook(client, SDKHook_OnTakeDamage, SDK_TakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, SDK_TakeDamagePost);
	SDKHook(client, SDKHook_PreThink, SDK_PreThink);
	
	m_dmdamage[client] = false;
	
	FakeClientCommandEx(client,"jointeam 5");
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!IsValidEntity(entity) || !IsValidEdict(entity))
		return;
		
	if(!strcmp(classname, "func_buyzone", false))
		SDKHook(entity, SDKHook_TouchPost, SDK_TouchPost);

	SDKHook(entity, SDKHook_SpawnPost, SDK_SpawnPost);
}

// Player Disconnect remove vars ====
public OnClientDisconnect(client)
{
	PlayerDataReset (client);

	SDKUnhook(client, SDKHook_OnTakeDamage, SDK_TakeDamage);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, SDK_TakeDamagePost);
	SDKUnhook(client, SDKHook_PreThink, SDK_PreThink);
}
// =======================

// DM Set Menu============
public Action:Command_DmSet(client, args)
{
	if (!client)
		client++;

	if (!GetUserAdmin(client))
		return Plugin_Continue;

	decl String:text[192];
	if (GetCmdArgString(text, sizeof(text)) < 1)  return Plugin_Continue;

	new startidx;
	if (text[strlen(text)-1] == '"') {
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	decl String:message[8];
	BreakString(text[startidx], message, sizeof(message));
	
	if (strcmp(message, "/dm_set", false) == 0 || strcmp(message, "!dm_set", false) == 0) {
		Dm_Game_Set_Menu(client);
	}
	
	return Plugin_Continue;
}

public Dm_Game_Set_Menu(client)
{
	delete m_menu[client];
	m_menu[client] = null;
	m_menuType[client] = 10;
	
	new String:Value[64];
	m_menu[client] = new Menu(Handler_Menu, MENU_ACTIONS_ALL);
	
	Format(Value, sizeof(Value), "DM:KD-S Setting Menu");
	m_menu[client].SetTitle("%s?", Value);
	
	Format(Value, sizeof(Value), "Set new spawn origin");
	m_menu[client].AddItem(Value, Value);

	m_menu[client].ExitButton = true;
	m_menu[client].Display (client, 9999);
}
// ========================

// Block Command ======
public Action:Command_ChangeTeam(client, const String:command[], args)
{
	if (!client || !IsClientConnected(client))
		return Plugin_Continue;

	if (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
		return Plugin_Stop;
	
	new joinTeam;
	if (GetTeamClientCount(2) > GetTeamClientCount(3))
		joinTeam = 3;
	else if (GetTeamClientCount(3) > GetTeamClientCount(2))
		joinTeam = 2;
	else 
		joinTeam = GetRandomInt (2, 3);
	
	CS_SwitchTeam(client, joinTeam);
	
	if (!dm_GameRun())
		CS_RespawnPlayer (client);
	else 
		m_spawnTime[client] = GetGameTime() + g_spawnTime;

	return Plugin_Handled;
}

public Action:Command_Kill(client, const String:command[], args)
{
	if (!g_blockKill || !client || !IsClientConnected(client))
		return Plugin_Continue;

	return Plugin_Handled;
}

public Action:Command_BlockGameBuyMenu(client, const String:command[], args)
{
	return Plugin_Handled;
}
// =======================


// Cs Round Set ===========
public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	GameDataReset();
	g_freezeTime = GetGameTime() + g_freezeTimeData;
		
	if (g_dmMode != MODE_DM)
		g_dmMode = MODE_TDM;
		
	for (new player = 1; player <= MAX_NAME_LENGTH; player++)
	{
		PlayerDataReset (player);
	}
}

public Action:Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_dmGameStart = true;
	g_dmGameEnd = false;
	g_freezeTime = GetGameTime() + 2.0;
	
	new ingame_player = 0;

	for (new player = 1; player <= MAX_NAME_LENGTH; player++)
	{
		if (!IsClientConnected(player) || !IsClientInGame(player)) continue;

		ingame_player++;
		PlayerSpawn(player);
	}

	if (g_maxKillData == 0)
	{
		if (g_dmMode == MODE_DM) g_maxKill = ingame_player * 2;
		else g_maxKill = ingame_player * 4;
	}
	else
		g_maxKill = g_maxKillData;
	
	if (g_maxKill <= 0)
		g_maxKill = -1;
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	if (!dm_GameRun ())
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public dm_roundEnd ()
{
	if (!dm_GameRun ())
		return;
	
	if (g_dmMode == MODE_TDM && g_teamCTKill == g_teamTRKill)
		return;

	g_dmGameEnd = true;
	
	if (g_dmMode == MODE_TDM)
	{
		if (g_teamCTKill > g_teamTRKill)
			EmitSoundToAll ("radio/ctwin.wav");
		else
			EmitSoundToAll ("radio/terwin.wav");
	}
	else
		EmitSoundToAll ("radio/terwin.wav");
}

public dm_changeNextMap (Float:gameTime)
{
	if (dm_GameRun ())
	{
		g_nextMapId = -1;
		g_changeMapTime = -1.0;
		return;
	}
	
	if (g_nextMapId == -1)
		g_nextMapId = GetRandomInt(0, g_mapsCount-1);

	if (g_changeMapTime == -1.0)
		g_changeMapTime = gameTime + 8.0;
	else if (g_changeMapTime <= gameTime)
	{
		ServerCommand("changelevel %s", g_mapsName[g_nextMapId]);
		g_nextMapId = -1;
		g_changeMapTime = -1.0;
	}
}
// ===================

// Player Hud MSG =============
public dm_showMsg (client, Float:gameTime)
{
	if (IsFakeClient (client))
		return;
	
	new String:Text[512];
	new len = 0;

	if (!g_dmGameStart)
	{
		if (g_freezeTime >= gameTime)
			len += Format(Text[len], sizeof(Text)-len, "%T", "COUNTDOWN_MSG", client, g_freezeTime - gameTime + 1);
	}
			
	if (g_dmGameEnd)
	{
		if (g_nextMapId == -1)
			return;
		
		if (g_dmMode == MODE_DM)
			len += Format(Text[len], sizeof(Text)-len, "%T", "DM_WIN", client, g_topKiller, g_mapsName[g_nextMapId]);
		else
			len += Format(Text[len], sizeof(Text)-len, "%T", "TDM_WIN", client,
			(g_teamTRKill >= g_teamCTKill) ? "TR" : "CT", g_mapsName[g_nextMapId]);
	}
	
	if (dm_GameRun ())
	{
		if (g_freezeTime >= gameTime && g_maxKill > 0)
		{
			if (g_dmMode == MODE_DM)
				PrintCenterText(client, "%T", "DM_GS_MSG", client, g_maxKill);
			else
				PrintCenterText(client, "%T", "TDM_GS_MSG", client, g_maxKill);
		}
		
		if (m_enforcementSpawnTime[client] > gameTime && m_enforcementSpawnTime[client] != -1.0)
			PrintCenterText(client, "%T", "INEV_RES_MSG", client, m_enforcementSpawnTime[client] - gameTime + 1);
	
		if (g_maxKill != -1)
			len += Format(Text[len], sizeof(Text)-len, "%T\n", "MAX_KILL", client, g_maxKill);
		
		if (g_dmMode == MODE_DM)
			len += Format(Text[len], sizeof(Text)-len, "%T\n\n", "DM_KILLNUM", client, m_playerKill[client]);
		else
			len += Format(Text[len], sizeof(Text)-len, "%T\n\n", "TDM_KILLNUM", client, g_teamCTKill, g_teamTRKill);
		
		len += Format(Text[len], sizeof(Text)-len, "%T", "GAME_TIME_MSG", client, g_maxGameTime, g_gameTime[1], g_gameTime[0]);
	}
	
	if (len > 0)
		PrintHintText (client, Text);
}
// ===================

// Dm playing ==================
public OnGameFrame ()
{
	new Float:gameTime = GetGameTime();
	
	if (g_dmGameEnd)
		dm_changeNextMap (gameTime);

	if (dm_GameRun ())
	{
		if (g_secondThinkTime <= gameTime)
		{
			g_gameTime[0]++;
			if (g_gameTime[0] >= 60)
			{
				g_gameTime[0] = 0;
				g_gameTime[1]++;
			}
		}
		
		if (g_gameTime[1] >= g_maxGameTime)
			dm_roundEnd();
	}
	
	if (g_secondThinkTime <= gameTime)
		g_secondThinkTime = gameTime + 1.0;
}

public SDK_PreThink(client)
{
	if (!IsClientConnected(client))
		return;
	
	new isAlive = IsPlayerAlive(client);
	new team = GetClientTeam(client);
	new Float:gameTime = GetGameTime();

	if (m_spawnTime[client] != -1.0 && m_spawnTime[client] <= gameTime)
	{
		if (team != CS_TEAM_T && team != CS_TEAM_CT)
			m_spawnTime[client] = gameTime + 0.5;
		else
		{
			if (!isAlive && g_enforcementSpawnTime > 0.0)
				m_enforcementSpawnTime[client] = gameTime + g_enforcementSpawnTime;
		
			m_spawnTime[client] = -1.0;
			PlayerSpawn(client);
		}
	}

	if (m_godMode[client] && m_godModeTime[client] < gameTime)
	{
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderFx(client, RENDERFX_NONE);
		SetEntityRenderColor(client);	
		m_godMode[client] = false;
		m_godModeTime[client] = -1.0;
	}
	
	if (!m_godMode[client] && m_godModeTime[client] >= gameTime)
	{
		SetEntityRenderMode(client, RENDER_TRANSADD);
		SetEntityRenderFx(client, RENDERFX_DISTORT);
		
		if (team == CS_TEAM_T)
			SetEntityRenderColor(client, 200, 0, 0, 120);
		else if (team == CS_TEAM_CT)
			SetEntityRenderColor(client, 0, 0, 200, 120);
			
		m_godMode[client] = true;
	}
	
	if (isAlive)
	{
		SetEntData(client, g_iAccount, 0);
		
		m_enforcementSpawnTime[client] = -1.0;

		if (g_ammoUnlimitbp)
		{
			new String:weapon_class[32], weaponID, ammo_offset;
			GetClientWeapon(client, weapon_class,  sizeof(weapon_class));
			weaponID = get_user_weapon_id(weapon_class);

			if (g_AmmoOffset[weaponID] != 0)
			{
				ammo_offset = FindDataMapInfo(client, "m_iAmmo")+(g_AmmoOffset[weaponID]*4);
				if (GetEntData(client, ammo_offset) != g_BpAmmo[weaponID])
					SetEntData(client, ammo_offset, g_BpAmmo[weaponID]);
			}
		}
		
		if (g_dmMode == MODE_TDM && g_tdmBuyZoneAddHpStart)
		{
			if (m_inBuyZoneCheckTime[client] != -1.0 && m_inBuyZoneCheckTime[client] <= gameTime)
			{
				m_inBuyZone[client] = false;
				m_inBuyZoneCheckTime[client] = -1.0;
				m_inBuyZoneAddHPTime[client] = -1.0;
				PrintToChat(client, "You out the buy zone");
			}
			
			if (!m_inBuyZone[client])
				m_inBuyZoneAddHPTime[client] = -1.0;
			else if (m_inBuyZoneAddHPTime[client] != -1.0 && m_inBuyZoneAddHPTime[client] <= gameTime)
			{
				PrintToChat(client, "Buy Zone Add HP");
				m_inBuyZoneAddHPTime[client] = gameTime + g_tdmBuyZoneAddHpTime + 0.1;
					
				new health = GetClientHealth(client) + g_tdmBuyZoneAddHp;
				if (health > 100)
					SetEntityHealth(client, 100);
				else
					SetEntityHealth(client, health);
			}
		}
	}
	else if ((team == CS_TEAM_T || team == CS_TEAM_CT))
	{
		m_inBuyZone[client] = false;
		m_inBuyZoneCheckTime[client] = -1.0;
		m_inBuyZoneAddHPTime[client] = -1.0;
	
		if (m_enforcementSpawnTime[client] != -1.0 && m_enforcementSpawnTime[client] <= gameTime)
			CS_RespawnPlayer(client);
	}
	
	if (m_showMsgTime[client] <= gameTime && (team == CS_TEAM_T || team == CS_TEAM_CT))
	{
		dm_showMsg (client, gameTime);
		m_showMsgTime[client] = gameTime + 1.0;
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!dm_GameRun ())
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	m_spawnTime[client] = GetGameTime() + g_spawnTime;
	
	if (client == attacker)
		return;
	
	m_playerKill[attacker]++;
	
	if (g_topKiller == -1 || m_playerKill[attacker] > m_playerKill[g_topKiller])
		g_topKiller = attacker;

	if (g_dmMode == MODE_DM)
	{
		if (g_dmKillEnemyAddHP > 0)
		{
			new health = GetClientHealth(attacker) + g_dmKillEnemyAddHP;
			if (health > 100)
				SetEntityHealth(attacker, 100);
			else
				SetEntityHealth(attacker, health);
		}
	
		if (g_maxKill != -1 && m_playerKill[attacker] >= g_maxKill)
			dm_roundEnd();
	}
	else
	{
		if (GetClientTeam(attacker) == CS_TEAM_T) g_teamTRKill++;
		else if (GetClientTeam(attacker) == CS_TEAM_CT) g_teamCTKill++;
	
		if (g_maxKill != -1 && (g_teamTRKill >= g_maxKill || g_teamCTKill >= g_maxKill))
			dm_roundEnd();
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_dmMode == MODE_DM && IsPlayerAlive (client))
		Set_Origin(client);
}

public Action:SDK_TakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!dm_GameRun ())
		return Plugin_Stop;

	if (m_godMode[victim])
		return Plugin_Stop;
		
	if (!attacker)
		return Plugin_Continue;
		
	new Vteam = GetClientTeam(victim);
	new Ateam = GetClientTeam (attacker);
	
	if (g_dmMode == MODE_TDM && Vteam == Ateam)
		return Plugin_Stop;

	if (g_dmMode == MODE_DM)
	{
		if (Vteam == Ateam)
		{
			if (Vteam == CS_TEAM_T)
				SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_CT,2);
			else 
				SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_T,2);

			m_dmdamage[victim] = true;
		}
	}

	return Plugin_Continue;
}

public SDK_TakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (!m_dmdamage[victim])
		return;

	if (GetClientTeam(victim) == CS_TEAM_T)
		SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_CT,2);
	else
		SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_T,2);

	m_dmdamage[victim] = false;
}
// ===============================

// Dm Spawn ====================
public PlayerSpawn(client)
{
	Get_Weapon_Menu(client);
}

public Get_Weapon_Menu(client)
{
	if ((m_secWeaponID[client] == -1 && m_priWeaponID[client] == -1) || IsFakeClient(client))
	{
		Send_Pri_Weapon_Menu(client);
		return;
	}
	
	delete m_menu[client];
	m_menu[client] = null;
	m_menuType[client] = 1;
	new String:Value[64];
	m_menu[client] = new Menu(Handler_Menu, MENU_ACTIONS_ALL);
	
	Format(Value, sizeof(Value), "%T", "Weapon Menu", client);
	m_menu[client].SetTitle("%s?", Value);

	Format(Value, sizeof(Value), "%T", "Use New Weapon", client);
	m_menu[client].AddItem(Value, Value);
	
	Format(Value, sizeof(Value), "%T", "Use Last-Time Weapon", client);
	m_menu[client].AddItem(Value, Value);
	
	Format(Value, sizeof(Value), "%T:", "Your Last Time Weapon", client);
	m_menu[client].AddItem(Value, Value);
	
	Format(Value, sizeof(Value), "%s", g_priweaponName[m_priWeaponID[client]]);
	m_menu[client].AddItem(Value, Value);
	
	Format(Value, sizeof(Value), "%s", g_secweaponName[m_secWeaponID[client]]);
	m_menu[client].AddItem(Value, Value);
		
	m_menu[client].ExitButton = false;
	m_menu[client].Display (client, 9999);
}

public Send_Pri_Weapon_Menu(client)
{
	if (IsFakeClient(client)) 
	{
		m_priWeaponID[client] = GetRandomInt(0, g_priweaponNum-1);
		Send_Sec_Weapon_Menu(client);
		return;
	}

	delete m_menu[client];
	m_menu[client] = null;
	m_menuType[client] = 2;
	new String:Value[64];
	m_menu[client] = new Menu(Handler_Menu, MENU_ACTIONS_ALL);
	
	Format(Value, sizeof(Value), "%T", "Pri Weapon Menu", client);
	m_menu[client].SetTitle("%s?", Value);
	
	for (new i = 0; i < g_priweaponNum; i++)
	{
		Format(Value, sizeof(Value), "%s", g_priweaponName[i]);
		m_menu[client].AddItem(Value, Value);
	}	
	
	m_menu[client].ExitButton = false;
	m_menu[client].Display (client, 9999);
}

public Send_Sec_Weapon_Menu(client)
{
	if (IsFakeClient(client)) 
	{
		m_secWeaponID[client] = GetRandomInt(0, g_secweaponNum-1);
		Player_Spawn(client);
		return;
	}

	delete m_menu[client];
	m_menu[client] = null;
	m_menuType[client] = 3;
	new String:Value[64];
	m_menu[client] = new Menu(Handler_Menu, MENU_ACTIONS_ALL);
	
	Format(Value, sizeof(Value), "%T", "Sec Weapon Menu", client);
	m_menu[client].SetTitle("%s?", Value);
	
	for (new i = 0; i < g_secweaponNum; i++)
	{
		Format(Value, sizeof(Value), "%s", g_secweaponName[i]);
		m_menu[client].AddItem(Value, Value);
	}	
	
	m_menu[client].ExitButton = false;
	m_menu[client].Display (client, 9999);
}

public int Handler_Menu(Menu:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (m_menuType[param1] == 1)
		{
			param2++;
			if (param2 == 1)
				Send_Pri_Weapon_Menu(param1);
			else
				Player_Spawn(param1);
		}
		else if (m_menuType[param1] == 2)
		{
			m_priWeaponID[param1] = param2;
			Send_Sec_Weapon_Menu(param1);
		}
		else if (m_menuType[param1] == 3)
		{
			m_secWeaponID[param1] = param2;
			Player_Spawn(param1);
		}
		
		else if (m_menuType[param1] == 10)
		{
			Dm_Game_Set_Menu(param1);
			SaveRandomSpawn(param1);
		}
	}

	return 0;
}

public Player_Spawn(client)
{
	if (!IsPlayerAlive(client))
		CS_RespawnPlayer(client);
		
	for (new i = 0; i < 2; i++)
	{
		new weaponEntity = GetPlayerWeaponSlot(client, i);
		if (weaponEntity == -1)
			continue;
			
		RemovePlayerItem(client, weaponEntity);
		RemoveEdict(weaponEntity);
	}

	GivePlayerItem(client, "item_assaultsuit", 0);

	m_godModeTime[client] = GetGameTime() + g_spawnGodTime;

	if (m_secWeaponID[client] >= 0)
		GivePlayerItem(client, WEAPON_CLASSNAME[g_secweaponID[m_secWeaponID[client]]]);
		
	if (m_priWeaponID[client] >= 0)
		GivePlayerItem(client, WEAPON_CLASSNAME[g_priweaponID[m_priWeaponID[client]]]);

	if (g_spawnGetGrenade[0]) GivePlayerItem(client, "weapon_hegrenade");
	if (g_spawnGetGrenade[1]) GivePlayerItem(client, "weapon_flashbang");
	if (g_spawnGetGrenade[2]) GivePlayerItem(client, "weapon_smokegrenade");
}
// ===============================

// Remove Weapon ===============
public Action:CS_OnCSWeaponDrop(client, weaponIndex) 
{
	if (g_removeDropWeaponTime <= 0.1)
		return;
	
	CreateTimer(0.1, RemoveWeaponCheck, weaponIndex);
}

public Action: RemoveWeaponCheck(Handle:timer, any:weaponIndex )
{
	Handle hData = CreateDataPack();
	WritePackCell(hData, weaponIndex);
	WritePackCell(hData, GetGameTime()+g_removeDropWeaponTime);
	CreateTimer(0.1, RemoveWeapon, hData);
}

public Action: RemoveWeapon(Handle hTimer, Handle hData)
{
	ResetPack(hData);
	new weaponIndex = ReadPackCell(hData);
	new Float:removeTime = ReadPackCell(hData);
	
	if (!IsValidEdict(weaponIndex) || !IsValidEntity(weaponIndex) || GetEntPropEnt(weaponIndex, Prop_Data, "m_hOwnerEntity") != -1)
		return;
	
	if (GetGameTime() >= removeTime)
	{
		AcceptEntityInput(weaponIndex, "Kill"); 	
		return;
	}
	
	CreateTimer(0.1, RemoveWeapon, hData);
}

// ===============================

// Remove Entity =========
public SDK_SpawnPost(entity)
{
	if(!IsValidEntity(entity))
		return;
		
	decl String:ent_name[64];
	GetEdictClassname(entity, ent_name, sizeof(ent_name));

	for (new j = 0; j  < sizeof OBJECTIVE_ENTITYS; j++)
	{
		if(!strcmp(ent_name, OBJECTIVE_ENTITYS[j], false))
			RemoveEdict(entity);
	}
}

public SDK_TouchPost(zoneEntity, client)
{
	if (!dm_GameRun () || g_dmMode == MODE_DM || !g_tdmBuyZoneAddHpStart)
		return;

	if (!IsClientInGame(client) || !IsPlayerAlive (client))
		return;
	
	if (!m_inBuyZone[client])
		PrintToChat(client, "You in the buy zone");
	
	m_inBuyZone[client] = true;
	m_inBuyZoneCheckTime[client] = GetGameTime () + 1.0;
	
	if (m_inBuyZoneAddHPTime[client] == -1.0)
		m_inBuyZoneAddHPTime[client] = GetGameTime () + g_tdmBuyZoneAddHpTime + 0.1;
}
// ====================

public PlayerDataReset(id)
{
	m_menu[id] = null;
	m_menuType[id] = 0;

	m_priWeaponID[id] = -1;
	m_secWeaponID[id] = -1;
	m_godModeTime[id] = -1.0;
	m_spawnTime[id] = -1.0;
	m_enforcementSpawnTime[id] = -1.0;
	m_godMode[id] = false;
	m_dmdamage[id] = false;
	m_playerKill[id] = 0;
	m_inBuyZone[id] = false;
	m_inBuyZoneAddHPTime[id] = -1.0;
	m_inBuyZoneCheckTime[id] = -1.0;
	
	m_showMsgTime[id] = GetGameTime();
}

public GameDataReset()
{
	g_secondThinkTime = GetGameTime();

	g_gameTime[0] = 0;
	g_gameTime[1] = 0;
	
	g_nextMapId = -1;
	g_changeMapTime = -1.0;

	g_dmGameStart = false;
	g_dmGameEnd = false;
	g_maxKill = 0;
	g_teamCTKill = 0;
	g_teamTRKill = 0;
	
	g_topKiller = -1;
	g_freezeTime = -1.0;
}

public bool:dm_GameRun()
{
	return (g_dmGameStart && !g_dmGameEnd);
}

public Set_Origin(client)
{
	new setOrigin = 1;
	while (setOrigin)
	{
		new workSpawnPoint = 1;
		new Float:spawnOrigin[3];
		spawnOrigin = g_spawns[GetRandomInt(0, g_spawnCount-1)];
		
		for (new player = 1; player <= MAX_NAME_LENGTH; player++)
		{
			if (client == player || !IsClientConnected(player) || !IsClientInGame(player) || !IsPlayerAlive (player))
				continue;
			
			new Float:Player_Origin[3];
			GetEntPropVector(player, Prop_Send, "m_vecOrigin", Player_Origin);
				
			if (GetVectorDistance (Player_Origin, spawnOrigin) > 80)
				continue;
			
			workSpawnPoint = 0;
			break;
		}
		
		if (workSpawnPoint == 0)
			continue;
			
		setOrigin = 0;
		TeleportEntity(client, spawnOrigin, NULL_VECTOR, NULL_VECTOR);
	}
}

stock get_user_weapon_id(const String:weapon[]) // This is order in DM:KD.
{
	for (new i = 0; i < sizeof WEAPON_CLASSNAME; i++)
		if(!strcmp(weapon, WEAPON_CLASSNAME[i], false)) return i;
	
	return 0;
}
