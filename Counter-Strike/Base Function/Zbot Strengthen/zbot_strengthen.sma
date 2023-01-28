
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

/* 18/5/2011  */

new const weapon_classname[][] = { "", "weapon_p228", "", "weapon_scout", "", "weapon_xm1014", "", "weapon_mac10",
	"weapon_aug", "", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas",
	"weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
	"weapon_tmp", "weapon_g3sg1", "", "weapon_deagle", "weapon_sg552", "weapon_ak47", "", "weapon_p90" }

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|
	(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|
	(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

const KEYSMENU = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

new g_add_godbot, g_godbot_game
new bool:g_godbot[33], bool:aim_auto[33], aim_id[33] = -1, g_miss_move[33] = -1, g_bot_weapon[33][2],
bool:g_sofood[33], g_getFood_Time[33], Float:user_punchangle[33][3], bool:g_WeapoNReloaD[33], 
bool:g_hell_bot[33], bool:g_foot_AIM[33], g_say_message[33]

new bool:c4_ingame, bool:g_c4allkn
new bool:BotHasDebug = false, cvar_botquota, cvar_difficulty

new TASK_SETAIM = 1234

public plugin_init() 
{
	register_plugin("Strengthen ZBOT", "1.0", "HsK")

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("ResetHUD", "event_NewRound", "be")
	register_event("ScreenFade", "event_ScreenFade", "be", "4=255", "5=255", "6=255", "7>199") 
	register_event("StatusValue", "event_ShowStatus", "be", "1=2", "2!0")
	register_event("CurWeapon","event_CurWeapon", "be", "1=1")

	register_forward(FM_PlayerPreThink,"fw_PlayerPreThink")

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	for (new i = 0; i < sizeof weapon_classname; i++)
	{
		if (strlen(weapon_classname[i]) == 0) continue;
		
		RegisterHam(Ham_Weapon_PrimaryAttack, weapon_classname[i], "fw_WeapPriAttack")
		RegisterHam(Ham_Weapon_PrimaryAttack, weapon_classname[i], "fw_WeapPriAttack_Post", 1)

		RegisterHam(Ham_Item_PostFrame, weapon_classname[i], "fw_backReload", 1)
		RegisterHam(Ham_Weapon_Reload, weapon_classname[i], "fw_backReload", 1)
	}

	register_clcmd("/god_bot", "meun_set_godbot")
	register_clcmd("say /bot", "say_bot")
	register_clcmd("say", "add_godbot")
	register_concmd("bot_add_god", "add_godbot_con", ADMIN_USER, "< flag # 0-32 > - Set God Bot.")

	register_menu("Zbot Menu 1", KEYSMENU, "zbot_menu1")
	register_menu("Zbot Menu LV", KEYSMENU, "zbot_menu_lv")
	register_menu("Zbot Menu MoD", KEYSMENU, "zbot_menu_mod")
	register_menu("Zbot Menu AoK", KEYSMENU, "zbot_menu_aok")

	cvar_botquota = get_cvar_pointer("bot_quota")
	cvar_difficulty = get_cvar_pointer("bot_difficulty")

	g_add_godbot = 0
	g_godbot_game = false

	if (get_pcvar_num(cvar_difficulty) >= 3 && !g_godbot_game)
		server_cmd("bot_difficulty 2")

	server_cmd("bot_profile_db BotProfile.db")
}

public say_bot(id)
{
	if (get_user_flags(id) & ADMIN_BAN) set_bot_menu(id)
	else client_print(id, print_chat, "你沒有權限")

	return PLUGIN_HANDLED;
}

public set_bot_menu(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN)) return;

	static menu[250], len
	len = 0

	len += formatex(menu[len], sizeof menu -1 - len, "\y ZBOT 選單^n^n")

	len += formatex(menu[len], sizeof menu -1 - len, "\r1.\w ZBOT等級^n")

	len += formatex(menu[len], sizeof menu -1 - len, "\r2.\w ZBOT模式^n")

	len += formatex(menu[len], sizeof menu -1 - len, "\r3.\w 加入/減小 ZBOT^n^n")

	len += formatex(menu[len], sizeof menu -1 - len, "\r5.\w 加入 GoD-ZBOT^n^n^n")

	len += formatex(menu[len], sizeof menu -1 - len, "\r0.\w 離開")

	show_menu(id, KEYSMENU, menu, -1, "Zbot Menu 1")
}

public zbot_menu1(id, key)
{
	switch (key)
	{
		case 0: set_bot_level(id)
		case 1: set_bot_mod(id)
		case 2: add_kick_bot(id)
		case 4: godbot_addmenu(id)
		case 9: return;
		default: set_bot_menu(id)
	}
}

public set_bot_level(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN)) return;

	static menu[250], len
	len = 0

	len += formatex(menu[len], sizeof menu -1 - len, "\y ZBOT 等級選單^n^n")

	len += formatex(menu[len], sizeof menu -1 - len, "\r1.\w 等級:新手級^n")
	len += formatex(menu[len], sizeof menu -1 - len, "\r2.\w 等級:入門級^n")
	len += formatex(menu[len], sizeof menu -1 - len, "\r3.\w 等級:進階級^n")

	len += formatex(menu[len], sizeof menu -1 - len, "^n^n^n^n^n\r9.\w 上一頁^n")
	len += formatex(menu[len], sizeof menu -1 - len, "\r0.\w 離開")

	show_menu(id, KEYSMENU, menu, -1, "Zbot Menu LV")
}

