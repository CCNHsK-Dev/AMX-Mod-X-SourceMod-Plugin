
#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

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
new g_dm_mod = -1; // DM MoD
new bool:dm_game = false; // DM Game
new Float:g_spawn_time; // Player Respawn Time
new Float:g_protect_time; // Player Protect Time
new g_redropp_weapon; // Remove Dropped Weapon
new g_block_kill; // Block player Suicide
new g_unlimitbp_ammo; // Unlimited Ammo(Magazine)
new g_spawn_grenade[3]; // Give Grenade
new Float:g_spawns[128][3], g_spawnCount; // Ran Spawn set
new g_MaxKill = 0; // Max Kill
new CT_kill, TR_kill; // CT and TR Kill [tdm]
new g_mapsCount, String:g_mapname[64][128];// Ran MAP set

// Player vars
new g_pri_weaponid[MAXPLAYERS + 1],  g_sec_weaponid[MAXPLAYERS + 1]; // Is Weap set
new g_Protection[MAXPLAYERS + 1]; // Is Protect 
new bool:g_inser_menu[MAXPLAYERS + 1] = false; // New Player put in ser menu
new bool:g_dmdamage[MAXPLAYERS + 1]; // DM Damage
new g_player_kill[MAXPLAYERS + 1]; // Player Kill [pdm]

// Weapon Menu 
new g_priweapon, g_secweapon, g_priweaponID[30], g_secweaponID[30], 
String:g_priweaponN[30][512], String:g_secweaponN[30][512];

// Game Offset
new g_iAccount;

public Plugin:myinfo = 
{
	name = "DeathMatch: Kill Duty - Source",
	author = "HsK",
	description = "Deathmatch: Kill Duty (Source)",
	version = "1.0",
	url = "http://www.youtube.com/user/mikeg234bbq"  /* This is my youtube acc */
};

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

	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
}

public OnConfigsExecuted()
{
	g_dm_mod = -1;
	dm_game = false;
	for (new i = 0; i < 128; i++)
		g_spawns[i][0] = 0.0, g_spawns[i][1] = 0.0, g_spawns[i][2] = 0.0;
	g_spawnCount = 0;
	g_MaxKill = 0, CT_kill = 0, TR_kill = 0;

	for (new id = 1; id <= MAX_NAME_LENGTH; id++)
	{
		g_pri_weaponid[id] = 0, g_sec_weaponid[id] = 0;
		g_Protection[id] = 0;
		g_inser_menu[id] = false, g_dmdamage[id] = false;
		g_player_kill[id] = 0;

		SDKUnhook(id, SDKHook_OnTakeDamage, SDK_TakeDamage);
		SDKUnhook(id, SDKHook_OnTakeDamagePost, SDK_TakeDamagePost);
		SDKUnhook(id, SDKHook_PreThink, SDK_PreThink);
	}

	load_dmsetting();
	load_ranspawn();
	load_ranmaps();

	ServerCommand("mp_timelimit 0");
}

// Player Disconnect remove vars ====
public OnClientDisconnect(client)
{
	g_pri_weaponid[client] = 0, g_sec_weaponid[client] = 0;
	g_Protection[client] = 0;
	g_inser_menu[client] = false, g_dmdamage[client] = false;
	g_player_kill[client] = 0;

	SDKUnhook(client, SDKHook_OnTakeDamage, SDK_TakeDamage);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, SDK_TakeDamagePost);
	SDKUnhook(client, SDKHook_PreThink, SDK_PreThink);
}
// ==================================

