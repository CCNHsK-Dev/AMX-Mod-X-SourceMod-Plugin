
/*

	Sex Roles

	v1.0  - 4/8/2010
	v1.1a - 27/2/2011
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <fun>

#define PLUGIN_NAME	"[CS & ZP & ZH]Male and female roles"
#define PLUGIN_VERSION	"1.1a"
#define PLUGIN_AUTHOR	"HsK"

/*以下只可選一個
2個也選當成 支援ZP
2個也不選當成 支援一般*/

//#define USE_IN_ZP		//用在ZP上(在最前面加上 // 即取消這項設定)
//#define USE_IN_ZH		//用在ZH上(在最前面加上 // 即取消這項設定)

//聲音------------------------------------------------------
//女性被擊中聲音
new const sex_girl_behit[][] = { "player/csow/f_headshot2.wav", "player/csow/f_headshot1.wav", "player/csow/f_headshot3.wav" }
//女性死亡聲音
new const sex_girl_die[][] = { "player/csow/f_die1.wav", "player/csow/f_die2.wav", "player/csow/f_die3.wav" }
//女性跌下聲音
new const sex_girl_fall[][] = { "player/csow/f_bhit_flesh-1.wav", "player/csow/f_bhit_flesh-2.wav", "player/csow/f_bhit_flesh-3.wav" }
//----------------------------------------------------------
//角色模組--------------------------------------------------
// 女角色模組
#define T_MODEL_N 5	//T有多小女角色
new const TG_MODEL_NAME[T_MODEL_N][] = {"麻生亞子", "伊琳娜", "安娜 (世足限定版)", "安娜", "潔西卡"}	//T女角色名
new const TG_PLAYER_MODEL[T_MODEL_N][] = { "jpngiel01", "ritsuka", "scyuri", "yuri", "jennifer" } 	//T女角色模組

#define CT_MODEL_N 5	//CT有多小女角色
new const CTG_MODEL_NAME[CT_MODEL_N][] = {"冷雨煙", "崔智雲", "葛蕾", "娜塔莎", "崔智云 (世足特定版)"}	//CT女角色名
new const CTG_PLAYER_MODEL[CT_MODEL_N][] = { "chngirl01" , "choijiyoon", "criss", "natasha", "sccjy"} 	//CT女角色模組

// 男角色模組
#define T_MODEL_NB 3	//T有多小男角色
new const TB_MODEL_NAME[T_MODEL_NB][] = {"中東恐怖遊擊部隊", "中東精銳恐怖分子", "日本赤軍"}		//T男角色名
new const TB_PLAYER_MODEL[T_MODEL_NB][] = { "qwdqwd", "qwvqwv", "jra" } 				//T男角色模組

#define CT_MODEL_NB 3	//CT有多小男角色
new const CTB_MODEL_NAME[CT_MODEL_NB][] = {"中國大陸特種部隊", "台灣霹靂小組", "南韓707特戰營"}		//CT男角色名
new const CTB_PLAYER_MODEL[CT_MODEL_NB][] = { "magui", "sozo", "707"} 					//CT男角色模組
//------------------------------------------------------------
// 持槍mdl ---------------------------------------------------

#if defined USE_IN_ZP 
new const ZPG_SUR_WEAPIN_MODEL[] = {"models/girl/v_mg3.mdl"}		//女倖存者持槍mdl [取替了ZP]
new const ZPG_SUR_KNIFE_MODEL[] = {"models/girl/v_knife.mdl"}		//女倖存者持刀mdl [取替了ZP]
new const SURG_PLAYER_MODEL[][] = {"mda", "mda1" , "mda5"} 		//女倖存者角色模組 [取替了ZP]

new const ZPB_SUR_WEAPIN_MODEL[] = {"models/v_m249.mdl"}		//女倖存者持槍mdl   [取替了ZP]
new const ZPB_SUR_KNIFE_MODEL[] = {"models/v_knife.mdl"}		//女倖存者持刀mdl  [取替了ZP]
new const SURB_PLAYER_MODEL[][] = {"vip", "vip1"} 			//女倖存者角色模組 [取替了ZP]
#endif

// 女角色持槍mdl
new const G_WEAPIN_GIRL_MODEL[CSW_P90+1][] = {
	"",
	"models/girl/v_p228.mdl",
	"models/girl/v_flashbang.mdl",
	"models/girl/v_scout.mdl",
	"models/girl/v_hegrenade.mdl",
	"models/girl/v_xm1014.mdl",
	"models/girl/v_c4.mdl",
	"models/girl/v_mac10.mdl",
	"models/girl/v_aug.mdl",
	"models/girl/v_smokegrenade.mdl",
	"models/girl/v_elite.mdl",
	"models/girl/v_fiveseven.mdl",
	"models/girl/v_ump45.mdl",
	"models/girl/v_sg550.mdl",
	"models/girl/v_galil.mdl",
	"models/girl/v_famas.mdl",
	"models/girl/v_usp.mdl",
	"models/girl/v_glock18.mdl",
	"models/girl/v_awp.mdl",
	"models/girl/v_mp5.mdl",
	"models/girl/v_m249.mdl",
	"models/girl/v_m3.mdl",
	"models/girl/v_m4a1.mdl",
	"models/girl/v_tmp.mdl",
	"models/girl/v_g3sg1.mdl",
	"models/girl/v_flashbang.mdl",
	"models/girl/v_deagle.mdl",
	"models/girl/v_sg552.mdl",
	"models/girl/v_ak47.mdl",
	"models/girl/v_knife.mdl",
	"models/girl/v_p90.mdl"
}
// 男角色持槍mdl
new const B_WEAPIN_GIRL_MODEL[CSW_P90+1][] = {
	"",
	"models/v_p228.mdl",
	"models/v_flashbang.mdl",
	"models/v_scout.mdl",
	"models/v_hegrenade.mdl",
	"models/v_xm1014.mdl",
	"models/v_c4.mdl",
	"models/v_mac10.mdl",
	"models/v_aug.mdl",
	"models/v_smokegrenade.mdl",
	"models/v_elite.mdl",
	"models/v_fiveseven.mdl",
	"models/v_ump45.mdl",
	"models/v_sg550.mdl",
	"models/v_galil.mdl",
	"models/v_famas.mdl",
	"models/v_usp.mdl",
	"models/v_glock18.mdl",
	"models/v_awp.mdl",
	"models/v_mp5.mdl",
	"models/v_m249.mdl",
	"models/v_m3.mdl",
	"models/v_m4a1.mdl",
	"models/v_tmp.mdl",
	"models/v_g3sg1.mdl",
	"models/v_flashbang.mdl",
	"models/v_deagle.mdl",
	"models/v_sg552.mdl",
	"models/v_ak47.mdl",
	"models/v_knife.mdl",
	"models/v_p90.mdl"
}

//------------------------------------------------------------

new const WEAPON_NAME[CSW_P90+1][] = { "", "CSW_P228", "CSW_FLASHBANG", "CSW_SCOUT", "CSW_HEGRENADE", "CSW_XM1014", "CSW_C4", "CSW_MAC10",
	"CSW_AUG", "CSW_SMOKEGRENADE", "CSW_ELITE", "CSW_FIVESEVEN", "CSW_UMP45", "CSW_SG550", "CSW_GALIL", "CSW_FAMAS", 
	"CSW_USP", "CSW_GLOCK18", "CSW_AWP", "CSW_MP5NAVY", "CSW_M249", "CSW_M3", "CSW_M4A1",
	"CSW_TMP", "CSW_G3SG1", "CSW_FLASHBANG", "CSW_DEAGLE", "CSW_SG552", "CSW_AK47", "CSW_KNIFE", "CSW_P90"
}

new const g_secondary_items[][] = { "weapon_glock18", "weapon_usp", "weapon_p228", "weapon_fiveseven", "weapon_deagle" }