public zbot_menu_lv(id, key)
{
	switch (key)
	{
		case 0: server_cmd("bot_difficulty 0")
		case 1: server_cmd("bot_difficulty 1")
		case 2: server_cmd("bot_difficulty 2")
		case 8: set_bot_menu(id)
		case 9: return;
		default: set_bot_level(id)
	}

	if (key == 1 || key == 2 || key == 3 || key == 0) client_print(id, print_chat, "[ZboT] 已設定 zbot等級")
}

public set_bot_mod(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN)) return;

	static menu[250], len
	len = 0

	len += formatex(menu[len], sizeof menu -1 - len, "\y ZBOT 模式選單^n^n")

	len += formatex(menu[len], sizeof menu -1 - len, "\r1.\w 模式:小刀^n")
	len += formatex(menu[len], sizeof menu -1 - len, "\r2.\w 模式:手槍^n")
	len += formatex(menu[len], sizeof menu -1 - len, "\r3.\w 模式:狙擊槍^n")
	len += formatex(menu[len], sizeof menu -1 - len, "\r4.\w 模式:所有武器^n")

	len += formatex(menu[len], sizeof menu -1 - len, "^n^n^n^n^n\r9.\w 上一頁^n")
	len += formatex(menu[len], sizeof menu -1 - len, "\r0.\w 離開")

	show_menu(id, KEYSMENU, menu, -1, "Zbot Menu MoD")
}

public zbot_menu_mod(id, key)
{
	switch (key)
	{
		case 0: server_cmd("bot_knives_only")
		case 1: server_cmd("bot_pistols_only")
		case 2: server_cmd("bot_snipers_only")
		case 3: server_cmd("bot_all_weapons")
		case 8: set_bot_menu(id)
		case 9: return;
		default: set_bot_mod(id)
	}

	if (key == 1 || key == 2 || key == 3 || key == 0) client_print(id, print_chat, "[ZboT] 已設定 zbot模式")
}

public add_kick_bot(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN)) return;

	static menu[250], len
	len = 0

	len += formatex(menu[len], sizeof menu -1 - len, "\y 加入/減小 ZBOT 選單^n^n")

	len += formatex(menu[len], sizeof menu -1 - len, "\r1.\w 加入 ZBOT [一名]^n")
	len += formatex(menu[len], sizeof menu -1 - len, "\r2.\w 加入 CT ZBOT [一名]^n")
	len += formatex(menu[len], sizeof menu -1 - len, "\r3.\w 加入 T ZBOT [一名]^n")

	len += formatex(menu[len], sizeof menu -1 - len, "^n\r5.\w 踢出 ZBOT [一名]^n")
	len += formatex(menu[len], sizeof menu -1 - len, "\r6.\w 踢出 ZBOT [全部]^n")

	len += formatex(menu[len], sizeof menu -1 - len, "^n^n^n\r9.\w 上一頁^n")
	len += formatex(menu[len], sizeof menu -1 - len, "\r0.\w 離開")

	show_menu(id, KEYSMENU, menu, -1, "Zbot Menu AoK")
}

public zbot_menu_aok(id, key)
{
	switch (key)
	{
		case 0: server_cmd("bot_add")
		case 1: server_cmd("bot_add_ct")
		case 2: server_cmd("bot_add_t")
		case 4:
		{
			new bot_nnu = 0
			for (new i = 1; i <= 32; i++)
			{
				if (!is_user_connected(i)) continue;
				if (is_user_bot(i)) bot_nnu += 1
			}
			bot_nnu -= 1

			if (bot_nnu > 0) server_cmd("bot_quota %d", bot_nnu)
			else server_cmd("bot_kick all")
		}
		case 5: server_cmd("bot_kick all")
		case 8: set_bot_menu(id)
		case 9: return;
		default: add_kick_bot(id)
	}

	if (key == 1 || key == 2 || key == 4 || key == 0 || key == 5) add_kick_bot(id)
}

public godbot_addmenu(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN)) return;

	client_cmd(id,"messagemode /god_bot")
}

public meun_set_godbot(id)
{
	if (!(get_user_flags(id) & ADMIN_BAN)) return;

	new saytext[96]
	read_args(saytext, 95)
	remove_quotes(saytext)

	if (saytext[0])
	{
		new arg[32]
		parse(saytext, arg, 31)

		server_cmd("bot_add_god %s", arg)
	}
}

public add_godbot()
{
	new saytext[96]
	read_args(saytext, 95)
	remove_quotes(saytext)

	if (saytext[0])
	{
		new arg[32], arg2[32]
		parse(saytext, arg, 31, arg2, 31)

		if (equali(arg, "/bot_add_god") || equali(arg, "bot_add_god") || 
		equali(arg, "/BOT_ADD_GOD") || equali(arg, "BOT_ADD_GOD"))
			server_cmd("bot_add_god %s", arg2)
	}
}

public add_godbot_con(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	static arg[32]
	read_argv(1, arg, sizeof arg - 1)
	
	new i = str_to_num(arg[0])

	if (i == 0) add_gotbot(-1, 0)
	else add_gotbot(i, 1)

	server_print("^"bot_add_god^" changed to ^"%d^"", i)

	return PLUGIN_HANDLED;
}