// DM:KD-S Setting =========
public load_dmsetting()
{
	new String:path[255];
	Format(path, sizeof(path), "cfg/DmKD-S/DeathmatchKD-S_Setting.cfg");

	new Handle:file = OpenFile(path, "rt");
	if (file == INVALID_HANDLE) return;

	new section, String:linedata[512];
	new String:Setting_value[2][256] , String:weapon_get[2][256];

	g_priweapon = 0, g_secweapon = 0;

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

				if(!strcmp(Setting_value[0], "DM MoD", false)) g_dm_mod = StringToInt(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Player Respawn Time", false)) g_spawn_time = StringToFloat(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Player Protect Time", false)) g_protect_time = StringToFloat(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Remove Dropped Weapon", false)) g_redropp_weapon = StringToInt(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Block Player Suicide", false)) g_block_kill = StringToInt(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Unlimited Ammo", false)) g_unlimitbp_ammo = StringToInt(Setting_value[1]);
				else if(!strcmp(Setting_value[0], "Give Grenade (hegrenade, flashbang, smokegrenade)", false)) 
				{
					new String:grenade_class[3][10];
					ExplodeString(Setting_value[1], ",", grenade_class, 3, 10);
					g_spawn_grenade[0] = StringToInt(grenade_class[0]);
					g_spawn_grenade[1] = StringToInt(grenade_class[1]);
					g_spawn_grenade[2] = StringToInt(grenade_class[2]);
				}
				else if(!strcmp(Setting_value[0], "Kill WiN", false)) g_MaxKill = StringToInt(Setting_value[1]);
			}
			case 2: 
			{
				ExplodeString(linedata, ",", weapon_get, 2, 256);

				g_priweaponID[g_priweapon] = get_user_weapon_id(weapon_get[0]);
				g_priweaponN[g_priweapon] = weapon_get[1];
				g_priweapon += 1;
			}
			case 3: 
			{
				ExplodeString(linedata, ",", weapon_get, 2, 256);

				g_secweaponID[g_secweapon] = get_user_weapon_id(weapon_get[0]);
				g_secweaponN[g_secweapon] = weapon_get[1];
				g_secweapon += 1;
			}
		}
	}
	CloseHandle(file);
}
// ================================

// Ran Spawn Save/Load ====
public load_ranspawn()
{
	new String:path[255], String:g_MapName[128];
	GetCurrentMap(g_MapName, sizeof(g_MapName));
	Format(path, sizeof(path), "cfg/DmKD-S/spawn/%s.cfg", g_MapName);

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
	new String:path[255], String:g_MapName[128], Float:Player_Origin[3], String:Save_path[254];
	GetCurrentMap(g_MapName, sizeof(g_MapName));
	Format(path, sizeof(path), "cfg/DmKD-S/spawn/%s.cfg", g_MapName);

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Player_Origin);
	Format(Save_path, sizeof(Save_path), "%f %f %f", Player_Origin[0], Player_Origin[1], Player_Origin[2]);

	new Handle:file = OpenFile(path, "at");

	WriteFileLine(file, Save_path);

	CloseHandle(file);
}
// =====================

// Next Maps =========================
public load_ranmaps()
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
		g_mapname[g_mapsCount] = linedata;

		if (g_mapsCount >= sizeof g_mapname) break;
	}

	CloseHandle(file);
}
// =================================

// New Entity put in server (player / entity) ==
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDK_TakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, SDK_TakeDamagePost);
	SDKHook(client, SDKHook_PreThink, SDK_PreThink);

	g_inser_menu[client] = false;
	g_dmdamage[client] = false;
	CreateTimer(0.5, Spawn_NewPlayeR, client);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!IsValidEntity(entity) || !IsValidEdict(entity)) return;

	SDKHook(entity, SDKHook_SpawnPost, SDK_SpawnPost);
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
	new Handle:dmsetmenu = CreatePanel();
	SetPanelTitle(dmsetmenu, "DM:KD-S Setting Menu");

	DrawPanelItem(dmsetmenu, "Set new spawn origin", ITEMDRAW_DEFAULT);

	DrawPanelItem(dmsetmenu, "Exit", ITEMDRAW_CONTROL);

	SendPanelToClient(dmsetmenu, client, Dm_Game_Set, 20);
	CloseHandle(dmsetmenu);
}

