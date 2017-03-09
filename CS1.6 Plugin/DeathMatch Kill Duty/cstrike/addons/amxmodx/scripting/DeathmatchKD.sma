
/* 
			DeathMatch: Kill Duty - Upgrade 2
				xx/3/2017 (Version: 3.1.0)
			
					HsK-Dev Blog By CCN
			
			http://ccnhsk-dev.blogspot.com/
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN	"Deathmatch: Kill Duty"
#define VERSION	"3.0.9.2"
#define AUTHOR	"HsK-Dev Blog By CCN"

new const MAX_BPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

new const BUY_AMMO[] = { -1, 13, -1, 30, -1, 8, -1, 12, 30, -1, 30, 50, 12, 30, 30, 30, 12, 30,
			10, 30, 30, 8, 30, 30, 30, -1, 7, 30, 30, -1, 50 }

new const AMMO_TYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

new const weapon_msgname[CSW_P90+1][] = { "skull", "p228", "", "scout", "hegrenade", "xm1014", "c4", "mac10",
     "aug", "smokegrenade", "elite", "fiveseven", "ump45", "sg550", "galil", "famas",
     "usp", "glock18", "awp", "mp5navy", "m249", "m3", "m4a1",
     "tmp", "g3sg1", "flashbang", "deagle", "sg552", "ak47", "knife", "p90" }

new const WEAPON_CLASSNAME[CSW_P90+1][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

new const AMMOID_WEAPON[] = { 0, CSW_AWP, CSW_SCOUT, CSW_M249, CSW_AUG, CSW_M3, CSW_MAC10, CSW_FIVESEVEN, CSW_DEAGLE,
			CSW_P228, CSW_ELITE, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_C4 }

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|
	(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|
	(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NOCLIP_WEAPONS_BIT_SUM = (1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4)

const KEYSMENU = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

new const OBJECTIVE_ENTITYS[][] = {  "func_bomb_target", "info_bomb_target", "info_vip_start", "func_vip_safetyzone", 
	"func_escapezone", "hostage_entity", "monster_scientist", "func_hostage_rescue", "info_hostage_rescue", "env_fog", 
	"env_rain", "env_snow", "item_longjump", "func_vehicle" }

// Task ID
enum (+= 1000)
{
	TASK_ADDHP = 1000,
	TASK_WEAP_M, 
	TASK_SPAWN,
	TASK_ORIGIN_SET, 
	TASK_INEV_RES, 
	TASK_MAKEGAME
}

const OFFSET_CSTEAMS = 114
const OFFSET_CSMONEY = 115
const OFFSET_DEFUSE_PLANT = 193
const OFFSET_LINUX = 5 

const EXTRAOFFSET_WEAPONS = 4
const OFFSET_SILENCER_FIREMODE = 74

#define M4A1_SILENCED                (1<<2)
#define USP_SILENCED                (1<<0)

const ACCESS_FLAG = ADMIN_BAN

// Game vars
new g_dmMode = -1; // DM MoD
new bool:g_dm_play; // DM Game
new g_MaxKill; // Max Kill
new g_CT_kill, g_TR_kill; // CT and TR Kill [tdm]
new g_Nmap_NU, g_Nmap_name[256][32]; // Next Map
new bool:g_ranspawn = false; // Ran Spawn mod
new Float:g_spawns[128][3], g_spawnCount; // Ran Spawn set
new Float:g_ReSTime; // Player Respawn Time
new Float:g_PtTime; // Player Protect Time
new Float:g_InResTime; // Player Enforcement Respawn Time
new Float:g_ReDropWeaponTime; // Remove Dropped Weapon Time
new bool:g_BlockSuicide; // Block player Suicide
new bool:g_UnlimitAmmo; // Unlimited Ammo(Magazine)
new bool:g_GGrenade[3]; // Give Grenade
new g_StartTimeData, g_StartTime; // Game Start Time (Freeze Time)
new g_fwSpawn; // Spawn and forward handles
new bool:g_BZAddHp, Float:g_BZAddHpTime, g_BZAddHpAmounT; // Buyzone Add hp setting
new g_KEAddHp; // Kill Enemy Add HP (DM Mode)

// Player vars
new m_in_buyzone[33]; // Is Buy Zone
new m_player_kill[33]; // Player Kill [pdm]
new bool:m_chosen_pri_weap[33]; // Is Pri Weap set
new m_pri_weaponid[33]; // Pri Weap id
new bool:m_chosen_sec_weap[33]; // Is Sec Weap set
new m_sec_weaponid[33]; // Sec Weap id
new bool:m_dead_fl[33]; // Player Dead Perspective
new bool:m_dmdamage[33] = false;  // DM Damage

// Weapons Menu
new g_priweapon, g_secweapon, g_priweaponID[30], g_secweaponID[30], 
g_priweaponN[30][512], g_secweaponN[30][512];
new g_bnweapon[2][3];  // Bot Nice Weapon (AK/M4...)

// Message IDs vars
new g_msgHideWeapon, g_msgCrosshair, g_msgSync, g_msgStatusText, g_magStatusValue;

// Ham Z-Bot
new cvar_botquota, g_hamczbots;

public plugin_precache()
{
	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn");
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	// Forward
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_ClientKill, "fw_ClientKill");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData", 1);
	unregister_forward(FM_Spawn, g_fwSpawn);

	// Ham
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1);

	// Event 
	register_event("ResetHUD", "event_hud_reset", "b");
	register_event("StatusIcon", "event_BuyZone", "b", "2=buyzone");
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	register_event("StatusValue", "event_ShowStatus", "be", "1=2", "2!0");
	register_event("StatusValue", "event_HideStatus", "be", "1=1", "2=0");
	register_logevent("logevent_round_start", 2, "1=Round_Start");

	register_clcmd("buy", "clcmd_buy");
	register_clcmd("chooseteam", "clcmd_changeteam");
	register_clcmd("jointeam", "clcmd_changeteam");
	register_clcmd("say dm_set", "dm_adminSettingMenu");
	register_clcmd("say /dm_set", "dm_adminSettingMenu");

	register_message(get_user_msgid("RoundTime"), "message_RoundTime");
	register_message(g_msgHideWeapon, "message_HideWeapon");
	register_message(get_user_msgid("ShowMenu"), "message_show_menu");
	register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu");
	register_message(get_user_msgid("Money"), "message_Money");
	register_message(get_user_msgid("AmmoX"), "message_AmmoX");
	register_message(get_user_msgid("TextMsg"), "message_textmsg");
	register_message(get_user_msgid("StatusIcon"), "message_statusIcon");
	register_message(get_user_msgid("Radar"), "message_radar");

	register_menu("UsE WeapoN MeuN", KEYSMENU, "dm_weapon_meun_set");
	register_menu("Admin Menu 1", KEYSMENU, "dm_admin_meun_set");

	LoadDMSettingFile();

	//MSG
	g_msgHideWeapon = get_user_msgid("HideWeapon");
	g_msgCrosshair = get_user_msgid("Crosshair");
	g_msgStatusText = get_user_msgid("StatusText");
	g_magStatusValue = get_user_msgid("StatusValue");
	g_msgSync = CreateHudSyncObj();

	register_dictionary("DeathmatchKD.txt");

	cvar_botquota = get_cvar_pointer("bot_quota");
}

public plugin_cfg() DM_BaseGameSetting()

// Dm Game ini load
LoadDMSettingFile()
{
	g_bnweapon[0][0] = -1; g_bnweapon[0][1] = -1; g_bnweapon[0][2] = -1;
	g_bnweapon[1][0] = -1; g_bnweapon[1][1] = -1; g_bnweapon[1][2] = -1;

	new path[64];
	get_configsdir(path, charsmax(path));
	format(path, charsmax(path), "%s/Dm_KD/DeathmatchKD_Setting.ini", path);

	if (!file_exists(path)) return;

	new file, linedata[1024], section = 0;
	file = fopen(path, "rt");

	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata));
		replace(linedata, charsmax(linedata), "^n", "");
		trim(linedata);

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
				new key[64], value[960];
				strtok(linedata, key, charsmax(key), value, charsmax(value), '=');
				trim(key);
				trim(value);

				if (equal(key, "DM MoD"))
				{
					g_dmMode = str_to_num(value);
					
					if (g_dmMode == 0) register_cvar("HsK_Deathmatch_Plugin_load_SyPB", "0");
					else register_cvar("HsK_Deathmatch_Plugin_load_SyPB", "1"); 
				}
				else if (equal(key, "Player Respawn Time")) g_ReSTime = str_to_float(value);
				else if (equal(key, "Player Protect Time")) g_PtTime = str_to_float(value);
				else if (equal(key, "Player Enforcement Respawn Time")) g_InResTime = str_to_float(value);
				else if (equal(key, "Remove Dropped Weapon Time")) g_ReDropWeaponTime = str_to_float(value);
				else if (equal(key, "Block Player Suicide")) g_BlockSuicide = str_to_bool(value);
				else if (equal(key, "Unlimited Ammo")) g_UnlimitAmmo = str_to_bool(value);
				else if (equal(key, "Give Grenade (hegrenade, flashbang, smokegrenade)"))
				{
					new i = 0;
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key);
						trim(value);
						
						g_GGrenade[i] = str_to_bool(key);
						i++;
					}
				}
				else if (equal(key, "Freeze Time")) g_StartTimeData = str_to_num(value);
				else if (equal(key, "Kill WiN")) g_MaxKill = str_to_num(value);
				else if (equal(key, "Buyzone Add HP")) g_BZAddHp = str_to_bool(value);
				else if (equal(key, "Buyzone Add HP Time")) g_BZAddHpTime = str_to_float(value);
				else if (equal(key, "Buyzone Add HP Amount")) g_BZAddHpAmounT = str_to_num(value);
				else if (equal(key, "Kill Enemy Add HP")) g_KEAddHp = str_to_num(value);
			}
			case 2:
			{
				new weaponid[255], weaponname[512];
				strtok(linedata, weaponid, charsmax(weaponid), weaponname, charsmax(weaponname), ',');

				g_priweaponID[g_priweapon] = get_user_weapon_id(weaponid);
				g_priweaponN[g_priweapon] = weaponname;

				if (equal(g_priweaponID[g_priweapon], "weapon_ak47")) g_bnweapon[0][0] = g_priweapon;
				else if (equal(g_priweaponID[g_priweapon], "weapon_m4a1")) g_bnweapon[0][1] = g_priweapon;
				else if (equal(g_priweaponID[g_priweapon], "weapon_awp")) g_bnweapon[0][2] = g_priweapon;

				g_priweapon += 1;
			}
			case 3:
			{
				new weaponid[255], weaponname[512];
				strtok(linedata, weaponid, charsmax(weaponid), weaponname, charsmax(weaponname), ',');

				g_secweaponID[g_secweapon] = get_user_weapon_id(weaponid);
				g_secweaponN[g_secweapon] = weaponname;

				if (equal(g_secweaponID[g_secweapon], "weapon_glock18")) g_bnweapon[1][0] = g_priweapon;
				else if (equal(g_secweaponID[g_secweapon], "weapon_usp")) g_bnweapon[1][1] = g_priweapon;
				else if (equal(g_secweaponID[g_secweapon], "weapon_deagle")) g_bnweapon[1][2] = g_priweapon;

				g_secweapon += 1;
			}
		}
	}
	if (file) fclose(file)
	
	if (g_StartTimeData < 5)
		g_StartTimeData = 5;
	
	GetGameMap();
	LoadSpawnPoint();
}

// Random Spawns ============================
public SetSpawnPoint(id)
{
	new cfgdir[32], mapname[32], filepath[100], Float:origin[3], buffer[512], file;
	get_configsdir(cfgdir, charsmax(cfgdir));
	get_mapname(mapname, charsmax(mapname));
	formatex(filepath, charsmax(filepath), "%s/Dm_KD/spawn/%s.cfg", cfgdir, mapname);
	pev(id, pev_origin, origin);

	file = fopen(filepath,"at");

	format(buffer, charsmax(buffer), "%f %f %f ^n", origin[0], origin[1], origin[2]);
	fputs(file, buffer);

	fclose(file);

	dm_adminSettingMenu (id);

	server_print("==========================");
	server_print("= [Deathmatch: Kill Duty]     ");
	server_print("= Save New Spawns");
	server_print("==========================");
	client_print(id, print_chat, "New Spawn : %f %f %f", origin[0], origin[1], origin[2]);
}

stock LoadSpawnPoint()
{
	new cfgdir[32], mapname[32], filepath[100], linedata[64];
	get_configsdir(cfgdir, charsmax(cfgdir));
	get_mapname(mapname, charsmax(mapname));
	formatex(filepath, charsmax(filepath), "%s/Dm_KD/spawn/%s.cfg", cfgdir, mapname);

	if (file_exists(filepath))
	{
		new data[10][6], file = fopen(filepath,"rt");
		
		while (file && !feof(file))
		{
			fgets(file, linedata, charsmax(linedata));

			if(!linedata[0] || str_count(linedata,' ') < 2) continue;

			parse(linedata,data[0],5,data[1],5,data[2],5);

			g_spawns[g_spawnCount][0] = str_to_float(data[0]);
			g_spawns[g_spawnCount][1] = str_to_float(data[1]);
			g_spawns[g_spawnCount][2] = str_to_float(data[2]);  //floatstr

			g_spawnCount++;
			if (g_spawnCount >= sizeof g_spawns)
				break;
		}
		if (file) fclose(file);
		g_ranspawn = true;

		server_print("==========================");
		server_print("= [Deathmatch: Kill Duty]     ");
		server_print("= MAP : %s", mapname);
		server_print("= Load Spawns.....");
		server_print("= Spawn Count Is %d", g_spawnCount);
		server_print("==========================");
	}
	else
		g_ranspawn = false;
}
//==============

// Random Map ============
public GetGameMap()
{
	new path[64];
	get_configsdir(path, charsmax(path));
	format(path, charsmax(path), "%s/Dm_KD/maps.ini", path);

	if (!file_exists(path)) return;

	new file, linedata[1024];

	file = fopen(path, "rt");

	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata));
		replace(linedata, charsmax(linedata), "^n", "");
		trim(linedata);
		
		if(!linedata[0] || linedata[0] == ';' || (linedata[0] == '/' && linedata[1] == '/')) continue;
		
		g_Nmap_NU += 1;
		
		copy(g_Nmap_name[g_Nmap_NU] , charsmax(g_Nmap_name), linedata);
	}
	if (file) fclose(file);
}
// =====================

// Admin meun ==========
public dm_adminSettingMenu(id)
{
	if ((get_user_flags(id) & ACCESS_FLAG))
	{
		static menu[250], len;
		len = 0;

		len += formatex(menu[len], sizeof menu -1 - len, "\y %L ^n^n", id, "ADMIN_SET_M1");
		len += formatex(menu[len], sizeof menu -1 - len, "\r1.\w %L ^n^n^n", id, "ADMIN_SET_M2");
		len += formatex(menu[len], sizeof menu -1 - len, "\r0.\w %L", id, "MENU_EXIT");

		show_menu(id, KEYSMENU, menu, -1, "Admin Menu 1");
	}

	return PLUGIN_HANDLED;
}

public dm_admin_meun_set(id, key)
{
	switch (key)
	{
		case 0: SetSpawnPoint(id);
	}
}
//=====================

//Set Dm mod and srever cmd... =========
public DM_BaseGameSetting()
{
	if (g_dmMode && !g_ranspawn)
	{
		g_dmMode = false;

		new mapname[32]; get_mapname(mapname, charsmax(mapname));
		server_print("%L", LANG_PLAYER, "ERROR_PDM", mapname);
	}

	if (!g_dmMode) server_cmd("mp_friendlyfire 0");
	else server_cmd("mp_friendlyfire 1");
	
	g_dm_play = false;
}

//==========================

// Hud Msg ==================
public dm_showHudMsg(id)
{
	if (!dm_game_play())
		return;

	if (is_user_alive(id))
		set_hudmessage(100, 100, 100, -1.0, 0.21, 0, 6.0, 999.0, 0.1, 0.2, -1);
	else
		set_hudmessage(100, 100, 100, 0.12, 0.21, 0, 6.0, 999.0, 0.1, 0.2, -1);
	
	if (!g_dmMode)
		ShowSyncHudMsg(id, g_msgSync, "%L", LANG_PLAYER, "TEAM_KILL_MSG", g_CT_kill, g_TR_kill, g_MaxKill);
	else
		ShowSyncHudMsg(id, g_msgSync, " %L", id, "P_KILL_MSG", m_player_kill[id], g_MaxKill);

}
//=======================

// Block map [c4...ho...] ==========
public fw_Spawn(entity)
{
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	static classname[32];
	pev(entity, pev_classname, classname, charsmax(classname));
	
	for (new i = 0; i < sizeof OBJECTIVE_ENTITYS; i++)
	{
		if (equal(classname, OBJECTIVE_ENTITYS[i]))
		{
			engfunc(EngFunc_RemoveEntity, entity);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}
// ======================

// ================================== 
//  Ham				    //
// ================================== 

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	new die_sounD[32];
	format(die_sounD, 31, "player/die%d.wav", random_num(1, 3));
	emit_sound(victim, CHAN_BODY, die_sounD, 1.0, ATTN_NORM, 0, PITCH_NORM);

	set_task(g_ReSTime, "dm_menu_weap", victim+TASK_WEAP_M);

	set_msg_block(get_user_msgid("HideWeapon"), BLOCK_SET);

	if (fm_get_user_defuse(victim)) fm_set_user_defuse(victim, 0);

	// 3.0.1 - Improve
	set_task(0.1, "dead_flag", victim);

	drop_weapons(victim, 0);
	fm_strip_user_weapons(victim);

	set_pev(victim, pev_solid, SOLID_NOT);
	set_pdata_int(victim, 444, get_user_deaths(victim) + 1, 5);
	set_pev(victim, pev_sequence, random_num(106, 109));
	set_pev(victim, pev_animtime, get_gametime()+0.07);
	set_pev(victim, pev_frame, 1.0);
	set_pev(victim, pev_framerate, 1.0);

	if (attacker == victim || attacker > 32 || !attacker)
	{
		set_pev(attacker, pev_frags, float(pev(attacker, pev_frags)-1));
		SendDeathMsg(attacker, victim, "worldspawn", 1);
		return HAM_SUPERCEDE;
	}
	static weapon, hitzone, hs;
	get_user_attacker(victim, weapon, hitzone);
	weapon = get_user_weapon(attacker);
	if (hitzone == 1) hs = 1; else hs = 0;

	set_pev(attacker, pev_frags, float(pev(attacker, pev_frags)+1));
	SendDeathMsg(attacker, victim, weapon_msgname[weapon], hs);

	// 3.0.1 - Add Msg
	new killer_name[32], victim_name[32];
	get_user_name(attacker, killer_name, 31);
	get_user_name(victim, victim_name, 31);
	
	m_player_kill[attacker] += 1;
	client_print(victim, print_center,"%L", victim, "DM_DEAD_MSG", killer_name);
	
	if (!g_dmMode)
	{
		if (fm_get_user_team(victim) != fm_get_user_team(attacker))
		{
			if (fm_get_user_team(victim) == 1) g_CT_kill += 1;
			else if (fm_get_user_team(victim) == 2) g_TR_kill += 1;
			
			client_print(attacker, print_center,"%L", attacker, "TDM_KILLER_MSG", victim_name, m_player_kill[attacker]);

			if (g_CT_kill >= g_MaxKill || g_TR_kill >= g_MaxKill)
			{
				g_dm_play = false;
				dm_game_end(fm_get_user_team(attacker), dm_next_map());
			}
		}
	}
	else
	{
		if (g_KEAddHp > 0)
			fm_set_user_health(attacker, min(fm_get_user_health(attacker) + g_KEAddHp, 100));
			
		client_print(attacker, print_center,"%L", attacker, "DM_KILLER_MSG", victim_name, m_player_kill[attacker], g_MaxKill);

		if (m_player_kill[attacker] >= g_MaxKill)
		{
			g_dm_play = false;
			dm_game_end(attacker, dm_next_map());
		}
	}

	return HAM_SUPERCEDE;
}

public dead_flag(id)
{
	set_pev(id, pev_deadflag, 3);
	m_dead_fl[id] = true;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!dm_game_play())
		return HAM_SUPERCEDE;

	if (victim == attacker)
		return HAM_IGNORED;

	if (fm_get_user_team(victim) == fm_get_user_team(attacker) && !g_dmMode)
		return HAM_SUPERCEDE;
		
	new Vteam = fm_get_user_team(victim);
	if (Vteam == fm_get_user_team(attacker) && g_dmMode)
	{
		m_dmdamage[victim] = true;

		if (Vteam == 1) fm_set_user_team(victim, 2);
		else if (Vteam == 2) fm_set_user_team(victim, 1);
	} 

	return HAM_IGNORED;
}

public fw_TakeDamage_Post(victim)
{
	if (!m_dmdamage[victim])
		return;

	new Vteam = fm_get_user_team(victim);
	if (Vteam == 1) fm_set_user_team(victim, 2);
	else if (Vteam == 2) fm_set_user_team(victim, 1);

	m_dmdamage[victim] = false;
}
// ================================== 
//  Ham	End			    //
// ================================== 

// ================================== 
//  Forward			    //
// ================================== 
public fw_SetModel(entity, const model[])
{
	if (strlen(model) < 8)
		return;
	
	if (g_ReDropWeaponTime > 0.0)
	{
		static classname[10];
		pev(entity, pev_classname, classname, charsmax(classname));
		
		if (equal(classname, "weaponbox"))
			set_pev(entity, pev_nextthink, get_gametime() + g_ReDropWeaponTime);
	}
}

public fw_ClientKill()
{
	if (g_BlockSuicide) return FMRES_SUPERCEDE;
	return FMRES_IGNORED;
}

public fw_UpdateClientData(id, sendweapons, cd_handle)
{
	if (is_user_alive(id) || !m_dead_fl[id]) return FMRES_IGNORED;
 
	set_cd(cd_handle, CD_iUser1, get_gametime() + 0.007);  

	return FMRES_HANDLED;
}
// ================================== 
//  Forward	End	            //
// ================================== 

// New Round ==================
public event_round_start()
{
	g_dm_play = false;
	g_TR_kill = 0;
	g_CT_kill = 0;
	g_StartTime = g_StartTimeData;
	
	server_cmd("mp_freezetime %d", g_StartTimeData);

	remove_task(TASK_MAKEGAME);
	set_task(0.0, "GameStartCountDown", TASK_MAKEGAME);

	for (new id = 1; id <= get_maxplayers(); id++)
	{
		if (!is_user_connected(id) || !is_user_alive(id))
			continue;
			
		m_player_kill[id] = 0;
		remove_task(id+TASK_WEAP_M);
		dm_menu_pri_weap(id+TASK_WEAP_M);
	}
}

public GameStartCountDown()
{
	if (g_StartTime >= 1)
	{
		client_print(0, print_center,"%L", LANG_PLAYER, "FREEZE_MSG", g_StartTime);

		g_StartTime -= 1;
		remove_task(TASK_MAKEGAME);
		set_task(1.0, "GameStartCountDown", TASK_MAKEGAME);
		
		if (g_StartTime == 1)
		{
			for (new id = 1; id <= get_maxplayers(); id++)
			{
				if (!is_user_connected(id))
					continue;

				if (!is_user_alive(id))
					continue;

				set_msg_block(get_user_msgid("HideWeapon"), BLOCK_SET);
				set_msg_block(get_user_msgid("RoundTime"), BLOCK_SET);
				set_task(0.1, "event_hud_reset", id);
				m_dead_fl[id] = false;
					
				if (g_dmMode && g_ranspawn)
				{
					remove_task(id+TASK_ORIGIN_SET);
					fm_set_user_origin(id+TASK_ORIGIN_SET, g_spawns[random_num(0, g_spawnCount - 1)]);
				}
			}
		}
	}
}

public logevent_round_start()
{
	new Players[32], iNum;
	get_players(Players, iNum);

	if (!g_dmMode)
	{
		if (g_MaxKill <= 0)
			g_MaxKill = random_num(10, 15) * (iNum-1);

		client_print(0, print_center, "%L", LANG_PLAYER, "TDM_GS_MSG", g_MaxKill);

		g_TR_kill = 0;
		g_CT_kill = 0;
	}
	else
	{
		if (g_MaxKill <= 0) g_MaxKill = random_num(4, 6) * (iNum-1);
		client_print(0, print_center, "%L", LANG_PLAYER, "PDM_GS_MSG", g_MaxKill);
	}
	g_dm_play = true
}
// =====================

// Player Spawn and Weap Menu =============
public dm_menu_weap(taskid)
{
	if (!dm_game_play())
		return;

	new id = taskid - TASK_WEAP_M;

	if (fm_get_user_team(id) != 1 && fm_get_user_team(id) != 2) return;

	new args[1];
	args[0] = id;
	if (!task_exists(id+TASK_INEV_RES))
	{
		set_task(g_InResTime, "dm_inev_res", id+TASK_INEV_RES, args, sizeof args, "b");
		client_print(id, print_center, "%L", id, "INEV_RES_MSG", g_InResTime);
	}

	if (is_user_alive(id))
		return;

	if (dm_user_tbot(id))
		dm_menu_pri_weap(id+TASK_WEAP_M);
	else
	{
		static menu[250], len;
		len = 0;

		len += formatex(menu[len], sizeof menu - 1 - len, "\y %L^n^n", id, "AGET_WEAP_MEUN1");
		len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\w %L ^n", id, "AGET_WEAP_MEUN2");
		//len += formatex(menu[len], sizeof menu - 1 - len, "\r2.\w %L^n", id, "AGET_WEAP_MEUN3");
		
		// 3.0.1 - Fixed 
		if (m_pri_weaponid[id] == 0 && m_sec_weaponid[id] == 0)
			len += formatex(menu[len], sizeof menu - 1 - len, "\r2.\w %L^n", id, "AGET_WEAP_MEUN3_N");
		else
			len += formatex(menu[len], sizeof menu - 1 - len, "\r2.\w %L^n", id, "AGET_WEAP_MEUN3");

		show_menu(id, KEYSMENU, menu, -1, "UsE WeapoN MeuN");
	}
}

public dm_weapon_meun_set(id, key)
{
	switch (key)
	{
		case 0:
			dm_menu_pri_weap(id+TASK_WEAP_M);
		case 1:	
		{
			// 3.0.1 - Fixed 
			if (m_pri_weaponid[id] == 0 && m_sec_weaponid[id] == 0)
				set_task(0.1, "dm_menu_weap", id+TASK_WEAP_M);
			else
			{
				m_chosen_pri_weap[id] = true;
				m_chosen_sec_weap[id] = true;
				remove_task(id+TASK_SPAWN);
				dm_user_spawn(id+TASK_SPAWN);
			}
		}
		default:
			set_task(0.1, "dm_menu_weap", id+TASK_WEAP_M);
	}
}

public dm_menu_pri_weap(taskid)
{
	new id = taskid - TASK_WEAP_M;

	if (fm_get_user_team(id) != 1 && fm_get_user_team(id) != 2) return;

	if (dm_user_tbot(id))
	{
		new random, weaponid;
		random = random_num(0, g_priweapon-1);
		weaponid = g_priweaponID[random];
		
		if (weaponid && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			m_pri_weaponid[id] = weaponid;
			m_chosen_pri_weap[id] = true;
		}
		else
		{
			m_pri_weaponid[id] = 0;
			m_chosen_pri_weap[id] = false;
		}

		if (g_bnweapon[0][0] != -1 || g_bnweapon[0][1] != -1 || g_bnweapon[0][2] != -1)
		{
			random = random_num(0, 3);
			if (random != 3 && g_bnweapon[0][random] != -1)
			{
				m_pri_weaponid[id] = random;
				m_chosen_pri_weap[id] = true;
			}
		}
		
		dm_menu_sec_weap(id+TASK_WEAP_M);
		
		return;
	}

	static weap_menu_name[100];
	formatex(weap_menu_name, sizeof weap_menu_name - 1, "\y %L", id, "PRI_WM_NAME");

	new menu = menu_create(weap_menu_name, "dm_pri_weap_select");
	
	new i, itemname[64], data[2], weaponid;
	for (i = 0; i < g_priweapon; i++)
	{
		weaponid = g_priweaponID[i];
		
		if (weaponid && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			format(itemname, 63, "\w %s", g_priweaponN[i]);
			data[0] = weaponid;
			data[1] = '^0';
			menu_additem(menu, itemname, data, 0, -1);
		}
	}
	
	static weap_menu_b[100], weap_menu_n[100], weap_menu_e[100];
	formatex(weap_menu_b, sizeof weap_menu_b - 1, "\y %L", id, "MENU_BACK");
	formatex(weap_menu_n, sizeof weap_menu_n - 1, "\y %L", id, "MENU_NEXT");
	formatex(weap_menu_e, sizeof weap_menu_e - 1, "\y %L", id, "MENU_EXIT");

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);

	menu_setprop(menu, MPROP_BACKNAME, weap_menu_b);
	menu_setprop(menu, MPROP_NEXTNAME, weap_menu_n);
	menu_setprop(menu, MPROP_EXITNAME, weap_menu_e);

	menu_display(id, menu, 0);
}

public dm_pri_weap_select(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		dm_menu_sec_weap(id+TASK_WEAP_M);
		return PLUGIN_HANDLED;
	}
	
	new data[2], itemname[64], access, callback, weaponid;
	menu_item_getinfo(menu, item, access, data, 5, itemname, 63, callback);
	weaponid = data[0];
	
	if (weaponid)
	{
		m_pri_weaponid[id] = weaponid;
		m_chosen_pri_weap[id] = true;
	}
	else
	{
		m_pri_weaponid[id] = 0;
		m_chosen_pri_weap[id] = false;
	}
	
	dm_menu_sec_weap(id+TASK_WEAP_M);
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public dm_menu_sec_weap(taskid)
{
	new id = taskid - TASK_WEAP_M;

	if (fm_get_user_team(id) != 1 && fm_get_user_team(id) != 2) return;
	
	if (dm_user_tbot(id))
	{
		new random, weaponid;
		random = random_num(0, g_secweapon-1);
		weaponid = g_secweaponID[random];
		
		if (weaponid && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		{
			m_sec_weaponid[id] = weaponid;
			m_chosen_sec_weap[id] = true;
		}
		else
		{
			m_sec_weaponid[id] = 0;
			m_chosen_sec_weap[id] = false;
		}

		if (g_bnweapon[1][0] != -1 || g_bnweapon[1][1] != -1 || g_bnweapon[1][2] != -1)
		{
			random = random_num(0, 3);
			if (random != 3 && g_bnweapon[1][random] != -1)
			{
				m_sec_weaponid[id] = random;
				m_chosen_sec_weap[id] = true;
			}
		}

		remove_task(id+TASK_SPAWN);
		set_task(0.1, "dm_user_spawn", id+TASK_SPAWN);
		return;
	}
	
	static weap_menu_name[100];
	formatex(weap_menu_name, sizeof weap_menu_name - 1, "\y %L", id, "SEC_WM_NAME");

	new menu = menu_create(weap_menu_name, "dm_sec_weap_select");
	
	new i, itemname[64], data[2], weaponid;
	for (i = 0; i < g_secweapon; i++)
	{
		weaponid = g_secweaponID[i];
		
		if (weaponid && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		{
			format(itemname, 63, "\w %s", g_secweaponN[i]);
			data[0] = weaponid;
			data[1] = '^0';
			menu_additem(menu, itemname, data, 0, -1);
		}
	}

	static weap_menu_e[100];
	formatex(weap_menu_e, sizeof weap_menu_e - 1, "\y %L", id, "MENU_EXIT");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);

	menu_setprop(menu, MPROP_EXITNAME, weap_menu_e);

	menu_display(id, menu, 0);
}

public dm_sec_weap_select(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		remove_task(id+TASK_SPAWN);
		dm_user_spawn(id+TASK_SPAWN);
		return PLUGIN_HANDLED;
	}

	new data[6], itemname[64], access, callback, weaponid;
	menu_item_getinfo(menu, item, access, data,5, itemname, 63, callback);
	weaponid = data[0];
	
	if (weaponid)
	{
		m_sec_weaponid[id] = weaponid;
		m_chosen_sec_weap[id] = true;
	}
	else
	{
		m_sec_weaponid[id] = 0;
		m_chosen_sec_weap[id] = false;
	}
	
	remove_task(id+TASK_SPAWN);
	dm_user_spawn(id+TASK_SPAWN);
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public dm_user_spawn(taskid)
{
	new id = taskid - TASK_SPAWN;

	new team = fm_get_user_team(id);
	if (team != 1 && team != 2) return;

	if (!is_user_alive(id))
	{
		if (!dm_game_play())
			return;
	
		ExecuteHamB(Ham_CS_RoundRespawn, id);

		if (g_PtTime != 0.0)
		{
			fm_set_user_godmode(id, 1);

			if (team == 1)
				fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 0);
			else if (team == 2)
				fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 0);

			set_task(g_PtTime, "dm_protect_over", id);
		}

		if (g_dmMode && g_ranspawn)
		{
			remove_task(id+TASK_ORIGIN_SET);
			fm_set_user_origin(id+TASK_ORIGIN_SET, g_spawns[random_num(0, g_spawnCount - 1)]);
		}
	}

	remove_task(id+TASK_INEV_RES);

	fm_strip_user_weapons(id);
	fm_give_item(id, "weapon_knife");

	set_msg_block(get_user_msgid("HideWeapon"), BLOCK_SET);
	set_msg_block(get_user_msgid("RoundTime"), BLOCK_SET);
	set_task(0.1, "event_hud_reset", id);
	m_dead_fl[id] = false;

	if (m_chosen_pri_weap[id] && m_pri_weaponid[id] != 0)
	{
		drop_weapons(id, 1);
		
		new weaponid = m_pri_weaponid[id];
		fm_give_item(id, WEAPON_CLASSNAME[weaponid]);
		
		while (fm_get_user_bpammo(id, weaponid) != MAX_BPAMMO[weaponid])
			ExecuteHamB(Ham_GiveAmmo, id, BUY_AMMO[weaponid], AMMO_TYPE[weaponid], MAX_BPAMMO[weaponid]);

		m_chosen_pri_weap[id] = false;
	}
	
	if (m_chosen_sec_weap[id] && m_sec_weaponid[id] != 0)
	{
		drop_weapons(id, 2);
		
		new weaponid = m_sec_weaponid[id];
		fm_give_item(id, WEAPON_CLASSNAME[weaponid]);

		while (fm_get_user_bpammo(id, weaponid) != MAX_BPAMMO[weaponid])
			ExecuteHamB(Ham_GiveAmmo, id, BUY_AMMO[weaponid], AMMO_TYPE[weaponid], MAX_BPAMMO[weaponid]);
		
		m_chosen_sec_weap[id] = false;
	}

	if (g_GGrenade[0]) fm_give_item(id, "weapon_hegrenade");
	if (g_GGrenade[1]) fm_give_item(id, "weapon_flashbang");
	if (g_GGrenade[2]) fm_give_item(id, "weapon_smokegrenade");

	fm_set_user_armor(id, 100);
}
// ==================

// Will Spawn... =======
public dm_inev_res(args[])
{
	new id = args[0];
	if (is_user_alive(id))
	{
		remove_task(id+TASK_INEV_RES);
		return;
	}

	remove_task(id+TASK_SPAWN);
	dm_user_spawn(id+TASK_SPAWN);
	dm_menu_weap(id+TASK_WEAP_M);
}
// ====================

// Dm Game end ==================
public dm_game_end(win_team, next_map)
{
	new sound[256]; 

	if (!g_dmMode)
	{
		if (win_team == 1)
		{
			set_hudmessage(255,0,0, -1.0, 0.75, 0, 5.0, 20.0, 2.0, 1.0, -1);
			show_hudmessage(0, "%L", LANG_PLAYER, "TR_WIN_MSG", g_Nmap_name[next_map]);
			copy(sound , charsmax(sound), "radio/terwin.wav");
		}
		else
		{
			set_hudmessage(0,0,255, -1.0, 0.75, 0, 5.0, 20.0, 2.0, 1.0, -1);
			show_hudmessage(0, "%L", LANG_PLAYER, "CT_WIN_MSG", g_Nmap_name[next_map]);
			copy(sound , charsmax(sound), "radio/ctwin.wav");
		}
	}
	else
	{
		new win_player[32];
		get_user_name(win_team, win_player, 31);
		set_hudmessage(174,120,121, -1.0, 0.75, 0, 6.0, 4.0, 1.0, 1.0, -1);
		show_hudmessage(0, "%L", LANG_PLAYER, "PL_WIN_MSG", win_player, g_Nmap_name[next_map]);

		copy(sound , charsmax(sound), "player/betmenushow.wav");
	}

	client_cmd(0, "spk ^"%s^"", sound);

	set_task(8.0, "change_map", next_map);
}

public change_map(next_map)
	server_cmd("changelevel %s", g_Nmap_name[next_map]);
// ===========================

public dm_protect_over(id)
{
	fm_set_user_godmode(id, 0);
	fm_set_rendering(id, kRenderFxNone, 0, 0, 0,kRenderNormal, 255);
}

public clcmd_buy(id)
	return PLUGIN_HANDLED;

public clcmd_changeteam(id)
{
	if (fm_get_user_team(id) == 0 || fm_get_user_team(id) == 3)
		return PLUGIN_CONTINUE;
		
	if ((get_user_flags(id) & ACCESS_FLAG)) // admin menu
	{
		dm_adminSettingMenu (id);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_HANDLED;
}

public event_hud_reset(id)
{
	message_begin(MSG_ONE, g_msgHideWeapon, _, id);
	write_byte((1<<4) | (1<<5));
	message_end();

	message_begin(MSG_ONE, g_msgCrosshair, _, id);
	write_byte(0);
	message_end();
}

public event_ShowStatus(id)
{
	if (!g_dmMode)
		return;

	static text[100], magtext[100], i;
	i = read_data(2);

	formatex(text, sizeof text - 1, "%L", id, "PDM_AIM_TEXT");
	add(text, sizeof text - 1, " : %p2 ");
	format(magtext, 99, "%s", text);

	if (is_user_alive(i) && is_user_alive(id))
	{
		message_begin(MSG_ONE,g_msgStatusText,_,id);
		write_byte(0);
		write_string(magtext);
		message_end();

		message_begin(MSG_ONE,g_magStatusValue,_,id);
		write_byte(1);
		write_short(1);
		message_end();

		message_begin(MSG_ONE,g_magStatusValue,_,id);
		write_byte(2);
		write_short(i);
		message_end();

		message_begin(MSG_ONE,g_magStatusValue,_,id);
		write_byte(3);
		write_short(fm_get_user_health(i));
		message_end();
	}
	else 
	{
		message_begin(MSG_ONE,g_msgStatusText,_,id);
		write_byte(0);
		write_string("");
		message_end();
	}
}

public event_HideStatus(id)
{
	if (g_dmMode)
	{
		message_begin(MSG_ONE,g_msgStatusText,_,id);
		write_byte(0);
		write_string("");
		message_end();
	}
}

public event_BuyZone(id)
{
	if (!dm_game_play())
		return;

	m_in_buyzone[id] = read_data(1);

	if (g_dmMode || !g_BZAddHp || !is_user_alive(id))
		return;
	
	if (m_in_buyzone[id] && !task_exists(id+TASK_ADDHP))
	{
		client_print(id, print_chat, "%L", id, "WILL_ADD_HP");

		new args[1];
		args[0] = id;
		set_task(g_BZAddHpTime, "dm_buyzone_addhp", id+TASK_ADDHP, args, sizeof args, "b");
	}
	else if (!m_in_buyzone[id] && task_exists(id+TASK_ADDHP))
	{
		client_print(id, print_chat, "%L", id, "WILL_NOT_ADD_HP");
		remove_task(id+TASK_ADDHP);
	}
}

public dm_buyzone_addhp(args[])
{
	if (!g_BZAddHp)
		return;
	
	new id = args[0];

	if (!is_user_alive(id))
	{
		remove_task(id+TASK_ADDHP);
		return;
	}
		
	new health, set_health;
	health = fm_get_user_health(id);
		
	if (m_in_buyzone[id] && health < 100)
	{
		set_health = min(health + g_BZAddHpAmounT, 100);
		fm_set_user_health(id, set_health);

		client_print(id, print_chat, "%L", id, "ADD_HP_IN_BZN", g_BZAddHpTime, set_health - health);
	}
}

public message_Money(msg_id, msg_dest, id)
{
	fm_cs_set_user_money(id, 0);

	message_begin(MSG_ONE, g_msgHideWeapon, _, id);
	write_byte((1<<5));
	message_end();
	
	return PLUGIN_HANDLED;
}

public message_AmmoX(msg_id, msg_dest, id)
{
	if (g_UnlimitAmmo == false || !is_user_alive(id))
		return PLUGIN_CONTINUE;

	if (get_msg_arg_int(1) >= sizeof AMMOID_WEAPON)
		return PLUGIN_CONTINUE;

	if ((1<<AMMOID_WEAPON[get_msg_arg_int(1)]) & NOCLIP_WEAPONS_BIT_SUM)
		return PLUGIN_CONTINUE;
	
	if (get_msg_arg_int(2) < MAX_BPAMMO[AMMOID_WEAPON[get_msg_arg_int(1)]])
		fm_set_user_bpammo(id, AMMOID_WEAPON[get_msg_arg_int(1)], MAX_BPAMMO[AMMOID_WEAPON[get_msg_arg_int(1)]]);
	
	return PLUGIN_CONTINUE;
}

public message_statusIcon(msg_id, msg_dest, id)
{
	static szMsg[8];
	get_msg_arg_string(2, szMsg, 7);
   
	if(equal(szMsg, "buyzone")) return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
} 

public message_radar(msg_id, msg_dest, id)
{
	if (!g_dmMode) return PLUGIN_CONTINUE;

	return PLUGIN_HANDLED;
}

public message_RoundTime(msg_id, msg_dest, id)
{
	return PLUGIN_HANDLED;
}

public message_HideWeapon()
	set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | (1<<4));

public message_textmsg()
{
	if (!g_dmMode)
		return PLUGIN_CONTINUE;

	static textmsg[22];
	get_msg_arg_string(2, textmsg, charsmax(textmsg));

	// Block round end related messages
	if (equal(textmsg, "#Game_teammate_attack") || equal(textmsg, "#Game_teammate_kills") ||
	equal(textmsg, "#Hint_win_round_by_killing_enemy") || equal(textmsg, "#Hint_cannot_play_because_tk") ||
	equal(textmsg, "#Hint_spotted_a_friend") || equal(textmsg, "#Hint_try_not_to_injure_teammates") ||
	equal(textmsg, "#Killed_Teammate"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public message_show_menu(msgid, dest, id)
{
	static team_select[] = "#Team_Select";
	static menu_text_code[sizeof team_select];
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1);
	if (!equal(menu_text_code, team_select))
		return PLUGIN_CONTINUE;

	set_force_team_join_task(id, msgid);

	return PLUGIN_HANDLED
}

public message_vgui_menu(msgid, dest, id)
{
	if (get_msg_arg_int(1) != 2)// || !should_autojoin(id))
		return PLUGIN_CONTINUE;

	set_force_team_join_task(id, msgid);

	return PLUGIN_HANDLED
}

public client_putinserver(id)
{
	m_player_kill[id] = 0;

	set_task(1.0, "dm_showHudMsg", id, _, _, "b");
	
	if (dm_user_tbot(id))
	{
		remove_task(id+TASK_WEAP_M);
		set_task(3.0, "dm_menu_pri_weap", id+TASK_WEAP_M);

		if (cvar_botquota && !g_hamczbots)
			set_task(0.1, "register_ham_czbots", id);
	}
}

public register_ham_czbots(id)
{
	if (!is_user_connected(id) || !get_pcvar_num(cvar_botquota) || g_hamczbots)
		return;
		
	if (is_bot_type (id) != 2)
		return;

	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled");
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage");

	g_hamczbots = true;
	
	server_print("***** [register_ham_czbots] *****")
}

set_force_team_join_task(id, menu_msgid)
{
	static param_menu_msgid[2];
	param_menu_msgid[0] = menu_msgid;
	set_task(0.1, "task_force_team_join", id, param_menu_msgid, sizeof param_menu_msgid);
}

public task_force_team_join(menu_msgid[], id)
{
	if (fm_get_user_team(id))
		return;

	dm_force_team_join(id, menu_msgid[0]);
}

stock dm_force_team_join(id, menu_msgid, team[] = "5", class[] = "5")
{
	static jointeam[] = "jointeam";
	remove_task(id+TASK_WEAP_M);
	if (class[0] == '0') {
		engclient_cmd(id, jointeam, team);
		dm_menu_pri_weap(id+TASK_WEAP_M);
		return;
	}

	static msg_block, joinclass[] = "joinclass";
	msg_block = get_msg_block(menu_msgid);
	set_msg_block(menu_msgid, BLOCK_SET);
	engclient_cmd(id, jointeam, team);
	client_cmd(id, "%s %i", joinclass, class);
	set_msg_block(menu_msgid, msg_block);
	dm_menu_pri_weap(id+TASK_WEAP_M);

	if (is_user_alive(id) && g_dmMode && g_ranspawn)
	{
		remove_task(id+TASK_ORIGIN_SET);
		fm_set_user_origin(id+TASK_ORIGIN_SET, g_spawns[random_num(0, g_spawnCount - 1)]);
	}
}

stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0);
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock is_player_stuck(id)
{
	static Float:originF[3];
	pev(id, pev_origin, originF);
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0);
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

SendDeathMsg(attacker, victim, const weapon[], hs)
{
	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(hs) // headshot flag
	write_string(weapon) // killer's weapon
	message_end()

	message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
	write_byte(attacker) // id
	write_short(pev(attacker, pev_frags)) // frags
	write_short(get_pdata_int(attacker, 444))
	write_short(0) // class?
	write_short(fm_get_user_team(attacker)) // team
	message_end()  

	message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
	write_byte(victim) // id
	write_short(pev(victim, pev_frags)) // frags
	write_short(get_pdata_int(victim, 444))
	write_short(0) // class?
	write_short(fm_get_user_team(victim)) // team
	message_end()  
}

stock fm_strip_user_weapons(index)
{
	new ent = fm_create_entity("player_weaponstrip");
	if (!pev_valid(ent))
		return 0;
	
	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);
	
	return 1;
}

stock fm_get_user_team(id)
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);

stock fm_set_user_team(id, team)
{
	set_pdata_int(id, OFFSET_CSTEAMS, team, OFFSET_LINUX)
}

stock fm_cs_set_user_money(id, value)
	set_pdata_int(id, OFFSET_CSMONEY, value, OFFSET_LINUX)

stock fm_set_user_armor(index, armor) 
{
	set_pev(index, pev_armorvalue, float(armor));
	
	return 1;
}

stock fm_get_user_health(id)
	return get_user_health(id)

stock fm_set_user_health(index, health) 
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);
	
	return 1;
}

stock fm_user_kill(index, flag = 0)
{
	if (flag)
	{
		new Float:frags;
		pev(index, pev_frags, frags);
		set_pev(index, pev_frags, ++frags);
	}
	
	dllfunc(DLLFunc_ClientKill, index);
	
	return 1;
}

stock fm_give_item(index, const item[])
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;
	
	new ent = fm_create_entity(item);
	if (!pev_valid(ent))
		return 0;
	
	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);
	
	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;
	
	engfunc(EngFunc_RemoveEntity, ent);
	
	return -1;
}

stock fm_create_entity(const classname[])
{
	return engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
}

stock drop_weapons(id, dropwhat) // dropwhat: 1 = primary weapon , 2 = secondary weapon
{
	// Get user weapons
	static weapons[32], num, i, weaponid, get_DW
	new bool:have_Pweapon = false
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)

	get_DW = dropwhat
	if (dropwhat == 0) get_DW = 1
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]

		if ((get_DW == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (get_DW == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon name
			static wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			
			// Drop weapon
			engclient_cmd(id, "drop", wname)

			have_Pweapon = true
		}
	}

	if (!have_Pweapon && dropwhat == 0) drop_weapons(id, 2)
}

stock fm_set_user_bpammo(index, weapon, amount)
{
	new offset;
	
	switch(weapon)
	{
		case CSW_AWP: offset = 377
		case CSW_SCOUT,CSW_AK47,CSW_G3SG1: offset = 378
		case CSW_M249: offset = 379
		case CSW_M4A1,CSW_FAMAS,CSW_AUG,CSW_SG550,CSW_GALI,CSW_SG552: offset = 380
		case CSW_M3,CSW_XM1014: offset = 381
		case CSW_USP,CSW_UMP45,CSW_MAC10: offset = 382
		case CSW_FIVESEVEN,CSW_P90: offset = 383
		case CSW_DEAGLE: offset = 384
		case CSW_P228: offset = 385
		case CSW_GLOCK18,CSW_MP5NAVY,CSW_TMP,CSW_ELITE: offset = 386
		case CSW_FLASHBANG: offset = 387
		case CSW_HEGRENADE: offset = 388
		case CSW_SMOKEGRENADE: offset = 389
		case CSW_C4: offset = 390

		default:
		{
			new invalidMsg[20 + 7];
			formatex(invalidMsg,20 + 6,"Invalid weapon id %d",weapon);
			set_fail_state(invalidMsg);
			
			return 0;
		}
	}
	
	set_pdata_int(index,offset,amount);
	
	return 1;
}

stock fm_get_user_bpammo(index, weapon)
{
	new offset;
	
	switch(weapon)
	{
		case CSW_AWP: offset = 377
		case CSW_SCOUT,CSW_AK47,CSW_G3SG1: offset = 378
		case CSW_M249: offset = 379
		case CSW_M4A1,CSW_FAMAS,CSW_AUG,CSW_SG550,CSW_GALI,CSW_SG552: offset = 380
		case CSW_M3,CSW_XM1014: offset = 381
		case CSW_USP,CSW_UMP45,CSW_MAC10: offset = 382
		case CSW_FIVESEVEN,CSW_P90: offset = 383
		case CSW_DEAGLE: offset = 384
		case CSW_P228: offset = 385
		case CSW_GLOCK18,CSW_MP5NAVY,CSW_TMP,CSW_ELITE: offset = 386
		case CSW_FLASHBANG: offset = 387
		case CSW_HEGRENADE: offset = 388
		case CSW_SMOKEGRENADE: offset = 389
		case CSW_C4: offset = 390
		default:
		{
			new invalidMsg[20 + 7];
			formatex(invalidMsg,20 + 6,"Invalid weapon id %d",weapon);
			set_fail_state(invalidMsg);
			
			return 0;
		}
	}
	
	return get_pdata_int(index,offset);
}

stock fm_set_user_origin(taskid, Float:origin[3])
{
	new id = taskid - TASK_ORIGIN_SET

	if (!is_hull_vacant(origin, ((pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN)))
	{
		remove_task(id+TASK_ORIGIN_SET)
		fm_set_user_origin(id+TASK_ORIGIN_SET, g_spawns[random_num(0, g_spawnCount - 1)])
		return;
	}

	engfunc(EngFunc_SetOrigin, id, origin)

	if (is_player_stuck(id))
	{
		remove_task(id+TASK_ORIGIN_SET)
		fm_set_user_origin(id+TASK_ORIGIN_SET, g_spawns[random_num(0, g_spawnCount - 1)])
	}
}

stock fm_get_user_defuse(id)
{
	if(get_pdata_int(id, OFFSET_DEFUSE_PLANT) & (1<<16) )
		return 1;

	return 0;
}

stock fm_set_user_defuse(id, defusekit = 1, r = 0, g = 160, b = 0, icon[] = "defuser", flash = 0)
{
	new defuse = get_pdata_int(id, OFFSET_DEFUSE_PLANT);

	if(defusekit)
	{
		new colour[3] = {0, 160, 0}
		if(r != -1) colour[0] = r;
		if(g != -1) colour[1] = g;
		if(b != -1) colour[2] = b;
    
    		set_pev(id, pev_body, 1);

		defuse |= (1<<16) ;
		set_pdata_int(id, OFFSET_DEFUSE_PLANT, defuse);
		
		message_begin(MSG_ONE, get_user_msgid("StatusIcon"), _, id);
		write_byte((flash == 1) ? 2 : 1);
		write_string(icon[0] ? icon : "defuser");
		write_byte(colour[0]);
		write_byte(colour[1]);
		write_byte(colour[2]);
		message_end();
	}

	else
	{
		defuse &= ~(1<<16) ;
		set_pdata_int(id, OFFSET_DEFUSE_PLANT, defuse);
		message_begin(MSG_ONE, get_user_msgid("StatusIcon"), _, id);
		write_byte(0);
		write_string("defuser");
		message_end();
		
		set_pev(id, pev_body, 0);
	}
}

stock fm_set_user_godmode(index, godmode = 0)
{
	set_pev(index, pev_takedamage, godmode == 1 ? DAMAGE_NO : DAMAGE_AIM);
	
	return 1;
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) 
{
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);
	
	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));
	
	return 1;
}

stock fm_set_user_velocity(entity, const Float:vector[3])
{
	set_pev(entity, pev_velocity, vector);

	return 1;
}

stock fm_get_user_velocity(entity, Float:vector[3])
{
	return pev(entity, pev_velocity, vector)
}

stock get_user_weapon_id(const weapon[])
{
	for (new i = 0; i < sizeof WEAPON_CLASSNAME; i++)
		if (equal(weapon, WEAPON_CLASSNAME[i])) return i;
	
	return 0;
}

stock dm_game_play()
{
	return g_dm_play;
}

stock dm_user_tbot(id)
{
	if (is_user_bot(id))
		return 1;

	return 0;
}

stock bool:has_custom_weapons(id, const bitsum)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if ((1<<weaponid) & bitsum)
			return true;
	}
	
	return false;
}

stock str_count(const str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if(str[i] == searchchar)
			count++
	}
	
	return count;
}

stock bool:str_to_bool(value[])
{
	if (equal(value, "1")) return true;

	return false;
}

stock dm_next_map()
{
	new next_map = -1; //random_num(1, g_Nmap_NU);

	while ( next_map == -1)
	{
		next_map = random_num(1, g_Nmap_NU);

		new game_map[64];
		format(game_map, charsmax(game_map), "maps/%s.bsp", g_Nmap_name[next_map]);
		if (!file_exists(game_map))
		{
		//	server_print("Have not map: %s", g_Nmap_name[next_map]);
			next_map = -1;
		}
	}

	return next_map;
}

// SyPB/PodBot/YaPB & ZBot fixed
stock is_bot_type (id)
{
        if (!is_user_bot (id))
                return 0; // not bot

        new tracker[2], friends[2], ah[2];
        get_user_info(id,"tracker",tracker,1);
        get_user_info(id,"friends",friends,1);
        get_user_info(id,"_ah",ah,1);

        if (tracker[0] == '0' && friends[0] == '0' && ah[0] == '0')
                return 1; // PodBot / YaPB / SyPB

        return 2; // Zbot
}