public add_gotbot(bot, newadd)
{
	if (newadd)
	{
		server_cmd("bot_prefix")
		server_cmd("bot_quota 0")
		server_cmd("bot_chatter normal")
		g_godbot_game = true
		g_add_godbot = bot
		server_cmd("bot_difficulty 3")
		server_cmd("bot_allow_rogues 1")
		server_cmd("bot_allow_shield 0")
	}

	if (bot == -1)
	{
		server_cmd("bot_quota 0")
		g_godbot_game = false

		if (get_pcvar_num(cvar_difficulty) >= 3 && !g_godbot_game)
			server_cmd("bot_difficulty 2")
	}
	if (bot > 0) set_task(0.3, "add_bot_now")
}

public add_bot_now() if (g_add_godbot > 0 && g_godbot_game) server_cmd("bot_add")

public get_godbot(id)
{
	if (!is_user_bot(id)) return;

	if (get_pcvar_num(cvar_difficulty) != 3)
		return;

	new name[32]

	g_godbot[id] = true;

	if (g_godbot_game)
	{
		if (!g_godbot[id])
		{
			server_cmd("kick %s", name)
			return;
		}

		g_add_godbot -= 1
		add_gotbot(g_add_godbot, 0)
	}

	if (g_godbot[id])
	{
		g_WeapoNReloaD[id] = true
	}
}

public event_round_start() 
{
	c4_ingame = false
	g_c4allkn = false
	set_task(1.0, "bot_set")
	if (get_pcvar_num(cvar_difficulty) >= 3 && !g_godbot_game)
	{
		server_cmd("bot_difficulty 2")
	}
}

public event_NewRound(id)
{
	g_sofood[id] = false
	off_autoaiM(id)
	c4_ingame = false
	g_c4allkn = false
}

public event_ScreenFade(id)
{
	if (g_godbot[id])
	{
		off_autoaiM(id)

		if (g_say_message[id] == 0)
		{
			g_say_message[id] = 100
			set_task(random_float(0.3, 1.4), "bot_say_print", id)
		}
	}
}

public event_ShowStatus(id)
{
	new enemy = read_data(2)

	if (g_godbot[enemy] && !aim_auto[enemy] && is_user_alive(enemy) && get_user_team(enemy) != get_user_team(id))
	{
		aim_auto[enemy] = true
		aim_id[enemy] = id
		g_miss_move[enemy] = 1
		g_WeapoNReloaD[enemy] = false
		set_task(random_float(1.1, 2.8), "off_autoaiM", enemy)
	}
}

public event_CurWeapon(id)
{
	new weap_id, weap_clip, weap_bpammo
	weap_id = get_user_weapon(id, weap_clip, weap_bpammo)

	switch (weap_id)
	{
		case CSW_P228, CSW_ELITE, CSW_FIVESEVEN, CSW_USP, CSW_DEAGLE, CSW_GLOCK18, CSW_SCOUT, CSW_M3: 
		{
			if (weap_clip == 0 && weap_bpammo >= 7) g_WeapoNReloaD[id] = true
		}
	}

	return PLUGIN_CONTINUE;
}

public bot_set()
{
	for (new id = 1; id <= 32; id++)
	{
		if (!is_user_connected(id) || !is_user_alive(id))
			continue;

		if (!g_godbot[id])
			continue;

		g_foot_AIM[id] = false
		g_hell_bot[id] = false
		g_WeapoNReloaD[id] = true

		set_pev(id, pev_armorvalue, float(100));
		if (get_user_team(id) == 2)
		{
			fm_set_user_defuse(id)
			fm_set_user_money(id, fm_get_user_money(id) - 200)
		}
		new a = random_num(0, 6)
		if (a == 4)
		{
			g_hell_bot[id] = true

			if (g_say_message[id] == 0)
			{
				g_say_message[id] = 200
				set_task(random_float(0.2, 3.7), "bot_say_print", id)
			}
		}
	}
}

public client_command(id)
{
	if (!g_godbot[id])
		return PLUGIN_CONTINUE 

	new arg[13]
	if (read_argv(0, arg, 12) > 11)
		return PLUGIN_CONTINUE 

	new a = 0 
	do
	{
		if (equali("shield", arg)) return PLUGIN_HANDLED 
	} while(++a < 34)
	
	return PLUGIN_CONTINUE 
} 