public Dm_Game_Set(Handle:menu, MenuAction:action, param1, param2)
{
	if (param2 == 1)
	{
		Dm_Game_Set_Menu(param1);
		save_ranspawn(param1);
	}
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
	if (!client || !IsClientConnected(client) || !g_block_kill) return Plugin_Continue;

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
	dm_game = true;

	if (g_dm_mod == 1 && g_spawnCount == 0)
	{
		g_dm_mod = 0;
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

	if (g_MaxKill == 0)
	{
		if (g_dm_mod == 1) g_MaxKill = ingame_player * 2;
		else g_MaxKill = ingame_player * 4;
	}

	SendMsg(-1, 1, " Max Kill is : %d", g_MaxKill);
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	if (!dm_game) return Plugin_Continue;
	return Plugin_Handled;
}
// ===================

// Spawn New player ==========
public Action:Spawn_NewPlayeR(Handle:timer, any:client )
{
	if (!IsClientConnected(client)) return;

	if (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
	{
		if (!g_inser_menu[client])
		{
			g_inser_menu[client] = true;
			CreateTimer(g_spawn_time, Respawn, client);
		}
		return;
	}

	CreateTimer(0.5, Spawn_NewPlayeR, client);
}
// ===============================

// Dm playing ==================
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!dm_game)
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	CreateTimer(g_spawn_time, Respawn, client);

	if (g_dm_mod == 1)
	{
		g_player_kill[attacker]++;
		SendMsg(attacker, 1, "%t", "DM_KILLNUM", g_player_kill[attacker], g_MaxKill);
	}
	else
	{
		if (GetClientTeam(attacker) == CS_TEAM_T) TR_kill++;
		else if (GetClientTeam(attacker) == CS_TEAM_CT) CT_kill++;

		SendMsg(-1, 1, "%t", "TDM_KILLNUM", CT_kill, TR_kill, g_MaxKill);
	}

	if (g_player_kill[attacker] >= g_MaxKill || TR_kill >= g_MaxKill || CT_kill >= g_MaxKill)
		dm_game_end( g_dm_mod, GetClientTeam(attacker), attacker, GetRandomInt(0, g_mapsCount-1));
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_dm_mod == 1 && g_spawnCount > 0) //CreateTimer(0.1, Set_Origin, client);
		Set_Origin(Handle:0.0, client);
}

public Action:SDK_TakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!dm_game)
		return Plugin_Stop;

	if (g_Protection[victim])
	{
		damage *= 0.0;
		return Plugin_Changed;
	}

	if (g_dm_mod == 1 && attacker)
	{
		new Vteam = GetClientTeam(victim);

		if (Vteam == GetClientTeam(attacker))
		{
			// Set m_iTeamNum, because use CS_SwitchTeam will call jointeam say..
			// and i don't know block jointeam say xDD'
			if (Vteam == CS_TEAM_T) SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_CT,2);
			else  SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_T,2);

			g_dmdamage[victim] = true;
		}
	}

	return Plugin_Continue;
}

public SDK_TakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (!g_dmdamage[victim])
		return;

	if (GetClientTeam(victim) == CS_TEAM_T) SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_CT,2);
	else SetEntProp(victim,Prop_Data,"m_iTeamNum", CS_TEAM_T,2);

	g_dmdamage[victim] = false;
}

public SDK_PreThink(client)
{
	if (!IsClientConnected(client)) return;
	if (!IsPlayerAlive(client)) return;

	SetEntData(client, g_iAccount, 0);

	if (g_unlimitbp_ammo) Set_BpAmmo(client);
}

public Action:CS_OnCSWeaponDrop(client, weaponIndex) 
	if (g_redropp_weapon) AcceptEntityInput(weaponIndex, "Kill"); 
// ===============================

// Dm Spawn ====================
public Action:Respawn(Handle:timer, any:client )
	Get_Weapon_Menu(client);