new const RADIO_MENU_TEXT[21][] = {  "Cover_me", "You_take_the_point", "Hold_this_position", "Regroup_team", "Follow_me",
"Taking_fire", "Go_go_go", "Team_fall_back", "Stick_together_team", "Get_in_position_and_wait", "Storm_the_front", "Report_in_team",
"Affirmative/Roger_that", "Enemy_spotted", "Need_backup", "Sector_clear", "In_position", "Reporting_in", "Get_out_of_there", "Negative","Enemy_down"
}
new const RADIO_MSG_TEXT[24][] = { "Cover_me", "You_take_the_point", "Hold_this_position", "Regroup_team", "Follow_me",
"Taking_fire", "Go_go_go", "Team_fall_back", "Stick_together_team", "Get_in_position_and_wait", "Storm_the_front", "Report_in_team",
"Affirmative", "Roger_that", "Enemy_spotted", "Need_backup", "Sector_clear", "In_position", "Reporting_in", "Get_out_of_there",
"Negative", "Enemy_down","Hostage_down","Fire_in_the_hole" }

#define TASK_MENU		7575
#define TASk_MODEL 		778899
#define TASk_ID			8686

#if defined USE_IN_ZP  
#include <zombieplague>
new const Use_in_ZP = 1
#else
#if defined USE_IN_ZH
new const Use_in_ZP = 2
#else
new const Use_in_ZP = 0
#endif
#endif

const KEYSMENU = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
const OFFSET_CSTEAMS = 114
const OFFSET_LINUX = 5
const OFFSET_MODELINDEX = 491

// HUD messages
const Float:HUD_EVENT_X = -1.0
const Float:HUD_EVENT_Y = 0.17

// Boy and Girl
new g_sex_roles[33]
new g_sex_girl[33] //Girl
new g_sex_nextr_girl[33]
new g_sex_boy[33] //Boy
new g_sex_nextr_boy[33]
new g_teammeun_on[33]
new g_do_set_sex[33]
new g_model[33]	//weapon model

//player model
new modelindex_tg[sizeof TG_PLAYER_MODEL]
new modelindex_ctg[sizeof CTG_PLAYER_MODEL]
new modelindex_tb[sizeof TB_PLAYER_MODEL]
new modelindex_ctb[sizeof CTB_PLAYER_MODEL]
new bool:PlayerChangeModel[33]
new g_player_model[33][32]
new g_will_set_model[33]
new g_set_model[33]
new g_set_modelB[33]
new g_use_new_model[33] 
#if defined USE_IN_ZP 
new modelindex_sur[sizeof SURG_PLAYER_MODEL]
new sur_model[33]
#endif
new g_tct_model[33]

// Radio
new g_radioSpr, g_msgid_TextMsg, g_msgid_SendAudio
new load_menu_file, boy_load_menu_file, load_data_file, boy_load_data_file
new Radio_Menu_Title[3][32], Radio_Menu_Desc[21][48], Radio_Menu_Exit[32]
new BOY_Radio_Menu_Title[3][32], BOY_Radio_Menu_Desc[21][48], BOY_Radio_Menu_Exit[32]
new Radio_Text[24][5][64], Radio_Sound[24][5][64], Radio_Data_Num[24]
new BOY_Radio_Text[24][5][64], BOY_Radio_Sound[24][5][64], BOY_Radio_Data_Num[24]
new const Float:Send_Radio_Cooldown = 1.0
new Float:NextSendRadioTime[33]

// Msg
new g_msgSayText

new g_maxplayers

public plugin_init()
{
        register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

	register_event("CurWeapon","event_CurWeapon", "be", "1=1")

	register_logevent("logevent_round_start", 2, "1=Round_Start")

	register_forward(FM_EmitSound, "fw_EmitSound")
	#if defined USE_IN_ZP 
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	#endif
	register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged")

	register_message(get_user_msgid("TextMsg"), "message_TextMsg")

	register_clcmd("chooseteam", "clcmd_changeteam")
	register_clcmd("say /sex", "clcmd_changeteam")

	register_menu("Sex Set Boy_Girl", KEYSMENU, "set_roles")
	register_menu("Set Use T or CT model", KEYSMENU, "set_tct_model")

	g_msgSayText = get_user_msgid("SayText")
	g_msgid_TextMsg = get_user_msgid("TextMsg")
	g_msgid_SendAudio = get_user_msgid("SendAudio")

	register_menucmd(register_menuid("Radio1 Menu"), 1023, "action_Radio1")
	register_menucmd(register_menuid("Radio2 Menu"), 1023, "action_Radio2")
	register_menucmd(register_menuid("Radio3 Menu"), 1023, "action_Radio3")

	register_dictionary("sex_plugins.txt")

	g_maxplayers = get_maxplayers()
}

public plugin_natives()
{
	// Get player is girl
	register_native("sex_get_girl", "native_sex_get_girl", 1)

	// Set player Sex
	register_native("sex_set_boy", "native_sex_set_boy", 1)
	register_native("sex_set_girl", "native_sex_set_girl", 1)

	// Open Sex Menu
	register_native("sex_menu", "native_sex_menu", 1)

	// ZP [ SV will not lag]
	register_native("sex_player_model", "native_sex_player_model", 1)
}

public plugin_precache()
{
	new i

	for (i = 0; i < sizeof sex_girl_die; i++)
	   engfunc(EngFunc_PrecacheSound, sex_girl_die[i])
	for (i = 0; i < sizeof sex_girl_behit; i++)
	   engfunc(EngFunc_PrecacheSound, sex_girl_behit[i])
	for (i = 0; i < sizeof sex_girl_fall; i++)
	   engfunc(EngFunc_PrecacheSound, sex_girl_fall[i])

	new configs_dir[64]
	get_configsdir(configs_dir, 63)
	new config_file[64]
	format(config_file, 63, "%s/sexg_radio_data.ini", configs_dir)
	load_data_file = Load_Radio_Data(config_file)
	format(config_file, 63, "%s/sexb_radio_data.ini", configs_dir)
	boy_load_data_file = Load_ZM_Radio_Data(config_file)
		
	format(config_file, 63, "%s/sexg_radio_menu.ini", configs_dir)
	load_menu_file = Load_Radio_Menu(config_file)
	format(config_file, 63, "%s/sexb_radio_menu.ini", configs_dir)
	boy_load_menu_file = Load_ZM_Radio_Menu(config_file)
	g_radioSpr = precache_model("sprites/radio.spr")

	static menu[250], len, weap
	for (i = 0; i < sizeof WEAPON_NAME; i++)
	{
		engfunc(EngFunc_PrecacheModel, B_WEAPIN_GIRL_MODEL[i])
		engfunc(EngFunc_PrecacheModel, G_WEAPIN_GIRL_MODEL[i])
	}

	
	for (weap = 0; weap < sizeof g_secondary_items; weap++)
		len += formatex(menu[len], sizeof menu - 1 - len, "^n\r%d.\w %s", weap+1, WEAPON_NAME[get_weaponid(g_secondary_items[weap])])
	
	new model[100]
	for (i = 0; i < sizeof TG_PLAYER_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", TG_PLAYER_MODEL[i], TG_PLAYER_MODEL[i])
		modelindex_tg[i] = precache_model(model)
	}
	for (i = 0; i < sizeof CTG_PLAYER_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", CTG_PLAYER_MODEL[i], CTG_PLAYER_MODEL[i])
		modelindex_ctg[i] = precache_model(model)
	}
	for (i = 0; i < sizeof TB_PLAYER_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", TB_PLAYER_MODEL[i], TB_PLAYER_MODEL[i])
		modelindex_tb[i] = precache_model(model)
	}
	for (i = 0; i < sizeof CTB_PLAYER_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", CTB_PLAYER_MODEL[i], CTB_PLAYER_MODEL[i])
		modelindex_ctb[i] = precache_model(model)
	}

	#if defined USE_IN_ZP 
	engfunc(EngFunc_PrecacheModel, ZPG_SUR_WEAPIN_MODEL)
	engfunc(EngFunc_PrecacheModel, ZPG_SUR_KNIFE_MODEL)
	for (i = 0; i < sizeof SURG_PLAYER_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", SURG_PLAYER_MODEL[i], SURG_PLAYER_MODEL[i])
		modelindex_sur[i] = precache_model(model)
	}
	engfunc(EngFunc_PrecacheModel, ZPB_SUR_WEAPIN_MODEL)
	engfunc(EngFunc_PrecacheModel, ZPB_SUR_KNIFE_MODEL)
	for (i = 0; i < sizeof SURB_PLAYER_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", SURB_PLAYER_MODEL[i], SURB_PLAYER_MODEL[i])
		modelindex_sur[i] = precache_model(model)
	}
	#endif
}

