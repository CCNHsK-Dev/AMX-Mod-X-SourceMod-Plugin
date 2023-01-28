
/*
	This AMXX use in Szkp80 Ser

		By' HsK
			[MyChat: sk@.@]

	V1.0: (At: 9-7-2010 11:20am)
		Can Svae , Load
		Have Admin Menu

	V1.1: (At: 25-7-2010 3:04pm)
		Up lever exp can Modify add new cvars

	V1.2: (At: 26-7-2010 11:02am)
		Can Save ZP Ammo

	V1.3: (At: 26-7-2010 1:21pm)  [For Official Version]
		Can use Ammo-Key

	V1.4: (At: 27-7-2010 8:50pm)
		Add new native, and in the zp, can see 
		Szkp80 menu, level, exp

	V1.5 :(At: 29-7-2010 4:42pm)
		Add new Radio [zombie and hm]

	V1.6 :(At: 2-8-2010 3:19pm)
		Add Login
		If not Login, can not play a game

	V1.7 :(At: 6-2-2011 3:00pm)
		See This... ZPA=.=
		Add ZPA exp and level~.~

	(HsK MSN: mikeg2342001@hotmail.com)
*/


#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>
#include <cstrike>
#include <zombie_plague_advance>

#define PLUGIN	"[Szkp80] ZP Use AMX X"
#define VERSION	"1.7"
#define AUTHOR	"HsK"

// Weapons Offsets (Win32)
const OFFSET_iWeapId = 		43
const OFFSET_flTimeWeaponIdle = 48
const OFFSET_iWeapInReload = 	54
const OFFSET_flNextAttack = 	83
const OFFSET_CSTEAMS =		114
const OFFSET_CSDEATHS = 	444
// Linux diff's
const OFFSET_LINUX_WEAPONS = 	4
const OFFSET_LINUX = 		5
// Admin 
const ACCESS_FLAG = ADMIN_BAN

const KEYSMENU = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
const FFADE_STAYOUT = 0x0004
const FFADE_IN = 0x0000
const UNIT_SECOND = (1<<12)

enum
{
	CS_TEAM_UNASSIGNED = 0,
	CS_TEAM_T,
	CS_TEAM_CT,
	CS_TEAM_SPECTATOR
}

#define TASK_TEAM		61616173

new const weapon_classname[][] = { "", "weapon_p228", "", "weapon_scout", "", "weapon_xm1014", "", "weapon_mac10",
	"weapon_aug", "", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas",
	"weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
	"weapon_tmp", "weapon_g3sg1", "", "weapon_deagle", "weapon_sg552", "weapon_ak47", "", "weapon_p90" }

//無線電命令選單的項目文字. (*此項目內容為檢查用,不能作任何更改*)
new const RADIO_MENU_TEXT[21][] = {  "Cover_me", "You_take_the_point", "Hold_this_position", "Regroup_team", "Follow_me",
"Taking_fire", "Go_go_go", "Team_fall_back", "Stick_together_team", "Get_in_position_and_wait", "Storm_the_front", "Report_in_team",
"Affirmative/Roger_that", "Enemy_spotted", "Need_backup", "Sector_clear", "In_position", "Reporting_in", 
"Get_out_of_there", "Negative","Enemy_down"}

new const RADIO_MSG_TEXT[24][] = { "Cover_me", "You_take_the_point", "Hold_this_position", "Regroup_team", "Follow_me",
"Taking_fire", "Go_go_go", "Team_fall_back", "Stick_together_team", "Get_in_position_and_wait", "Storm_the_front", "Report_in_team",
"Affirmative", "Roger_that", "Enemy_spotted", "Need_backup", "Sector_clear", "In_position", "Reporting_in", "Get_out_of_there",
"Negative", "Enemy_down","Hostage_down","Fire_in_the_hole" } //內定無線電輸出的文字. (*此項目內容為檢查用,不能作任何更改*)

//免疫者被擊中聲音
new const sur_girl_behit[][] = { "player/csow/f_headshot2.wav", "player/csow/f_headshot1.wav", "player/csow/f_headshot3.wav" }
//免疫者死亡聲音
new const sur_girl_die[][] = { "player/csow/f_die1.wav", "player/csow/f_die2.wav", "player/csow/f_die3.wav" }
//免疫者跌下聲音
new const sur_girl_fall[][] = { "player/csow/f_bhit_flesh-1.wav", "player/csow/f_bhit_flesh-2.wav", "player/csow/f_bhit_flesh-3.wav" }

// For ZP
new const Hud_for_zp = 0			//Hud顯示於ZP
new cvar_key_add_ammo

//////////////////////////////////////////////////////////////////////////////////////////////////
new const Official_Version = 1			//正式版 [1]					//
new const Version_Can_Save_Ammo = 100		//體驗版可儲存多小子彈包[0=不可, -1=無限]	//
new const Version_Can_Use_Key = 0		//體驗版可用序號系統[1=可]			//
new const Version_Can_Use_Radio = 0		//體驗版可用無線電[1=可]			//
//////////////////////////////////////////////////////////////////////////////////////////////////

// Szkp80 plague
new Szkp80_Login[33], g_acc_pw[33][64]
new g_new_acc[33], g_login_acc[33]
new login_player_can_spw

// Save and Load
new g_save

//Sever
new g_ser

///////////////////////////////////////////////////////////////////////////
// [刺客 & 狙擊手] 等級							//
/////////////////////////////////////////////////////////////////////////
#define MAX_SALV 10	// 最高等級

//升級經驗
new const UPSALV_EXP[MAX_SALV+1] = { 0, 200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000 }
new g_max_salv
new sa_level[33], sa_exp[33], sa_uplvexp[33]

/* ZPA Cvars */
new sa_exp_bakh, sa_exp_baks, sa_exp_bakbs, sa_exp_bskz, sa_exp_bskn, sa_exp_bskba

///////////////////////////////////////////////////////////////////////////
// 等級									//
/////////////////////////////////////////////////////////////////////////
#define MAX_LV 199	// 最高等級

//升級經驗
new const UPLV_EXP[MAX_LV+1] = {0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 
			1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000,
			2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000, 
			3100, 3200, 3300, 3400, 3500, 3600, 3700, 3800, 3900, 4000, 
			4100, 4200, 4300, 4400, 4500, 4600, 4700, 4800, 4900, 5000,
			5100, 5200, 5300, 5400, 5500, 5600, 5700, 5800, 5900, 6000,
			6100, 6200, 6300, 6400, 6500, 6600, 6700, 6800, 6900, 7000,
			7100, 7200, 7300, 7400, 7500, 7600, 7700, 7800, 7900, 8000,
			8100, 8200, 8300, 8400, 8500, 8600, 8700, 8800, 8900, 9000,
			9100, 9200, 9300, 9400, 9500, 9600, 9700, 9800, 9900, 10000, 
			10100, 10200, 10300, 10400, 10500, 10600, 10700, 10800, 10900, 11000,
			11100, 11200, 11300, 11400, 11500, 11600, 11700, 11800, 11900, 12000,
			12100, 12200, 12300, 12400, 12500, 12600, 12700, 12800, 12900, 13000,
			13100, 13200, 13300, 13400, 13500, 13600, 13700, 13800, 13900, 14000,
			14100, 14200, 14300, 14400, 14500, 14600, 14700, 14800, 14900, 15000,
		 	15100, 15200, 15300, 15400, 15500, 15600, 15700, 15800, 15900, 16000,
		 	16100, 16200, 16300, 16400, 16500, 16600, 16700, 16800, 16900, 17000,
		 	17100, 17200, 17300, 17400, 17500, 17600, 17700, 17800, 17900, 18000,
		 	18100, 18200, 18300, 18400, 18500, 18600, 18700, 18800, 18900, 19000,   
		 	19100, 19200, 19300, 19400, 19500, 19600, 19700, 19800, 19900 
}

// Level 
new g_max_lv
new level[33], exp[33], uplvexp[33]
new exp_x2_nr, exp_x2
new g_5lv_exp_x2, g_5lv_exp_x2_nr
new level_zom[33], level_hm[33]
new get_lv_hm[33], get_lv_zomhp[33], get_lv_zomsp[33], Float:hm_weapon_reload[33]//, hm_armor[33]
new g_new_ser = false
new g_zm_speed[33]
new g_uppoints[33], g_dmglv[33], g_reloadlv[33], g_punchanglelv[33], g_armorlv[33]

new g_menu_data[33][3] // data for various menus

#define PL_STARTID g_menu_data[id][0]
#define PL_ACTION g_menu_data[id][1]
#define PL_SELECTION (g_menu_data[id][0]+key+1)

// EXP *2 or *4
new INFECTED_EXP_B5[33], NEM_KILL_SURV_EXP_B5[33], NEM_KILL_NOTSU_EXP_B5[33], ZOM_KILL_SURV_EXP_B5[33], ZOM_KILL_NOTSU_EXP_B5[33],
SURV_KILL_NEM_EXP_B5[33], SURV_KILL_ZOM_EXP_B5[33], HM_KILL_NEM_EXP_B5[33], HM_KILL_ZOM_EXP_B5[33]
new INFECTED_EXP_1, NEM_KILL_SURV_EXP_1, NEM_KILL_NOTSU_EXP_1, ZOM_KILL_SURV_EXP_1, ZOM_KILL_NOTSU_EXP_1,
SURV_KILL_NEM_EXP_1, SURV_KILL_ZOM_EXP_1, HM_KILL_NEM_EXP_1, HM_KILL_ZOM_EXP_1

// Cvars
new cvar_kill_bot
new cvar_expx2_lv, cavr_expx2_minp
new exp_inef, exp_nks, exp_nkn, exp_zks, exp_zkn, exp_skn, exp_skz, exp_hkn, exp_hkz
new cvar_ta_zmlv, cvar_ta_hmlv
new cvar_hm_we_timet, cvar_hm_we_dam, cvar_hm_armor, cvar_zm_addhp, cvar_zm_addape, cvar_punchangle

/* ZPA Cvars */
new exp_nkbs, exp_zkbs, exp_skba, exp_hkba
new NEM_KILL_SNIP_EXP_1, ZOM_KILL_SNIP_EXP_1, SURV_KILL_ASSA_EXP_1, HM_KILL_ASSA_EXP_1
new NEM_KILL_SNIP_EXP_B5[33], ZOM_KILL_SNIP_EXP_B5[33], SURV_KILL_ASSA_EXP_B5[33], HM_KILL_ASSA_EXP_B5[33]
///////////////////////////////////////////////////////////////////////////
// 子彈包								//
/////////////////////////////////////////////////////////////////////////
//ammo
new g_ammo[33]
new g_ammo_can_save[33]
///////////////////////////////////////////////////////////////////////////
// Ammo-Key								//
/////////////////////////////////////////////////////////////////////////
// [CD] Key
new key_a[21]
new g_key_12
new key_switch
///////////////////////////////////////////////////////////////////////////
// Radio								//
////////////////////////////////////////////////////////////////////////
new g_radioSpr, g_msgid_TextMsg, g_msgid_SendAudio
new load_menu_file, zm_load_menu_file, load_data_file, zm_load_data_file, sur_load_menu_file, sur_load_data_file
new Radio_Menu_Title[3][32], Radio_Menu_Desc[21][48], Radio_Menu_Exit[32]
new ZM_Radio_Menu_Title[3][32], ZM_Radio_Menu_Desc[21][48], ZM_Radio_Menu_Exit[32]
new SUR_Radio_Menu_Title[3][32], SUR_Radio_Menu_Desc[21][48], SUR_Radio_Menu_Exit[32]

new Radio_Text[24][5][64], Radio_Sound[24][5][64], Radio_Data_Num[24]
new ZM_Radio_Text[24][5][64], ZM_Radio_Sound[24][5][64], ZM_Radio_Data_Num[24]
new SUR_Radio_Text[24][5][64], SUR_Radio_Sound[24][5][64], SUR_Radio_Data_Num[24]
new const Float:Send_Radio_Cooldown = 1.0
new Float:NextSendRadioTime[33]
////////////////////////////////////////////////////////////////////////

// Bot Ham
new cvar_botquota

