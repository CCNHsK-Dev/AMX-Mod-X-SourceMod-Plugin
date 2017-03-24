
/* 
			DeathMatch: Kill Duty Source - Upgrade 1
				xx/3/2017 (Version: 2.0)
			
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
	version = "2.0.0.6",
	url = "http://ccnhsk-dev.blogspot.com/"
};

#define MODE_TDM                0
#define MODE_DM                 1

// Block hostage and c4 [reference amxx plugin]
new const String:OBJECTIVE_ENTITYS[][] = { "func_vehicleclip", "func_buyzone", "func_hostage_rescue", "func_bomb_target", 
	"hostage_entity", "info_hostage_rescue", "info_bomb_target", "prop_physics_multiplayer" }

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
new g_maxKill = 0; // Max Kill
new g_teamCTKill, g_teamTRKill; // CT and TR Kill [tdm]

new Float:g_spawnTime; // Player Respawn Time
new Float:g_spawnGodTime; // Player Protect Time
new g_ammoUnlimitbp; // Unlimited Ammo(Magazine)
new g_removeDropWeapon; // Remove Dropped Weapon
new g_blockKill; // Block player Suicide

// Maps & Spawn Point
new g_mapsCount, String:g_mapsName[64][128];// Ran MAP set
new Float:g_spawns[128][3], g_spawnCount; // Ran Spawn set

// Weapon Menu 
new g_spawnGetGrenade[3]; // Give Grenade
new g_priweaponNum, g_secweaponNum
new g_priweaponID[30], g_secweaponID[30];
new String:g_priweaponName[30][512], String:g_secweaponName[30][512];

// Player vars
Menu m_menu[MAXPLAYERS + 1];
new m_menuType[MAXPLAYERS + 1];
new m_priWeaponID[MAXPLAYERS + 1],  m_secWeaponID[MAXPLAYERS + 1]; // Is Weap set
new bool:m_godMode[MAXPLAYERS + 1], Float:m_godModeTime[MAXPLAYERS + 1]; // Is Protect 
new Float:m_spawnTime[MAXPLAYERS + 1]; // Player Spawn Time
new bool:m_dmdamage[MAXPLAYERS + 1]; // DM Damage
new m_playerKill[MAXPLAYERS + 1]; // Player Kill [pdm]

// Game Offset
new g_iAccount;

public OnPluginStart()
{
	RegConsoleCmd("say", Command_DmSet);

	HookEvent("round_start", Event_Round_Start, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath);

	HookEvent("player_spawn", Event_PlayerSpawn);

	LoadTranslations("DeathmatchKD_Source.phrases");

	AddCommandListener(Command_Kill, "kill");
	AddCommandListener(Command_ChangeTeam, "jointeam");
	AddCommandListener(Command_ChangeTeam, "chooseteam");

	g_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
}

public OnConfigsExecuted()
{
	g_spawnCount = 0;
	for (new i = 0; i < 128; i++)
	{
		g_spawns[i][0] = 0.0;
		g_spawns[i][1] = 0.0;
		g_spawns[i][2] = 0.0;
	}

	g_dmMode = -1;
	GameDataReset();
	
	for (new id = 1; id <= MAX_NAME_LENGTH; id++)
	{
		PlayerDataReset (id);

		SDKUnhook(id, SDKHook_OnTakeDamage, SDK_TakeDamage);
		SDKUnhook(id, SDKHook_OnTakeDamagePost, SDK_TakeDamagePost);
		SDKUnhook(id, SDKHook_PreThink, SDK_PreThink);
	}

	LoadDMSettingFile();
	LoadRandomSpawnFile();
	LoadRandomMapsFile();

	ServerCommand("mp_timelimit 0");
}
// ==================================

// DM:KD-S Setting =========
public LoadDMSettingFile()
{
	new String:path[255];
	Format(path, sizeof(path), "cfg/DmKD-S/DeathmatchKD-S_Setting.cfg");

	new Handle:file = OpenFile(path, "rt");
	if (file == INVALID_HANDLE) return;

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
				else if(!strcmp(Setting_value[0], "Remove Dropped Weapon", false)) g_removeDropWeapon = StringToInt(Setting_value[1]);
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
				else if(!strcmp(Setting_value[0], "Kill WiN", false)) g_maxKill = StringToInt(Setting_value[1]);
			}
			case 2: 
			{
				ExplodeString(linedata, ",", weapon_get, 2, 256);

				g_priweaponID[g_priweaponNum] = get_user_weapon_id(weapon_get[0]);
				g_priweaponName[g_priweaponNum] = weapon_get[1];
				g_priweaponNum += 1;
			}
			case 3: 
			{
				ExplodeString(linedata, ",", weapon_get, 2, 256);

				g_secweaponID[g_secweaponNum] = get_user_weapon_id(weapon_get[0]);
				g_secweaponName[g_secweaponNum] = weapon_get[1];
				g_secweaponNum += 1;
			}
		}
	}
	CloseHandle(file);
}
// ================================

// Ran Spawn Save/Load ====
public LoadRandomSpawnFile()
{
	new String:path[255], String:mapName[128];
	GetCurrentMap(mapName, sizeof(mapName));
	Format(path, sizeof(path), "cfg/DmKD-S/spawn/%s.cfg", mapName);

	new Handle:file = OpenFile(path, "rt");
	if (file == INVALID_HANDLE) return;

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

public save_ranspawn(client)
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
	new String:path[255];
	Format(path, sizeof(path), "cfg/DmKD-S/maps.cfg");

	new Handle:file = OpenFile(path, "rt");
	if (file == INVALID_HANDLE) return;

	new String:linedata[128];
	g_mapsCount = 0;

	while (!IsEndOfFile(file) && ReadFileLine(file, linedata, sizeof(linedata)))
	{
		g_mapsCount++;
		g_mapsName[g_mapsCount] = linedata;

		if (g_mapsCount >= sizeof g_mapsName) break;
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
	m_spawnTime[client] = GetGameTime() + g_spawnTime;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!IsValidEntity(entity) || !IsValidEdict(entity)) return;

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
	if (!client) client++;  
	else
		if (!GetUserAdmin(client)) return Plugin_Handled;

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
	if (!client || !IsClientConnected(client) || !IsClientInGame(client)) return Plugin_Continue;

	if (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
		return Plugin_Stop;

	return Plugin_Continue;
}

public Action:Command_Kill(client, const String:command[], args)
{
	if (!client || !IsClientConnected(client) || !g_blockKill) return Plugin_Continue;

	return Plugin_Handled;
}
// =======================


// Remove Entity =========
public SDK_SpawnPost(entity)
{
	if(!IsValidEntity(entity)) return;
	decl String:ent_name[64];
	GetEdictClassname(entity, ent_name, sizeof(ent_name));

	for (new j = 0; j  < sizeof OBJECTIVE_ENTITYS; j++)
		if(!strcmp(ent_name, OBJECTIVE_ENTITYS[j], false))  RemoveEdict(entity);
}
// ====================

// Cs Round Set ===========
public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	GameDataReset();

	g_dmGameStart = true;
	g_dmGameEnd = false;

	if (g_dmMode != MODE_DM)
		g_dmMode = MODE_TDM;
	
	if (g_dmMode == MODE_DM && g_spawnCount == 0)
	{
		g_dmMode = MODE_TDM;
		SendMsg(-1, 2, "%t", "Have not Spawn Origin In DM");
		SendMsg(-1, 2, "%t", "Have not Spawn Origin In DM");
		SendMsg(-1, 2, "%t", "Have not Spawn Origin In DM");
		SendMsg(-1, 2, "%t", "Have not Spawn Origin In DM");
		SendMsg(-1, 2, "%t", "Have not Spawn Origin In DM");
	}

	new ingame_player = 0;

	for (new player = 1; player <= MAX_NAME_LENGTH; player++)
	{
		if (!IsClientConnected(player) || !IsClientInGame(player)) continue;

		ingame_player++;
	}

	if (g_maxKill == 0)
	{
		if (g_dmMode == MODE_DM) g_maxKill = ingame_player * 2;
		else g_maxKill = ingame_player * 4;
	}

	SendMsg(-1, 1, " Max Kill is : %d", g_maxKill);
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	if (!dm_GameRun ()) return Plugin_Continue;
	return Plugin_Handled;
}
// ===================

// Dm playing ==================
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!dm_GameRun ())
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	m_spawnTime[client] = GetGameTime() + g_spawnTime;

	m_playerKill[attacker]++;
	if (g_dmMode == MODE_DM)
		SendMsg(attacker, 1, "%t", "DM_KILLNUM", m_playerKill[attacker], g_maxKill);
	else
	{
		if (GetClientTeam(attacker) == CS_TEAM_T) g_teamTRKill++;
		else if (GetClientTeam(attacker) == CS_TEAM_CT) g_teamCTKill++;

		SendMsg(-1, 1, "%t", "TDM_KILLNUM", g_teamCTKill, g_teamTRKill, g_maxKill);
	}

	if (m_playerKill[attacker] >= g_maxKill || g_teamTRKill >= g_maxKill || g_teamCTKill >= g_maxKill)
		dm_game_end( GetClientTeam(attacker), attacker, GetRandomInt(0, g_mapsCount-1));
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_dmMode == MODE_DM && g_spawnCount > 0) //CreateTimer(0.1, Set_Origin, client);
		Set_Origin(Handle:0.0, client);
}

public Action:SDK_TakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!dm_GameRun ())
		return Plugin_Stop;

	if (m_godMode[victim])
	{
		damage *= 0.0;
		return Plugin_Changed;
	}

	if (g_dmMode == MODE_DM && attacker)
	{
		new Vteam = GetClientTeam(victim);

		if (Vteam == GetClientTeam(attacker))
		{
			// Set m_iTeamNum, because use CS_SwitchTeam will call jointeam say..
			// and i don't know block jointeam say xDD'
			if (Vteam == CS_TEAM_T) SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_CT,2);
			else  SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_T,2);

			m_dmdamage[victim] = true;
		}
	}

	return Plugin_Continue;
}

public SDK_TakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (!m_dmdamage[victim])
		return;

	if (GetClientTeam(victim) == CS_TEAM_T) SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_CT,2);
	else SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_T,2);

	m_dmdamage[victim] = false;
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
			m_spawnTime[client] = -1.0;
			PlayerSpawn(client);
		}
	}

	if (m_godMode[client] && (m_godModeTime[client] < gameTime) || !isAlive)
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
	}
}

public Action:CS_OnCSWeaponDrop(client, weaponIndex) 
	if (g_removeDropWeapon) AcceptEntityInput(weaponIndex, "Kill"); 
// ===============================

// Dm Spawn ====================
public PlayerSpawn(client)
{
	Get_Weapon_Menu(client);
}

public Get_Weapon_Menu(client)
{
	if ((m_secWeaponID[client] == 0 && m_priWeaponID[client] == 0) || get_user_bot(client))
	{
		Send_Pri_Weapon_Menu(client);
		return;
	}
	
	delete m_menu[client];
	m_menu[client] = null;
	m_menuType[client] = 1;
	new String:Value[64];
	m_menu[client] = new Menu(Handler_Menu, MENU_ACTIONS_ALL);
	
	Format(Value, sizeof(Value), "%t", "Weapon Menu");
	m_menu[client].SetTitle("%s?", Value);

	Format(Value, sizeof(Value), "%t", "Use New Weapon");
	m_menu[client].AddItem(Value, Value);
	
	Format(Value, sizeof(Value), "%t", "Use Last-Time Weapon");
	m_menu[client].AddItem(Value, Value);
	
	Format(Value, sizeof(Value), "%t :", "Your Last Time Weapon");
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
	if (get_user_bot(client)) 
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
	
	Format(Value, sizeof(Value), "%t", "Pri Weapon Menu");
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
	if (get_user_bot(client)) 
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
	
	Format(Value, sizeof(Value), "%t", "Sec Weapon Menu");
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
			save_ranspawn(param1);
		}
	}

	return 0;
}

public Player_Spawn(client)
{
	if (!IsPlayerAlive(client)) CS_RespawnPlayer(client);

	new weaponEntity = GetPlayerWeaponSlot(client, 1);

	RemovePlayerItem(client, weaponEntity);
	RemoveEdict(weaponEntity);

	GivePlayerItem(client, "item_assaultsuit", 0);

	m_godModeTime[client] = GetGameTime () + g_spawnGodTime;

	GivePlayerItem(client, WEAPON_CLASSNAME[g_secweaponID[m_secWeaponID[client]]]);
	GivePlayerItem(client, WEAPON_CLASSNAME[g_priweaponID[m_priWeaponID[client]]]);

	if (g_spawnGetGrenade[0]) GivePlayerItem(client, "weapon_hegrenade");
	if (g_spawnGetGrenade[1]) GivePlayerItem(client, "weapon_flashbang");
	if (g_spawnGetGrenade[2]) GivePlayerItem(client, "weapon_smokegrenade");
}
// ===============================

// Dm game end ====================
public dm_game_end(winteam, winplayer, next_map)
{	
	g_dmGameEnd = true;
	CreateTimer(8.0, change_map, next_map);
	if (g_dmMode == MODE_DM)
		SendMsg(-1, 1, "%t", "DM_WIN", winplayer, g_mapsName[next_map]);
	else
		SendMsg(-1, 1, "%t", "TDM_WILL", winteam, g_mapsName[next_map]);
}

public Action: change_map(Handle:timer, any:next_map )
	ServerCommand("changelevel %s", g_mapsName[next_map]);
// ===============================

public PlayerDataReset(id)
{
	m_menu[id] = null;
	m_menuType[id] = 0;

	m_priWeaponID[id] = 0;
	m_secWeaponID[id] = 0;
	m_godModeTime[id] = -1.0;
	m_spawnTime[id] = -1.0;
	m_godMode[id] = false;
	m_dmdamage[id] = false;
	m_playerKill[id] = 0;
}

public GameDataReset()
{
	g_dmGameStart = false;
	g_dmGameEnd = false;
	g_maxKill = 0;
	g_teamCTKill = 0;
	g_teamTRKill = 0;
}

public bool:dm_GameRun()
{
	return (g_dmGameStart && !g_dmGameEnd);
}

public Action:Set_Origin(Handle:timer, any:client)
{
	new Float:spawn_or[3];
	spawn_or = g_spawns[GetRandomInt(0, g_spawnCount-1)];

	TeleportEntity(client, spawn_or, NULL_VECTOR, NULL_VECTOR);

	new Float:Player_Origin[3], Float:fMins[3], Float:fMaxs[3], Float:ang[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Player_Origin);
	GetClientMaxs(client, fMaxs);
	GetClientMins(client, fMins);
	GetClientAbsAngles(client, ang);

	new Handle:trace = TR_TraceHullFilterEx(Player_Origin, ang, fMins, fMaxs, MASK_ALL, TraceEntityFilterPlayer);

	if (TR_DidHit(trace))
	{
		if (TR_GetEntityIndex(trace) != client)
		{
			SendMsg(client, 2, "%t", "Debug Stuck");
			CreateTimer(0.1, Set_Origin, client);
		}
	}
	CloseHandle(trace);
}

public bool:TraceEntityFilterPlayer(entity, mask, any:data)
{
	if (entity != 0)// && IsClientConnected(entity))
		return true;

	if(entity == data)
		return false;
		
	return true;
}

get_user_bot(client) // Beacuse i know bot steam id is 'BOT'
{
	if (!client || !IsClientConnected(client) || !IsClientInGame(client)) return false;

	new String:SteamID[50];
	GetClientAuthId(client, AuthId_Steam3, SteamID, sizeof(SteamID));

	if (StrEqual(SteamID, "BOT")) return true;
	else return false;
}

stock get_user_weapon_id(const String:weapon[]) // This is order in DM:KD.
{
	for (new i = 0; i < sizeof WEAPON_CLASSNAME; i++)
		if(!strcmp(weapon, WEAPON_CLASSNAME[i], false)) return i;
	
	return 0;
}

stock SendMsg(client, Tc, const String:format[], any:...) // Good Print By ' HsK
{
	decl String:buffer[192];
	VFormat(buffer, sizeof(buffer), format, 4);

	if (client == -1)
	{
		for(client=1; client<=GetMaxClients(); client++)
			if (IsClientConnected(client) && IsClientInGame(client)) SendMsg(client, Tc, buffer);

		return;
	}

	if (!client || !IsClientConnected(client) || !IsClientInGame(client)) return;

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