public bomb_planted() c4_ingame = true
public bomb_defused()
{
	c4_ingame = false
	g_c4allkn = false

	for (new id = 1; id <= 32; id++)
	{
		if (!is_user_connected(id) || !is_user_alive(id) || !g_godbot[id])
			continue;

		g_WeapoNReloaD[id] = true

		if (g_bot_weapon[id][0] != 0)
		{
			fm_give_item(id, weapon_classname[g_bot_weapon[id][0]])
			g_bot_weapon[id][0] = 0
		}
		if (g_bot_weapon[id][1] != 0)
		{
			fm_give_item(id, weapon_classname[g_bot_weapon[id][1]])
			g_bot_weapon[id][1] = 0
		}
	}
}
public bomb_explode() c4_ingame = false

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
	{
		if (g_sofood[id]) g_sofood[id] = false
		if (aim_auto[id]) off_autoaiM(id)
		return FMRES_IGNORED;
	}

	new Float:maxspeed, speed
	maxspeed = fm_get_user_maxspeed(id)
	speed = fm_get_speed(id)

	if ((maxspeed/1.5) >= float(speed)) g_sofood[id] = false
	else g_sofood[id] = true

	if (!g_godbot[id])
	{
		if (aim_auto[id]) off_autoaiM(id)
		return FMRES_IGNORED;
	}

	if (!is_user_bot(id) && g_godbot[id]) g_godbot[id] = false

	if (get_user_team(id) == 2) fm_set_user_defuse(id)

	new weap_id = get_user_weapon(id)
	if (weap_id == CSW_HEGRENADE || weap_id == CSW_HEGRENADE || weap_id == CSW_SMOKEGRENADE)
	{
		engclient_cmd(id, "weapon_knife")
		return FMRES_IGNORED;
	}

	if (g_c4allkn)
	{
		if (has_custom_weapons(id, PRIMARY_WEAPONS_BIT_SUM) || has_custom_weapons(id, SECONDARY_WEAPONS_BIT_SUM))
		{
			g_bot_weapon[id][0] = get_user_weaponid(id, PRIMARY_WEAPONS_BIT_SUM)
			g_bot_weapon[id][1] = get_user_weaponid(id, SECONDARY_WEAPONS_BIT_SUM)

			fm_strip_user_weapons(id)
			fm_give_item(id, "weapon_knife")
		}
		engclient_cmd(id, "weapon_knife")
		g_WeapoNReloaD[id] = false
		return FMRES_IGNORED;
	}

	if (aim_auto[id])
	{
		if (!is_user_alive(aim_id[id]))
		{
			off_autoaiM(id)
			return FMRES_IGNORED;
		}
		if (g_getFood_Time[id] != 0) g_getFood_Time[id] = 0

		remove_task(id+TASK_SETAIM)
		set_aim(id+TASK_SETAIM, aim_id[id])
		if (g_miss_move[id]) bot_move(id, g_miss_move[id])

		return FMRES_IGNORED;
	}

	static enemy, body
	get_user_aiming(id, enemy, body);

	if ((1 <= enemy <= 32) && is_user_alive(enemy) && get_user_team(enemy) != get_user_team(id))
	{
		aim_auto[id] = true
		aim_id[id] = enemy
		g_miss_move[id] = 1
		g_WeapoNReloaD[id] = false
		set_task(1.2, "off_autoaiM", id)
		return FMRES_IGNORED;
	}

	if (g_miss_move[id]) g_miss_move[id] = -1

	new TTA = random_num(0, 60)
	if (TTA != 15)
		return FMRES_IGNORED;

	if (g_getFood_Time[id] == 0)
	{
		g_getFood_Time[id] = 1
		set_task(random_float(2.7, 3.7), "Can_GET_FooD", id)
		return FMRES_IGNORED;
	}

	if (g_getFood_Time[id] != 2)
		return FMRES_IGNORED;

	for (new i = 1; i <= 32; i++)
	{
		if (i == id || get_user_team(id) == get_user_team(i) || !g_sofood[i])
			continue;
		
		if (!get_user_distance(id, i))
			continue;

		aim_auto[id] = true
		aim_id[id] = i
		g_miss_move[id] = 1
		g_foot_AIM[id] = true
		g_WeapoNReloaD[id] = false
		set_task(random_float(1.1, 2.8), "off_autoaiM", id)

		if (g_say_message[id] == 0)
		{
			g_say_message[id] = 400
			set_task(random_float(1.2, 3.0), "bot_say_print", id)
		}

		break;
	}

	g_getFood_Time[id] = 3
	set_task(random_float(2.2, 3.4), "cannot_get_food", id)

	return FMRES_IGNORED;
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	new kill_team = get_user_team(victim), id, now_teamT = 0, now_teamCT = 0
	for (id = 1; id <= 32; id++)
	{
		if (!is_user_connected(id) || !is_user_alive(id))
			continue;

		if (get_user_team(id) == 1 && kill_team == 1)
			now_teamT += 1
		if (get_user_team(id) == 2 && kill_team == 2)
			now_teamCT += 1
	}

	if (now_teamCT == 1 || now_teamT == 1)
	{
		new set_team = 0
		if (now_teamCT == 1)  set_team = 2
		if (now_teamT == 1) set_team = 1
		for (id = 1; id <= 32; id++)
		{
			if (!is_user_connected(id) || !is_user_alive(id) || !g_godbot[id])
				continue;

			if (set_team == 1 && get_user_team(id) == 1 || set_team == 2 && get_user_team(id) == 2)
			{
				g_hell_bot[id] = true

				if (g_say_message[id] == 0)
				{
					g_say_message[id] = 205
					set_task(random_float(0.7, 2.7), "bot_say_print", id)
				}

				break;
			}
		}
	}

	if (!g_godbot[attacker])
		return HAM_IGNORED;

	if (kill_team == 1 && c4_ingame)
	{
		now_teamT = 0
		for (id = 1; id <= 32; id++)
		{
			if (!is_user_connected(id) || !is_user_alive(id) || get_user_team(id) != 1)
				continue;

			now_teamT += 1
			break;
		}
		if (now_teamT == 0)
		{
			g_c4allkn = true

			if (g_say_message[attacker] == 0)
			{
				g_say_message[attacker] = 300
				set_task(random_float(1.2, 1.7), "bot_say_print", attacker)
			}
		}
	}

	return HAM_IGNORED;
}