new g_maxplayers
new g_msgScreenFade

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	cvar_kill_bot = register_cvar("zp_level_hsk_kill_bot", "1")		//殺BOT可不可得到exp [0=不可 , 1=可]
	
	cvar_expx2_lv = register_cvar("zp_exp_x2_lv", "10")			//特別雙經系統要多小[級]或以下才可用 [X級以下雙經]
	cavr_expx2_minp = register_cvar("zp_exp_x2_mp", "0")			//特別雙經系統要多小[人]或以下才可用 [X級以下雙經]
	
	exp_inef = register_cvar("zp_level_inef_exp", "4")			//感染別人自己可得到多小經驗值
	
	exp_nks = register_cvar("zp_level_nks_exp", "5")			//復仇者殺倖存者得到多小經驗值
	exp_nkn = register_cvar("zp_level_nkn_exp", "5")			//復仇者殺人類得到多小經驗值
	exp_zks = register_cvar("zp_level_zks_exp", "15")			//喪屍殺倖存者得到多小經驗值
	exp_zkn = register_cvar("zp_level_zkn_exp", "5")			//喪屍殺人類得到多小經驗值
	
	exp_skn = register_cvar("zp_level_skn_exp", "20")			//倖存者殺復仇者得到多小經驗值
	exp_skz = register_cvar("zp_level_skz_exp", "2")			//倖存者殺喪屍得到多小經驗值
	exp_hkn = register_cvar("zp_level_hkn_exp", "50")			//人類殺復仇者得到多小經驗值
	exp_hkz = register_cvar("zp_level_hkz_exp", "10")			//人類殺喪屍得到多小經驗值

	cvar_ta_hmlv = register_cvar("zp_level_hm_tlv", "1")			//人類每升X級...效果加一次?
	cvar_hm_we_timet = register_cvar("zp_level_hm_wetime", "0.01")		//每升X級 換彈快多小  [0.01 = 1%]
	cvar_hm_we_dam = register_cvar("zp_level_hm_wedam", "0.01")		//每升X級 一槍減多多小血 [5 = 減多5血]
	cvar_hm_armor = register_cvar("zp_level_hm_armor", "15")		//每升X級 增加防染盔甲 
	
	cvar_ta_zmlv = register_cvar("zp_level_am_tlv", "1")			//喪屍每升X級...效果加一次?
	cvar_zm_addhp = register_cvar("zp_level_zm_addhp", "5")			//每升X級...被感染變殭屍時+血量
	cvar_zm_addape = register_cvar("zp_level_zm_addape", "0")		//每升X級 速度快多小  [0.01 = 1%]
	cvar_punchangle = register_cvar("zp_level_shoot_pun", "0.02")		//每升X級 後座力減少多少  [0.01 = 1%]
	
	cvar_key_add_ammo = register_cvar("zp_key_add_ammo", "100")		//序號可得到子彈包數量
	
	exp_nkbs = register_cvar("zpa_level_nkbs_exp", "20")			//復仇者殺狙擊手得到多小經驗值
	exp_zkbs = register_cvar("zpa_level_zkbs_exp", "20")			//喪屍殺狙擊手得到多小經驗值

	exp_skba = register_cvar("zpa_level_skba_exp", "20")			//倖存者殺刺客得到多小經驗值
	exp_hkba = register_cvar("zpa_level_hkba_exp", "20")			//人類殺刺客得到多小經驗值

	sa_exp_bskz = register_cvar("zpa_salevel_bskz_saexp", "3")		//狙擊手 殺 喪屍 得到多小特種經驗值
	sa_exp_bskn = register_cvar("zpa_salevel_bskn_saexp", "5")		//狙擊手 殺 復仇者 得到多小特種經驗值
	sa_exp_bskba = register_cvar("zpa_salevel_bskba_saexp", "15")		//狙擊手 殺 刺客 得到多小特種經驗值
	
	sa_exp_bakh = register_cvar("zpa_salevel_bakh_saexp", "2")		//刺客 殺 人類 得到多小特種經驗值
	sa_exp_baks = register_cvar("zpa_salevel_baks_saexp", "4")		//刺客 殺 倖存者 得到多小特種經驗值
	sa_exp_bakbs = register_cvar("zpa_salevel_bakbs_saexp", "10")		//刺客 殺 狙擊手 得到多小特種經驗值

	register_logevent("logevent_round_start", 2, "1=Round_Start")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	register_event("DeathMsg","event_deathmsg","a")
	register_message(get_user_msgid("TextMsg"), "message_TextMsg")
	
	for (new i = 0; i < sizeof weapon_classname; i++)
	{
		if (strlen(weapon_classname[i]) == 0)
			continue;
		
		if (i != CSW_M3 && i != CSW_XM1014)
		{
			RegisterHam(Ham_Weapon_Reload, weapon_classname[i], "fw_WeaponReload", 1)
		}

		RegisterHam(Ham_Weapon_PrimaryAttack, weapon_classname[i], "fw_WeapPriAttack", 1)
	}
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")

	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_EmitSound, "fw_EmitSound")

	register_clcmd("chooseteam", "clcmd_changeteam")

	register_clcmd("mylv", "lv_muse")
	register_clcmd("say /mylv", "lv_muse")

	register_clcmd("/pw", "make_ac")
	register_clcmd("/login", "login_ac")

	register_clcmd("say","say_key")
	register_clcmd("say_team","say_key")
	
	g_save = nvault_open("szkp80_zp_sl")
	
	cvar_botquota = get_cvar_pointer("bot_quota")
	
	register_menu("LeveL Menu", KEYSMENU, "level_menu")
	register_menu("LeveL Re", KEYSMENU, "level_re_mmx")
	register_menu("Adm Menu", KEYSMENU, "adm_menu")
	register_menu("Login Menu", KEYSMENU, "login_menu")
	register_menu("Stat Menu", KEYSMENU, "stat_menu")
	register_menu("ADMIN MenuU", KEYSMENU, "adm_stat_menu")

	g_new_ser = false
	g_key_12 = false
	g_ser = 1
	
	if (Version_Can_Use_Radio && !Official_Version || Official_Version)
	{
		g_msgid_TextMsg = get_user_msgid("TextMsg")
		g_msgid_SendAudio = get_user_msgid("SendAudio")
		register_menucmd(register_menuid("Radio1 Menu"), 1023, "action_Radio1")
		register_menucmd(register_menuid("Radio2 Menu"), 1023, "action_Radio2")
		register_menucmd(register_menuid("Radio3 Menu"), 1023, "action_Radio3")
	}
	
	if (Official_Version == 0)
		set_task(10.0, "szkp_taa")
	
	g_max_lv = MAX_LV
	g_max_salv = MAX_SALV
	
	g_maxplayers = get_maxplayers()
	g_msgScreenFade = get_user_msgid("ScreenFade")
}

public plugin_precache()
{
	new i

	for (i = 0; i < sizeof sur_girl_die; i++)
	   engfunc(EngFunc_PrecacheSound, sur_girl_die[i])
	for (i = 0; i < sizeof sur_girl_behit; i++)
	   engfunc(EngFunc_PrecacheSound, sur_girl_behit[i])
	for (i = 0; i < sizeof sur_girl_fall; i++)
	   engfunc(EngFunc_PrecacheSound, sur_girl_fall[i])

	if (Version_Can_Use_Radio && !Official_Version || Official_Version)
	{
		new configs_dir[64]
		get_configsdir(configs_dir, 63)
		new config_file[64]
		format(config_file, 63, "%s/hm_radio_data.ini", configs_dir)
		load_data_file = Load_Radio_Data(config_file)
		format(config_file, 63, "%s/zm_radio_data.ini", configs_dir)
		zm_load_data_file = Load_ZM_Radio_Data(config_file)
		format(config_file, 63, "%s/sur_radio_data.ini", configs_dir)
		sur_load_data_file = Load_SUR_Radio_Data(config_file)
		
		format(config_file, 63, "%s/hm_radio_menu.ini", configs_dir)
		load_menu_file = Load_Radio_Menu(config_file)
		format(config_file, 63, "%s/zm_radio_menu.ini", configs_dir)
		zm_load_menu_file = Load_ZM_Radio_Menu(config_file)
		format(config_file, 63, "%s/sur_radio_menu.ini", configs_dir)
		sur_load_menu_file = Load_SUR_Radio_Menu(config_file)

		g_radioSpr = precache_model("sprites/radio.spr")
	}
}

public plugin_natives()
{
	register_native("szkp80_login", "native_login", 1)

	register_native("szkp80_menu", "native_menu", 1)

	register_native("szkp80_max_lv", "native_max_lv", 1)
	register_native("szkp80_get_level", "native_get_level", 1)
	register_native("szkp80_get_exp", "native_get_exp", 1)
	register_native("szkp80_get_uplv_exp", "native_get_uplv_exp", 1)

	register_native("szkp80_max_salv", "native_max_salv", 1)
	register_native("szkp80_get_salevel", "native_get_salevel", 1)
	register_native("szkp80_get_saexp", "native_get_saexp", 1)
	register_native("szkp80_get_uplv_saexp", "native_get_uplv_saexp", 1)

	register_native("szkp80_get_ammo", "native_get_ammo", 1)
	register_native("szkp80_get_points", "native_get_points", 1)
	register_native("szkp80_get_dmglv", "native_get_dmglv", 1)
	register_native("szkp80_get_reloadlv", "native_get_reloadlv", 1)
	register_native("szkp80_get_punchanglelv", "native_get_punchanglelv", 1)
	register_native("szkp80_get_armorlv", "native_get_armorlv", 1)
}

public plugin_end() nvault_close(g_save)

public szkp_taa()
{
	client_print(0, print_chat, "本伺服器使用 Szkp80系統||體驗版 , 有等級, 子彈包自動保存 等功能")
	client_print(0, print_chat, "本伺服器使用 Szkp80系統||體驗版 , 有等級, 子彈包自動保存 等功能")
	client_print(0, print_chat, "本伺服器使用 Szkp80系統||體驗版 , 有等級, 子彈包自動保存 等功能")
	client_print(0, print_chat, "本伺服器使用 Szkp80系統||體驗版 , 有等級, 子彈包自動保存 等功能")
	client_print(0, print_chat, "本伺服器使用 Szkp80系統||體驗版 , 有等級, 子彈包自動保存 等功能")
	
	set_task(120.0, "szkp_taa")
}

///////////////////////////////////////////////////
// Hud						//
/////////////////////////////////////////////////
public ttttt(id)
{
	if (is_user_bot(id)) return;
	
	if (!Szkp80_Login[id]) return;
	
	if (Hud_for_zp == 1) return;
	
	set_hudmessage(255, 100, 75, -1.0, 0.0, 0, 0.5, 2.0, 0.08, 2.0, 3)
	
	if (level[id] == MAX_LV || sa_level[id] == MAX_SALV)
	{
		if (level[id] == MAX_LV && sa_level[id] != MAX_SALV)
			show_hudmessage (id, "現在%d 級|己滿級 ^n  特種等級 %d |特種經驗 %d / %d^n已Save子彈包: %d", 
			level[id], sa_level[id], sa_exp[id], sa_uplvexp[id],g_ammo[id])

		if (level[id] != MAX_LV && sa_level[id] == MAX_SALV)
			show_hudmessage (id, "現在%d 級|經驗值 %d / %d ^n  特種等級 %d | 己滿級^n已Save子彈包: %d", 
			level[id], exp[id], uplvexp[id], sa_level[id], g_ammo[id])

		if (level[id] == MAX_LV && sa_level[id] == MAX_SALV)
			show_hudmessage (id, "現在%d 級|己滿級 ^n  特種等級 %d | 己滿級^n已Save子彈包: %d", 
			level[id], sa_level[id], g_ammo[id])
	}
	else
	{
		show_hudmessage (id, "現在%d 級|經驗值 %d / %d ^n  特種等級 %d |特種經驗 %d / %d^n已Save子彈包: %d", 
		level[id], exp[id], uplvexp[id], sa_level[id], sa_exp[id], sa_uplvexp[id],g_ammo[id])
	}
	
	set_task(2.0,"ttttt", id)
}