public Get_Weapon_Menu(client)
{
	if ((g_sec_weaponid[client] == 0 && g_pri_weaponid[client] == 0) || get_user_bot(client))
	{
		Send_Pri_Weapon_Menu(client);
		return;
	}

	new Handle:weaponmenu = CreatePanel();

	decl String:menu_setting[100];
	Format(menu_setting, 99, "%t", "Weapon Menu");

	SetPanelTitle(weaponmenu, menu_setting);

	Format(menu_setting, 99, "%t", "Use New Weapon");
	DrawPanelItem(weaponmenu, menu_setting, ITEMDRAW_DEFAULT);

	Format(menu_setting, 99, "%t", "Use Last-Time Weapon");
	DrawPanelItem(weaponmenu, menu_setting, ITEMDRAW_DEFAULT);

	new String:Weapon_Name[64];
	SetPanelCurrentKey(weaponmenu, 7);

	Format(menu_setting, 99, "%t :", "Your Last Time Weapon");
	DrawPanelItem(weaponmenu, menu_setting, ITEMDRAW_DISABLED);

	Format(Weapon_Name, sizeof(Weapon_Name), "%s", WEAPON_CLASSNAME[g_sec_weaponid[client]]);
	DrawPanelItem(weaponmenu, Weapon_Name, ITEMDRAW_DISABLED);

	Format(Weapon_Name, sizeof(Weapon_Name), "%s", WEAPON_CLASSNAME[g_pri_weaponid[client]]);
	DrawPanelItem(weaponmenu, Weapon_Name, ITEMDRAW_DISABLED);

	SendPanelToClient(weaponmenu, client, Weapon_Menu, 500);
	CloseHandle(weaponmenu);
}

public Weapon_Menu(Handle:menu, MenuAction:action, param1, param2)
{
	if (param2 == 1) Send_Pri_Weapon_Menu(param1);
	else Player_Spawn(param1);
}

public Send_Pri_Weapon_Menu(client)
{
	if (get_user_bot(client)) 
	{
		g_pri_weaponid[client] = g_priweaponID[GetRandomInt(0, g_priweapon-1)];
		Send_Sec_Weapon_Menu(client);
		return;
	}

	decl String:title[100];
	Format(title, 64, "%t", "Pri Weapon Menu");
	new Handle:weaponmenu = CreatePanel();
	SetPanelTitle(weaponmenu, title);

	new i, String:Value[64];
	for (i = 0; i < g_priweapon; i++)
	{
		Format(Value, sizeof(Value), "%s", g_priweaponN[i]);
		DrawPanelItem(weaponmenu, Value, ITEMDRAW_DEFAULT);
	}

	SendPanelToClient(weaponmenu, client, PriWeapon_Menu, 500);
	CloseHandle(weaponmenu);
}

public PriWeapon_Menu(Handle:menu, MenuAction:action, param1, param2)
{
	param2--;
	g_pri_weaponid[param1] = g_priweaponID[param2];
	Send_Sec_Weapon_Menu(param1);
}

public Send_Sec_Weapon_Menu(client)
{
	if (get_user_bot(client)) 
	{
		g_sec_weaponid[client] = g_secweaponID[GetRandomInt(0, g_secweapon-1)];
		Player_Spawn(client);
		return;
	}

	decl String:title[100];
	Format(title, 64, "%t", "Sec Weapon Menu");
	new Handle:weaponmenu = CreatePanel();
	SetPanelTitle(weaponmenu, title);

	new i, String:Value[64];
	for (i = 0; i < g_secweapon; i++)
	{
		Format(Value, sizeof(Value), "%s", g_secweaponN[i]);
		DrawPanelItem(weaponmenu, Value, ITEMDRAW_DEFAULT);
	}

	SendPanelToClient(weaponmenu, client, SecWeapon_Menu, 500);
	CloseHandle(weaponmenu);
}

public SecWeapon_Menu(Handle:menu, MenuAction:action, param1, param2)
{
	param2--;
	g_sec_weaponid[param1] = g_secweaponID[param2];

	Player_Spawn(param1);
}