public fw_TakeDamage_Post(victim)
{
	if (!g_godbot[victim])
		return;

	set_pdata_float(victim, 108, 1.0, 5)
}

public fw_TouchWeapon(weapon, id)
{
	if (!g_c4allkn)
		return HAM_IGNORED;

	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (g_godbot[id])
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker)
		return HAM_IGNORED;

	if (g_godbot[victim])
	{
		if (get_user_team(victim) == get_user_team(attacker))
		{
			if (g_say_message[victim]==0)
			{
				g_say_message[victim] = 500
				set_task(random_float(0.3, 2.4), "bot_say_print", victim)
			}
			return HAM_IGNORED;
		}

		if (!aim_auto[victim])
		{
			aim_auto[victim] = true
			aim_id[victim] = attacker
			set_task(random_float(1.1, 2.8), "off_autoaiM", victim)
		}

		return HAM_IGNORED;
	}

	if (!g_godbot[attacker])
		return HAM_IGNORED;

	if (get_user_team(victim) == get_user_team(attacker) && g_say_message[attacker]==0)
	{
		g_say_message[attacker] = 505
		set_task(random_float(0.3, 2.4), "bot_say_print", attacker)
	}

	new getiHitgroup = get_tr2(tracehandle, TR_iHitgroup)

	if (getiHitgroup != 1)
	{
		if (victim == aim_id[attacker])
		{
			remove_task(attacker+TASK_SETAIM)
			set_aim(attacker+TASK_SETAIM, aim_id[attacker])
		}

		if (getiHitgroup != 6 && getiHitgroup != 7)
		{
			new HS_Attack
			if (g_foot_AIM[attacker] || g_hell_bot[attacker])
				HS_Attack = 1
			else
			{
				if (!get_user_distance(attacker, victim))
					HS_Attack = 1
				else
					HS_Attack = random_num(0, 2)
			}

			if (!aim_auto[attacker]) HS_Attack = 1

			switch (get_user_weapon(attacker))
			{
				case CSW_P228, CSW_ELITE, CSW_FIVESEVEN, CSW_USP, CSW_DEAGLE, CSW_GLOCK18: 
					HS_Attack = 1
			}

			if (g_miss_move[attacker] == 4 || g_miss_move[attacker] == 7 || g_miss_move[attacker] == 11) HS_Attack = 1;

			if (victim != aim_id[attacker]) HS_Attack = 1;

			if (HS_Attack == 1) set_tr2(tracehandle, TR_iHitgroup, 1)
		}
	}
	return HAM_IGNORED;
}

public fw_WeapPriAttack_Post(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	static owner, Float:multiplier
	owner = pev(weapon, pev_owner)
	
	if (!g_godbot[owner])
		return HAM_IGNORED;

	if (aim_auto[owner])
	{
		set_aim(owner+TASK_SETAIM, aim_id[owner])
		set_button_qe(owner)
	}

	multiplier = 0.0
	
	new Float:punchangle[3]
	pev(owner, pev_punchangle, punchangle)

	punchangle[0] -= user_punchangle[owner][0]
	punchangle[1] -= user_punchangle[owner][1]
	punchangle[2] -= user_punchangle[owner][2]

	punchangle[0] *= multiplier
	punchangle[1] *= multiplier
	punchangle[2] *= multiplier

	punchangle[0] += user_punchangle[owner][0]
	punchangle[1] += user_punchangle[owner][1]
	punchangle[2] += user_punchangle[owner][2]

	set_pev(owner, pev_punchangle, punchangle)
	
	return HAM_IGNORED;
}

public fw_backReload(iEnt)
{
	if (!pev_valid(iEnt))
		return HAM_IGNORED;

	static id
	id = fm_get_ent_owner(iEnt)

	if (!g_godbot[id])
		return HAM_IGNORED;

	static weap_id, weap_reload1, weap_reload2

	weap_id = fm_get_weaponid(iEnt)
	weap_reload1 = get_weapon_in_reload(iEnt)
	weap_reload2 = get_weapon_in_special_reload(iEnt)
	if (!weap_reload1 && !weap_reload2)
		return HAM_IGNORED;

	if (g_WeapoNReloaD[id])
		return HAM_IGNORED;

	set_weapon_in_reload(iEnt, 0)
	set_weapon_in_special_reload(iEnt, 0)
	set_weapon_idle_time(iEnt, 0.01)
	set_pev(id, pev_frame, 200.0)

	if (weap_id == CSW_USP && !fm_get_weapon_silen(id)) SendWeaponAnim(id, 8)
	else if (weap_id == CSW_M4A1 && !fm_get_weapon_silen(id)) SendWeaponAnim(id, 7)
	else SendWeaponAnim(id, 0)

	return HAM_IGNORED;
}