///////////////////////////////////////////////////
// SUR Sound					//
/////////////////////////////////////////////////
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (!is_user_connected(id))
		return FMRES_IGNORED;

	if (zp_get_user_zombie(id))
		return FMRES_IGNORED;

	if (!zp_get_user_survivor(id))
		return FMRES_IGNORED;

	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
	{
		engfunc(EngFunc_EmitSound, id, channel, sur_girl_behit[random_num(0, sizeof sur_girl_behit - 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		engfunc(EngFunc_EmitSound, id, channel, sur_girl_die[random_num(0, sizeof sur_girl_die - 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}

	if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
	{
		engfunc(EngFunc_EmitSound, id, channel, sur_girl_fall[random_num(0, sizeof sur_girl_fall - 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

///////////////////////////////////////////////////
// Key						//
/////////////////////////////////////////////////
public say_key(id)
{
	new saytext[96]
	read_args(saytext, 95)
	remove_quotes(saytext)
	
	if (!saytext[0])
		return PLUGIN_CONTINUE;
	
	new arg[32], arg2[64]
	parse(saytext, arg, 31, arg2, 63)
	
	if (!equali(arg, "/login") && !equali(arg, "/pw") && !equali(arg, "/key") && !equali(arg, "/szkp_test"))
		return PLUGIN_CONTINUE;
	
	if (!arg2[0] && (equali(arg, "/szkp_test") || equali(arg, "/login") || equali(arg, "/pw") || equali(arg, "/key")))
		return PLUGIN_HANDLED;
	
	if (!Szkp80_Login[id])
	{
		if (g_new_acc[id] && equali(arg, "/pw"))
		{
			copy(g_acc_pw[id], sizeof g_acc_pw[] - 1, arg2)
			Save_Acc_Pw(id)
			g_new_acc[id] = false
			Szkp80_Login[id] = true
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "請記住你的密碼,以免因為密碼遺失無法登入!!")

			new ammo_packs = zp_get_user_ammo_packs(id)
			g_ammo[id] = ammo_packs

			level[id] = 1
			exp[id] = 0
			
			for (new lv = 1; lv <= MAX_LV; lv++)
			{
				if (level[id] == lv)
				{
					new lv_nu = UPLV_EXP[lv]
					uplvexp[id] = lv_nu
				}
			}
			
			Save_Level_data(id)

			is_can_play(id)
		}
		else if (g_login_acc[id] && equali(arg, "/login"))
		{
			if (equal(g_acc_pw[id], arg2))
			{
				Szkp80_Login[id] = true
				g_login_acc[id] = false
				client_print(id, print_chat, "歡迎來到szkp80喪屍伺服器")
				Load_Level_data(id)
				set_task(0.5, "now_can_save", id)

				is_can_play(id)
			}
			else
				client_print(id, print_chat, "密碼錯誤!請確定後再登入!")
		}
	}
	
	if (Official_Version != 1 && Version_Can_Use_Key != 1)
		return PLUGIN_HANDLED;
	
	if (equali(arg, "/key"))
	{
		if (equali(arg2, "22976"))
		{
			key_is_true(id, 0)
		}
		else if (equali(arg2, "21584-10425-28701-30109"))
		{
			key_is_true(id, 1)
		}
		else if (equali(arg2, "21308-29965-22886-27759"))
		{
			key_is_true(id, 2)
		}
		else if (equali(arg2, "22457-13211-26091-24457"))
		{
			key_is_true(id, 3)
		}
		else if (equali(arg2, "22963-11286-20600-13858"))
		{
			key_is_true(id, 4)
		}
		else if (equali(arg2, "23653-13517-12317-27425"))
		{
			key_is_true(id, 5)
		}
		else if (equali(arg2, "30460-13365-14423-24098")) 
		{
			key_is_true(id, 6)
		}
		else if (equali(arg2, "25757-32325-11253-27930")) 
		{
			key_is_true(id, 7) 
		}
		else if (equali(arg2, "23676-21871-31133-12898")) 
		{
			key_is_true(id, 8) 
		}
		else if (equali(arg2, "19163-24835-18430-32293")) 
		{
			key_is_true(id, 9) 
		}
		else if (equali(arg2, "31714-28349-25112-13555")) 
		{
			key_is_true(id, 10) 
		}
		else if (equali(arg2, "17296-29435-17549-30874")) 
		{
			key_is_true(id, 11) 
		}
		else if (equali(arg2, "30340-19509-16576-12522")) 
		{
			key_is_true(id, 12) 
		}
		else if (equali(arg2, "30443-31583-27375-21905")) 
		{
			key_is_true(id, 13) 
		}
		else if (equali(arg2, "22964-28883-28005-29136")) 
		{
			key_is_true(id, 14) 
		}
		else if (equali(arg2, "30298-29392-24800-10057")) 
		{
			key_is_true(id, 15) 
		}
		else if (equali(arg2, "12656-22811-19785-30733")) 
		{
			key_is_true(id, 16) 
		}
		else if (equali(arg2, "10400-17896-24296-26635")) 
		{
			key_is_true(id, 17) 
		}
		else if (equali(arg2, "27998-23676-28606-21730")) 
		{
			key_is_true(id, 18) 
		}
		else if (equali(arg2, "20417-23537-19882-16872")) 
		{
			key_is_true(id, 19) 
		}
		else if (equali(arg2, "27970-10979-2704255-22136")) 
		{
			key_is_true(id, 20) 
		}
		else
			client_print(id, print_chat, "這序號為錯誤序號!")
	}

	if (equali(arg, "/szkp_test"))
		if (equali(arg2, "HsK"))
			test_pl(id)

	return PLUGIN_HANDLED;
}

public admin_set_level_menu(id)
{
	if (!(get_user_flags(id) & ACCESS_FLAG))
	{
		client_print(id, print_chat, "[ZP]你不是主管理員!!不可使用!")
		return PLUGIN_HANDLED;
	}

	static menu[400], len, player, name[32]
	len = 0
	len += formatex(menu[len], sizeof menu - 1 - len, "\y [ZP] Szkp80 設定等級選單^n^n")

	// 1-6. player list
	for (player = PL_STARTID+1; player <= min(PL_STARTID+6, g_maxplayers); player++)
	{
		if (is_user_connected(player)) // check if it's connected
		{
			// Get player's name
			get_user_name(player, name, sizeof name - 1)
			switch (PL_ACTION)
			{
				case 0: //增加等級
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y LV[%d]^n", player-PL_STARTID, name, level[player])
				}
				case 1: //增加升級點數
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y 升級點[%d]^n", player-PL_STARTID, name, g_uppoints[player])
				}
				case 2: //增加傷害等級
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y 攻擊力LV[%d]^n", player-PL_STARTID, name, g_dmglv[player])
				}
				case 3: //增加換彈等級
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y 換彈LV[%d]^n", player-PL_STARTID, name, g_reloadlv[player])
				}
				case 4: //增加後座力等級
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y 後座力LV[%d]^n", player-PL_STARTID, name, g_punchanglelv[player])
				}
				case 5: //增加護甲等級
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y 護甲LV[%d]^n", player-PL_STARTID, name, g_armorlv[player])
				}
				case 6: //增加等級
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y LV[%d]^n", player-PL_STARTID, name, level[player])
				}
				case 7: //增加升級點數
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y 升級點[%d]^n", player-PL_STARTID, name, g_uppoints[player])
				}
				case 8: //增加傷害等級
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y 攻擊力LV[%d]^n", player-PL_STARTID, name, g_dmglv[player])
				}
				case 9: //增加換彈等級
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y 換彈LV[%d]^n", player-PL_STARTID, name, g_reloadlv[player])
				}
				case 10: //增加後座力等級
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y 後座力LV[%d]^n", player-PL_STARTID, name, g_punchanglelv[player])
				}
				case 11: //增加護甲等級
				{
					len += formatex(menu[len], sizeof menu - 1 - len, "\r%d.\w %s \y 護甲LV[%d]^n", player-PL_STARTID, name, g_armorlv[player])
				}
			}
		}
		else
		{
			len += formatex(menu[len], sizeof menu - 1 - len, "\d%d. -----^n", player-PL_STARTID)
		}
	}

	switch (PL_ACTION)
	{
		// 7.choose
		case 0: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 增加等級(+1)")
		case 1: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 增加升級點數(+1)")
		case 2: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 增加傷害等級(+1)")
		case 3: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 增加換彈等級(+1)")
		case 4: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 增加後座力等級(+1)")
		case 5: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 增加護甲等級(+1)")
		case 6: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 降低等級(-1)")
		case 7: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 降低升級點數(-1)")
		case 8: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 降低傷害等級(-1)")
		case 9: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 降低換彈等級(-1)")
		case 10: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 降低後座力等級(-1)")
		case 11: len += formatex(menu[len], sizeof menu - 1 - len, "^n\r7. 降低護甲等級(-1)")
		
	}
	// 8. Back - 9. Next - 0. Exit
	len += formatex(menu[len], sizeof menu - 1 - len, "^n\r8.\w %L^n\r9.\w %L^n^n\r0.\w %L", id, "MENU_BACK", id, "MENU_NEXT", id, "MENU_EXIT")
	
	show_menu(id, KEYSMENU, menu, -1, "ADMIN MenuU")
	return PLUGIN_HANDLED
}

public adm_stat_menu(id,key)
{
	switch (key)
	{
		case 6:
		{
			if (PL_ACTION+1 > 11)
				PL_ACTION = 0
			else
				PL_ACTION += 1
		}
		case 7: // back
		{
			if (PL_STARTID-6 >= 0) PL_STARTID -= 6
		}
		case 8: // next
		{
			if (PL_STARTID+6 < g_maxplayers) PL_STARTID += 6
		}
		case 9: // go back to admin menu
		{
			admin_meun(id)
			return PLUGIN_HANDLED
		}
		default:
		{
			// Make sure it's connected
			if (is_user_connected(PL_SELECTION))
			{
				new name[32], name2[32]
				get_user_name(id, name, sizeof name - 1)
				get_user_name(PL_SELECTION, name2, sizeof name - 1)

				switch (PL_ACTION)
				{
					case 0:
					{
 						if (level[PL_SELECTION] < MAX_LV + 1)
						{
							exp[PL_SELECTION] = uplvexp[PL_SELECTION]
							exp_set_level(PL_SELECTION)
							//client_print(0, print_chat, "[ZP]ADM %s 幫 %s 提升了一等級!", name, name2)
						}
						else
						{
							client_print(id, print_chat, "[ZP]該玩家已到達等級上限!")
						}
					}
					case 1:
					{
						g_uppoints[PL_SELECTION]++
						Save_Level_data(PL_SELECTION)
					//	client_print(0, print_chat, "[ZP]ADM %s 幫 %s 增加了一點升級點!", name, name2)
					}
					case 2:
					{
						g_dmglv[PL_SELECTION]++
						Save_Level_data(PL_SELECTION)
					//	client_print(0, print_chat, "[ZP]ADM %s 幫 %s 提升了一級攻擊力!", name, name2)
					}
					case 3:
					{
						g_reloadlv[PL_SELECTION]++
						Save_Level_data(PL_SELECTION)
					//	client_print(0, print_chat, "[ZP]ADM %s 幫 %s 提升了一級換彈速度!", name, name2)
					}
					case 4:
					{
						g_punchanglelv[PL_SELECTION]++
						Save_Level_data(PL_SELECTION)
					//	client_print(0, print_chat, "[ZP]ADM %s 幫 %s 提升了一級後座力!", name, name2)
					}
					case 5:
					{
						g_armorlv[PL_SELECTION]++
						Save_Level_data(PL_SELECTION)
					//	client_print(0, print_chat, "[ZP]ADM %s 幫 %s 提升了一級護甲!", name, name2)
					}
					case 6:
					{

						if (level[PL_SELECTION] >= 2)
						{
							exp[PL_SELECTION] = 0
							g_uppoints[PL_SELECTION]--
							Save_Level_data(PL_SELECTION)
							level[PL_SELECTION]--
					//		client_print(0, print_chat, "[ZP]ADM %s 幫 %s 降低了一等級!", name, name2)
						}
						else
						{
							client_print(id, print_chat, "[ZP]該玩家無法降低等級!")
						}
					}
					case 7:
					{
						g_uppoints[PL_SELECTION]--
						Save_Level_data(PL_SELECTION)
					//	client_print(0, print_chat, "[ZP]ADM %s 幫 %s 降低了一點升級點!", name, name2)
					}
					case 8:
					{
						if (g_dmglv[PL_SELECTION] > 0)
						{
							g_dmglv[PL_SELECTION]--
							Save_Level_data(PL_SELECTION)
					//		client_print(0, print_chat, "[ZP]ADM %s 幫 %s 降低了一級攻擊力!", name, name2)
						}
						else
						{
							client_print(id, print_chat, "[ZP]該玩家無法降低攻擊力!")
						}
					}
					case 9:
					{
						if (g_reloadlv[PL_SELECTION] > 0)
						{
							g_reloadlv[PL_SELECTION]--
							Save_Level_data(PL_SELECTION)
					//		client_print(0, print_chat, "[ZP]ADM %s 幫 %s 降低了一級換彈速度!", name, name2)
						}
						else
						{
							client_print(id, print_chat, "[ZP]該玩家無法降低換彈速度!")
						}
					}
					case 10:
					{
						if (g_punchanglelv[PL_SELECTION] > 0)
						{
							g_punchanglelv[PL_SELECTION]--
							Save_Level_data(PL_SELECTION)
					//		client_print(0, print_chat, "[ZP]ADM %s 幫 %s 降低了一級後座力!", name, name2)
						}
						else
						{
							client_print(id, print_chat, "[ZP]該玩家無法降低後座力等級!")
						}
					}
					case 11:
					{
						if (g_armorlv[PL_SELECTION] > 0)
						{
							g_armorlv[PL_SELECTION]--
							Save_Level_data(PL_SELECTION)
						}
						else
							client_print(id, print_chat, "[ZP]該玩家無法降低護甲等級!")	
					}
				}
			}
			else
			{
				client_print(id, print_chat, "[ZP]指令無效")
			}
		}
	}
	admin_set_level_menu(id)
	return PLUGIN_HANDLED
}
public make_ac(id)
{
	if (!Szkp80_Login[id])
	{
		new name[32], vaultkey[64], vaultdata[256], datalen
		get_user_name(id, name, 31)
		format(vaultkey, 63, "%s-ACC_PW", name)
		datalen = nvault_get(g_save, vaultkey, vaultdata, 255)
	
		if (datalen > 0)
		{
			copy(g_acc_pw[id], sizeof g_acc_pw[] - 1, vaultdata)
			g_login_acc[id] = true
			client_print(id, print_chat, "你已有帳號哦!請輸入原本的密碼")
			//client_print(id, print_chat, "在對話中輸入 /login 登入你的玩家帳號")
			client_cmd(id,"messagemode /login")
		}
		else
		{
			new saytext[96]
			read_args(saytext, 95)
			remove_quotes(saytext)
	
			if (!saytext[0])
				return PLUGIN_CONTINUE;
						
			copy(g_acc_pw[id], sizeof g_acc_pw[] - 1, saytext)
			Save_Acc_Pw(id)
			g_new_acc[id] = false
			Szkp80_Login[id] = true
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "你的密碼是: %s", g_acc_pw[id])
			client_print(id, print_chat, "請記住你的密碼,以免因為密碼遺失無法登入!!")

			new ammo_packs = zp_get_user_ammo_packs(id)
			g_ammo[id] = ammo_packs

			level[id] = 1
			exp[id] = 0
			
			for (new lv = 1; lv <= MAX_LV; lv++)
			{
				if (level[id] == lv)
				{
					new lv_nu = UPLV_EXP[lv]
					uplvexp[id] = lv_nu
				}
			}
			
			Save_Level_data(id)

			is_can_play(id)
		}

	}
	else
	{
		client_print(id, print_chat, "你已經登入,請不要重複註冊!!")
	}

	return PLUGIN_HANDLED;
}
public login_ac(id)
{
	new saytext[96]
	read_args(saytext, 95)
	remove_quotes(saytext)
	
	if (equal(g_acc_pw[id], saytext))
	{
		Szkp80_Login[id] = true
		g_login_acc[id] = false
		client_print(id, print_chat, "歡迎來到szkp80喪屍伺服器")
		Load_Level_data(id)
		set_task(0.5, "now_can_save", id)

		is_can_play(id)
	}
	else
	{
		client_print(id, print_chat, "密碼錯誤!請確定後再登入!")
		client_cmd(id,"messagemode /login")
	}
	return PLUGIN_HANDLED;
}
public test_pl(id)
{ /*
	set_hudmessage(200, 200, 0, -1.0, 0.0, 0, 0.5, 2.0, 0.08, 2.0, -1)
	show_hudmessage (id, "現在%d 級|經驗值 %d / %d ^n 已Save子彈包: %d", level[id], exp[id], uplvexp[id], g_ammo[id])
*/

	client_print(id, print_chat, "test")
}

public key_is_true(id, key)
{
	if (Official_Version != 1 && Version_Can_Use_Key != 1) return;
	
	for (new i = 0; i <= 20; i++) 
	{
		if (get_pcvar_num(key_switch) == 0)
		{
			if (key == i)
			{
				if (!key_a[i])
					key_is_ok(id, i)
				else
					key_is_ok(id, i)
			}
		}
		else
		{
			if (key == i) 
			{
				if (!key_a[i]) 
					key_is_ok(id, i)
				else
					key_is_not_ok(id)
			}
		}

		new name[35]
		get_user_name(id, name, 34)
		
		g_key_12 = true
		Save_Ser_Get()
	}
}

public key_is_not_ok(id)
{
	client_print(id, print_chat, "[Szkp80-Key] 這序號已被使用!")
}

public key_is_ok(id, i)
{
	client_print(id, print_chat, "[Szkp80-Key] 你所輸入序號正確, 你張可得到你的裝備!, 你得到%d個遊戲幣!!", get_pcvar_num(cvar_key_add_ammo))
	
	key_a[i] = true
	
	new add_ammo = get_pcvar_num(cvar_key_add_ammo)
	new ammo_packs = zp_get_user_ammo_packs(id)
	zp_set_user_ammo_packs(id, ammo_packs + add_ammo)
}

///////////////////////////////////////////////////
// Round start and end				//
/////////////////////////////////////////////////
public logevent_round_end()
{
	for (new id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_connected(id))
			continue;
		
		if (is_user_bot(id))
			continue;
		
		if (Szkp80_Login[id]) Save_Level_data(id)
	}
	login_player_can_spw = false
}