public plugin_cfg() set_task(0.5, "event_round_start")

#if defined USE_IN_ZP 
public zp_user_infected_post(id, infector)
	g_use_new_model[id] = false

public fw_PlayerPreThink(id)
{
	if (zp_get_user_zombie(id))
	{
		if (g_use_new_model[id])
			g_use_new_model[id] = false
	}
	else
	{
		if (!g_use_new_model[id] || zp_get_user_survivor(id) && !sur_model[id])
		{
			set_task(0.2, "set_user_model_RZP", id+TASk_MODEL)

			if (zp_get_user_survivor(id) && !sur_model[id])
				sur_model[id] = true
		}
	}

	if (!zp_get_user_survivor(id) && sur_model[id]) sur_model[id] = false
}
#endif
public clcmd_changeteam(id)
{
	new CsTeams:team = cs_get_user_team(id)
	if (team == CS_TEAM_UNASSIGNED || team == CS_TEAM_SPECTATOR)
		return PLUGIN_CONTINUE;
	
	if (g_teammeun_on[id])
		return PLUGIN_CONTINUE;

	if (!g_sex_roles[id])
		g_sex_roles[id] = true

	if (g_sex_roles[id])
		sex_rolse_set(id)

	return PLUGIN_HANDLED;
}

sex_rolse_set(id)
{
	static menu[250], len
	len = 0

	len += formatex(menu[len], sizeof menu - 1 - len, "\y %L %L ^n^n", id, "SEX_NAME", id, "SET_YOUR_SEX_LEN")

	len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\w %L!! ^n", id, "SET_SEX_IS_BOY_LEN")

	len += formatex(menu[len], sizeof menu - 1 - len, "\r2.\w %L!! ^n", id, "SET_SEX_IS_GIRL_LEN")

	len += formatex(menu[len], sizeof menu - 1 - len, "\r3.\w %L ^n^n", id, "OPEN_TEAM_MENU")

	len += formatex(menu[len], sizeof menu - 1 - len, "\r5.\w %L", id, "PLAYER_MODEL_LEN")

	len += formatex(menu[len], charsmax(menu) - len, "^n^n^n\r0.\w %L", id, "OFF_THE_MENU")

	show_menu(id, KEYSMENU, menu, -1, "Sex Set Boy_Girl")
}

public set_roles(id, key)
{
	switch (key)
	{
		case 0:
		{
			if (g_sex_boy[id] && !g_sex_nextr_girl[id])
			{
				client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "SEX_IS_BOY_NOT_R")
				return;
			}
			
			g_sex_nextr_boy[id] = true
			g_do_set_sex[id] = true
			player_model_menu(id)
			client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "NR_SEX_IS_BOY")
		}
		case 1:
		{
			if (g_sex_girl[id] && !g_sex_nextr_boy[id])
			{
				client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "SEX_IS_GIRL_NOT_R")
				return;
			}
			
			g_sex_nextr_girl[id] = true
			g_do_set_sex[id] = true
			player_model_menu(id)
			client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "NR_SEX_IS_GIRL")
		}
		case 2: team_menu_on(id)
		case 4: player_model_menu(id)
	}
}

team_menu_on(id)
{
	g_teammeun_on[id] = true
	client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "OPEN_TEAM_MENU_TRUE")
	set_task(10.0, "team_menu_off", id)
}

public team_menu_off(id)
{
	g_teammeun_on[id] = false
	client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "OPEN_TEAM_MENU_FALSE")
}

public player_model_menu(id)
{
	if (Use_in_ZP == 0)
	{
		remove_task(id+TASK_MENU)

		if (!g_sex_nextr_boy[id] && !g_sex_nextr_girl[id])
		{
			if (g_sex_girl[id])
				set_task(0.3, "can_set_menu_g", id+TASK_MENU)
			else if (g_sex_boy[id])
				set_task(0.3, "can_set_menu_b", id+TASK_MENU)
		}
		else
		{
			if (g_sex_nextr_boy[id]) set_task(0.3, "can_set_menu_b", id+TASK_MENU)
			else if (g_sex_nextr_girl[id]) set_task(0.3, "can_set_menu_g", id+TASK_MENU)
		}
	}
	else
		set_task(0.3, "zp_zh_set_menu", id)

	client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "IN_PLAYER_MODEL_LEN")
}

public zp_zh_set_menu(id)
{
	static menu[250], len
	len = 0

	len += formatex(menu[len], sizeof menu - 1 - len, "\y %L %L ^n^n", id, "SEX_NAME", id, "MODEL_TEAM")

	len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\w %L!! ^n", id, "MODEL_TEAM_T")

	len += formatex(menu[len], sizeof menu - 1 - len, "\r2.\w %L!! ^n", id, "MODEL_TEAM_CT")

	len += formatex(menu[len], charsmax(menu) - len, "^n^n^n\r0.\w %L", id, "OFF_THE_MENU")

	show_menu(id, KEYSMENU, menu, -1, "Set Use T or CT model")
}

public set_tct_model(id, key)
{
	// g_tct_model[id] = 1  == T      
	// g_tct_model[id] = 2	== CT

	switch (key)
	{
		case 0: g_tct_model[id] = 1
		case 1: g_tct_model[id] = 2
	}
	remove_task(id+TASK_MENU)
	if (!g_sex_nextr_boy[id] && !g_sex_nextr_girl[id])
	{
		if (g_sex_girl[id])
			set_task(0.3, "can_set_menu_g", id+TASK_MENU)
		else if (g_sex_boy[id])
			set_task(0.3, "can_set_menu_b", id+TASK_MENU)
	}
	else
	{
		if (g_sex_nextr_boy[id]) set_task(0.3, "can_set_menu_b", id+TASK_MENU)
		else if (g_sex_nextr_girl[id]) set_task(0.3, "can_set_menu_g", id+TASK_MENU)
	}
}

public can_set_menu_b(taskid)
{
	new id = taskid - TASK_MENU

	new CsTeams:userTeam = cs_get_user_team(id);

	if (userTeam == CS_TEAM_T && Use_in_ZP == 0 || Use_in_ZP != 0 && g_tct_model[id] == 1)
	{
		new menu = menu_create("\y [SexR] 請選擇人物模組[T[男]]", "test_b")
		
		new i, itemname[64], data[2]
		for (i = 0; i < T_MODEL_NB; i++)
		{
			format(itemname, 63, "\w %s", TB_MODEL_NAME[i])
			data[0] = i
			data[1] = '^0'
			menu_additem(menu, itemname, data, 0, -1)
		}
		menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
		menu_setprop(menu, MPROP_BACKNAME, "上一頁")
		menu_setprop(menu, MPROP_NEXTNAME, "下一頁")
		menu_setprop(menu, MPROP_EXITNAME, "離開")
		menu_display(id, menu, 0)
	}
	if (userTeam == CS_TEAM_CT && Use_in_ZP == 0 || Use_in_ZP != 0 && g_tct_model[id] == 2)
	{
		new menu = menu_create("\y[SexR] 請選擇人物模組[CT[男]]", "test_b")
		
		new i, itemname[64], data[2]
		for (i = 0; i < CT_MODEL_NB; i++)
		{
			format(itemname, 63, "\w %s", CTB_MODEL_NAME[i])
			data[0] = i
			data[1] = '^0'
			menu_additem(menu, itemname, data, 0, -1)
		}
		menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
		menu_setprop(menu, MPROP_BACKNAME, "上一頁")
		menu_setprop(menu, MPROP_NEXTNAME, "下一頁")
		menu_setprop(menu, MPROP_EXITNAME, "離開")
		menu_display(id, menu, 0)
	}
}

public test_b(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	new data[6], itemname[64], access, callback, model_index
	menu_item_getinfo(menu, item, access, data,5, itemname, 63, callback);
	model_index = data[0]
	
	g_set_modelB[id] = model_index
	new CsTeams:userTeam = cs_get_user_team(id);
	if (userTeam == CS_TEAM_T && Use_in_ZP == 0 || Use_in_ZP != 0 && g_tct_model[id] == 1)
		client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "YOU_MODL_IS", TB_MODEL_NAME[model_index])
	if (userTeam == CS_TEAM_CT && Use_in_ZP == 0 || Use_in_ZP != 0 && g_tct_model[id] == 2)
		client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "YOU_MODL_IS", CTB_MODEL_NAME[model_index])
	
	g_will_set_model[id] = true
	
	menu_destroy(menu)
	
	return PLUGIN_HANDLED;
}