public Player_Spawn(client)
{
	if (!IsPlayerAlive(client)) CS_RespawnPlayer(client);

	new weaponEntity = GetPlayerWeaponSlot(client, 1);

	RemovePlayerItem(client, weaponEntity);
	RemoveEdict(weaponEntity);

	GivePlayerItem(client, "item_assaultsuit", 0);

	g_Protection[client] = 1;
	SetEntityRenderMode(client, RENDER_TRANSADD);
	SetEntityRenderFx(client, RENDERFX_DISTORT);

	if (GetClientTeam(client) == CS_TEAM_T)
		SetEntityRenderColor(client, 200, 0, 0, 120);
	else if (GetClientTeam(client) == CS_TEAM_CT)
		SetEntityRenderColor(client, 0, 0, 200, 120);

	GivePlayerItem(client, WEAPON_CLASSNAME[g_sec_weaponid[client]]);
	GivePlayerItem(client, WEAPON_CLASSNAME[g_pri_weaponid[client]]);

	if (g_spawn_grenade[0]) GivePlayerItem(client, "weapon_hegrenade");
	if (g_spawn_grenade[1]) GivePlayerItem(client, "weapon_flashbang");
	if (g_spawn_grenade[2]) GivePlayerItem(client, "weapon_smokegrenade");

	CreateTimer(g_protect_time, RemoveProtection, client);
}
// ===============================

// Dm game end ====================
public dm_game_end(gamemod, winteam, winplayer, next_map)
{	
	dm_game = false;
	CreateTimer(8.0, change_map, next_map);
	if (gamemod == 1)
	{
		SendMsg(-1, 1, "%t", "DM_WIN", winplayer, g_mapname[next_map]);
		return;
	}
	SendMsg(-1, 1, "%t", "TDM_WILL",  winteam, g_mapname[next_map]);
}

public Action: change_map(Handle:timer, any:next_map )
	ServerCommand("changelevel %s", g_mapname[next_map]);
// ===============================

public Action:Set_Origin(Handle:timer, any:client)
//public Set_Origin(client)
{
//	SetEntPropVector(client, Prop_Send, "m_vecOrigin", g_spawns[GetRandomInt(0, g_spawnCount-1)]); // sad set =-='

	new Float:spawn_or[3];
	spawn_or = g_spawns[GetRandomInt(0, g_spawnCount-1)];

	TeleportEntity(client, spawn_or, NULL_VECTOR, NULL_VECTOR);

	new Float:Player_Origin[3], Float:fMins[3], Float:fMaxs[3], Float:ang[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Player_Origin);
	GetClientMaxs(client, fMaxs);
	GetClientMins(client, fMins);
//	GetEntPropVector(client, Prop_Send, "m_vecMins", fMins);
//	GetEntPropVector(client, Prop_Send, "m_vecMaxs", fMaxs);
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

public Action:RemoveProtection(Handle:timer, any:client )
{
	if (!IsClientConnected(client))
		return;

	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderFx(client, RENDERFX_NONE);
	SetEntityRenderColor(client);	
	g_Protection[client] = 0;
}

public Set_BpAmmo(client) // Set Bp ammo, i order in amxx plug-in..
{
	new String:weapon_class[32], weaponID, ammo_offset;
	GetClientWeapon(client, weapon_class,  sizeof(weapon_class));
	weaponID = get_user_weapon_id(weapon_class);

	if (g_AmmoOffset[weaponID] == 0) return;

	ammo_offset = FindDataMapOffs(client, "m_iAmmo")+(g_AmmoOffset[weaponID]*4);
	if (GetEntData(client, ammo_offset) == g_BpAmmo[weaponID]) return;

	SetEntData(client, ammo_offset, g_BpAmmo[weaponID]);
}

get_user_bot(client) // Beacuse i know bot steam id is 'BOT'
{
	if (!client || !IsClientConnected(client) || !IsClientInGame(client)) return false;

	new String:SteamID[50];
	GetClientAuthString(client, SteamID, sizeof(SteamID));

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