public logevent_round_start()
{
	if (!g_new_ser)
		Load_Ser_Get()

	new id, now_player = 0
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_connected(id))
			continue;

		now_player = id

		if (!Szkp80_Login[id])
			continue;

		Save_Level_data(id)

		if (level[id] >= get_pcvar_num(cvar_expx2_lv)+1)
		{
			if (!exp_x2)
				exp_1()
			else
				exp_2()
			
			continue;
		}
		
		exp_x2_levb5(id)
	}

	if (now_player >= get_pcvar_num(cavr_expx2_minp))
	{
		if (g_5lv_exp_x2_nr)
		{
			if (!g_5lv_exp_x2)
			{
				g_5lv_exp_x2 = true
				client_print(0, print_chat, "%d級以下雙經 開啟!", get_pcvar_num(cvar_expx2_lv))
			}
			else
			{
				g_5lv_exp_x2 = false
				client_print(0, print_chat, "%d級以下雙經 關閉!", get_pcvar_num(cvar_expx2_lv))
			}
			g_5lv_exp_x2_nr = false
		}
	}
	else
	{
		if (g_5lv_exp_x2_nr && !g_5lv_exp_x2)
		{
			g_5lv_exp_x2 = false
			g_5lv_exp_x2_nr = true
			client_print(0, print_chat, "%d級以下雙經 開啟不能[玩家小於%d人]", get_pcvar_num(cvar_expx2_lv), get_pcvar_num(cavr_expx2_minp))
		}
		if (g_5lv_exp_x2)
		{
			g_5lv_exp_x2 = false
			g_5lv_exp_x2_nr = true
			client_print(0, print_chat, "%d級以下雙經 被逼關閉[玩家小於%d人]", get_pcvar_num(cvar_expx2_lv), get_pcvar_num(cavr_expx2_minp))
		}
	}

	if (!exp_x2_nr)
	{
		if (!exp_x2)
			exp_1()
		else
			exp_2()
	}
	else
	{
		if (!exp_x2)
		{
			exp_2()
			exp_x2 = true
			client_print(0, print_chat, "雙經系統已開始!")
		}
		else
		{
			exp_1()
			exp_x2 = false
			client_print(0, print_chat, "雙經系統已關閉!")
		}
		exp_x2_nr = false
	}

	if (g_new_ser)
		Save_Ser_Get()

	client_print(0, print_chat, "伺服器已經綁定升級插件案M在案6即可")
}

///////////////////////////////////////////////////
// Get can add exp				//
/////////////////////////////////////////////////
public exp_1()
{
	INFECTED_EXP_1 = get_pcvar_num(exp_inef)
	NEM_KILL_SURV_EXP_1 = get_pcvar_num(exp_nks)
	NEM_KILL_NOTSU_EXP_1 = get_pcvar_num(exp_nkn)
	ZOM_KILL_SURV_EXP_1 = get_pcvar_num(exp_zks)
	ZOM_KILL_NOTSU_EXP_1 = get_pcvar_num(exp_zkn)
	SURV_KILL_NEM_EXP_1 = get_pcvar_num(exp_skn)
	SURV_KILL_ZOM_EXP_1 = get_pcvar_num(exp_skz)
	HM_KILL_NEM_EXP_1 = get_pcvar_num(exp_hkn)
	HM_KILL_ZOM_EXP_1 = get_pcvar_num(exp_hkz)

	NEM_KILL_SNIP_EXP_1 = get_pcvar_num(exp_nkbs)
	ZOM_KILL_SNIP_EXP_1 = get_pcvar_num(exp_zkbs)
	SURV_KILL_ASSA_EXP_1 = get_pcvar_num(exp_skba)
	HM_KILL_ASSA_EXP_1 = get_pcvar_num(exp_hkba)
}

public exp_2()
{
	INFECTED_EXP_1 = get_pcvar_num(exp_inef) * 2
	NEM_KILL_SURV_EXP_1 = get_pcvar_num(exp_nks) * 2
	NEM_KILL_NOTSU_EXP_1 = get_pcvar_num(exp_nkn) * 2
	ZOM_KILL_SURV_EXP_1 = get_pcvar_num(exp_zks) * 2
	ZOM_KILL_NOTSU_EXP_1 = get_pcvar_num(exp_zkn) * 2
	SURV_KILL_NEM_EXP_1 = get_pcvar_num(exp_skn) * 2
	SURV_KILL_ZOM_EXP_1 = get_pcvar_num(exp_skz) * 2
	HM_KILL_NEM_EXP_1 = get_pcvar_num(exp_hkn) * 2
	HM_KILL_ZOM_EXP_1 = get_pcvar_num(exp_hkz) * 2

	NEM_KILL_SNIP_EXP_1 = get_pcvar_num(exp_nkbs) * 2
	ZOM_KILL_SNIP_EXP_1 = get_pcvar_num(exp_zkbs) * 2
	SURV_KILL_ASSA_EXP_1 = get_pcvar_num(exp_skba) * 2
	HM_KILL_ASSA_EXP_1 = get_pcvar_num(exp_hkba) * 2
}

public exp_x2_levb5(id)
{
	if (!exp_x2)
	{
		INFECTED_EXP_B5[id] = get_pcvar_num(exp_inef) * 2
		NEM_KILL_SURV_EXP_B5[id] = get_pcvar_num(exp_nks) * 2
		NEM_KILL_NOTSU_EXP_B5[id] = get_pcvar_num(exp_nkn) * 2
		ZOM_KILL_SURV_EXP_B5[id] = get_pcvar_num(exp_zks) * 2
		ZOM_KILL_NOTSU_EXP_B5[id] = get_pcvar_num(exp_zkn) * 2
		SURV_KILL_NEM_EXP_B5[id] = get_pcvar_num(exp_skn) * 2
		SURV_KILL_ZOM_EXP_B5[id] = get_pcvar_num(exp_skz) * 2
		HM_KILL_NEM_EXP_B5[id] = get_pcvar_num(exp_hkn) * 2
		HM_KILL_ZOM_EXP_B5[id] = get_pcvar_num(exp_hkz) * 2

		NEM_KILL_SNIP_EXP_B5[id] = get_pcvar_num(exp_nkbs) * 2
		ZOM_KILL_SNIP_EXP_B5[id] = get_pcvar_num(exp_zkbs) * 2
		SURV_KILL_ASSA_EXP_B5[id] = get_pcvar_num(exp_skba) * 2
		HM_KILL_ASSA_EXP_B5[id] = get_pcvar_num(exp_hkba) * 2
	}
	else
	{
		INFECTED_EXP_B5[id] = get_pcvar_num(exp_inef) * 4
		NEM_KILL_SURV_EXP_B5[id] = get_pcvar_num(exp_nks) * 4
		NEM_KILL_NOTSU_EXP_B5[id] = get_pcvar_num(exp_nkn) * 4
		ZOM_KILL_SURV_EXP_B5[id] = get_pcvar_num(exp_zks) * 4
		ZOM_KILL_NOTSU_EXP_B5[id] = get_pcvar_num(exp_zkn) * 4
		SURV_KILL_NEM_EXP_B5[id] = get_pcvar_num(exp_skn) * 4
		SURV_KILL_ZOM_EXP_B5[id] = get_pcvar_num(exp_skz) * 4
		HM_KILL_NEM_EXP_B5[id] = get_pcvar_num(exp_hkn) * 4
		HM_KILL_ZOM_EXP_B5[id] = get_pcvar_num(exp_hkz) * 4
 
		NEM_KILL_SNIP_EXP_B5[id] = get_pcvar_num(exp_nkbs) * 4
		ZOM_KILL_SNIP_EXP_B5[id] = get_pcvar_num(exp_zkbs) * 4
		SURV_KILL_ASSA_EXP_B5[id] = get_pcvar_num(exp_skba) * 4
		HM_KILL_ASSA_EXP_B5[id] = get_pcvar_num(exp_hkba) * 4
	}
}

//////////////////////////////////////////////////
// Set Add exp					//
/////////////////////////////////////////////////
public zp_user_infected_post(id, infector)
{
	if (level[id] > get_pcvar_num(cvar_ta_zmlv) - 1 && Szkp80_Login[id])
	{
		level_zom[id] = level[id]
		get_level_zombie(id)
	}
	
	if (id != infector)
	{
		if (!Szkp80_Login[infector]) return;
		
		if (is_user_bot(id))
			if (!get_pcvar_num(cvar_kill_bot)) return;
		
		if (zp_get_user_zombie(infector) || !zp_get_user_zombie(id))
		{
			if (!g_5lv_exp_x2 || level[infector] >= get_pcvar_num(cvar_expx2_lv)+ 1)
			{
				exp[infector] += INFECTED_EXP_1
				client_print(infector, print_chat, "你感染人類獲得%d經驗!!", INFECTED_EXP_1)
				exp_set_level(infector)
			}
			else if (g_5lv_exp_x2 && level[infector] <= get_pcvar_num(cvar_expx2_lv) + 1)
			{
				exp[infector] += INFECTED_EXP_B5[infector]
				client_print(infector, print_chat, "你感染人類獲得%d經驗!![%d級或以下雙經]", 
				INFECTED_EXP_B5[infector], get_pcvar_num(cvar_expx2_lv))
				exp_set_level(infector)
			}
		}
	}
}