public can_set_menu_g(taskid)
{
	new id = taskid - TASK_MENU

	new CsTeams:userTeam = cs_get_user_team(id);

	if (userTeam == CS_TEAM_T && Use_in_ZP == 0 || Use_in_ZP != 0 && g_tct_model[id] == 1)
	{
		new menu = menu_create("\y [SexR] 請選擇人物模組[T[女]]", "test")
		
		new i, itemname[64], data[2]
		for (i = 0; i < T_MODEL_N; i++)
		{
			format(itemname, 63, "\w %s", TG_MODEL_NAME[i])
			data[0] = i
			data[1] = '^0'
			menu_additem(menu, itemname, data, 0, -1)
		}
		menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
		menu_setprop(menu, MPROP_BACKNAME, "上一頁")
		menu_setprop(menu, MPROP_NEXTNAME, "下一頁")
		menu_setprop(menu, MPROP_EXITNAME, "離開")
		menu_display(id, menu, 0)
	}
	if (userTeam == CS_TEAM_CT && Use_in_ZP == 0 || Use_in_ZP != 0 && g_tct_model[id] == 2)
	{
		new menu = menu_create("\y[SexR] 請選擇人物模組[CT[女]]", "test")
		
		new i, itemname[64], data[2]
		for (i = 0; i < CT_MODEL_N; i++)
		{
			format(itemname, 63, "\w %s", CTG_MODEL_NAME[i])
			data[0] = i
			data[1] = '^0'
			menu_additem(menu, itemname, data, 0, -1)
		}
		menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
		menu_setprop(menu, MPROP_BACKNAME, "上一頁")
		menu_setprop(menu, MPROP_NEXTNAME, "下一頁")
		menu_setprop(menu, MPROP_EXITNAME, "離開")
		menu_display(id, menu, 0)
	}
}

public test(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	new data[6], itemname[64], access, callback, model_index
	menu_item_getinfo(menu, item, access, data,5, itemname, 63, callback);
	model_index = data[0]
	
	g_set_model[id] = model_index
	new CsTeams:userTeam = cs_get_user_team(id);
	if (userTeam == CS_TEAM_T && Use_in_ZP == 0 || Use_in_ZP != 0 && g_tct_model[id] == 1)
		client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "YOU_MODL_IS", TG_MODEL_NAME[model_index])
	if (userTeam == CS_TEAM_CT && Use_in_ZP == 0 || Use_in_ZP != 0 && g_tct_model[id] == 2)
		client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "YOU_MODL_IS", CTG_MODEL_NAME[model_index])
	
	g_will_set_model[id] = true
	
	menu_destroy(menu)
	
	return PLUGIN_HANDLED;
}

public event_round_start()
{
	for (new id = 1; id <= g_maxplayers; id++)
		g_do_set_sex[id] = false

	set_task(2.0, "welcome_msg")
}

public logevent_round_start()
{
	for (new id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_connected(id) || !is_user_alive(id))
			continue;

		if (g_sex_boy[id] && g_sex_nextr_girl[id])
		{
			g_sex_boy[id] = false
			g_sex_girl[id] = true
			g_sex_nextr_girl[id] = false
			g_sex_nextr_boy[id] = false
			set_task(0.2, "set_user_model_R", id+TASk_MODEL)
			client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "TR_SEX_IS_GIRL")
		}
		if (g_sex_girl[id] && g_sex_nextr_boy[id])
		{
			g_sex_boy[id] = true
			g_sex_girl[id] = false
			g_sex_nextr_girl[id] = false
			g_sex_nextr_boy[id] = false
			set_task(0.2, "set_user_model_R", id+TASk_MODEL)
			client_print(id, print_chat, "%L %L", id, "SEX_NAME", id, "TR_SEX_IS_BOY")
		}

		event_CurWeapon(id)

		if (is_user_bot(id) && Use_in_ZP != 2)
		{
			set_task(0.2, "set_user_model_R", id+TASk_MODEL)
			continue;
		}

		if (!g_will_set_model[id]) continue;

		PlayerChangeModel[id] = false

		if (Use_in_ZP == 1)
		{
			set_task(0.2, "set_user_model_RZP", id+TASk_MODEL)
			continue;
		}

		if (Use_in_ZP == 2)
		{
			set_task(0.2, "set_user_model_RZH", id+TASk_MODEL)
			continue;
		}

		new CsTeams:userTeam = cs_get_user_team(id);
		if (g_sex_girl[id])
		{
			if (userTeam == CS_TEAM_T)
				set_task(0.2, "task_set_user_model_TG", id+TASk_MODEL)
			else if (userTeam == CS_TEAM_CT) 
				set_task(0.2, "task_set_user_model_CTG", id+TASk_MODEL)
		}
		else if (g_sex_boy[id])
		{
			if (userTeam == CS_TEAM_T)
				set_task(0.2, "task_set_user_model_TB", id+TASk_MODEL)
			else if (userTeam == CS_TEAM_CT) 
				set_task(0.2, "task_set_user_model_CTB", id+TASk_MODEL)
		}
	}
}

public fw_ClientUserInfoChanged(id)
{
	#if defined USE_IN_ZP  
	remove_task(id+TASk_ID)
	zp_model_lag_debug(id+TASk_ID)
	#else
	if (PlayerChangeModel[id] && g_use_new_model[id])
	{
		if (Use_in_ZP == 2)
		{
			new CsTeams:userTeam = cs_get_user_team(id);
			if (userTeam == CS_TEAM_T) return;
		}

		static current_model[32]
		fm_get_user_model(id, current_model, sizeof current_model - 1)
		
		if (!equal(current_model, g_player_model[id]))
			fm_set_user_model(id, g_player_model[id])
	}
	#endif
}
#if defined USE_IN_ZP  
public zp_model_lag_debug(taskid)
{
	new id = taskid - TASk_ID
	if (PlayerChangeModel[id] && g_use_new_model[id] && !zp_get_user_zombie(id))
	{
		static current_model[32]
		fm_get_user_model(id, current_model, sizeof current_model - 1)
		
		if (!equal(current_model, g_player_model[id]))
			fm_set_user_model(id, g_player_model[id])
	}
}
#endif

public task_set_user_model_TB(taskid)
{
	new id = taskid-TASk_MODEL

	new index = g_set_modelB[id]
	copy(g_player_model[id], sizeof g_player_model[] - 1, TB_PLAYER_MODEL[index])
		
	fm_set_user_model(id, g_player_model[id])
	PlayerChangeModel[id] = true
	g_use_new_model[id] = true
}

public task_set_user_model_CTB(taskid)
{
	new id = taskid-TASk_MODEL
	
	new index = g_set_modelB[id]
	copy(g_player_model[id], sizeof g_player_model[] - 1, CTB_PLAYER_MODEL[index])

	fm_set_user_model(id, g_player_model[id])
	PlayerChangeModel[id] = true
	g_use_new_model[id] = true
}

public task_set_user_model_TG(taskid)
{
	new id = taskid-TASk_MODEL

	new index = g_set_model[id]
	copy(g_player_model[id], sizeof g_player_model[] - 1, TG_PLAYER_MODEL[index])
		
	fm_set_user_model(id, g_player_model[id])
	PlayerChangeModel[id] = true
	g_use_new_model[id] = true
}

public task_set_user_model_CTG(taskid)
{
	new id = taskid-TASk_MODEL
	
	new index = g_set_model[id]
	copy(g_player_model[id], sizeof g_player_model[] - 1, CTG_PLAYER_MODEL[index])

	fm_set_user_model(id, g_player_model[id])
	PlayerChangeModel[id] = true
	g_use_new_model[id] = true
}