public bot_move(id, move)
{
	if (!aim_auto[id] || !g_godbot[id] || g_miss_move[id] == 12)
		return;

	g_miss_move[id] += 1

	new g_auto_atT = 1
	switch(get_user_weapon(id))
	{
		case CSW_AWP, CSW_P228, CSW_ELITE, CSW_FIVESEVEN, CSW_USP, CSW_DEAGLE, CSW_GLOCK18, CSW_SCOUT, CSW_M3: 
			g_auto_atT = 0
	}
	if (g_auto_atT != 0) set_pev(id, pev_button, (pev(id, pev_button) | IN_ATTACK))

	set_button_qe(id)
}

public off_autoaiM(id)
{
	aim_auto[id] = false
	aim_id[id] = -1
	g_miss_move[id] = -1
	if (!g_WeapoNReloaD[id]) set_task(random_float(2.6, 3.2), "Can_WeapoNReloaD", id)
	g_foot_AIM[id] = false
	g_getFood_Time[id] = 0
}

public Can_GET_FooD(id)
{
	if (g_getFood_Time[id] == 1) g_getFood_Time[id] = 2
}

public cannot_get_food(id) g_getFood_Time[id] = 0

public Can_WeapoNReloaD(id) g_WeapoNReloaD[id] = true
 
public set_aim(taskid, aim_id)
{
	new id = taskid - TASK_SETAIM

	if (!g_godbot[id])
	 return;

	static Float:origin[3], Float:angles[3], players[32], num

	pev(id,pev_origin,origin)

	if (!get_user_distance(id, aim_id))
		return

	get_players_distance(id, origin,players,num,"a")

	engfunc(EngFunc_GetBonePosition,id,8,origin,angles)

	get_players_distance(id, origin,players,num,"aij")

	engfunc(EngFunc_GetBonePosition,aim_id,8,origin,angles)

	entity_set_aim(id,origin,8)
}

public bot_say_print(id)
{
	if (g_say_message[id] == 0)
		return;

	new name[32], IDteam = get_user_team(id)-1
	get_user_name(id, name, charsmax(name))

	if (g_say_message[id] == 300)
	{
		send_client_print(-2, "^x3%s^x1 : OH.YA!! GO Defused C4444!!!", name)
		g_say_message[id] = 0
		return;
	}

	for (new team = 1; team <= 32; team++) if (get_user_team(id) == get_user_team(team))
	switch (g_say_message[id]+is_user_alive(id))
	{
		case 101: send_client_print(team, "^x3(%s) %s^x1 : oh.no!!! My Screen Fade...help!!", IDteam ? "CT" : "TR" ,name)
		case 201: send_client_print(team, "^x3(%s) %s^x1 : This round i will Seriously!! \./!", IDteam ? "CT" : "TR" ,name)
		case 206: send_client_print(team, "^x3(%s) %s^x1 : Now i will seriously!! we will win", IDteam ? "CT" : "TR" ,name)
		case 401: send_client_print(team, "^x3(%s) %s^x1 : Have People!!", IDteam ? "CT" : "TR" ,name)
		case 500: send_client_print(team, "^x3(%s) %s^x1 : .... you kill me-.-?", IDteam ? "CT" : "TR" ,name)
		case 501: send_client_print(team, "^x3(%s) %s^x1 : why you damage me!?", IDteam ? "CT" : "TR" ,name)
		case 506: send_client_print(team, "^x3(%s) %s^x1 : Sorry..I careless damage you...><'", IDteam ? "CT" : "TR" ,name)
	}
	g_say_message[id] = 0
}

public fw_WeapPriAttack(weapon)
{
	if (!pev_valid(weapon) || !g_godbot[pev(weapon, pev_owner)])
		return HAM_IGNORED;

	pev(pev(weapon, pev_owner), pev_punchangle, user_punchangle[pev(weapon, pev_owner)])
	
	return HAM_IGNORED;
}

set_button_qe(id)
{
	new move_lrlr = random_num(1, 2), move_fbfb = random_num(1, 6)
	if (move_lrlr == 1) set_pev(id, pev_button, (pev(id, pev_button) | IN_MOVERIGHT))
	else set_pev(id, pev_button, (pev(id, pev_button) | IN_MOVELEFT))

	if (move_fbfb == 2) set_pev(id, pev_button, (pev(id, pev_button) | IN_JUMP))
	else if (move_fbfb == 3) set_pev(id, pev_button, (pev(id, pev_button) | IN_DUCK))
}

public client_putinserver(id)
{
	g_godbot[id] = false
	g_hell_bot[id] = false
	g_say_message[id] = 0
	g_getFood_Time[id] = 0

	if (!is_user_bot(id) || !cvar_botquota) return;

	get_godbot(id)

	if (BotHasDebug) return;

	new classname[32]
	pev(id, pev_classname, classname, 31)
	
	if (!equal(classname, "player")) set_task(0.1, "_Debug", id)
}

public _Debug(id)
{
	if (!get_pcvar_num(cvar_botquota) || !is_user_connected(id))
		return;
	
	BotHasDebug = true
	
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled")
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage_Post", 1)
}