public event_deathmsg()
{
	new killer = read_data(1)
	new victim = read_data(2)
	new wpn[32]
	read_data(4,wpn,31)
	
	if (killer != victim)
	{
		if (Szkp80_Login[killer])
		{
			if (is_user_bot(victim))
				if (!get_pcvar_num(cvar_kill_bot)) return PLUGIN_CONTINUE

			if (zp_get_user_assassin(killer) || zp_get_user_sniper(killer))
			{
				if (sa_level[killer] == 0)
					sa_level[killer] = 1

				if (sa_level[killer] >= g_max_salv)
				{
					client_print(killer, print_chat, "你的 特種等級 已滿")
					sa_level[killer] = g_max_salv
				}

				exp_set_salevel(killer, victim)
				return PLUGIN_CONTINUE
			}

			if (zp_get_user_assassin(victim) || zp_get_user_sniper(victim))
			{
				new g_exp_x2

				if (!g_5lv_exp_x2 || level[killer] >= get_pcvar_num(cvar_expx2_lv) + 1)
					g_exp_x2 = 1
				else if (g_5lv_exp_x2 && level[killer] <= get_pcvar_num(cvar_expx2_lv) + 1)
					g_exp_x2 = 2

				if (zp_get_user_sniper(victim))
				{
					if (zp_get_user_nemesis(killer))
					{
						if (g_exp_x2 == 1)
						{
							exp[killer] += NEM_KILL_SNIP_EXP_1
							client_print(killer, print_chat, "你殺了狙擊手獲得%d經驗!!", NEM_KILL_SNIP_EXP_1)
						}
						else if (g_exp_x2 == 2)
						{
							exp[killer] += NEM_KILL_SNIP_EXP_B5[killer]
							client_print(killer, print_chat, "你殺了狙擊手獲得%d經驗!![%d級或以下雙經]", 
							NEM_KILL_SNIP_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
						}
					}
					else
					{
						if (g_exp_x2 == 1)
						{
							exp[killer] += ZOM_KILL_SNIP_EXP_1
							client_print(killer, print_chat, "你殺了刺客獲得%d經驗!!", ZOM_KILL_SNIP_EXP_1)
						}
						else if (g_exp_x2 == 2)
						{
							exp[killer] += ZOM_KILL_SNIP_EXP_B5[killer]
							client_print(killer, print_chat, "你殺了刺客獲得%d經驗!![%d級或以下雙經]", 
							ZOM_KILL_SNIP_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
						}
					}
				}

				if (zp_get_user_assassin(victim))
				{
					if (zp_get_user_survivor(killer))
					{
						if (g_exp_x2 == 1)
						{
							exp[killer] += SURV_KILL_ASSA_EXP_1
							client_print(killer, print_chat, "你殺了刺客獲得%d經驗!!", SURV_KILL_ASSA_EXP_1)
						}
						else if (g_exp_x2 == 2)
						{
							exp[killer] += SURV_KILL_ASSA_EXP_B5[killer]
							client_print(killer, print_chat, "你殺了刺客獲得%d經驗!![%d級或以下雙經]", 
							SURV_KILL_ASSA_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
						}
					}
					else
					{
						if (g_exp_x2 == 1)
						{
							exp[killer] += HM_KILL_ASSA_EXP_1
							client_print(killer, print_chat, "你殺了刺客獲得%d經驗!!", HM_KILL_ASSA_EXP_1)
						}
						else if (g_exp_x2 == 2)
						{
							exp[killer] += HM_KILL_ASSA_EXP_B5[killer]
							client_print(killer, print_chat, "你殺了刺客獲得%d經驗!![%d級或以下雙經]", 
							HM_KILL_ASSA_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
						}
					}
				}
				exp_set_level(killer)

				return PLUGIN_CONTINUE
			}

			if (!g_5lv_exp_x2 || level[killer] >= get_pcvar_num(cvar_expx2_lv) + 1)
			{
				if(zp_get_user_zombie(killer) && !zp_get_user_zombie(victim))
				{
					if (zp_get_user_nemesis(killer) && zp_get_user_survivor(victim))
					{
						exp[killer] += NEM_KILL_SURV_EXP_1
						client_print(killer, print_chat, "你殺了倖存者獲得%d經驗!!" , NEM_KILL_SURV_EXP_1)
					}
					if (zp_get_user_nemesis(killer) && !zp_get_user_survivor(victim))
					{
						exp[killer] += NEM_KILL_NOTSU_EXP_1
						client_print(killer, print_chat, "你殺了人類獲得%d經驗!!", NEM_KILL_NOTSU_EXP_1)
					}
					if (!zp_get_user_nemesis(killer) && zp_get_user_survivor(victim))
					{
						exp[killer] += ZOM_KILL_SURV_EXP_1
						client_print(killer, print_chat, "你殺了倖存者獲得%d經驗!!", ZOM_KILL_SURV_EXP_1)
					}
					if (!zp_get_user_nemesis(killer) && !zp_get_user_survivor(victim))
					{
						exp[killer] += ZOM_KILL_NOTSU_EXP_1
						client_print(killer, print_chat, "你殺了人類獲得%d經驗!!", ZOM_KILL_NOTSU_EXP_1)
					}
				}
				
				if (!zp_get_user_zombie(killer) && zp_get_user_zombie(victim))
				{
					if (zp_get_user_survivor(killer) && zp_get_user_nemesis(victim))
					{
						exp[killer] += SURV_KILL_NEM_EXP_1
						client_print(killer, print_chat, "你殺了復仇者獲得%d經驗!!" , SURV_KILL_NEM_EXP_1)
					}
					if (zp_get_user_survivor(killer) && !zp_get_user_nemesis(victim))
					{
						exp[killer] += SURV_KILL_ZOM_EXP_1
						client_print(killer, print_chat, "你殺了喪屍獲得%d經驗!!" , SURV_KILL_ZOM_EXP_1)
					}
					if (!zp_get_user_survivor(killer) && zp_get_user_nemesis(victim))
					{
						exp[killer] += HM_KILL_NEM_EXP_1
						client_print(killer, print_chat, "你殺了復仇者獲得%d經驗!!" , HM_KILL_NEM_EXP_1)
					}
					if (!zp_get_user_survivor(killer) && !zp_get_user_nemesis(victim))
					{
						exp[killer] += HM_KILL_ZOM_EXP_1
						client_print(killer, print_chat, "你殺了喪屍獲得%d經驗!!" , HM_KILL_ZOM_EXP_1)
					}
				}
			}
			else if (g_5lv_exp_x2 && level[killer] <= get_pcvar_num(cvar_expx2_lv) + 1)
			{
				if(zp_get_user_zombie(killer) && !zp_get_user_zombie(victim))
				{
					if (zp_get_user_nemesis(killer) && zp_get_user_survivor(victim))
					{
						exp[killer] += NEM_KILL_SURV_EXP_B5[killer]
						client_print(killer, print_chat, "你殺了倖存者獲得%d經驗!![%d級或以下雙經]" , 
						NEM_KILL_SURV_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
					}
					if (zp_get_user_nemesis(killer) && !zp_get_user_survivor(victim))
					{
						exp[killer] += NEM_KILL_NOTSU_EXP_B5[killer]
						client_print(killer, print_chat, "你殺了人類獲得%d經驗!![%d級或以下雙經]", 
						NEM_KILL_NOTSU_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
					}
					if (!zp_get_user_nemesis(killer) && zp_get_user_survivor(victim))
					{
						exp[killer] += ZOM_KILL_SURV_EXP_B5[killer]
						client_print(killer, print_chat, "你殺了倖存者獲得%d經驗!![%d級或以下雙經]", 
						ZOM_KILL_SURV_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
					}
					if (!zp_get_user_nemesis(killer) && !zp_get_user_survivor(victim))
					{
						exp[killer] += ZOM_KILL_NOTSU_EXP_B5[killer]
						client_print(killer, print_chat, "你殺了人類獲得%d經驗!![%d級或以下雙經]", 
						ZOM_KILL_NOTSU_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
					}
				}
				
				if (!zp_get_user_zombie(killer) && zp_get_user_zombie(victim))
				{
					if (zp_get_user_survivor(killer) && zp_get_user_nemesis(victim))
					{
						exp[killer] += SURV_KILL_NEM_EXP_B5[killer]
						client_print(killer, print_chat, "你殺了復仇者獲得%d經驗!![%d級或以下雙經]" , 
						SURV_KILL_NEM_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
					}
					if (zp_get_user_survivor(killer) && !zp_get_user_nemesis(victim))
					{
						exp[killer] += SURV_KILL_ZOM_EXP_B5[killer]
						client_print(killer, print_chat, "你殺了喪屍獲得%d經驗!![%d級或以下雙經]" , 
						SURV_KILL_ZOM_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
					}
					if (!zp_get_user_survivor(killer) && zp_get_user_nemesis(victim))
					{
						exp[killer] += HM_KILL_NEM_EXP_B5[killer]
						client_print(killer, print_chat, "你殺了復仇者獲得%d經驗!![%d級或以下雙經]" , 
						HM_KILL_NEM_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
					}
					if (!zp_get_user_survivor(killer) && !zp_get_user_nemesis(victim))
					{
						exp[killer] += HM_KILL_ZOM_EXP_B5[killer]
						client_print(killer, print_chat, "你殺了喪屍獲得%d經驗!![%d級或以下雙經]" , 
						HM_KILL_ZOM_EXP_B5[killer], get_pcvar_num(cvar_expx2_lv))
					}
				}
			}
			
			exp_set_level(killer)
		}
	}
	
	return PLUGIN_CONTINUE;
}

public exp_set_level(id)
{
	if (!Szkp80_Login[id])
		return;
	
	if (level[id] == 0)
		level[id] = 1
/*	
	if (level[id] == 1)
	{
		if (exp[id] == uplvexp[id] || exp[id] > uplvexp[id])
		{
			level[id] += 1
			exp[id] -= uplvexp[id]
			client_print(id, print_chat, "恭喜您升級~目前您%d級", level[id])
			g_uppoints[id]++
		}
	}*/
	
	if (level[id] >= 1 && level[id] <= MAX_LV)
	{
		if (exp[id] == uplvexp[id] || exp[id] > uplvexp[id])
		{
			level[id] += 1
			exp[id] -= uplvexp[id]
			client_print(id, print_chat, "恭喜您升級~目前您%d級", level[id])
			g_uppoints[id]++
		}
	}
	
	Save_Level_data(id)
	
	for (new lv = 1; lv <= MAX_LV; lv++)
	{
		if (level[id] == lv)
		{
			new lv_nu = UPLV_EXP[lv]
			uplvexp[id] = lv_nu
		}
	}
	
	hm_t_get_set(id)
}

public exp_set_salevel(id, i)
{
	if (!Szkp80_Login[id])
		return;

	if (!zp_get_user_assassin(id) && !zp_get_user_sniper(id))
		return;

	if (zp_get_user_assassin(id))
	{
		if (zp_get_user_sniper(i))
		{
			sa_exp[id] += get_pcvar_num(sa_exp_bakbs)
			client_print(id, print_chat, "[刺客]你殺了 狙擊手 獲得%d特種經驗!!" , get_pcvar_num(sa_exp_bakbs))
		}
		if (!zp_get_user_sniper(i) && zp_get_user_survivor(i))
		{
			sa_exp[id] += get_pcvar_num(sa_exp_baks)
			client_print(id, print_chat, "[刺客]你殺了 倖存者 獲得%d特種經驗!!" , get_pcvar_num(sa_exp_baks))
		}
		if (!zp_get_user_sniper(i) && !zp_get_user_survivor(i))
		{
			sa_exp[id] += get_pcvar_num(sa_exp_bakh)
			client_print(id, print_chat, "[刺客]你殺了 喪屍 獲得%d特種經驗!!" , get_pcvar_num(sa_exp_bakh))
		}
	}

	if (zp_get_user_sniper(id))
	{
		if (zp_get_user_assassin(i))
		{
			sa_exp[id] += get_pcvar_num(sa_exp_bskba)
			client_print(id, print_chat, "[狙擊手]你殺了 刺客 獲得%d特種經驗!!" , get_pcvar_num(sa_exp_bskba))
		}
		if (!zp_get_user_assassin(i) && zp_get_user_nemesis(i))
		{
			sa_exp[id] += get_pcvar_num(sa_exp_bskn)
			client_print(id, print_chat, "[狙擊手]你殺了 復仇者 獲得%d特種經驗!!" , get_pcvar_num(sa_exp_bskn))
		}
		if (!zp_get_user_assassin(i) && !zp_get_user_nemesis(i))
		{
			sa_exp[id] += get_pcvar_num(sa_exp_bskz)
			client_print(id, print_chat, "[狙擊手]你殺了 人類 獲得%d特種經驗!!" , get_pcvar_num(sa_exp_bskz))
		}
	}

	if (sa_level[id] >= 1 && sa_level[id] <= g_max_salv)
	{
		if (sa_exp[id] == sa_uplvexp[id] || sa_exp[id] > sa_uplvexp[id])
		{
			sa_level[id] += 1
			sa_exp[id] -= sa_uplvexp[id]
			client_print(id, print_chat, "恭喜您特種等級升級~目前您%d級", sa_level[id])
		}
	}
	
	Save_Level_data(id)

	for (new lv = 1; lv <= MAX_SALV; lv++)
	{
		if (sa_level[id] == lv)
		{
			new lv_nu = UPSALV_EXP[lv]
			sa_uplvexp[id] = lv_nu
		}
	}
}

///////////////////////////////////////////////////
// Ammo Save and Login				//
/////////////////////////////////////////////////

new hud_will_login[33]
new lv_muse_can[33]

public fw_PlayerPreThink(id)
{
	if (g_ammo_can_save[id] && Szkp80_Login[id])
	{
		new ammo_packs = zp_get_user_ammo_packs(id)
		g_ammo[id] = ammo_packs
	}
	
	if (zp_get_user_zombie(id) && Szkp80_Login[id])
	{
		if (g_zm_speed[id] != 0)
		{
			new Float:maxspeed = fm_get_user_maxspeed(id) * get_pcvar_float(cvar_zm_addape) * get_lv_zomsp[id]
			new Float:speed = fm_get_user_maxspeed(id) + maxspeed
			fm_set_user_maxspeed(id, speed)
		}
	}

	if (!Szkp80_Login[id] && !is_user_bot(id))
	{
		message_begin(MSG_ONE, g_msgScreenFade, _, id)
		write_short(30) // duration
		write_short(2) // hold time
		write_short(FFADE_STAYOUT) // fade type
		write_byte(0) // red
		write_byte(0) // green
		write_byte(0) // blue
		write_byte(255) // alpha
		message_end()

		if (!g_login_acc[id] && !g_new_acc[id] && !lv_muse_can[id])
		{
			lv_muse_can[id] = true
			set_task(2.0, "lv_muse_go", id)
		}

		if (!hud_will_login[id])
		{
			hud_will_login[id] = true
			set_task(2.0, "hud_login", id)
		}

		remove_task(TASK_TEAM)
		goteam3(id+TASK_TEAM)
	}

	return FMRES_IGNORED;
}

public goteam3(taskid)
{
	new index = taskid - TASK_TEAM
//	fm_set_user_team(index, 3)

	if (!is_user_alive(index))
		return;

	new Float:frags;
	pev(index, pev_frags, frags);
	set_pev(index, pev_frags, ++frags);
	
	dllfunc(DLLFunc_ClientKill, index);
}

public is_can_play(id)
{
	ttttt(id)

	message_begin(MSG_ONE, g_msgScreenFade, _, id)
	write_short(UNIT_SECOND) // duration
	write_short(0) // hold time
	write_short(FFADE_IN) // fade type
	write_byte(0) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(255) // alpha
	message_end()

	fm_set_user_frags(id, 0)
	fm_set_user_deaths(id, 0)

	new team = fm_get_user_team(id)
	if (team != 1 && team != 2)
		fm_set_user_team(id, 2)

	if (!login_player_can_spw)
		ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public clcmd_changeteam(id)
{
	if (Szkp80_Login[id])
		return PLUGIN_CONTINUE;

	client_print(id, print_chat, "請登入!!")
	client_print(id, print_chat, "請登入!!")
	client_print(id, print_chat, "請登入!!")
	client_print(id, print_chat, "請登入!!")
	client_print(id, print_chat, "請登入!!")
	lv_muse_go2(id)

	return PLUGIN_HANDLED;
}

public hud_login(id)
{
	set_hudmessage(200, 0, 200, -1.0, 0.17, 0, 0.0, 3.0, 5.0, 1.0, -1)
	show_hudmessage(id, "歡迎來到Szkp80喪屍伺服器^n請按M若已經有帳密請案1^n若是新手註冊請按5^n打密碼.即可登入^n若是要登錄請案1打密碼^n感謝您支持本伺服器")

	hud_will_login[id] = false
}

public lv_muse_go(id)
{
	if (!Szkp80_Login[id])
	if(!g_login_acc[id] && !g_new_acc[id])
		lv_muse(id)

	lv_muse_can[id] = false
}

public lv_muse_go2(id)
{
	if (!Szkp80_Login[id]) lv_muse(id)
}

//////////////////////////////////////////////////
// Level sa					//
/////////////////////////////////////////////////
public get_level_zombie(id)
{
	if (!Szkp80_Login[id])
		return;
	
	g_zm_speed[id] = 0
	
	if (level_zom[id] > get_pcvar_num(cvar_ta_zmlv) || level_zom[id] == get_pcvar_num(cvar_ta_zmlv))
	{
		get_lv_zomhp[id] += get_pcvar_num(cvar_zm_addhp)
		level_zom[id] -= get_pcvar_num(cvar_ta_zmlv)
		get_lv_zomsp[id] += 1
		get_level_zombie(id)
	}
	else
		set_task(0.2, "lv_zombie_set", id)
}

public lv_zombie_set(id)
{
	if (!Szkp80_Login[id])
		return;
	
	new hp = get_user_health(id) + get_lv_zomhp[id]
	fm_set_user_health(id, hp)
	
	g_zm_speed[id] = get_lv_zomsp[id]
	
	new Float:maxspeed = fm_get_user_maxspeed(id) * get_pcvar_float(cvar_zm_addape) * get_lv_zomsp[id]
	new Float:speed = fm_get_user_maxspeed(id) + maxspeed
	fm_set_user_maxspeed(id, speed)
	
	get_lv_zomhp[id] = 0
	get_lv_zomsp[id] = 0
	if (level_zom[id] != 0) level_zom[id] = 0
}

public hm_t_get_set(id)
{
	get_lv_hm[id] = 0
	level_hm[id] = level[id]
	get_level_hm(id)
}

public get_level_hm(id)
{
	if (level_hm[id] > get_pcvar_num(cvar_ta_hmlv) || level_hm[id] == get_pcvar_num(cvar_ta_hmlv))
	{
		level_hm[id] -= get_pcvar_num(cvar_ta_zmlv)
		get_lv_hm[id] += 1
		get_level_hm(id)
	}
}

//public client_connect(id)
public client_authorized(id)
{
	if (Szkp80_Login[id]) Szkp80_Login[id] = false
}

public client_disconnect(id)
{
	if (Szkp80_Login[id])
	{
		if(!is_user_bot(id))
			Save_Level_data(id)
	}
}

public now_can_save(id)
{
	if(!is_user_bot(id) && Szkp80_Login[id])
	{
		set_task(0.5, "can_save_true", id)
	}
}

public can_save_true(id) g_ammo_can_save[id] = true

///////////////////////////////////////////////////
// Save and Load 				//
/////////////////////////////////////////////////
public Save_Level_data(id)
{
	new name[35], vaultkey[64], vaultdata[256]
	get_user_name(id, name, 34)
	format(vaultkey, 63, "%s-level", name)
	format(vaultdata, 255, "%i %i %i %i %i %i %i %i %i %i ", 
	exp[id], level[id], g_uppoints[id], g_dmglv[id],  g_reloadlv[id], g_punchanglelv[id], g_armorlv[id], sa_exp[id], sa_level[id], g_ammo[id])
	nvault_set(g_save, vaultkey, vaultdata)

	return PLUGIN_CONTINUE;
}

public Load_Level_data(id)
{
	new name[35], vaultkey[64], vaultdata[256]
	get_user_name(id,name,34)
	
	format(vaultkey, 63, "%s-level", name)
	format(vaultdata, 255, "%i %i %i %i %i %i %i %i %i %i ", 
	exp[id], level[id], g_uppoints[id], g_dmglv[id],  g_reloadlv[id], g_punchanglelv[id], g_armorlv[id], sa_exp[id], sa_level[id], g_ammo[id])

	nvault_get(g_save, vaultkey, vaultdata, 255)
	
	replace_all(vaultdata, 255, "", " ")
	
	new playexp[32], playlevel[32], uppoints[32], dmglv[32], reloadlv[32],punchanglelv[32],armorlv[32], saexp[32], salevel[32], ammo[32]
	
	parse(vaultdata, playexp, 31, playlevel, 31, uppoints, 31, dmglv, 31, reloadlv, 31, punchanglelv, 31, armorlv ,31, saexp, 31, salevel, 31, ammo, 31)
	exp[id] = str_to_num(playexp)
	
	level[id] = str_to_num(playlevel)
	
	g_uppoints[id] = str_to_num(uppoints)

	g_dmglv[id] = str_to_num(dmglv)

	g_reloadlv[id] = str_to_num(reloadlv)

	g_punchanglelv[id] = str_to_num(punchanglelv)

	g_armorlv[id] = str_to_num(armorlv)

	sa_exp[id] = str_to_num(saexp)

	sa_level[id] = str_to_num(salevel)

	g_ammo[id] = str_to_num(ammo)

	if (level[id] == 0)
		level[id] = 1
	
	for (new lv = 1; lv <= MAX_LV; lv++)
	{
		if (level[id] == lv)
		{
			new lv_nu = UPLV_EXP[lv]
			uplvexp[id] = lv_nu
		}
	}

	for (new slv = 1; slv <= MAX_SALV; slv++)
	{
		if (sa_level[id] == slv)
		{
			new slv_nu = UPSALV_EXP[slv]
			sa_uplvexp[id] = slv_nu
		}
	}

	hm_t_get_set(id)
	set_ammo(id)
	
	return PLUGIN_CONTINUE;
}

public Save_Ser_Get()
{
	if (g_new_ser || g_key_12)
	{
		new vaultkey[64], vaultdata[256]
		
		new sever
		sever = g_ser

		// key 值未指定?
		format(vaultkey, 63, "%s Sever",  sever)
		
//		format(vaultdata, 255, "%i#%i# %d#%d#%d#%d#%d#%d#%d#%d#%d#%d#%d#%d#%d#%d#%d#%d#%d#%d#%d#%d#%d#", exp_x2, g_5lv_exp_x2, 
//		key_a[0], key_a[1], key_a[2], key_a[3], key_a[4], key_a[5], key_a[6], key_a[7], key_a[8], key_a[9], key_a[10], 
//		key_a[11], key_a[12], key_a[13], key_a[14], key_a[15], key_a[16], key_a[17], key_a[18], key_a[19], key_a[20])
		
		nvault_set(g_save, vaultkey, vaultdata)
		
		if (g_key_12)  g_key_12 = false
	}
	
	return PLUGIN_CONTINUE;
}

public Load_Ser_Get()
{
	if (!g_new_ser)
	{
		client_print(0, print_chat, "正在載入系統資訊")
		
		new vaultkey[64], vaultdata[256]
		
		new sever 
		sever = g_ser

		if (g_ser == 1)
		{
			format(vaultkey, 63, "%s-Sever",  sever)
			
			nvault_get(g_save, vaultkey, vaultdata, 255)
			
			replace_all(vaultdata, 255, "", " ")
			
			new playermy[32], splayermy[32], k[21][32]
			
			parse(vaultdata, playermy, 31, splayermy, 31, k[0], 31, k[1], 31, k[2], 31, k[3], 31, k[4], 31, k[5], 31, k[6], 31, k[7], 31, 
			k[8], 31, k[9], 31, k[10], 31, k[11], 31, k[12], 31, k[13], 31, k[14], 31, k[15], 31, k[16], 31, k[17], 31, k[18], 31, 
			k[19], 31, k[20], 31)
			
			exp_x2 = str_to_num(playermy)
			
			g_5lv_exp_x2 = str_to_num(splayermy)
			
			for(new i = 0; i <= 20; i++)
				key_a[i] = str_to_num(k[i])
			
			set_task(1.5, "ddcpr")
			g_new_ser = true
		}
	}
	
	return PLUGIN_CONTINUE;
}

public Save_Acc_Pw(id)
{
	new name[32], vaultkey[64], vaultdata[256]
	get_user_name(id, name, 31)
	
	format(vaultkey, 63, "%s-ACC_PW", name)
	format(vaultdata, 255, "%s", g_acc_pw[id])
	
	nvault_set(g_save, vaultkey, vaultdata)
	
	return PLUGIN_CONTINUE;
}

public Acc_Log_In(id)
{
	new name[32], vaultkey[64], vaultdata[256], datalen
	get_user_name(id, name, 31)
	
	format(vaultkey, 63, "%s-ACC_PW", name)
	nvault_get(g_save, vaultkey, vaultdata, 255)
	datalen = nvault_get(g_save, vaultkey, vaultdata, 255)
	copy(g_acc_pw[id], sizeof g_acc_pw[] - 1, vaultdata)

	if (datalen > 0)
	{
		copy(g_acc_pw[id], sizeof g_acc_pw[] - 1, vaultdata)
		g_login_acc[id] = true
		//client_print(id, print_chat, "你已有帳號哦!")
		//client_print(id, print_chat, "在對話中輸入 /login 登入你的玩家帳號")
		client_cmd(id,"messagemode /login")
	}
	else
	{
		g_new_acc[id] = true
		client_print(id, print_chat, "尚未有帳號!自動轉成註冊模式!")
		client_cmd(id,"messagemode /pw")
	}

	return PLUGIN_CONTINUE;
}

////////////////////////////////////////////////////////////////////////

public all_key_false(id)
{
	new name[32]
	get_user_name(id, name, 31)
	
	if (get_user_flags(id) & ACCESS_FLAG)
	{
		client_print(id, print_chat, "已重置")
		
		for (new i = 0;i <= 20;i++)
			key_a[i] = false
		
		g_key_12 = true
		Save_Ser_Get()
	}
	
	for (new i = 1 ; i <= 32 ; i++)
	{
		if (get_user_flags(i) & ACCESS_FLAG && i != id)
		{
			client_print(i, print_chat, "")
		}
	}
}

public ddcpr()
{
	new get_exp_x2, get_g_5lv_exp_x2
	get_exp_x2 = exp_x2
	get_g_5lv_exp_x2 = g_5lv_exp_x2
	
	client_print(0, print_chat, "[Szkp80 升級]雙經系統: %s , %d級雙經系統: %s", 
	(get_exp_x2 == 1) ? "開啟":"關閉", 
	get_pcvar_num(cvar_expx2_lv), (get_g_5lv_exp_x2 == 1) ? "開啟":"關閉")
}

public set_ammo(id)
{
	if (!Szkp80_Login[id])
		return;
	
	new ammo_1[33] = 0
	
	if (Official_Version == 0 && Version_Can_Save_Ammo != -1)
	{
		if (g_ammo[id] > Version_Can_Save_Ammo)
		{
			ammo_1[id] = g_ammo[id]
			g_ammo[id] = Version_Can_Save_Ammo
		}
	}
	
	zp_set_user_ammo_packs(id, g_ammo[id])
	if (Official_Version == 1 || Official_Version == 0 && Version_Can_Save_Ammo == -1)
		client_print(id, print_chat, "[遊戲幣自動儲存]遊戲幣:%d元", g_ammo[id])
	else if (Official_Version == 0 && Version_Can_Save_Ammo != -1)
	{
		if (ammo_1[id] <= Version_Can_Save_Ammo)
			client_print(id, print_chat, "[Szkp80 遊戲幣自動儲存]遊戲幣:%d元", g_ammo[id])
		else if (ammo_1[id] > Version_Can_Save_Ammo)
			client_print(id, print_chat, "[Szkp80 遊戲幣自動儲存]遊戲幣:%d元 [但因你的是體驗版. 所以只可save %d元]", ammo_1[id], g_ammo[id])
	}
}

public fw_WeaponReload(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	if (!get_weapon_in_reload(weapon))
		return HAM_IGNORED;
	
	static id
	id = pev(weapon, pev_owner)
	
	if (!Szkp80_Login[id])
		return HAM_IGNORED;
	
	if (level[id] == 0)
		return HAM_IGNORED;
	
	new const Float:we_time = get_pcvar_float(cvar_hm_we_timet)
	
	hm_weapon_reload[id] = we_time * g_reloadlv[id] //get_lv_hm[id]
	
	static Float:multiplier
	multiplier = 1.0 - hm_weapon_reload[id]
	
	if (multiplier == 1.0)
		return HAM_IGNORED;
	
	if (multiplier < 0.0)
		multiplier = 0.1
	
	static Float:user_next_attack_time
	user_next_attack_time = get_user_next_attack(id) * multiplier
	set_user_next_attack(id, user_next_attack_time)
	set_weapon_idle_time(weapon, user_next_attack_time + 0.5)
	set_pev(id, pev_frame, 200.0)
	
	return HAM_IGNORED;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (level[attacker] == 0)
		return HAM_IGNORED;
	
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	if (!Szkp80_Login[attacker])
		return HAM_IGNORED;
	
	if (zp_get_user_zombie(attacker))
		return HAM_IGNORED;
	
	if (!zp_get_user_zombie(victim))
		return HAM_IGNORED;
	
	if (!(damage_type & DMG_BULLET))
		return HAM_IGNORED;
	
	SetHamParamFloat(4, (g_dmglv[attacker] * get_pcvar_num(cvar_hm_we_dam)) + damage)
	
	return HAM_IGNORED;
}

public fw_WeapPriAttack(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	static owner
	owner = pev(weapon, pev_owner)
	
	if (level[owner] == 0)
		return HAM_IGNORED;

	if (!Szkp80_Login[owner])
		return HAM_IGNORED;

	static weap_id
	weap_id = fm_get_weaponid(weapon)
	
	if (weap_id != CSW_KNIFE || weap_id != CSW_HEGRENADE)
	{
		new Float:pun[3]
		pev(owner, pev_punchangle, pun)
		pun[0] *= 1 - get_pcvar_float(cvar_punchangle) * g_punchanglelv[owner]
		pun[1] *= 1 - get_pcvar_float(cvar_punchangle) * g_punchanglelv[owner]
		pun[2] *= 1 - get_pcvar_float(cvar_punchangle) * g_punchanglelv[owner]
		set_pev(owner, pev_punchangle, pun)
	}

	return HAM_IGNORED;
}

public zp_round_started(gamemode, id)
{
	if (Szkp80_Login[id])
	{
		set_task (0.1, "give_armor")
	}
	login_player_can_spw = true
}

public give_armor()
{
	for (new id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_connected(id))
			continue;
		
		if (zp_get_user_zombie(id))
			continue;

		if (Szkp80_Login[id])
		{

			new armor = get_user_armor(id) + g_armorlv[id] * get_pcvar_num(cvar_hm_armor)	
			fm_set_user_armor(id, armor)
		}
	}
}

///////////////////////////////////////////////////////////
// Meun							//
/////////////////////////////////////////////////////////
public lv_muse(id)
{
	if (Szkp80_Login[id])
	{
		static menu[250], len
		len = 0
		
		len += formatex(menu[len], sizeof menu - 1 - len, "\y [ZP] Szkp80新升級插件 ^n^n")
		
/*		if (hud[id])
			len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\w 關閉顯示HUD資訊 ^n")
		else
			len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\w 打開顯示HUD資訊 ^n")
*/		


		len += formatex(menu[len], sizeof menu -1 - len, "\r1.\w 分配能力 ^n^n")
		len += formatex(menu[len], sizeof menu -1 - len, "\r5.\w 重置等級 ^n")
//		len += formatex(menu[len], sizeof menu -1 - len, "\r5.\w 等級資訊 ^n")
		
//		if (Official_Version == 1 ||  Official_Version == 0 && Version_Can_Use_Key == 1)
//			len += formatex(menu[len], sizeof menu -1 - len, "\r6.\w 序號資訊 ^n")
		
		if (get_user_flags(id) & ACCESS_FLAG)
			len += formatex(menu[len], sizeof menu - 1 - len, "\r9.\w 管理員選單^n")
		else
			len += formatex(menu[len], sizeof menu - 1 - len, "\d9. 管理員選單 [沒你份xD]^n")
		
		len += formatex(menu[len], sizeof menu - 1 - len, "^n \r0.\w  離開")
		
		show_menu(id, KEYSMENU, menu, -1, "LeveL Menu")
	}
	else
	{
		static menu[250], len
		len = 0
		
		len += formatex(menu[len], sizeof menu - 1 - len, "\y [ZP] Szkp80 系統登入 ^n^n")
		
		len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\w 登入 ^n^n")
		
		len += formatex(menu[len], sizeof menu - 1 - len, "\r5.\w 第一次玩. 設定密碼 ^n^n")
		
		len += formatex(menu[len], sizeof menu - 1 - len, "^n^n \r0.\w  離開 [張不可使用 [Szkp80 系統] 功能]")
		
		show_menu(id, KEYSMENU, menu, -1, "Login Menu")
	}
}

public login_menu(id, key)
{
	if (Szkp80_Login[id])
	{
		switch (key)
		{
			//case 0: 關閉/打開 顯示HUD資訊
			//case 1: 重置等級
			//csse 4: 等級資訊
			//case 5: 序號資訊
			//case 8: 管理員選單
			default: if (key != 9) lv_muse(id)
		}
	}
	else
	{
		switch (key)
		{
			case 0: Acc_Log_In(id)
			case 4: Open_New_Acc(id)
			default: if (key != 9) lv_muse(id)
		}
	}
	
	return PLUGIN_HANDLED;
}

public Open_New_Acc(id)
{
	new name[32], vaultkey[64], vaultdata[256], datalen
	get_user_name(id, name, 31)
	format(vaultkey, 63, "%s-ACC_PW", name)
	datalen = nvault_get(g_save, vaultkey, vaultdata, 255)
	
	if (datalen > 0)
	{
		copy(g_acc_pw[id], sizeof g_acc_pw[] - 1, vaultdata)
		g_login_acc[id] = true
		client_print(id, print_chat, "你已有帳號哦!")
		//client_print(id, print_chat, "在對話中輸入 登入你的玩家帳號")
		client_cmd(id,"messagemode /login")
	}
	else
	{
		g_new_acc[id] = true
		//client_print(id, print_chat, "在對話中輸入密碼,建立你的玩家帳號登入密碼")
		client_cmd(id,"messagemode /pw")
	}
}

public level_menu(id, key)
{
	switch (key)
	{
		case 0: stat_up(id)
/*
		case 4: level_pu_gw(id)
		case 5: if (Official_Version == 1 || Official_Version == 0 && Version_Can_Use_Key == 1) ammo_key_pu_gw(id)
*/
		case 4: level_re_set(id)
		case 8:
		{
			if (get_user_flags(id) & ACCESS_FLAG)
				admin_meun(id)
			else
				client_print(id, print_chat, "你沒有權限")
		}
	}
}

public stat_up(id)
{
	static menu[250], len
	len = 0
		
	len += formatex(menu[len], sizeof menu - 1 - len, "\y [ZP] Szkp80 屬性點分配 ^n選擇一項適合你的技能吧^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\w 強化攻擊 ^n^n")
		
	len += formatex(menu[len], sizeof menu - 1 - len, "\r2.\w 疾速換彈 ^n^n")

	len += formatex(menu[len], sizeof menu - 1 - len, "\r3.\w 穩定射擊 ^n^n")

//	len += formatex(menu[len], sizeof menu - 1 - len, "\r4.\w 防禦護甲 ^n^n")

	len += formatex(menu[len], sizeof menu - 1 - len, "^n^n \r0.\w  離開")
		
	show_menu(id, KEYSMENU, menu, -1, "Stat Menu")
}
public stat_menu(id, key)
{
	if (g_uppoints[id] <= 0)
	{
		client_print(id, print_chat, "屬性點不足!")
		return
	}
	switch (key)
	{
		case 0:
		{
			//加攻擊力
			g_dmglv[id]++
			g_uppoints[id]--
			Save_Level_data(id)
			client_print(id, print_chat, "你增加了攻擊力的等級, (1Lv = %f)", get_pcvar_float(cvar_hm_we_dam))
		}
		case 1:
		{
			//加換彈速
			g_reloadlv[id]++
			g_uppoints[id]--
			Save_Level_data(id)
			client_print(id, print_chat, "你增加了換彈速度的等級 (1Lv = %d)", get_pcvar_float(cvar_hm_we_timet))
		}
		case 2:
		{
			//降低後座力
			g_punchanglelv[id]++
			g_uppoints[id]--
			Save_Level_data(id)
			client_print(id, print_chat, "你增加了降低後座力的等級, (1Lv = %f)", get_pcvar_float(cvar_punchangle))
		}
	/*	case 3:
		{
			//增加護甲
			g_punchanglelv[id]++
			g_uppoints[id]--
			Save_Level_data(id)
			client_print(id, print_chat, "你增加了護甲的等級, (1Lv = %d)", get_pcvar_num(cvar_hm_armor))
		}
*/
		case 9:
		{
			return
		}
		default: stat_up(id)
	}
}
public level_pu_gw(id)
{
	set_hudmessage(255, 0, 255, 0.55, 0.75, 1, 6.0, 4.0, 1.0, 6.0, -1);
	show_hudmessage (id, "[Szkp80升級說明]人類每升lv.1傷害+0.05喪屍則是HP+5 最高等級-lv.100",
	get_pcvar_num(cvar_ta_hmlv), get_pcvar_float(cvar_hm_we_timet) , get_pcvar_num(cvar_hm_we_dam), get_pcvar_num(cvar_hm_armor), 
	get_pcvar_num(cvar_ta_zmlv), get_pcvar_num(cvar_zm_addhp), get_pcvar_float(cvar_zm_addape))
}

public ammo_key_pu_gw(id)
{
	set_hudmessage(255, 0, 255, 0.55, 0.75, 1, 6.0, 4.0, 1.0, 6.0, -1);
	show_hudmessage(id, "[Szkp80序號說明]序號不易拿到~可以用檢舉方式獲得!每個序號是隨機給X彈藥包最高300個 最低1個,比較容易獲得的是100~250包", 
	key_a[0], key_a[1], key_a[2], key_a[3], key_a[4], key_a[5], key_a[6], key_a[7], key_a[8], key_a[9], key_a[10], key_a[11], key_a[12], key_a[13], key_a[14],
	key_a[15], key_a[16], key_a[17], key_a[18], key_a[19], key_a[20])
}

public level_re_set(id)
{
	static menu[250], len
	len = 0
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\y 你是否要重置等級? ^n請慎重選擇!^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\w 是[我要重置] ^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r2.\w 否[我不想重練] ^n")
	
	show_menu(id, KEYSMENU, menu, -1, "LeveL Re")
}

public level_re_mmx(id, key)
{
	switch (key)
	{
		case 0:
		{
			level[id] = 1
			exp[id] = 0
			g_uppoints[id] = 0
			g_dmglv[id] = 0
			g_reloadlv[id] = 0
			g_punchanglelv[id] = 0
			g_armorlv[id] = 0

			for (new lv = 1; lv <= MAX_LV; lv++)
			{
				if (level[id] == lv)
				{
					new lv_nu = UPLV_EXP[lv]
					uplvexp[id] = lv_nu
				}
			}
			
			Save_Level_data(id)
			client_print(id, print_chat, "你已重置等級")
		}
	}
}

public admin_meun(id)
{
	static menu[250], len
	len = 0
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\y [Szkp80 SV 插件] 管理員選單 ^n^n")
	
	if (!exp_x2_nr)
	{
		if (exp_x2)
			len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\w 雙經系統 [現在:開啟] ^n")
		else
			len += formatex(menu[len], sizeof menu - 1 - len, "\r1.\w 雙經系統 [現在:關閉] ^n")
	}
	else
	{
		if (exp_x2)
			len += formatex(menu[len], sizeof menu - 1 - len, "\d1.\w 雙經系統 [下回合張關閉] ^n")
		else
			len += formatex(menu[len], sizeof menu - 1 - len, "\d1.\w 雙經系統 [下回合張開啟] ^n")
	}
	
	if (!g_5lv_exp_x2_nr)
	{
		if (g_5lv_exp_x2)
			len += formatex(menu[len], sizeof menu - 1 - len, "\r2.\w %d級以下雙經 系統 [現在:開啟] ^n", get_pcvar_num(cvar_expx2_lv))
		else
			len += formatex(menu[len], sizeof menu - 1 - len, "\r2.\w %d級以下雙經 系統 [現在:關閉] ^n", get_pcvar_num(cvar_expx2_lv))
	}
	else
	{
		if (g_5lv_exp_x2)
			len += formatex(menu[len], sizeof menu - 1 - len, "\d1.\w %d級以下雙經 [下回合張關閉] ^n", get_pcvar_num(cvar_expx2_lv))
		else
			len += formatex(menu[len], sizeof menu - 1 - len, "\d1.\w %d級以下雙經 [下回合張開啟] ^n", get_pcvar_num(cvar_expx2_lv))
	}
	


	if (Official_Version == 1 || Version_Can_Use_Key == 1 && Official_Version == 0)
		len += formatex(menu[len], sizeof menu - 1 - len, "\r3.\w 重新使用所有序號 ^n^n^n^n")
	
	len += formatex(menu[len], sizeof menu - 1 - len, "\r4.\w 設定玩家能力選單^n")

	len += formatex(menu[len], sizeof menu - 1 - len, "\r0.\w 離開")
	
	show_menu(id, KEYSMENU, menu, -1, "Adm Menu")
}

public adm_menu(id, key)
{
	switch (key)
	{
		case 0:
		{
			if (!exp_x2_nr)
			{
				if (exp_x2)
					client_print(id, print_chat, "雙經系統在下回合完結")
				else
					client_print(id, print_chat, "雙經系統在下回合開始")
				
				exp_x2_nr = true
			}
			else
				client_print(id, print_chat, "一回合只可改一次!! [可能被其他Adm改過]")
		}
		case 1:
		{
			if (!g_5lv_exp_x2_nr)
			{
				g_5lv_exp_x2_nr = true
				
				if (!g_5lv_exp_x2)
					client_print(id, print_chat, "已設定: %d級以下雙經 開啟", get_pcvar_num(cvar_expx2_lv))
				else
					client_print(id, print_chat, "已設定: %d級以下雙經 完結", get_pcvar_num(cvar_expx2_lv))
			}
			else
				client_print(id, print_chat, "一回合只可改一次!! [可能被其他Adm改過]")
		}
		case 2:
		{
			if (Official_Version == 1 || Official_Version == 0 && Version_Can_Use_Key == 1)
				all_key_false(id)
		}
		case 3:
		{
			admin_set_level_menu(id)
		}
	}
}

///////////////////////////////////////////////////////////
// Radio						//
/////////////////////////////////////////////////////////
Load_SUR_Radio_Data(config_file[])
{
	if (!file_exists(config_file))
	{
		log_amx("Cannot load customization file ^"%s^" !", config_file)
		return 0;
	}
	
	new i
	for (i = 0; i < 24; i++)
		SUR_Radio_Data_Num[i] = 0
	
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
		
		if (radio_set_index == -1 || SUR_Radio_Data_Num[radio_set_index] >= 5)
			continue;
		
		if (strtok(string, left_string, charsmax(left_string), right_string, charsmax(right_string), ':'))
		{
			trim(left_string)
			trim(right_string)
			
			if (strlen(right_string) > 0)
			{
				if (equal(left_string, "text"))
				{
					index = SUR_Radio_Data_Num[radio_set_index]
					copy(SUR_Radio_Text[radio_set_index][index], 64 - 1, right_string)
					get_text_data = true
				}
				else if (equal(left_string, "sound"))
				{
					if (get_text_data)
					{
						index = SUR_Radio_Data_Num[radio_set_index]
						copy(SUR_Radio_Sound[radio_set_index][index], 64 - 1, right_string)
						precache_sound(SUR_Radio_Sound[radio_set_index][index])
						SUR_Radio_Data_Num[radio_set_index]++
						get_text_data = false
					}
				}
			}
		}
	}
	
	return 1;
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
		ZM_Radio_Data_Num[i] = 0
	
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
		
		if (radio_set_index == -1 || ZM_Radio_Data_Num[radio_set_index] >= 5)
			continue;
		
		if (strtok(string, left_string, charsmax(left_string), right_string, charsmax(right_string), ':'))
		{
			trim(left_string)
			trim(right_string)
			
			if (strlen(right_string) > 0)
			{
				if (equal(left_string, "text"))
				{
					index = ZM_Radio_Data_Num[radio_set_index]
					copy(ZM_Radio_Text[radio_set_index][index], 64 - 1, right_string)
					get_text_data = true
				}
				else if (equal(left_string, "sound"))
				{
					if (get_text_data)
					{
						index = ZM_Radio_Data_Num[radio_set_index]
						copy(ZM_Radio_Sound[radio_set_index][index], 64 - 1, right_string)
						precache_sound(ZM_Radio_Sound[radio_set_index][index])
						ZM_Radio_Data_Num[radio_set_index]++
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

Load_ZM_Radio_Menu(config_file[]) //ZM_Radio_Menu_Desc
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
					copy(ZM_Radio_Menu_Title[0], 32 - 1, right_string)
				else if (equal(left_string, "Radio2_Title"))
					copy(ZM_Radio_Menu_Title[1], 32 - 1, right_string)
				else if (equal(left_string, "Radio3_Title"))
					copy(ZM_Radio_Menu_Title[2], 32 - 1, right_string)
				else if (equal(left_string, "Exit"))
					copy(ZM_Radio_Menu_Exit, 32 - 1, right_string)
				else
				{
					index = get_string_index(RADIO_MENU_TEXT, 21, left_string)
					if (index != -1)
						copy(ZM_Radio_Menu_Desc[index], 48 - 1, right_string)
				}
			}
		}
	}
	
	return 1;
}

Load_SUR_Radio_Menu(config_file[]) //SUR_Radio_Menu_Desc
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
					copy(SUR_Radio_Menu_Title[0], 32 - 1, right_string)
				else if (equal(left_string, "Radio2_Title"))
					copy(SUR_Radio_Menu_Title[1], 32 - 1, right_string)
				else if (equal(left_string, "Radio3_Title"))
					copy(SUR_Radio_Menu_Title[2], 32 - 1, right_string)
				else if (equal(left_string, "Exit"))
					copy(SUR_Radio_Menu_Exit, 32 - 1, right_string)
				else
				{
					index = get_string_index(RADIO_MENU_TEXT, 21, left_string)
					if (index != -1)
						copy(SUR_Radio_Menu_Desc[index], 48 - 1, right_string)
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
	
	if (msg_index != -1 && Szkp80_Login[sender])
	{
		set_msg_arg_int(1, get_msg_argtype(1), 0)
		set_msg_arg_string(2, "")
		set_msg_arg_string(3, "")
		set_msg_arg_string(4, "")
		set_msg_arg_string(5, "")
		
		radio_sound_off(id)
		
		static index
		if (zp_get_user_zombie(sender))
		{
			index = random_num(0, ZM_Radio_Data_Num[msg_index] - 1)
			send_user_radio(sender, id, ZM_Radio_Text[msg_index][index], ZM_Radio_Sound[msg_index][index], 1, 0)
		}
		else
		{
			if (zp_get_user_survivor(sender))
			{
				index = random_num(0, SUR_Radio_Data_Num[msg_index] - 1)
				send_user_radio(sender, id, SUR_Radio_Text[msg_index][index], SUR_Radio_Sound[msg_index][index], 1, 0)
			}
			else
			{
				index = random_num(0, Radio_Data_Num[msg_index] - 1)
				send_user_radio(sender, id, Radio_Text[msg_index][index], Radio_Sound[msg_index][index], 1, 0)
			}
		}
	}
}

public client_command(id)
{
	if (!Official_Version)
	{
		if (!Version_Can_Use_Radio)
			return PLUGIN_CONTINUE;
	}

	if (!Szkp80_Login[id])
		return PLUGIN_CONTINUE;

	if (!load_menu_file || !load_data_file || !zm_load_menu_file || !zm_load_data_file || !sur_load_menu_file || !sur_load_data_file)
		return PLUGIN_CONTINUE;
	
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	new cmd_string[32]
	read_argv(0, cmd_string, 31)
	
	if (equal(cmd_string, "radio1"))
	{
		if (zp_get_user_zombie(id)) zmenu_Radio1(id)
		else 
		{
			if (zp_get_user_survivor(id))
				sur_menu_Radio1(id)
			else
				menu_Radio1(id)
		}
		return PLUGIN_HANDLED_MAIN;
	}
	else if (equal(cmd_string, "radio2"))
	{
		if (zp_get_user_zombie(id)) zmenu_Radio2(id)
		else 
		{
			if (zp_get_user_survivor(id))
				sur_menu_Radio2(id)
			else
				menu_Radio2(id)
		}
		return PLUGIN_HANDLED_MAIN;
	}
	else if (equal(cmd_string, "radio3"))
	{
		if (zp_get_user_zombie(id)) zmenu_Radio3(id)
		else 
		{
			if (zp_get_user_survivor(id))
				sur_menu_Radio3(id)
			else
				menu_Radio3(id)
		}
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
	len = format(menu_text, menu_chars, "\y%s^n^n", ZM_Radio_Menu_Title[0])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", ZM_Radio_Menu_Desc[0])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", ZM_Radio_Menu_Desc[1])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", ZM_Radio_Menu_Desc[2])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", ZM_Radio_Menu_Desc[3])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", ZM_Radio_Menu_Desc[4])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", ZM_Radio_Menu_Desc[5])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", ZM_Radio_Menu_Exit)
	
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<9)
	
	show_menu(id, keys, menu_text, -1, "Radio1 Menu")
}

sur_menu_Radio1(id)
{
	new menu_text[256], len
	new menu_chars = charsmax(menu_text)
	len = format(menu_text, menu_chars, "\y%s^n^n", SUR_Radio_Menu_Title [0])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", SUR_Radio_Menu_Desc[0])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", SUR_Radio_Menu_Desc[1])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", SUR_Radio_Menu_Desc[2])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", SUR_Radio_Menu_Desc[3])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", SUR_Radio_Menu_Desc[4])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", SUR_Radio_Menu_Desc[5])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", SUR_Radio_Menu_Exit)
	
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
	len = format(menu_text, menu_chars, "\y%s^n^n", ZM_Radio_Menu_Title[1])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", ZM_Radio_Menu_Desc[6])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", ZM_Radio_Menu_Desc[7])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", ZM_Radio_Menu_Desc[8])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", ZM_Radio_Menu_Desc[9])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", ZM_Radio_Menu_Desc[10])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", ZM_Radio_Menu_Desc[11])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", ZM_Radio_Menu_Exit)
	
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<9)
	
	show_menu(id, keys, menu_text, -1, "Radio2 Menu")
}

sur_menu_Radio2(id)
{
	new menu_text[256], len
	new menu_chars = charsmax(menu_text)
	len = format(menu_text, menu_chars, "\y%s^n^n", SUR_Radio_Menu_Title[1])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", SUR_Radio_Menu_Desc[6])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", SUR_Radio_Menu_Desc[7])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", SUR_Radio_Menu_Desc[8])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", SUR_Radio_Menu_Desc[9])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", SUR_Radio_Menu_Desc[10])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", SUR_Radio_Menu_Desc[11])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", SUR_Radio_Menu_Exit)
	
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
	len = format(menu_text, menu_chars, "\y%s^n^n", ZM_Radio_Menu_Title[2])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", ZM_Radio_Menu_Desc[12])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", ZM_Radio_Menu_Desc[13])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", ZM_Radio_Menu_Desc[14])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", ZM_Radio_Menu_Desc[15])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", ZM_Radio_Menu_Desc[16])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", ZM_Radio_Menu_Desc[17])
	len += format(menu_text[len], menu_chars - len, "\w7. %s^n", ZM_Radio_Menu_Desc[18])
	len += format(menu_text[len], menu_chars - len, "\w8. %s^n", ZM_Radio_Menu_Desc[19])
	len += format(menu_text[len], menu_chars - len, "\w9. %s^n", ZM_Radio_Menu_Desc[20])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", ZM_Radio_Menu_Exit)
	
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
	
	show_menu(id, keys, menu_text, -1, "Radio3 Menu")
}