public set_user_model_R(taskid)
{
	new id = taskid-TASk_MODEL
	new DefinePlayerModels
	new CsTeams:userTeam = cs_get_user_team(id);

	if (g_sex_boy[id])
	{
		if (userTeam == CS_TEAM_T)
			DefinePlayerModels = sizeof TB_PLAYER_MODEL
		else if (userTeam == CS_TEAM_CT)
			DefinePlayerModels = sizeof CTB_PLAYER_MODEL

		if (DefinePlayerModels > 0)
		{
			//fm_get_user_model(id, g_player_original_model[id], sizeof g_player_original_model[] - 1)

			new index = random_num(0, DefinePlayerModels - 1)
			if (userTeam == CS_TEAM_T)
				copy(g_player_model[id], sizeof g_player_model[] - 1, TB_PLAYER_MODEL[index])
			else if (userTeam == CS_TEAM_CT)
				copy(g_player_model[id], sizeof g_player_model[] - 1, CTB_PLAYER_MODEL[index])

			fm_set_user_model(id, g_player_model[id])
			PlayerChangeModel[id] = true
			g_use_new_model[id] = true
		}

		return;
	}
	if (!g_sex_girl[id]) return;

	if (userTeam == CS_TEAM_T)
		DefinePlayerModels = sizeof TG_PLAYER_MODEL
	else if (userTeam == CS_TEAM_CT)
		DefinePlayerModels = sizeof CTG_PLAYER_MODEL

	if (DefinePlayerModels > 0)
	{
		new index = random_num(0, DefinePlayerModels - 1)
		if (userTeam == CS_TEAM_T)
			copy(g_player_model[id], sizeof g_player_model[] - 1, TG_PLAYER_MODEL[index])
		else if (userTeam == CS_TEAM_CT)
			copy(g_player_model[id], sizeof g_player_model[] - 1, CTG_PLAYER_MODEL[index])

		fm_set_user_model(id, g_player_model[id])
		PlayerChangeModel[id] = true
		g_use_new_model[id] = true
	}
}

public set_user_model_RZH(taskid)
{
	new id = taskid-TASk_MODEL

	new CsTeams:userTeam = cs_get_user_team(id);
	if (userTeam == CS_TEAM_T || is_user_bot(id))
		return;

	if (g_sex_boy[id])
	{
		new index = g_set_modelB[id]
		if (g_tct_model[id] == 1)
			copy(g_player_model[id], sizeof g_player_model[] - 1, TB_PLAYER_MODEL[index])
		else if(g_tct_model[id] == 2)
			copy(g_player_model[id], sizeof g_player_model[] - 1, CTB_PLAYER_MODEL[index])

		fm_set_user_model(id, g_player_model[id])
		PlayerChangeModel[id] = true
		g_use_new_model[id] = true

		return;
	}

	if (!g_sex_girl[id])
		return;

	new index = g_set_model[id]
	if (g_tct_model[id] == 1)
		copy(g_player_model[id], sizeof g_player_model[] - 1, TG_PLAYER_MODEL[index])
	else if(g_tct_model[id] == 2)
		copy(g_player_model[id], sizeof g_player_model[] - 1, CTG_PLAYER_MODEL[index])

	fm_set_user_model(id, g_player_model[id])
	PlayerChangeModel[id] = true
	g_use_new_model[id] = true

	return;
}

#if defined USE_IN_ZP  
public set_user_model_RZP(taskid)
{
	new id = taskid-TASk_MODEL
	new DefinePlayerModels

	if (zp_get_user_zombie(id)) return;

	if (zp_get_user_survivor(id)) 
	{
		if (g_sex_boy[id])
		{
			DefinePlayerModels = sizeof SURB_PLAYER_MODEL
			new index = random_num(0, DefinePlayerModels - 1)
			copy(g_player_model[id], sizeof g_player_model[] - 1, SURB_PLAYER_MODEL[index])

			fm_set_user_model(id, g_player_model[id])
			PlayerChangeModel[id] = true
			g_use_new_model[id] = true
			sur_model[id] = true

			return;
		}

		if (!g_sex_girl[id])
			return;

		DefinePlayerModels = sizeof SURG_PLAYER_MODEL
		new index = random_num(0, DefinePlayerModels - 1)
		copy(g_player_model[id], sizeof g_player_model[] - 1, SURG_PLAYER_MODEL[index])

		fm_set_user_model(id, g_player_model[id])
		PlayerChangeModel[id] = true
		g_use_new_model[id] = true
		sur_model[id] = true

		return;
	}

	if (g_sex_boy[id])
	{
		new index = g_set_modelB[id]
		if (g_tct_model[id] == 1)
			copy(g_player_model[id], sizeof g_player_model[] - 1, TB_PLAYER_MODEL[index])
		else if(g_tct_model[id] == 2)
			copy(g_player_model[id], sizeof g_player_model[] - 1, CTB_PLAYER_MODEL[index])

		fm_set_user_model(id, g_player_model[id])
		PlayerChangeModel[id] = true
		g_use_new_model[id] = true

		return;
	}

	if (!g_sex_girl[id])
		return;

	new index = g_set_model[id]
	if (g_tct_model[id] == 1)
		copy(g_player_model[id], sizeof g_player_model[] - 1, TG_PLAYER_MODEL[index])
	else if(g_tct_model[id] == 2)
		copy(g_player_model[id], sizeof g_player_model[] - 1, CTG_PLAYER_MODEL[index])

	fm_set_user_model(id, g_player_model[id])
	PlayerChangeModel[id] = true
	g_use_new_model[id] = true

	return;
}
#endif

public client_putinserver(id)
{
	PlayerChangeModel[id] = false
	if (!is_user_bot(id))
	{
		g_sex_boy[id] = true
		g_sex_roles[id] = false
		g_sex_girl[id] = false
		g_sex_nextr_girl[id] = false
		g_sex_nextr_boy[id] = false
		g_teammeun_on[id] = false
		g_do_set_sex[id] = false
	}
	else
	{
		new random = random_num(0,1)
		if (random == 0)
		{
			g_sex_boy[id] = true
			g_sex_roles[id] = true
			g_sex_girl[id] = false
			g_sex_nextr_girl[id] = false
			g_sex_nextr_boy[id] = false
			g_teammeun_on[id] = false
			g_do_set_sex[id] = false
		}
		else
		{
			g_sex_boy[id] = false
			g_sex_roles[id] = true
			g_sex_girl[id] = true
			g_sex_nextr_girl[id] = false
			g_sex_nextr_boy[id] = false
			g_teammeun_on[id] = false
			g_do_set_sex[id] = false
		}
	}
}

public client_disconnect(id)
{
	remove_task(id+TASk_MODEL)
	PlayerChangeModel[id] = false
}

public welcome_msg()
{
	sexr_colored_print(0, "^x04%L %L^x01 ", LANG_PLAYER, "SEX_NAME", LANG_PLAYER, "SEX_CPRT")

	set_hudmessage(168, 176, 253, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 5.0, 1.0, -1)
	show_hudmessage(0, "%L", LANG_PLAYER, "WELCOME_SEX_SER")
}

public event_CurWeapon(id)
{
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;

	#if defined USE_IN_ZP  
	if (zp_get_user_zombie(id)) return PLUGIN_CONTINUE;
	#endif

	if (Use_in_ZP == 2)
	{
		new CsTeams:userTeam = cs_get_user_team(id);
		if (userTeam == CS_TEAM_T)
			return FMRES_IGNORED;
	}

	new i
	for (i = 0; i < sizeof WEAPON_NAME; i++)
	{
		new weap_id, weap_clip, weap_bpammo
		weap_id = get_user_weapon(id, weap_clip, weap_bpammo)

		if (weap_id != i)
			continue;

		g_model[id] = i
		#if defined USE_IN_ZP 
		if(zp_get_user_survivor(id)) if (weap_id == CSW_KNIFE) g_model[id] = 1000
		#endif

		if (g_sex_girl[id])
			set_we_model_G(id)
		if (g_sex_boy[id])
			set_we_model_B(id)
	}

	return PLUGIN_CONTINUE;
}

set_we_model_G(id)
{
	#if defined USE_IN_ZP 
	if(zp_get_user_survivor(id))
	{
		if (g_model[id] == 1000)
		{
			set_pev(id, pev_viewmodel2, ZPG_SUR_KNIFE_MODEL)
			return;
		}
		set_pev(id, pev_viewmodel2, ZPG_SUR_WEAPIN_MODEL)
		return;
	}
	#endif
	new i = g_model[id]
	set_pev(id, pev_viewmodel2, G_WEAPIN_GIRL_MODEL[i])
}