stock get_players_distance(id, const Float:origin2[3],players[32], &num,const flags[]="")
{
	if (g_godbot[id]) return 0;

	new bool:flag1, bool:flag2, num2, bool:continuea=true
	static Float:origin[3], players2[32], Float:hit[3]

	if(containi(flags,"j")!=-1) flag2 = true
	if(containi(flags,"i")!=-1)
	{
		if(!pev_valid(0)) return 0;
		flag1 = true
	}

	origin[0] = origin2[0]
	origin[1] = origin2[1]
	origin[2] = origin2[2]

	arrayset(players2,0,32)
	get_players(players2,num2,flags,"")
	static Float:origin3[3]
	static Float:distance[32]
	for(new i=0;i<32;i++) distance[i]=0.0
	num = num2

	for(new i=0;i<num2;i++)
	{
		pev(players2[i],pev_origin,origin3)
		if(flag2)
		{
			engfunc(EngFunc_TraceLine,origin2,origin3,1,0,0)
			get_tr2(0,TR_vecEndPos,hit)
			if(hit[0]==origin3[0] && hit[1]==origin3[1] && hit[2]==origin3[2])
				distance[i] = vector_distance(origin,origin3)
			else
			{
				continuea=false
				distance[i] = 9999999.1337
				num--
			}
		}
		if(flag1 && continuea)
		{
			static Float:angles[3], Float:diff[3], Float:reciprocalsq, Float:norm[3], Float:dot, Float:fov
			pev(0, pev_angles, angles)
			engfunc(EngFunc_MakeVectors, angles)
			global_get(glb_v_forward, angles)
			angles[2] = 0.0

			pev(0, pev_origin, origin)
			diff[0] = origin3[0] - origin[0]
			diff[1] = origin3[1] - origin[1]
			diff[2] = origin3[2] - origin[2]

			reciprocalsq = 1.0 / floatsqroot(diff[0]*diff[0] + diff[1]*diff[1] + diff[2]*diff[2])
			norm[0] = diff[0] * reciprocalsq
			norm[1] = diff[1] * reciprocalsq
			norm[2] = diff[2] * reciprocalsq

			dot = norm[0]*angles[0] + norm[1]*angles[1] + norm[2]*angles[2]
			pev(0, pev_fov, fov)
			if(dot >= floatcos(fov * 3.1415926535 / 360.0))
				distance[i] = vector_distance(origin,origin3)
			else
			{
				continuea=false
				distance[i] = 9999999.1337
				num--
			}
		}
		if(continuea) distance[i] = vector_distance(origin,origin3)
	}
	static distance_cnt[32]
	arrayset(distance_cnt,0,32)
	for(new i=0;i<num2;i++)
	{
		if(distance[i]!=9999999.1337)
		{
			for(new i2=0;i2<num;i2++)
				if(distance[i2]<distance[i]) distance_cnt[i]++
			players[distance_cnt[i]]=players2[i]
		}
	}
	return 1;
}

stock entity_set_aim(ent,const Float:origin2[3],bone=0)
{
	if(!g_godbot[ent]) return 0;

	static Float:origin[3], Float:ent_origin[3], Float:angles[3], Float:v_length, Float:aim_vector[3], Float:new_angles[3]

	origin[0] = origin2[0]
	origin[1] = origin2[1]
	origin[2] = origin2[2]

	engfunc(EngFunc_GetBonePosition,ent,bone,ent_origin,angles)

	origin[0] -= ent_origin[0]
	origin[1] -= ent_origin[1]
	origin[2] -= ent_origin[2]

	v_length = vector_length(origin)

	aim_vector[0] = origin[0] / v_length
	aim_vector[1] = origin[1] / v_length
	aim_vector[2] = origin[2] / v_length

	vector_to_angle(aim_vector,new_angles)

	new_angles[0] *= -1

	if(new_angles[1]>180.0) new_angles[1] -= 360

	if(new_angles[1]<-180.0) new_angles[1] += 360

	if(new_angles[1]==180.0 || new_angles[1]==-180.0) new_angles[1]=-179.999999

	set_pev(ent,pev_angles,new_angles)
	set_pev(ent,pev_fixangle,1)

	return 1;
}

send_client_print(target, const message[], any:...)
{
	static buffer[512]
	vformat(buffer, charsmax(buffer), message, 3)

	if (target <= 0)
	{
		new team_id
		if (target != 0)
		{
			for (new i = 1; i <= 32; i++)
			{
				if (target == -1 && get_user_team(i) == 1) {team_id=i;break;}
				if (target == -2 && get_user_team(i) == 2) {team_id=i;break;}
				if (target == -3) {team_id=33;break;}
			}
		}

		for (new i = 1; i <= 32; i++)
		{
			if (is_user_connected(i) && !is_user_bot(i))
			{
				message_begin(MSG_ONE, get_user_msgid("SayText"), _, i)
				if (target == 0) write_byte(i)
				else write_byte(team_id)
				write_string(buffer)
				message_end()
			}
		}
		return;
	}

	message_begin(MSG_ONE, get_user_msgid("SayText"), _, target)
	write_byte(target)
	write_string(buffer)
	message_end()
}

stock Float:fm_get_user_maxspeed(index) {
	new Float:speed;
	pev(index, pev_maxspeed, speed);

	return speed;
}

stock fm_get_speed(entity) {
	new Float:Vel[3];
	pev(entity, pev_velocity, Vel);

	return floatround(vector_length(Vel));
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

stock get_user_weaponid(id, const bitsum)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if ((1<<weaponid) & bitsum)
			return weaponid;
	}
	
	return false;
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

stock fm_create_entity(const classname[])
{
	return engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
}