sur_menu_Radio3(id)
{
	new menu_text[384], len
	new menu_chars = charsmax(menu_text)
	len = format(menu_text, menu_chars, "\y%s^n^n", SUR_Radio_Menu_Title[2])
	len += format(menu_text[len], menu_chars - len, "\w1. %s^n", SUR_Radio_Menu_Desc[12])
	len += format(menu_text[len], menu_chars - len, "\w2. %s^n", SUR_Radio_Menu_Desc[13])
	len += format(menu_text[len], menu_chars - len, "\w3. %s^n", SUR_Radio_Menu_Desc[14])
	len += format(menu_text[len], menu_chars - len, "\w4. %s^n", SUR_Radio_Menu_Desc[15])
	len += format(menu_text[len], menu_chars - len, "\w5. %s^n", SUR_Radio_Menu_Desc[16])
	len += format(menu_text[len], menu_chars - len, "\w6. %s^n", SUR_Radio_Menu_Desc[17])
	len += format(menu_text[len], menu_chars - len, "\w7. %s^n", SUR_Radio_Menu_Desc[18])
	len += format(menu_text[len], menu_chars - len, "\w8. %s^n", SUR_Radio_Menu_Desc[19])
	len += format(menu_text[len], menu_chars - len, "\w9. %s^n", SUR_Radio_Menu_Desc[20])
	len += format(menu_text[len], menu_chars - len, "^n\w0. %s", SUR_Radio_Menu_Exit)
	
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
	
	new hm_msg_index, zm_msg_index, sur_msg_index
	
	hm_msg_index = get_string_index(RADIO_MSG_TEXT, 24, msg_str)
	zm_msg_index = get_string_index(RADIO_MSG_TEXT, 24, msg_str)
	sur_msg_index = get_string_index(RADIO_MSG_TEXT, 24, msg_str)

	if (hm_msg_index != -1 || zm_msg_index != -1 || sur_msg_index != -1)
	{
		if(!zp_get_user_zombie(sender))
		{
			if (zp_get_user_survivor(sender))
			{
				new index = random_num(0, SUR_Radio_Data_Num[sur_msg_index] - 1)
				send_radio_group(sender, SUR_Radio_Text[sur_msg_index][index], SUR_Radio_Sound[sur_msg_index][index])
			}
			else
			{
				new index = random_num(0, Radio_Data_Num[hm_msg_index] - 1)
				send_radio_group(sender, Radio_Text[hm_msg_index][index], Radio_Sound[hm_msg_index][index])
			}
		}
		else
		{
			new index = random_num(0, ZM_Radio_Data_Num[zm_msg_index] - 1)
			send_radio_group(sender, ZM_Radio_Text[zm_msg_index][index], ZM_Radio_Sound[zm_msg_index][index])
		}
		show_radio_sprite(sender)
		NextSendRadioTime[sender] = get_gametime() + Send_Radio_Cooldown
	}
}