set_we_model_B(id)
{
	#if defined USE_IN_ZP 
	if(zp_get_user_survivor(id))
	{
		if (g_model[id] == 1000)
		{
			set_pev(id, pev_viewmodel2, ZPB_SUR_KNIFE_MODEL)
			return;
		}
		set_pev(id, pev_viewmodel2, ZPB_SUR_WEAPIN_MODEL)
		return;
	}
	#endif

	new i = g_model[id]
	set_pev(id, pev_viewmodel2, B_WEAPIN_GIRL_MODEL[i])
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (!is_user_connected(id) || !g_sex_girl[id])
		return FMRES_IGNORED;

	#if defined USE_IN_ZP  
	if (zp_get_user_zombie(id)) return FMRES_IGNORED;
	#endif

	if (Use_in_ZP == 2)
	{
		new CsTeams:userTeam = cs_get_user_team(id);
		if (userTeam == CS_TEAM_T)
			return FMRES_IGNORED;
	}
	
	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
	{
		engfunc(EngFunc_EmitSound, id, channel, sex_girl_behit[random_num(0, sizeof sex_girl_behit - 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		engfunc(EngFunc_EmitSound, id, channel, sex_girl_die[random_num(0, sizeof sex_girl_die - 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}

	if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
	{
		engfunc(EngFunc_EmitSound, id, channel, sex_girl_fall[random_num(0, sizeof sex_girl_fall - 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

sexr_colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	// Send to everyone
	if (!target)
	{
		static player
		for (player = 1; player <= g_maxplayers; player++)
		{
			// Not connected
			if (!is_user_connected(player))
				continue;
			
			// Remember changed arguments
			static changed[5], changedcount // [5] = max LANG_PLAYER occurencies
			changedcount = 0
			
			// Replace LANG_PLAYER with player id
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			// Format message for player
			vformat(buffer, charsmax(buffer), message, 3)
			
			// Send it
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			// Replace back player id's with LANG_PLAYER
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	// Send to specific target
	else
	{
		// Format message for player
		vformat(buffer, charsmax(buffer), message, 3)
		
		// Send it
		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}

Load_ZM_Radio_Data(config_file[])
{
	if (!file_exists(config_file))
	{
		log_amx("Cannot load customization file ^"%s^" !", config_file)
		return 0;
	}
	
	new i
	for (i = 0; i < 24; i++)
		BOY_Radio_Data_Num[i] = 0
	
	new lines = file_size(config_file, 1)
	new string[256], len
	new left_string[32], right_string[224]
	new radio_set_index = -1
	new bool:get_text_data = false
	new index
	
	for (i = 0; i < lines; i++)
	{
		read_file(config_file, i, string, charsmax(string), len)
		replace(string, charsmax(string), "^n", "")
		trim(string)
		
		if (!string[0] || string[0] == ';')
			continue;
		
		if (string[0] == '[')
		{
			index = containi(string, "]")
			if (index != -1)
			{
				string[index] = 0
				copy(string, charsmax(string), string[1])
				
				index = get_string_index(RADIO_MSG_TEXT, 24, string)
				if (index != -1)
					radio_set_index = index
			}
			
			continue;
		}
		
		if (radio_set_index == -1 || BOY_Radio_Data_Num[radio_set_index] >= 5)
			continue;
		
		if (strtok(string, left_string, charsmax(left_string), right_string, charsmax(right_string), ':'))
		{
			trim(left_string)
			trim(right_string)
			
			if (strlen(right_string) > 0)
			{
				if (equal(left_string, "text"))
				{
					index = BOY_Radio_Data_Num[radio_set_index]
					copy(BOY_Radio_Text[radio_set_index][index], 64 - 1, right_string)
					get_text_data = true
				}
				else if (equal(left_string, "sound"))
				{
					if (get_text_data)
					{
						index = BOY_Radio_Data_Num[radio_set_index]
						copy(BOY_Radio_Sound[radio_set_index][index], 64 - 1, right_string)
						precache_sound(BOY_Radio_Sound[radio_set_index][index])
						BOY_Radio_Data_Num[radio_set_index]++
						get_text_data = false
					}
				}
			}
		}
	}
	
	return 1;
}

Load_Radio_Data(config_file[])
{
	if (!file_exists(config_file))
	{
		log_amx("Cannot load customization file ^"%s^" !", config_file)
		return 0;
	}
	
	new i
	for (i = 0; i < 24; i++)
		Radio_Data_Num[i] = 0
	
	new lines = file_size(config_file, 1)
	new string[256], len
	new left_string[32], right_string[224]
	new radio_set_index = -1
	new bool:get_text_data = false
	new index
	
	for (i = 0; i < lines; i++)
	{
		read_file(config_file, i, string, charsmax(string), len)
		replace(string, charsmax(string), "^n", "")
		trim(string)
		
		if (!string[0] || string[0] == ';')
			continue;
		
		if (string[0] == '[')
		{
			index = containi(string, "]")
			if (index != -1)
			{
				string[index] = 0
				copy(string, charsmax(string), string[1])
				
				index = get_string_index(RADIO_MSG_TEXT, 24, string)
				if (index != -1)
					radio_set_index = index
			}
			
			continue;
		}
		
		if (radio_set_index == -1 || Radio_Data_Num[radio_set_index] >= 5)
			continue;
		
		if (strtok(string, left_string, charsmax(left_string), right_string, charsmax(right_string), ':'))
		{
			trim(left_string)
			trim(right_string)
			
			if (strlen(right_string) > 0)
			{
				if (equal(left_string, "text"))
				{
					index = Radio_Data_Num[radio_set_index]
					copy(Radio_Text[radio_set_index][index], 64 - 1, right_string)
					get_text_data = true
				}
				else if (equal(left_string, "sound"))
				{
					if (get_text_data)
					{
						index = Radio_Data_Num[radio_set_index]
						copy(Radio_Sound[radio_set_index][index], 64 - 1, right_string)
						precache_sound(Radio_Sound[radio_set_index][index])
						Radio_Data_Num[radio_set_index]++
						get_text_data = false
					}
				}
			}
		}
	}
	
	return 1;
}

Load_ZM_Radio_Menu(config_file[]) //BOY_Radio_Menu_Desc
{
	if (!file_exists(config_file))
	{
		log_amx("Cannot load customization file ^"%s^" !", config_file)
		return 0;
	}
	
	new lines = file_size(config_file, 1)
	new string[128], len
	new left_string[32], right_string[96]
	new index
	new i
	
	for (i = 0; i < lines; i++)
	{
		read_file(config_file, i, string, charsmax(string), len)
		replace(string, charsmax(string), "^n", "")
		trim(string)
		
		if (!string[0] || string[0] == ';')
			continue;
		
		if (string[0] == '[')
		{
			index = containi(string, "]")
			if (index != -1)
			{
				copy(string, charsmax(string), string[1])
				strtok(string, left_string, charsmax(left_string), right_string, charsmax(right_string), ']')
				trim(left_string)
				trim(right_string)
				
				if (equal(left_string, "Radio1_Title"))
					copy(BOY_Radio_Menu_Title[0], 32 - 1, right_string)
				else if (equal(left_string, "Radio2_Title"))
					copy(BOY_Radio_Menu_Title[1], 32 - 1, right_string)
				else if (equal(left_string, "Radio3_Title"))
					copy(BOY_Radio_Menu_Title[2], 32 - 1, right_string)
				else if (equal(left_string, "Exit"))
					copy(BOY_Radio_Menu_Exit, 32 - 1, right_string)
				else
				{
					index = get_string_index(RADIO_MENU_TEXT, 21, left_string)
					if (index != -1)
						copy(BOY_Radio_Menu_Desc[index], 48 - 1, right_string)
				}
			}
		}
	}
	
	return 1;
}

Load_Radio_Menu(config_file[])
{
	if (!file_exists(config_file))
	{
		log_amx("Cannot load customization file ^"%s^" !", config_file)
		return 0;
	}
	
	new lines = file_size(config_file, 1)
	new string[128], len
	new left_string[32], right_string[96]
	new index
	new i
	
	for (i = 0; i < lines; i++)
	{
		read_file(config_file, i, string, charsmax(string), len)
		replace(string, charsmax(string), "^n", "")
		trim(string)
		
		if (!string[0] || string[0] == ';')
			continue;
		
		if (string[0] == '[')
		{
			index = containi(string, "]")
			if (index != -1)
			{
				copy(string, charsmax(string), string[1])
				strtok(string, left_string, charsmax(left_string), right_string, charsmax(right_string), ']')
				trim(left_string)
				trim(right_string)
				
				if (equal(left_string, "Radio1_Title"))
					copy(Radio_Menu_Title[0], 32 - 1, right_string)
				else if (equal(left_string, "Radio2_Title"))
					copy(Radio_Menu_Title[1], 32 - 1, right_string)
				else if (equal(left_string, "Radio3_Title"))
					copy(Radio_Menu_Title[2], 32 - 1, right_string)
				else if (equal(left_string, "Exit"))
					copy(Radio_Menu_Exit, 32 - 1, right_string)
				else
				{
					index = get_string_index(RADIO_MENU_TEXT, 21, left_string)
					if (index != -1)
						copy(Radio_Menu_Desc[index], 48 - 1, right_string)
				}
			}
		}
	}
	
	return 1;
}

public message_TextMsg(msg_id, msg_dest, id)
{
	if (get_msg_args() != 5)
		return;
	
	static msg_string[32]
	get_msg_arg_string(3, msg_string, 31)
	if (!equal(msg_string, "#Game_radio"))
		return;
	
	static sender_id_str[3], sender
	get_msg_arg_string(2, sender_id_str, 2)
	sender = str_to_num(sender_id_str)
	
	get_msg_arg_string(5, msg_string, 31)
	
	static msg_index
	msg_index = get_string_index(RADIO_MSG_TEXT, 24, msg_string[1])

	#if defined USE_IN_ZP  
	if (msg_index != -1 && !zp_get_user_zombie(sender))
	#else
	if (msg_index != -1)
	#endif
	{
		set_msg_arg_int(1, get_msg_argtype(1), 0)
		set_msg_arg_string(2, "")
		set_msg_arg_string(3, "")
		set_msg_arg_string(4, "")
		set_msg_arg_string(5, "")
		
		radio_sound_off(id)
		
		static index
		if (g_sex_boy[sender])
		{
			index = random_num(0, BOY_Radio_Data_Num[msg_index] - 1)
			send_user_radio(sender, id, BOY_Radio_Text[msg_index][index], BOY_Radio_Sound[msg_index][index], 1, 0)
		}
		if (g_sex_girl[sender])
		{
			index = random_num(0, Radio_Data_Num[msg_index] - 1)
			send_user_radio(sender, id, Radio_Text[msg_index][index], Radio_Sound[msg_index][index], 1, 0)
		}
	}
}

stock radio_sound_off(id)
{
	message_begin(MSG_ONE, g_msgid_SendAudio, {0, 0, 0}, id)
	write_byte(0)
	write_string("%!MRAD_")
	write_short(32767)
	message_end()
}

public client_command(id)
{
	if (!load_menu_file || !load_data_file || !boy_load_menu_file || !boy_load_data_file)
		return PLUGIN_CONTINUE;
	
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;

	#if defined USE_IN_ZP  
	if (zp_get_user_zombie(id))
		return PLUGIN_CONTINUE;
	#endif
	
	new cmd_string[32]
	read_argv(0, cmd_string, 31)
	
	if (equal(cmd_string, "radio1"))
	{
		if (g_sex_boy[id]) zmenu_Radio1(id)
		else if (g_sex_girl[id]) menu_Radio1(id)
		return PLUGIN_HANDLED_MAIN;
	}
	else if (equal(cmd_string, "radio2"))
	{
		if (g_sex_boy[id]) zmenu_Radio2(id)
		else if (g_sex_girl[id]) menu_Radio2(id)
		return PLUGIN_HANDLED_MAIN;
	}
	else if (equal(cmd_string, "radio3"))
	{
		if (g_sex_boy[id]) zmenu_Radio3(id)
		else if (g_sex_girl[id]) menu_Radio3(id)
		return PLUGIN_HANDLED_MAIN;
	}
	
	return PLUGIN_CONTINUE;
}

menu_Radio1(id)
{
	new menu_text[256], len
	new menu_chars = charsmax(menu_text)
	len = format(menu_text, menu_chars, "\y%s^n^n", Radio_Menu_Title[0])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", Radio_Menu_Desc[0])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", Radio_Menu_Desc[1])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", Radio_Menu_Desc[2])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", Radio_Menu_Desc[3])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", Radio_Menu_Desc[4])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", Radio_Menu_Desc[5])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", Radio_Menu_Exit)
	
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<9)
	
	show_menu(id, keys, menu_text, -1, "Radio1 Menu")
}

zmenu_Radio1(id)
{
	new menu_text[256], len
	new menu_chars = charsmax(menu_text)
	len = format(menu_text, menu_chars, "\y%s^n^n", BOY_Radio_Menu_Title[0])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", BOY_Radio_Menu_Desc[0])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", BOY_Radio_Menu_Desc[1])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", BOY_Radio_Menu_Desc[2])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", BOY_Radio_Menu_Desc[3])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", BOY_Radio_Menu_Desc[4])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", BOY_Radio_Menu_Desc[5])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", BOY_Radio_Menu_Exit)
	
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<9)
	
	show_menu(id, keys, menu_text, -1, "Radio1 Menu")
}

public action_Radio1(id, key)
{
	switch (key)
	{
		case 0: send_radio_msg(id, "Cover_me")
		case 1: send_radio_msg(id, "You_take_the_point")
		case 2: send_radio_msg(id, "Hold_this_position")
		case 3: send_radio_msg(id, "Regroup_team")
		case 4: send_radio_msg(id, "Follow_me")
		case 5: send_radio_msg(id, "Taking_fire")
		case 9: return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

menu_Radio2(id)
{
	new menu_text[256], len
	new menu_chars = charsmax(menu_text)
	len = format(menu_text, menu_chars, "\y%s^n^n", Radio_Menu_Title[1])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", Radio_Menu_Desc[6])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", Radio_Menu_Desc[7])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", Radio_Menu_Desc[8])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", Radio_Menu_Desc[9])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", Radio_Menu_Desc[10])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", Radio_Menu_Desc[11])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", Radio_Menu_Exit)
	
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<9)
	
	show_menu(id, keys, menu_text, -1, "Radio2 Menu")
}

zmenu_Radio2(id)
{
	new menu_text[256], len
	new menu_chars = charsmax(menu_text)
	len = format(menu_text, menu_chars, "\y%s^n^n", BOY_Radio_Menu_Title[1])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", BOY_Radio_Menu_Desc[6])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", BOY_Radio_Menu_Desc[7])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", BOY_Radio_Menu_Desc[8])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", BOY_Radio_Menu_Desc[9])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", BOY_Radio_Menu_Desc[10])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", BOY_Radio_Menu_Desc[11])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", BOY_Radio_Menu_Exit)
	
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<9)
	
	show_menu(id, keys, menu_text, -1, "Radio2 Menu")
}