stock fm_get_ent_owner(entity)
{
	return get_pdata_cbase(entity, 41,4);
}

stock Float:get_weapon_idle_time(entity)
{
	return get_pdata_float(entity, 48, 4)
}

stock set_weapon_idle_time(entity, Float:time)
{
	set_pdata_float(entity, 48, time, 4)
}

stock get_weapon_in_reload(entity)
{
	return get_pdata_int(entity, 54, 4);
}

stock get_weapon_in_special_reload(entity)
{
	return get_pdata_int(entity, 55, 4)
}

stock set_weapon_in_special_reload(entity, special_reload_flag)
{
	set_pdata_int(entity, 55, special_reload_flag, 4)
}

stock set_weapon_in_reload(entity, reload_flag)
{
	set_pdata_int(entity, 54, reload_flag, 4);
}

stock fm_get_weaponid(entity)
{
	return get_pdata_int(entity, 43, 4);
}

stock SendWeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(iAnim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock fm_get_weapon_silen(index)
{
	new silencemode = get_pdata_int(index, 74, 4), weapon = get_pdata_int(index, 43, 4);

	if (weapon == CSW_USP)
		if(silencemode & (1<<0)) return 1;
	if (weapon == CSW_M4A1)
		if(silencemode & (1<<2)) return 1;

	return 0;
}

stock fm_set_user_defuse(id)
{
	new defuse = get_pdata_int(id, 193);
	new colour[3] = {0, 160, 0}

    	set_pev(id, pev_body, 1);

	defuse |= (1<<16)
	set_pdata_int(id, 193, defuse);
		
	message_begin(MSG_ONE, get_user_msgid("StatusIcon"), _, id);
	write_byte(2);
	write_string("defuser");
	write_byte(colour[0]);
	write_byte(colour[1]);
	write_byte(colour[2]);
	message_end();
}

stock fm_get_user_money(index)
{
	return get_pdata_int(index, 115);
}

stock fm_set_user_money(index, money)
{
	set_pdata_int(index, 115, money);
	
	message_begin(MSG_ONE, get_user_msgid("Money"), {0,0,0}, index);
	write_long(money);
	write_byte(1);
	message_end();
}

stock get_distance_to_line(Float:pos_start[3], Float:pos_end[3], Float:pos_object[3])  
{  
	new Float:vec_start_end[3], Float:vec_start_object[3], Float:vec_end_object[3], Float:vec_end_start[3] 
	xs_vec_sub(pos_end, pos_start, vec_start_end) // vector from start to end 
	xs_vec_sub(pos_object, pos_start, vec_start_object) // vector from end to object 
	xs_vec_sub(pos_start, pos_end, vec_end_start) // vector from end to start 
	xs_vec_sub(pos_end, pos_object, vec_end_object) // vector object to end 
	
	new Float:len_start_object = getVecLen(vec_start_object) 
	new Float:angle_start = floatacos(xs_vec_dot(vec_start_end, vec_start_object) / (getVecLen(vec_start_end) * len_start_object), degrees)  
	new Float:angle_end = floatacos(xs_vec_dot(vec_end_start, vec_end_object) / (getVecLen(vec_end_start) * getVecLen(vec_end_object)), degrees)  

	if(angle_start <= 90.0 && angle_end <= 90.0) 
		return floatround(len_start_object * floatsin(angle_start, degrees)) 
	return -1  
}

stock get_user_distance(id, i)
{ 
	static Float:origin[3], Float:originI[3], Float:distance01, Float:distance2
	pev(id,pev_origin,origin)
	pev(i, pev_origin, originI)
	distance01 = get_distance_f(origin, originI)
	distance2 = origin[2] - originI[2]

	if (distance01 >= 600 || -60 >= distance2 >= 60)
		return 0;

	return 1;
} 

stock xs_vec_sub(const Float:in1[], const Float:in2[], Float:out[])
{
	out[0] = in1[0] - in2[0];
	out[1] = in1[1] - in2[1];
	out[2] = in1[2] - in2[2];
}

stock Float:xs_vec_dot(const Float:vec1[], const Float:vec2[])
{
	return vec1[0]*vec2[0] + vec1[1]*vec2[1] + vec1[2]*vec2[2];
}

stock xs_vec_add(const Float:in1[], const Float:in2[], Float:out[])
{
	out[0] = in1[0] + in2[0];
	out[1] = in1[1] + in2[1];
	out[2] = in1[2] + in2[2];
}

stock Float:getVecLen(Float:Vec[3])
{ 
	new Float:VecNull[3] = {0.0, 0.0, 0.0}
	new Float:len = get_distance_f(Vec, VecNull)
	return len
} 

stock bool:fm_is_ent_visible(index, entity) 
{
	new Float:origin[3], Float:view_ofs[3], Float:eyespos[3]
	pev(index, pev_origin, origin)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(origin, view_ofs, eyespos)

	new Float:entpos[3]
	pev(entity, pev_origin, entpos)
	engfunc(EngFunc_TraceLine, eyespos, entpos, 0, index)

	switch (pev(entity, pev_solid)) {
		case SOLID_BBOX..SOLID_BSP: return global_get(glb_trace_ent) == entity
	}

	new Float:fraction
	global_get(glb_trace_fraction, fraction)
	if (fraction == 1.0)
		return true

	return false
}