///////////////////////////////////////////////////////////
// Ham Bot						//
/////////////////////////////////////////////////////////
new bool:BotHasDebug = false
public client_putinserver(id)
{
	set_task(2.0, "now_can_save", id)
	
	if (!cvar_botquota || !is_user_bot(id) || BotHasDebug)
		return;
	
	new classname[32]
	pev(id, pev_classname, classname, 31)
	
	if (!equal(classname, "player"))
		set_task(0.1, "_Debug", id)
}

public _Debug(id)
{
	// Make sure it's a CZ bot and it's still connected
	if (!get_pcvar_num(cvar_botquota) || !is_user_connected(id))
		return;
	
	BotHasDebug = true
	
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}

///////////////////////////////////////////////////////////
// Native 						//
/////////////////////////////////////////////////////////
public native_get_level(id)
{
	return level[id];
}

public native_get_exp(id)
{
	return exp[id];
}

public native_get_uplv_exp(id)
{
	return uplvexp[id];
}

public native_max_lv()
{
	return g_max_lv;
}


public native_get_salevel(id)
{
	return sa_level[id];
}

public native_get_saexp(id)
{
	return sa_exp[id];
}

public native_get_uplv_saexp(id)
{
	return sa_uplvexp[id];
}

public native_max_salv()
{
	return g_max_salv;
}