public action_Radio2(id, key)
{
	switch (key)
	{
		case 0: send_radio_msg(id, "Go_go_go")
		case 1: send_radio_msg(id, "Team_fall_back")
		case 2: send_radio_msg(id, "Stick_together_team")
		case 3: send_radio_msg(id, "Get_in_position_and_wait")
		case 4: send_radio_msg(id, "Storm_the_front")
		case 5: send_radio_msg(id, "Report_in_team")
		case 9: return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

menu_Radio3(id)
{
	new menu_text[384], len
	new menu_chars = charsmax(menu_text)
	len = format(menu_text, menu_chars, "\y%s^n^n", Radio_Menu_Title[2])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", Radio_Menu_Desc[12])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", Radio_Menu_Desc[13])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", Radio_Menu_Desc[14])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", Radio_Menu_Desc[15])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", Radio_Menu_Desc[16])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", Radio_Menu_Desc[17])
	len += format(menu_text[len], menu_chars - len, "\w7. %s^n", Radio_Menu_Desc[18])
	len += format(menu_text[len], menu_chars - len, "\w8. %s^n", Radio_Menu_Desc[19])
	len += format(menu_text[len], menu_chars - len, "\w9. %s^n", Radio_Menu_Desc[20])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", Radio_Menu_Exit)
	
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
	
	show_menu(id, keys, menu_text, -1, "Radio3 Menu")
}

zmenu_Radio3(id)
{
	new menu_text[384], len
	new menu_chars = charsmax(menu_text)
	len = format(menu_text, menu_chars, "\y%s^n^n", BOY_Radio_Menu_Title[2])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", BOY_Radio_Menu_Desc[12])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", BOY_Radio_Menu_Desc[13])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", BOY_Radio_Menu_Desc[14])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", BOY_Radio_Menu_Desc[15])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", BOY_Radio_Menu_Desc[16])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", BOY_Radio_Menu_Desc[17])
	len += format(menu_text[len], menu_chars - len, "\w7. %s^n", BOY_Radio_Menu_Desc[18])
	len += format(menu_text[len], menu_chars - len, "\w8. %s^n", BOY_Radio_Menu_Desc[19])
	len += format(menu_text[len], menu_chars - len, "\w9. %s^n", BOY_Radio_Menu_Desc[20])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", BOY_Radio_Menu_Exit)
	
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
	
	show_menu(id, keys, menu_text, -1, "Radio3 Menu")
}

public action_Radio3(id, key)
{
	switch (key)
	{
		case 0: send_radio_msg(id, random_num(0, 1) ? "Affirmative" : "Roger_that")
		case 1: send_radio_msg(id, "Enemy_spotted")
		case 2: send_radio_msg(id, "Need_backup")
		case 3: send_radio_msg(id, "Sector_clear")
		case 4: send_radio_msg(id, "In_position")
		case 5: send_radio_msg(id, "Reporting_in")
		case 6: send_radio_msg(id, "Get_out_of_there")
		case 7: send_radio_msg(id, "Negative")
		case 8: send_radio_msg(id, "Enemy_down")
		case 9: return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

public send_radio_msg(sender, const msg_str[])
{
	if (get_gametime() < NextSendRadioTime[sender])
		return;

	#if defined USE_IN_ZP  
	if (zp_get_user_zombie(sender))
		return;
	#endif

	new hm_msg_index, zm_msg_index
	
	hm_msg_index = get_string_index(RADIO_MSG_TEXT, 24, msg_str)
	zm_msg_index = get_string_index(RADIO_MSG_TEXT, 24, msg_str)
	
	if (hm_msg_index != -1 || zm_msg_index != -1)
	{
		if(g_sex_girl[sender])
		{
			new index = random_num(0, Radio_Data_Num[hm_msg_index] - 1)
			send_radio_group(sender, Radio_Text[hm_msg_index][index], Radio_Sound[hm_msg_index][index])
		}
		else if (g_sex_boy[sender])
		{
			new index = random_num(0, BOY_Radio_Data_Num[zm_msg_index] - 1)
			send_radio_group(sender, BOY_Radio_Text[zm_msg_index][index], BOY_Radio_Sound[zm_msg_index][index])
		}
		show_radio_sprite(sender)
		NextSendRadioTime[sender] = get_gametime() + Send_Radio_Cooldown
	}
}

stock send_radio_group(sender, const message[], const sound_file[])
{
	new i, maxplayers
	maxplayers = get_maxplayers()

	#if defined USE_IN_ZP  
	new id_m, i_m
	id_m = zp_get_user_zombie(sender)
	#else
	new CsTeams:userTeam = cs_get_user_team(sender);
	#endif
	for (i = 1; i <= maxplayers; i++)
	{
		if (!is_user_connected(i) || !is_user_alive(i))
			continue;

		#if defined USE_IN_ZP 
		i_m = zp_get_user_zombie(i)
		
		if (id_m == 1 && i_m == 1 || id_m == 0 && i_m == 0)
			send_user_radio(sender, i, message, sound_file, 1, 0)
		#else
		new CsTeams:i_Team  = cs_get_user_team(i);
		if (userTeam == CS_TEAM_T && i_Team == CS_TEAM_T || userTeam == CS_TEAM_CT && i_Team == CS_TEAM_CT)
			send_user_radio(sender, i, message, sound_file, 1, 0)
		#endif
	}
}

stock send_user_radio(sender, target, const message[], const sound_file[], msg_name_type = 0, msg_string_type = 0)
{
	new sender_id_str[3], sender_name[32], show_name[34]
	num_to_str(sender, sender_id_str, charsmax(sender_id_str))
	get_user_name(sender, sender_name, charsmax(sender_name))
	
	if (msg_name_type == 1) // Use team color message
		format(show_name, charsmax(show_name), "^x03%s^x01", sender_name)
	else if (msg_name_type == 2) // Use green color message
		format(show_name, charsmax(show_name), "^x04%s^x01", sender_name)
	else // Use default color message
		format(show_name, charsmax(show_name), "%s", sender_name)
	
	new show_message[64]
	if (msg_string_type == 1) // Use team color message
		format(show_message, charsmax(show_message), "^x03%s^x01", message)
	else if (msg_string_type == 2) // Use green color message
		format(show_message, charsmax(show_message), "^x04%s^x01", message)
	else // Use default color message
		format(show_message, charsmax(show_message), "%s", message)
	
	if (strlen(message) > 0)
	{
		message_begin(MSG_ONE, g_msgid_TextMsg, _, target)
		write_byte(5) // print radio
		write_string(sender_id_str) // sender id string
		write_string("#Game_radio") // radio mid string
		write_string(show_name) // sender name
		write_string(show_message) // radio message
		message_end()
	}
	
	if (strlen(sound_file) > 0)
	{
		message_begin(MSG_ONE, g_msgid_SendAudio, _, target)
		write_byte(sender) //sender id
		write_string(sound_file) //Radio sound file path string
		write_short(100) //Pitch radio
		message_end()
	}
}

stock get_string_index(const string_array[][], string_num, const dest_string[])
{
	new i
	for (i = 0; i < string_num; i++)
	{
		if (equal(string_array[i], dest_string))
			return i;
	}
	
	return -1;
}

stock show_radio_sprite(id)  //zp_get_user_zombie
{
	new i, maxplayers
	maxplayers = get_maxplayers()

	#if defined USE_IN_ZP  
	new id_m, i_m
	id_m = zp_get_user_zombie(id)
	#else
	new CsTeams:userTeam  = cs_get_user_team(id);
	#endif
	for (i = 1; i <= maxplayers; i++)
	{
		if (!is_user_connected(i) || !is_user_alive(i))
			continue;

		#if defined USE_IN_ZP 
		i_m = zp_get_user_zombie(i)
		
		if (id_m == 1 && i_m == 1 || id_m == 0 && i_m == 0)
		{
			message_begin(MSG_ONE, SVC_TEMPENTITY, _, i)
			write_byte(TE_PLAYERATTACHMENT) // TE_PLAYERATTACHMENT (124)
			write_byte(id) // player id
			write_coord(35) // vertical offset (attachment origin.z = player origin.z + vertical offset)
			write_short(g_radioSpr) // sprite entity index
			write_short(20) // life (scale in 0.1's)
			message_end()
		}
		#else
		new CsTeams:i_Team  = cs_get_user_team(i);

		if (userTeam == CS_TEAM_T && i_Team == CS_TEAM_T || userTeam == CS_TEAM_CT && i_Team == CS_TEAM_CT)
		{
			message_begin(MSG_ONE, SVC_TEMPENTITY, _, i)
			write_byte(TE_PLAYERATTACHMENT) // TE_PLAYERATTACHMENT (124)
			write_byte(id) // player id
			write_coord(35) // vertical offset (attachment origin.z = player origin.z + vertical offset)
			write_short(g_radioSpr) // sprite entity index
			write_short(20) // life (scale in 0.1's)
			message_end()
		}
		#endif
	}
}

public native_sex_get_girl(id)
{
	return g_sex_girl[id];
}

public native_sex_set_girl(id)
{
	g_sex_nextr_girl[id] = true
	return 1;
}

public native_sex_set_boy(id)
{
	g_sex_nextr_boy[id] = true
	return 1;
}

public native_sex_player_model(id)
{
	return g_use_new_model[id];
}

public native_sex_menu(id)
{
	sex_rolse_set(id)
}

stock fm_get_user_team(id)
{
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}

// Get User Model -model passed byref-
stock fm_get_user_model(player, model[], len)
{
	get_user_info(player, "model", model, len)
}

// Set User Model
stock fm_set_user_model(id, const model[])
{
	set_user_info(id, "model", model)
	cs_set_user_model(id, model)
}