public native_get_ammo(id)
{
	return g_ammo[id];
}

public native_menu(id)
{
	lv_muse(id)
}

public native_login(id)
{
	return Szkp80_Login[id];
}

public native_get_armorlv(id)
{
	return g_armorlv[id];
}
public native_get_punchanglelv(id)
{
	return g_punchanglelv[id];
}
public native_get_reloadlv(id)
{
	return g_reloadlv[id];
}
public native_get_dmglv(id)
{
	return g_dmglv[id];
}
public native_get_points(id)
{
	return g_uppoints[id];
}
///////////////////////////////////////////////////////////
// stock						//
/////////////////////////////////////////////////////////
stock fm_get_weaponid(entity)
{
	return get_pdata_int(entity, OFFSET_iWeapId, OFFSET_LINUX_WEAPONS);
}

stock get_weapon_in_reload(entity)
{
	return get_pdata_int(entity, OFFSET_iWeapInReload, OFFSET_LINUX_WEAPONS);
}

stock Float:get_user_next_attack(id)
{
	return get_pdata_float(id, OFFSET_flNextAttack, OFFSET_LINUX)
}

stock set_user_next_attack(id, Float:time)
{
	set_pdata_float(id, OFFSET_flNextAttack, time, OFFSET_LINUX)
}

stock set_weapon_idle_time(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flTimeWeaponIdle, time, OFFSET_LINUX_WEAPONS)
}


stock radio_sound_off(id)
{
	message_begin(MSG_ONE, g_msgid_SendAudio, {0, 0, 0}, id)
	write_byte(0)
	write_string("%!MRAD_")
	write_short(32767)
	message_end()
}

stock send_radio_group(sender, const message[], const sound_file[])
{
/*
	new i, maxplayers, team1, team2
	maxplayers = get_maxplayers()
	team1 = fm_get_user_team(sender)
	for (i = 1; i <= maxplayers; i++)
	{
		if (!is_user_connected(i) || !is_user_alive(i))
			continue;
		
		team2 = fm_get_user_team(i)
		if (team2 == 0 || team2 == 3) continue;
		if (team1 != team2) continue;
		
		send_user_radio(sender, i, message, sound_file, 1, 2)
	}
*/
	
	new i, maxplayers, id_m, i_m
	maxplayers = get_maxplayers()
	id_m = zp_get_user_zombie(sender)
	for (i = 1; i <= maxplayers; i++)
	{
		if (!is_user_connected(i) || !is_user_alive(i))
			continue;
		
		i_m = zp_get_user_zombie(i)
		
		if (id_m == 1 && i_m == 1 || id_m == 0 && i_m == 0)
			send_user_radio(sender, i, message, sound_file, 1, 0)
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

stock Float:fm_get_user_maxspeed(index) {
	new Float:speed;
	pev(index, pev_maxspeed, speed);

	return speed;
}

stock fm_get_user_team(id)
{
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}

// Set a Player's Team
stock fm_set_user_team(id, team)
{
	set_pdata_int(id, OFFSET_CSTEAMS, team, OFFSET_LINUX)
}

stock fm_set_user_frags(index, frags) {
	set_pev(index, pev_frags, float(frags));

	return 1;
}


stock fm_set_user_maxspeed(index, Float:speed = -1.0) {
	engfunc(EngFunc_SetClientMaxspeed, index, speed);
	set_pev(index, pev_maxspeed, speed);

	return 1;
}

stock fm_set_user_deaths(id, value)
{
	set_pdata_int(id, OFFSET_CSDEATHS, value, OFFSET_LINUX)
}

stock fm_set_user_health(index, health) {
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);

	return 1;
}

stock fm_set_user_armor(index, armor) {
	set_pev(index, pev_armorvalue, float(armor));

	return 1;
}

stock user_silent_kill(id)
{
	static msgid = 0;
	new msgblock;
	if (!msgid) msgid = get_user_msgid("DeathMsg");

	msgblock = get_msg_block(msgid);
	set_msg_block(msgid, BLOCK_ONCE);

	dllfunc(DLLFunc_ClientKill, id);

	set_msg_block(msgid, msgblock);

	return 1;
}

stock show_radio_sprite(id)  //zp_get_user_zombie
{
	new i, maxplayers, id_m, i_m
	maxplayers = get_maxplayers()
	id_m = zp_get_user_zombie(id)
	for (i = 1; i <= maxplayers; i++)
	{
		if (!is_user_connected(i) || !is_user_alive(i))
			continue;
		
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
	}
}
