/*================================================================================
* Please don't change plugin register information.
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>
#include <xs>
#include <engine>
//#include <sexplugins>

/*   17/5/2010  */

#define PLUGIN_NAME 	"[ZP] Extra:Super M4A1(CSO:Super SVD)"
#define PLUGIN_VERSION	"1.0 (2.4)"
#define PLUGIN_AUTHOR	"Jim (HsK)"	//原創為 yy大....本人只是修改 ^^"

//===============================================================================================================================

#define SUPPORT_BOT_TO_USE			//支援BOT使用.(在最前面加上 // 即取消對BOT的技援)
#define SUPPORT_CZBOT				//支援CZBot的使用.(在最前面加上 // 即取消這項設定)

#define TASK_CHOOSE_HERO 797979

#if defined SUPPORT_BOT_TO_USE
#define BOT_TASK_ID_1	i+3344
#define BOT_USER_ID_1	taskid-3344
#endif

#define TASK_ID_1	ent+4321
//===============================================================================================================================

// Item name & cost
new g_item_name[] = { "英雄戰擊" } //道具名稱
new g_item_cost = 20 //購買"英雄戰擊"要花多少子彈包
new g_m203_ammo_cost = 5 //購買M203槍榴彈彈藥1次要花多少子彈包
new g_m203_ammo_num = 1 //購買M203彈藥一次可購得多少發槍榴彈

const Float:Damage_Human_Multiplier = 0.05 	//對人類造成的傷害數值的乘數
const Float:Damage_Survivor_Multiplier = 0.02 	//對倖存者造成的傷害數值的乘數

// SuperMan model
new const SUPER_MAN_MODEL[] = { "SVDPEP" } 					// 英雄的人物模型

// SuperMan SVD model & sound
new const SuperMan_SVD_V_Model[] = { "models/zombie_plague/v_svdex.mdl" } 	//英雄戰擊的v_模型
new const SuperMan_SVD_P_Model[] = { "models/zombie_plague/p_svdex.mdl" } 	//英雄戰擊的p_模型
new const M4A1_V_Model[] = { "models/v_m4a1.mdl" } 				//原始M4A1的v_模型
new const M4A1_P_Model[] = { "models/p_m4a1.mdl" } 				//原始M4A1的p_模型
new const SuperMan_SVD_Switch_Sound[] = { "common/wpn_select.wav" } 		//切換使用或不使用M203模式時的聲音
new const SVD_weapons[] = { "weapons/svdex-1.wav" }				//英雄戰擊開火的聲音

// M203 model & sound
//new const g_M203_sprites[] = { "scope_vip_grenade" }				//準心spr
new const M203_Grenade_Model[] = { "models/zombie_plague/m203_grenade.mdl" } 	//M203槍榴彈的模型
new const M203_Launch_Sound[][] = { "weapons/glauncher.wav", "weapons/glauncher2.wav" } //M203射出槍榴彈時的聲音
new const M203_CantShoot_Sound[] = { "common/wpn_denyselect.wav" } 		//因前方視角距離太近時,無法射擊的警告聲音
new const M203_Dryfire_Sound[] = { "weapons/dryfire1.wav" } 			//槍榴彈用完時,扣板機時的聲音
new const M203_Reload_Sound[] = { "items/ammopickup1.wav" } 			//裝填槍榴彈完成時的聲音
new const GrenadeHit_Sound[][] = { "weapons/grenade_hit1.wav", "weapons/grenade_hit2.wav", "weapons/grenade_hit3.wav" } //槍榴彈撞到東西時的聲音
new const GrenadeHitBody_Sound[][] = { "player/pl_slosh1.wav", "player/pl_slosh2.wav", "player/pl_slosh3.wav", "player/pl_slosh4.wav" } //槍榴彈撞到玩家時的聲音
new const GrenadeExplode_Sound[][] = { "weapons/explode3.wav", "weapons/explode4.wav", "weapons/explode5.wav" } //槍榴彈爆炸時的聲音
new const BuyGrenade_Sound[] = { "items/9mmclip2.wav"	} 			//購買槍榴彈時的聲音

#if defined SUPPORT_BOT_TO_USE
// Bot use weapon bitsums #設定BOT如果持有那些槍就不會再購買或撿取英雄戰擊
const BOT_USE_WEAPONS_BIT_SUM = (1<<CSW_SG550)|(1<<CSW_AWP)|(1<<CSW_M249)|(1<<CSW_G3SG1)
#endif

// Weapons Offsets (win32)
const OFFSET_FlNextPrimaryAttack = 46
const OFFSET_FlNextSecondaryAttack = 47
const OFFSET_FlTimeWeaponIdle = 48
const OFFSET_WeapInReload = 54
const OFFSET_FlNextAttack = 83
const OFFSET_iWeapId = 43
const OFFSET_iClipAmmo = 51

// Linux diff's
const OFFSET_MODELINDEX = 491 // by Orangutanz
const OFFSET_LINUX = 5 // offsets 5 higher in Linux builds
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux

// Primary Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|
	(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|
	(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

new const GUNSHOT_DECALS[] = {41, 42, 43, 44, 45}
const m_flKnown = 44
const m_flNextSecondaryAttack = 47
const m_weapId = 43
const m_flNextPrimaryAttack = 46

// Cvars
new g_itemid_ssvd
new cvar_M203_GiveAmmo, cvar_M203_MaxAmmo, cvar_M203_ReloadTime, cvar_M203_MaxDmg, cvar_M203_MinDmg, cvar_M203_HitDmg, cvar_M203_DmgRange,
cvar_M203_KilledAmmopack, cvar_M203_KilledFrags
new cvar_dmg_12, cvar_DmgMultiplier, cvar_svd_dmg_head, cvar_svd_dmg_chest, cvar_svd_dmg_stomach, cvar_svd_dmg_arm, 
cvar_svd_dmg_leg, cvar_ssvd_wmc, cvar_m4a1_wmc, cvar_M203_OnTime, cvar_M203_OffTime, cvar_M203_Start_Speed, cvar_M203_Explode_Knockback,
cvar_SVD_Knockback, cvar_svd_att_time, cvar_M203_dmg_fd, cvar_M203_flag_ptd, cvar_svd_buy

new maxplayers, g_round_ssvd
new g_explodeSpr, g_trailSpr, g_blastSpr, g_msgScreenShake, g_msgScreenFade
new g_msgDeathMsg, g_msgScoreAttrib, g_msgScoreInfo, g_msgSync

new bool:freeze_time_over
new bool:round_end
new bool:g_has_ssvd[33]
new bool:use_m203[33], m203_ammo[33]
new bool:m203_ready[33], bool:m203_reload[33], Float:m203_ready_time[33]
new Float:show_msg_time[33]
new user_weapon[33]
new bool:m203_shoot[33]
new g_player_model[33][32]
new modelindex[sizeof SUPER_MAN_MODEL]
new bool:g_svd_mode_ian[33], bool:g_svd_m203att_ian[33]
new bool:g_mod_ab_ing[33]

#if defined SUPPORT_BOT_TO_USE
new Float:bot_next_attack_time[33]
#endif

#if defined SUPPORT_CZBOT
new cvar_botquota
#endif

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	
	g_itemid_ssvd = zp_register_extra_item(g_item_name, g_item_cost, ZP_TEAM_HUMAN)

	//重要
	cvar_svd_buy = register_cvar("zp_svd_buy", "1")				//可不可買 英雄戰擊 [0=不可, 1=可]
	cvar_m4a1_wmc = register_cvar("zp_m4a1_svd_wmc", "50")			//原本的m4a1的子彈量
	cvar_M203_OnTime = register_cvar("zp_ssvd_m203_ontime", "1.01")		//開啟M203模式時間
	cvar_M203_OffTime = register_cvar("zp_ssvd_m203_offtime", "1.35")	//關閉M203模式時間
	
	//SVD
	cvar_ssvd_wmc = register_cvar("zp_svd_wmc", "20")			//英雄戰擊子彈量
	cvar_SVD_Knockback  = register_cvar("zp_svd_Knockback", "16.0")	   	//武器擊退的威力數值
	cvar_svd_att_time = register_cvar("zp_svd_att_time", "0.45")	   	//射擊間距[秒]
	cvar_dmg_12 = register_cvar("zp_svd_dmg", "2")				//武器傷害加乘 
										//[0=沒有,1=攻擊力以倍率計, 2=命中不同地方有不同傷害]

	cvar_DmgMultiplier = register_cvar("zp_svd_dmgmultiplier", "8.0")	//武器傷害加乘數值  	(攻擊力以倍率計)

	cvar_svd_dmg_head = register_cvar("zp_ssvd_dmg_head", "2300") 		// 命中頭部的傷害值數值 (命中不同地方有不同傷害)
	cvar_svd_dmg_chest = register_cvar("zp_ssvd_dmg_chest", "1500") 	// 命中胸部的傷害值數值 (命中不同地方有不同傷害)
	cvar_svd_dmg_stomach = register_cvar("zp_ssvd_dmg_stomach", "1200") 	// 命中腹部的傷害值數值 (命中不同地方有不同傷害)
	cvar_svd_dmg_arm = register_cvar("zp_ssvd_dmg_arm", "800") 		// 命中手部傷害值數值   (命中不同地方有不同傷害)
	cvar_svd_dmg_leg = register_cvar("zp_ssvd_dmg_leg", "800") 		// 命中腳部的傷害值數值 (命中不同地方有不同傷害)

	//M203
	cvar_M203_GiveAmmo = register_cvar("zp_svd_m203_ammo", "10")		//購買英雄戰擊後會同時配給幾發M203槍榴彈彈藥
	cvar_M203_MaxAmmo = register_cvar("zp_svd_m203_maxammo", "10")		//最多可攜帶多少發M203槍榴彈彈藥
	cvar_M203_ReloadTime = register_cvar("zp_svd_m203_reloadtime", "2.65") 	//M203槍榴彈發射後的重新裝彈時間(單位:秒)
	cvar_M203_MaxDmg = register_cvar("zp_svd_m203_maxdmg", "2000") 		//M203槍榴彈爆炸後造成的最大傷害數值
	cvar_M203_MinDmg = register_cvar("zp_svd_m203_mindmg", "100") 		//M203槍榴彈爆炸後造成的最小傷害數值
	cvar_M203_HitDmg = register_cvar("zp_svd_m203_hitdmg", "1500") 		//被M203槍榴彈直接擊中的傷害數值
	cvar_M203_DmgRange = register_cvar("zp_svd_m203_dmgrange", "225") 	//M203槍榴彈爆炸後造成傷害的範圍距離
	cvar_M203_Start_Speed = register_cvar("zp_svd_m203_start_speed", "1300")	//M203槍榴彈射出的最初速度
	cvar_M203_Explode_Knockback = register_cvar("zp_svd_m203_explode_knockback", "300") //爆炸時震退效果的力量數值.(設定成 0 代表無震退效果)
	cvar_M203_dmg_fd = register_cvar("zp_svd_m203_dmg_fd", "0")		//M203槍榴彈 傷害會不會隊友 [0=不會, 1=會]
	cvar_M203_flag_ptd = register_cvar("zp_svd_m203_flag_ptd", "1")		//M203槍榴彈 未過保險時間(0.5秒) 碰撞後會不會爆炸 [0=不會, 1=會]
	cvar_M203_KilledAmmopack = register_cvar("zp_svd_m203_killedammopack", "3")	//用榴彈殺死一個敵人能得到多少子彈包
	cvar_M203_KilledFrags = register_cvar("zp_svd_m203_killedfrags", "3")		//用榴彈殺死一個敵人殺敵數增加數

	RegisterHam(Ham_Item_AttachToPlayer, "weapon_m4a1", "Item_AttachToPlayer")
	RegisterHam(Ham_Item_PostFrame, "weapon_m4a1", "Item_PostFrame")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Item_PostFrame, "weapon_m4a1", "fw_Item_PostFrame", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_m4a1", "fw_WeapSecAttack", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_WeapPriAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_WeapPriAttack_1", 1)

	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged")

	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0")
	register_event("CurWeapon","event_CurWeapon", "be", "1=1")
	register_logevent("logevent_RoundStart",2, "1=Round_Start")
	register_logevent("logevent_RoundEnd", 2, "1=Round_End")

	register_clcmd("superman_not_svd", "superman_svd")

	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	g_msgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	g_msgSync = CreateHudSyncObj()
	maxplayers = get_maxplayers()

	#if defined SUPPORT_CZBOT
	cvar_botquota = get_cvar_pointer("bot_quota")
	#endif
}

public plugin_precache()
{
	new i, model[100]
	for (i = 0; i < sizeof SUPER_MAN_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", SUPER_MAN_MODEL, SUPER_MAN_MODEL)
		modelindex[i] = precache_model(model)
	}
	precache_model(SuperMan_SVD_V_Model)
	precache_model(SuperMan_SVD_P_Model)
	precache_model(M4A1_V_Model)
	precache_model(M4A1_P_Model)
	precache_model(M203_Grenade_Model)

	for (i = 0; i < sizeof M203_Launch_Sound; i++)
		precache_sound(M203_Launch_Sound[i])
	
	precache_sound(SuperMan_SVD_Switch_Sound)
	precache_sound(SVD_weapons)
	precache_sound(M203_CantShoot_Sound)
	precache_sound(M203_Dryfire_Sound)
	precache_sound(M203_Reload_Sound)
	precache_sound(BuyGrenade_Sound)
	
	for (i = 0; i < sizeof GrenadeHit_Sound; i++)
		precache_sound(GrenadeHit_Sound[i])
	
	for (i = 0; i < sizeof GrenadeHitBody_Sound; i++)
		precache_sound(GrenadeHitBody_Sound[i])
	
	for (i = 0; i < sizeof GrenadeExplode_Sound; i++)
		precache_sound(GrenadeExplode_Sound[i])
	
	g_explodeSpr = precache_model("sprites/zerogxplode.spr")
	g_trailSpr = precache_model("sprites/smoke.spr")
	g_blastSpr = precache_model("sprites/white.spr")
}

public zp_extra_item_selected(id, itemid)
{
	if (get_pcvar_num(cvar_svd_buy) == 1)
	{
		if (itemid == g_itemid_ssvd)
		{
			if (g_has_ssvd[id])
			{
				zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + g_item_cost)
				client_print(id, print_chat, "[ZP] 你已經有英雄戰擊了.")
			}
			else
			{
				give_user_ssvd(id)

				new name[32];
				get_user_name(id, name, 31)
				client_print(0, print_center, "[%s]使用子彈包令自己變為英雄", name)
			}
		}
	}
}

give_user_ssvd(id)
{
	drop_primary_weapons(id)
	
	g_has_ssvd[id] = true
	use_m203[id] = false
	m203_ammo[id] = get_pcvar_num(cvar_M203_GiveAmmo)
	m203_ready[id] = true
	m203_shoot[id] = false

/*	伺服器lag bug
	zp_set_player_model(id, 0)
	sex_player_model_set(id, 0)
*/
	new iWep = give_item(id, "weapon_m4a1")
	if( iWep > 0 )
	{
		cs_set_weapon_ammo(iWep, get_pcvar_num(cvar_ssvd_wmc))
	}
	fm_give_item(id, "ammo_556nato")
	fm_give_item(id, "ammo_556nato")
	fm_give_item(id, "ammo_556nato")
	fm_give_item(id, "ammo_556nato")
	fm_give_item(id, "ammo_556nato")
	fm_give_item(id, "ammo_556nato")
	engclient_cmd(id, "weapon_m4a1")

	if (get_pcvar_num(cvar_dmg_12) == 0)
		client_print(id, print_chat, "[ZP] 你已購買了英雄戰擊!")

	if (get_pcvar_num(cvar_dmg_12) == 1)
		client_print(id, print_chat, "[ZP] 你已購買了英雄戰擊! (攻擊力變%.1f倍)", get_pcvar_float(cvar_DmgMultiplier))

	if (get_pcvar_num(cvar_dmg_12) == 2)
		client_print(id, print_chat, "[ZP] 你已購買了英雄戰擊! (傷害值:頭部[%d],胸部[%d],腹部[%d],手部[%d],腳部[%d]",
		floatround(get_pcvar_float(cvar_svd_dmg_head)), floatround(get_pcvar_float(cvar_svd_dmg_chest)), 
		floatround(get_pcvar_float(cvar_svd_dmg_stomach)), floatround(get_pcvar_float(cvar_svd_dmg_arm)), 
		floatround(get_pcvar_float(cvar_svd_dmg_leg)))

	client_print(id, print_chat, "[ZP] 按^"滑鼠右鍵^"可切換為M203攻擊模式發射槍榴彈.")

	set_task(0.2, "set_user_model", id+7278966)
}

public set_user_model(taskid)
{
	new id = taskid - 7278966

	new SetModel = random_num(0, sizeof SUPER_MAN_MODEL)
	if (SetModel > 0)
	{
		if (g_has_ssvd[id] && !zp_get_user_zombie(id))
		{
			new index = SetModel - 1
			copy(g_player_model[id], charsmax(g_player_model[]), SUPER_MAN_MODEL)
			fm_set_user_model(id, g_player_model[id])
			fm_set_user_model_index(id, modelindex[index])
		}
	}
}

public fw_ClientUserInfoChanged(id)
{
//	if (!zp_get_player_model(id) && !sex_player_model(id))   伺服器lag bug
	if (g_has_ssvd[id] && !zp_get_user_zombie(id))
	{
		static current_model[32]
		fm_get_user_model(id, current_model, charsmax(current_model))
		
		if (!equal(current_model, g_player_model[id]))
			fm_set_user_model(id, g_player_model[id])
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	if (zp_get_user_zombie(victim) == zp_get_user_zombie(attacker))
		return HAM_IGNORED;
	
	if (!(damage_type & DMG_BULLET))
		return HAM_IGNORED;
	
	if (!g_has_ssvd[attacker] || (get_user_weapon(attacker) != CSW_M4A1))
		return HAM_IGNORED;
	
	if (get_pcvar_num(cvar_dmg_12) != 0)
	{
		if (get_pcvar_num(cvar_dmg_12) == 1)
			SetHamParamFloat(4, damage * get_pcvar_float(cvar_DmgMultiplier))
		else if (get_pcvar_num(cvar_dmg_12) == 2)
		{
			static use_weapon, hitzone
			get_user_attacker(victim, use_weapon, hitzone)
			
			switch (hitzone)
			{
				case 1: damage = get_pcvar_float(cvar_svd_dmg_head);
				case 2: damage = get_pcvar_float(cvar_svd_dmg_chest);
				case 3: damage = get_pcvar_float(cvar_svd_dmg_stomach);
				case 4: damage = get_pcvar_float(cvar_svd_dmg_arm);
				case 5: damage = get_pcvar_float(cvar_svd_dmg_arm);
				case 6: damage = get_pcvar_float(cvar_svd_dmg_leg);
				case 7: damage = get_pcvar_float(cvar_svd_dmg_leg);
			}
		}
		SetHamParamFloat(4, damage)
	}

	return HAM_IGNORED;
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	// Prevent friendly fire
	if (zp_get_user_zombie(attacker) == zp_get_user_zombie(victim))
		return HAM_IGNORED;
	
	// Victim isn't a normal zombie
	if (!zp_get_user_zombie(victim) || zp_get_user_nemesis(victim))
		return HAM_IGNORED;
	
	// Knockback disabled or not bullet damage
	if (!(damage_type & DMG_BULLET) || !get_cvar_num("zp_knockback"))
		return HAM_IGNORED;
	
	if (!g_has_ssvd[attacker] || (get_user_weapon(attacker) != CSW_M4A1))
		return HAM_IGNORED;
	
	// Get victim flags and knockback while ducking setting
	static victimflags, Float:knockduck
	victimflags = pev(victim, pev_flags)
	knockduck = get_cvar_float("zp_knockback_ducking")
	
	// Zombie is ducking on ground
	if (knockduck == 0.0 && (victimflags & FL_DUCKING) && (victimflags & FL_ONGROUND))
		return HAM_IGNORED;
	
	// Get distance between players
	static Float:origin1F[3], Float:origin2F[3]
	pev(victim, pev_origin, origin1F)
	pev(attacker, pev_origin, origin2F)
	
	// Max distance exceeded
	if (get_distance_f(origin1F, origin2F) > get_cvar_float("zp_knockback_distance"))
		return HAM_IGNORED;
	
	// Get victim's velocity
	static Float:velocity[3]
	pev(victim, pev_velocity, velocity)
	
	// Use damage on knockback calculation
	if (get_cvar_num("zp_knockback_damage"))
		xs_vec_mul_scalar(direction, damage, direction)
	
	// Use weapon power on knockback calculation
	if (get_pcvar_float(cvar_SVD_Knockback) > 0.0 && get_cvar_num("zp_knockback_power"))
		xs_vec_mul_scalar(direction, get_pcvar_float(cvar_SVD_Knockback), direction)
	
	// Apply ducking knockback multiplier
	if ((victimflags & FL_DUCKING) && (victimflags & FL_ONGROUND))
		xs_vec_mul_scalar(direction, knockduck, direction)
	
	// Add up the new vector
	xs_vec_add(velocity, direction, direction)
	
	// Should knockback also affect vertical velocity?
	if (!get_cvar_num("zp_knockback_zvel"))
		direction[2] = velocity[2]
	
	// Set the knockback'd victim's velocity
	set_pev(victim, pev_velocity, direction)
	
	SetHamParamVector(4, Float:{0.0, 0.0, 0.0})
	
	return HAM_IGNORED;
}

public fw_Item_PostFrame(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	static id
	id = pev(weapon, pev_owner)
	
	if (use_m203[id])
	{
		set_weapon_next_pri_attack(weapon, 0.5)
		set_weapon_next_sec_attack(weapon, 0.5)
	}
	
	return HAM_IGNORED;
}

public fw_WeapSecAttack(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	static id
	id = pev(weapon, pev_owner)
	
	if (g_has_ssvd[id] && !use_m203[id])
	{
		cs_set_weapon_silen(weapon, 0, 0)
		set_weapon_next_pri_attack(weapon, 0.0)
	}
	
	return HAM_IGNORED;
}

public fw_Touch(ptr, ptd)
{
	if (!pev_valid(ptr))
		return FMRES_IGNORED;
	
	new classname[32]
	pev(ptr, pev_classname, classname, charsmax(classname))

	if (equal(classname, "zp_M203_Grenade"))
	{
		new Float:origin[3], Float:velocity[3]
		pev(ptr, pev_origin, origin)
		pev(ptr, pev_velocity, velocity)
		new ent_speed = floatround(vector_length(velocity))

		if (get_pcvar_num(cvar_M203_flag_ptd) == 0)
		{
			new insurance_flag = pev(ptr, pev_iuser4)
			if (insurance_flag)
			{
				M203_grenade_detonate(ptr)
				return FMRES_IGNORED;
			}
		}

		if (get_pcvar_num(cvar_M203_flag_ptd) == 1)
		{
			M203_grenade_detonate(ptr)
		}
		
		if (get_pcvar_num(cvar_M203_flag_ptd) == 0)
		{
			set_pev(ptr, pev_iuser2, 0) //設定記錄M203槍榴彈為已經過第一次碰撞過後的狀態flag
			set_pev(ptr, pev_iuser3, 0) //設定記錄M203槍榴彈為剛剛有碰撞過的狀態flag
			
			if ((1 <= ptd <= 32) && is_user_alive(ptd)) //碰撞到玩家
			{
				engfunc(EngFunc_EmitSound, ptr, CHAN_VOICE, GrenadeHitBody_Sound[random_num(0, sizeof GrenadeHitBody_Sound - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				xs_vec_mul_scalar(velocity, 0.3, velocity) //設定碰撞過後的M203槍榴彈的速度為降為原本的30%
				set_pev(ptr, pev_velocity, velocity)
				
				new set_speed  = max(ent_speed - 800, 0) //計算玩定被槍榴彈直接擊中身體時的彈開速度
				if (set_speed > 0)
				{
					get_speed_vector_point_entity(origin, ptd, set_speed, velocity)
					
					set_pev(ptd, pev_velocity, velocity)
				}
				
				if (ent_speed >= 800 && !round_end) //若槍榴彈撞擊玩家時的速度大於800,玩家將會受到撞擊傷害
				{
					new damage = floatround(get_pcvar_float(cvar_M203_HitDmg) * (float(ent_speed) / float(get_pcvar_num(cvar_M203_Start_Speed))))
					new attacker = pev(ptr, pev_iuser1)
					grenade_hit_damage(ptd, attacker, damage, ptr)
				}
			} 
			else 
			{
				engfunc(EngFunc_EmitSound, ptr, CHAN_VOICE, GrenadeHit_Sound[random_num(0, sizeof GrenadeHit_Sound - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				xs_vec_mul_scalar(velocity, 0.6, velocity) //設定碰撞過後的M203槍榴彈的速度為降為原本的60%
				set_pev(ptr, pev_velocity, velocity)
			}
		}
	}
	
	return FMRES_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id) || !g_has_ssvd[id])
		return FMRES_IGNORED;
	
	static weap_id
	weap_id = get_user_weapon(id)
	if (weap_id != CSW_M4A1)
		return FMRES_IGNORED;

	if (zp_get_user_zombie(id))
		return FMRES_IGNORED;

	#if defined SUPPORT_BOT_TO_USE
	if (is_user_bot(id))
	{
		bot_use_m203(id)
		return FMRES_IGNORED;
	}
	#endif
		
	static button, oldbutton
	button = get_uc(uc_handle, UC_Buttons)
	oldbutton = pev(id, pev_oldbuttons)

	if (g_mod_ab_ing[id] && !use_m203[id])
	{
		if ((button & IN_ATTACK2) || !(oldbutton & IN_ATTACK2) || (button & IN_ATTACK) || !(oldbutton & IN_ATTACK))
			return FMRES_IGNORED;
	}

	if ((button & IN_ATTACK2) && !(oldbutton & IN_ATTACK2))
	{
		if (!g_svd_mode_ian[id])
		{
			if (use_m203[id])
				set_M203_mode_off(id)
			else
				set_M203_mode_on(id)
		}
	}
	else if ((button & IN_ATTACK) && !(oldbutton & IN_ATTACK))
	{
		if (use_m203[id] && freeze_time_over && !m203_shoot[id] && !zp_get_user_zombie(id))
			M203_lanuch_grenade(id)
	}
	
	return FMRES_HANDLED;
}

set_M203_mode_on(id)
{
	if (!g_has_ssvd[id]) 
		return;
	
	new weap_id = get_user_weapon(id)
	if (weap_id != CSW_M4A1) 
		return;

	if (zp_get_user_zombie(id))
		return;

	new weap_ent
	weap_ent = fm_find_ent_by_owner(-1, "weapon_m4a1", id)

	g_svd_mode_ian[id] = true
	g_mod_ab_ing[id] = true

	if (g_svd_mode_ian[id])
	{
		SendWeaponAnim(id, 13)
		set_weapon_idle_time(weap_ent, get_pcvar_float(cvar_M203_OnTime) + 0.5)

		set_task(get_pcvar_float(cvar_M203_OnTime) + 0.5, "svd_mode_ian", id)
	}

	set_task(get_pcvar_float(cvar_M203_OnTime), "M203_mode_on", id)

	if (get_weapon_in_reload(weap_ent))
	{
		set_weapon_in_reload(weap_ent, 0)
		set_user_next_attack(id, 0.0)
		set_weapon_idle_time(weap_ent, 0.0)
	}	
	set_weapon_next_pri_attack(weap_ent, 1.0)
	set_weapon_next_sec_attack(weap_ent, 1.0)

	engfunc(EngFunc_EmitSound, id, CHAN_ITEM, SuperMan_SVD_Switch_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public M203_mode_on(id)
{
	if (!g_has_ssvd[id]) 
		return;

	new weap_id = get_user_weapon(id)
	if (weap_id != CSW_M4A1) 
	{
		g_svd_mode_ian[id] = false
		return;
	}

	if (zp_get_user_zombie(id))
	{
		use_m203[id] = false
		m203_reload[id] = false
		g_svd_mode_ian[id] = false
		g_has_ssvd[id] = false
		g_mod_ab_ing[id] = false
		return;
	}

	use_m203[id] = true
	m203_reload[id] = false

	g_svd_mode_ian[id] = false

	client_print(id, print_center, "己^"開啟^"M203攻擊模式.")
	client_print(id, print_chat, "[ZP] 在使用M203攻擊模式下, 按^"滑鼠左鍵^"發射槍榴彈, ^",^"和^".^"買槍榴彈.")
}

set_M203_mode_off(id)
{
	if (!g_has_ssvd[id]) 
		return;
	
	new weap_id = get_user_weapon(id)
	if (weap_id != CSW_M4A1) 
		return;

	if (zp_get_user_zombie(id)) return;

	use_m203[id] = false
	m203_reload[id] = false
	g_svd_mode_ian[id] = true

	if (g_svd_mode_ian[id])
	{
		new weap_ent
		weap_ent = fm_find_ent_by_owner(-1, "weapon_m4a1", id)

		SendWeaponAnim(id, 6)
		set_weapon_idle_time(weap_ent, get_pcvar_float(cvar_M203_OffTime) + 0.5)

		set_task(get_pcvar_float(cvar_M203_OffTime) + 0.5, "svd_mode_ian",id)
	}

	set_task(get_pcvar_float(cvar_M203_OffTime), "M203_mode_off", id)

	engfunc(EngFunc_EmitSound, id, CHAN_ITEM, SuperMan_SVD_Switch_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public M203_mode_off(id)
{
	if (!g_has_ssvd[id]) 
		return;

	new weap_id = get_user_weapon(id)
	if (weap_id != CSW_M4A1) 
	{
		g_svd_mode_ian[id] = false
		return;
	}

	if (zp_get_user_zombie(id))
	{
		use_m203[id] = false
		m203_reload[id] = false
		g_svd_mode_ian[id] = false
		g_has_ssvd[id] = false
		return;
	}

	new weap_ent
	weap_ent = fm_find_ent_by_owner(-1, "weapon_m4a1", id)

	set_weapon_next_pri_attack(weap_ent, 0.2)
	set_weapon_next_sec_attack(weap_ent, 0.2)

	g_svd_mode_ian[id] = false
	set_task(0.3, "off_ab", id)

	client_print(id, print_center, "己^"關閉^"M203攻擊模式!")
	clear_M203_ammo_msg(id)
}

public off_ab(id)
{
	static button, oldbutton
	button = pev(id, pev_button)
	oldbutton = pev(id, pev_oldbuttons)

	if (g_mod_ab_ing[id] && !use_m203[id])
	{
		if ((button & IN_ATTACK2) && !(oldbutton & IN_ATTACK2) && (button & IN_ATTACK) && !(oldbutton & IN_ATTACK))
		{
			off_ab(id)
			return;
		}
		g_mod_ab_ing[id] = false
	}
}

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	if (!g_has_ssvd[id])
	{
		client_cmd(id, "bind g drop")
		if (g_mod_ab_ing[id])
			g_mod_ab_ing[id] = false

		return FMRES_IGNORED;
	}

	if (zp_get_user_zombie(id))
	{
		if (g_has_ssvd[id]) g_has_ssvd[id] = false
		if (use_m203[id]) use_m203[id] = false
		if (m203_reload[id]) m203_reload[id] = false
		if (g_svd_mode_ian[id]) g_svd_mode_ian[id] = false
		if (g_mod_ab_ing[id]) g_mod_ab_ing[id] = false

		return FMRES_IGNORED;
	}

	if (!user_has_weapon(id, CSW_M4A1))
	{
		drop_primary_weapons(id)

		new iWep = give_item(id, "weapon_m4a1")
		if( iWep > 0 )
			cs_set_weapon_ammo(iWep, get_pcvar_num(cvar_ssvd_wmc))

		engclient_cmd(id, "weapon_m4a1")
		client_print(id, print_center, "你是英雄...手上不可沒有英雄戰擊的!!")

		return FMRES_IGNORED;
	}
	static weap_id
	weap_id = get_user_weapon(id)

	if (weap_id == CSW_M4A1)
	{
		client_cmd(id, "bind g superman_not_svd")

		if (use_m203[id])
		{
			static Float:gametime
			gametime = get_gametime()
			if (gametime >= show_msg_time[id])
			{
				show_M203_ammo_msg(id)
				show_msg_time[id] = gametime + 0.5
			}
			check_M203_ready_status(id)

			cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 1)
			message_begin(MSG_ONE, get_user_msgid("SetFOV"), _, id)
			write_byte(90)
			message_end()
		}
		else 
		{
			cs_set_user_zoom( id, CS_RESET_ZOOM, 0)
			new sendweapons, cd_handle
			fw_UpdateClientData_Post(id, sendweapons, cd_handle)
		}
	}
	else
	{
		client_cmd(id, "bind g drop")
		if (!use_m203[id])
			if (g_mod_ab_ing[id]) g_mod_ab_ing[id] = false
	}

	return FMRES_IGNORED;
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	static weapon_id
	weapon_id = get_user_weapon(id)
	if (weapon_id != CSW_M4A1)
		return FMRES_IGNORED;

	if (g_has_ssvd[id] && !use_m203[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.01)

	return FMRES_HANDLED;
}

public fw_WeapPriAttack(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;

	static owner
	owner = pev(weapon, pev_owner)

	if (!g_has_ssvd[owner])
		return HAM_IGNORED;

	if (fm_get_weaponid(weapon) != CSW_M4A1)
		return HAM_IGNORED;

	if (!use_m203[owner] && fm_get_weapon_ammo(weapon) > 0)
	{
		new weap_ent
		weap_ent = fm_find_ent_by_owner(-1, "weapon_m4a1", owner)

		SendWeaponAnim(owner, random_num(8, 9))
		set_weapon_idle_time(weap_ent, get_pcvar_float(cvar_svd_att_time) + 0.5)
		set_task(get_pcvar_float(cvar_svd_att_time) + 0.5, "svd_mode_ian", owner)

		if (is_user_bot(owner))
			emit_sound(owner, CHAN_AUTO, SVD_weapons, 1.0, ATTN_NONE, 0, 150)
		else
			emit_sound(owner, CHAN_WEAPON, SVD_weapons, 1.0, ATTN_NORM, 0, PITCH_NORM)

		new aimOrigin[3], target, body
		get_user_origin(owner, aimOrigin, 3)
		get_user_aiming(owner, target, body)
		if(!(1 <= target <= get_maxplayers())) 
		{
			new decal = GUNSHOT_DECALS[random_num(0, sizeof(GUNSHOT_DECALS) - 1)]
			if(target) 
			{
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
				write_byte(TE_DECAL)
				write_coord(aimOrigin[0])
				write_coord(aimOrigin[1])
				write_coord(aimOrigin[2])
				write_byte(decal)
				write_short(target)
				message_end()
			} 
			else
			{
				message_begin(MSG_ALL, SVC_TEMPENTITY)
				write_byte(TE_WORLDDECAL) // TE id
				write_coord(aimOrigin[0]) // x
				write_coord(aimOrigin[1]) // y
				write_coord(aimOrigin[2]) // z
				write_byte(decal)
				message_end()
			}
			message_begin(MSG_ALL, SVC_TEMPENTITY)
			write_byte(TE_SPARKS)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			message_end()
		}
	}

	return HAM_IGNORED;
}

public fw_WeapPriAttack_1(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;

	static weap_id
	weap_id = fm_get_weaponid(weapon)

	if (weap_id != CSW_M4A1)
		return HAM_IGNORED;
	
	static owner
	owner = pev(weapon, pev_owner)

	if (g_mod_ab_ing[owner])
	{
		new weap_ent
		weap_ent = fm_find_ent_by_owner(-1, "weapon_m4a1", owner)

		if (get_weapon_in_reload(weap_ent))
		{
			set_weapon_in_reload(weap_ent, 0)
			set_user_next_attack(owner, 0.0)
			set_weapon_idle_time(weap_ent, 0.0)
		}	
		set_weapon_next_pri_attack(weap_ent, 1.0)
		set_weapon_next_sec_attack(weap_ent, 1.0)

		return HAM_IGNORED;
	}

	if (g_has_ssvd[owner] && !use_m203[owner])
	{
		static Float:multiplier
		multiplier = get_pcvar_float(cvar_svd_att_time)

		if (multiplier <= 0.0)
			return HAM_IGNORED;

		static Float:next_attack_delay
		next_attack_delay = get_weapon_next_attack_dealy(weapon) - get_weapon_next_attack_dealy(weapon) + multiplier
		set_weapon_next_attack_dealy(weapon, next_attack_delay)
	}

	return HAM_IGNORED;
}

public svd_mode_ian(id)
{
	if (!is_user_alive(id) || !g_has_ssvd[id])
		return;

	static weap_id
	weap_id = get_user_weapon(id)
	if (weap_id != CSW_M4A1)
		return;

	new weap_ent
	weap_ent = fm_find_ent_by_owner(-1, "weapon_m4a1", id)

	if (use_m203[id])
	{
		if (!g_svd_m203att_ian[id] && !g_svd_mode_ian[id])
		{
			SendWeaponAnim(id, 0)
			set_weapon_idle_time(weap_ent, 5.0)
			set_task(5.0, "svd_mode_ian", id)
		}
	}
}

public superman_svd(id)
{
	if (!is_user_alive(id) || !g_has_ssvd[id])
		return FMRES_IGNORED;

	static weap_id
	weap_id = get_user_weapon(id)
	if (weap_id != CSW_M4A1)
		return FMRES_IGNORED;

	client_print(id, print_center, "你是英雄...不可掉下英雄戰擊!!")

	return FMRES_IGNORED;
}

public check_M203_ready_status(id)
{
	if (!m203_ready[id])
	{
		if (!m203_reload[id])
		{
			if (m203_ammo[id] > 0)
			{
				m203_reload[id] = true
				m203_ready_time[id] = get_gametime() + get_pcvar_float(cvar_M203_ReloadTime)
			}
		} 
		else 
		{
			if (get_gametime() >= m203_ready_time[id])
			{
				m203_ready[id] = true
				m203_reload[id] = false
				engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, M203_Reload_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
				show_M203_ammo_msg(id)
			}
		}
	} 
	else 
		m203_reload[id] = false
}

public M203_lanuch_grenade(id)
{
	client_print(id, print_center, "")
	
	if (m203_ammo[id] <= 0 || !m203_ready[id])
	{
		engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, M203_Dryfire_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		return;
	}
	
	new view_dist = get_forward_view_dist(id)
	if (view_dist < 10)
	{
		engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, M203_CantShoot_Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		client_print(id, print_center, "視角前方距離太近,無法射擊!")
		return;
	}
	
	m203_shoot[id] = true
	g_svd_m203att_ian[id] = true
	
	// create entity for m203 grenade
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (pev_valid(ent))
	{
		// get entity's origin and velocity
		new view_dist = 45
		new Float:velocity[3], Float:origin[3], Float:temp
		fm_get_aim_vector(id, view_dist, velocity, origin)
		temp = float(get_pcvar_num(cvar_M203_Start_Speed)) / (view_dist)
		xs_vec_mul_scalar(velocity, temp, velocity)

		#if defined SUPPORT_BOT_TO_USE
		if (is_user_bot(id))
		{
			// 當BOT所瞄準的目標距離太遠時,就嘗試把射擊角度拉高,以防打不到目標所在的地點
			new bot_aim_target, hitzone, distance
			bot_aim_target = get_valid_aim_target(id, hitzone, distance)
			if (bot_aim_target > 0)
			{
				new Float:velocity_angles[3], vertical_angle
				vector_to_angle(velocity, velocity_angles)
				vertical_angle = floatround(velocity_angles[0], floatround_floor) //取得榴彈發射時的向量的垂直角度數值
				vertical_angle = (vertical_angle > 180) ? (vertical_angle - 360) : vertical_angle
				
				// 當BOT對著目標的射擊線垂直角不超出-45.0至45.0度的範圍,則檢查是否該修正射擊的垂直角度,
				// 主要是為了修正射擊距離,讓榴彈拋物線能打中目標的傷害範圍內.
				
				new Float:aim_tune_angle = 0.0
				
				if (0 <= vertical_angle <= 45)
				{
					if (400 < distance <= 500)
						aim_tune_angle = 2.0
					else if (500 < distance <= 600)
						aim_tune_angle = 3.0
					else if (600 < distance <= 700)
						aim_tune_angle = 4.0
					else if (700 < distance <= 800)
						aim_tune_angle = 5.0
					else if (800 < distance <= 900)
						aim_tune_angle = 6.0
					else if (900 < distance <= 1000)
						aim_tune_angle = 7.0
					else if (1000 < distance <= 1100)
						aim_tune_angle = 8.0
					else if (1100 < distance <= 1200)
						aim_tune_angle = 9.0
					else if (1200 < distance <= 1300)
						aim_tune_angle = 9.0
					else if (1300 < distance <= 1400)
						aim_tune_angle = 10.0
					else if (1400 < distance <= 1500)
						aim_tune_angle = 10.0
					else if (1500 < distance <= 1600)
						aim_tune_angle = 11.0
					else if (1600 < distance <= 1700)
						aim_tune_angle = 12.0
					else if (1700 < distance <= 1800)
						aim_tune_angle = 13.0
					
					aim_tune_angle += vertical_angle
					
					if (!(pev(id, pev_flags) & FL_DUCKING))
						aim_tune_angle = floatmax((aim_tune_angle - 1.0), 0.0)
				}
				else if (-45 <= vertical_angle < 0)
				{
					if (400 < distance <= 500)
						aim_tune_angle = 2.0
					else if (500 < distance <= 600)
						aim_tune_angle = 2.0
					else if (600 < distance <= 700)
						aim_tune_angle = 3.0
					else if (700 < distance <= 800)
						aim_tune_angle = 4.0
					else if (800 < distance <= 900)
						aim_tune_angle = 5.0
					else if (900 < distance <= 1000)
						aim_tune_angle = 6.0
					else if (1000 < distance <= 1100)
						aim_tune_angle = 7.0
					else if (1100 < distance <= 1200)
						aim_tune_angle = 8.0
					else if (1200 < distance <= 1300)
						aim_tune_angle = 9.0
					else if (1300 < distance <= 1400)
						aim_tune_angle = 10.0
					else if (1400 < distance <= 1500)
						aim_tune_angle = 11.0
					else if (1500 < distance <= 1600)
						aim_tune_angle = 12.0
					else if (1600 < distance <= 1700)
						aim_tune_angle = 13.0
					else if (1700 < distance <= 1800)
						aim_tune_angle = 14.0
					
					if (-45 <= vertical_angle <= -40)
						aim_tune_angle /= 13.0
					else if (-40 < vertical_angle <= -35)
						aim_tune_angle /= 12.0
					else if (-35 < vertical_angle <= -30)
						aim_tune_angle /= 11.0
					else if (-30 < vertical_angle <= -25)
						aim_tune_angle /= 10.0
					else if (-25 < vertical_angle <= -20)
						aim_tune_angle /= 8.0
					else if (-20 < vertical_angle <= -15)
						aim_tune_angle /= 6.0
					else if (-15 < vertical_angle <= -10)
						aim_tune_angle /= 4.0
					else if (-10 < vertical_angle <= -5)
						aim_tune_angle /= 2.0
					else if (-5 < vertical_angle < 0)
						aim_tune_angle /= 1.0
					
					aim_tune_angle = floatmax((aim_tune_angle - 2.0), 0.0)
				}
				
				if (aim_tune_angle > 0.0)
					set_vector_change_angle2(velocity, 0.0, aim_tune_angle, velocity)
			}
		}
		#endif

		if (g_svd_m203att_ian[id])
		{
			new weap_ent
			weap_ent = fm_find_ent_by_owner(-1, "weapon_m4a1", id)

			SendWeaponAnim(id, 1)
			set_weapon_idle_time(weap_ent, get_pcvar_float(cvar_M203_ReloadTime) + 0.5)
			set_task(get_pcvar_float(cvar_M203_ReloadTime) + 0.5, "svd_mode_ian", id)
			set_task(get_pcvar_float(cvar_M203_ReloadTime), "off_m203att_ian", id)
		}

		// set entity's status
		set_pev(ent, pev_classname, "zp_M203_Grenade")
		set_pev(ent, pev_solid, SOLID_BBOX)
		set_pev(ent, pev_movetype, MOVETYPE_BOUNCE)
		set_pev(ent, pev_sequence, 1)
		
		// set entity's size
		new Float:mins[3] = { -2.5, -5.0, -2.5 }
		new Float:maxs[3] = { 2.5, 5.0, 2.5 }
		engfunc(EngFunc_SetSize, ent, mins, maxs)
		
		// set entity's angle same as player's angle
		new Float:angles[3]
		pev(id, pev_angles, angles)
		set_pev(ent, pev_angles, angles)
		
		// set entity's model
		engfunc(EngFunc_SetModel, ent, M203_Grenade_Model)
		
		// set entity's origin
		set_pev(ent, pev_origin, origin)
		
		// set entity's gravity
		set_pev(ent, pev_gravity, 0.60)
		
		// set entity's status flag value
		set_pev(ent, pev_iuser1, id) //記錄發射槍榴彈的玩家ID
		set_pev(ent, pev_iuser2, 0) //記錄槍榴彈是否有碰撞過障礙物的flag (此數值是一有碰撞過就一直設定成 1,用於判別是否有經過第一次的碰撞)
		set_pev(ent, pev_iuser3, 0) //記錄槍榴彈是否有碰撞過障礙物的flag (數值為 1 時代表剛剛有碰撞過)
		if (get_pcvar_num(cvar_M203_flag_ptd) == 0)
			set_pev(ent, pev_iuser4, 0) //記錄槍榴彈發射後是否已過了保險時間的flag (數值為 1 時代表已經過了保險時間)
		
		engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, M203_Launch_Sound[random_num(0, sizeof M203_Launch_Sound - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)

		//顯示榴彈飛行的尾部煙雲拖曳效果
		create_beam_follow(ent)
		
		// set entity's velocity
		set_pev(ent, pev_velocity, velocity)
		
		new param[5]
		param[0] = ent	//記錄M203槍榴彈的物件ID
		param[1] = 20	//設定M203最遲的爆炸時間,即最多延遲到這個時間一定會爆炸.(單位:0.1's)
		if (get_pcvar_num(cvar_M203_flag_ptd) == 0)
			param[2] = 5 	//設定M203槍榴彈發射後的保險時間,即至少要過了保險時間後才會爆炸.(單位:0.1's)
		param[3] = 0 	//記錄槍榴彈物件是否有卡住的情況的連續次數
		param[4] = 0	//記錄槍榴彈隨機改變一次物件的角度所使用的時間記錄變數
		set_task(0.1, "M203_grenade_process", TASK_ID_1, param, 5)
		
		m203_ammo[id]--
		m203_ready[id] = false
		show_M203_ammo_msg(id)
	}
	
	m203_shoot[id] = false
}

public off_m203att_ian(id)
{
	if (!is_user_alive(id) && !g_has_ssvd[id])
		return;

	g_svd_m203att_ian[id] = false
}

public M203_grenade_process(param[5])
{
	new ent = param[0]
	
	if (!pev_valid(ent))
		return;
	
	if (round_end)
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	
	// 設定槍榴彈的行進間拖尾效果
	create_beam_follow(ent)
	
	if (param[1] <= 0) //當槍榴彈的爆炸延遲時間已過時,就設定引爆槍榴彈
	{
		M203_grenade_detonate(ent)
		return;
	}
	
	if (get_pcvar_num(cvar_M203_flag_ptd) == 0)
	{
		if (param[2] <= 0)
			set_pev(ent, pev_iuser4, 1) //設定槍榴彈為已過了保險時間的flag數值
		else
			param[2]--
	}
	
	if (is_ent_stuck(ent))
		param[3]++
	else
		param[3] = 0
	
	if (param[3] > 2) //若連續卡住超過10次(即時間大於1.0秒),就設定引爆槍榴彈
	{
		M203_grenade_detonate(ent)
		return;
	}
	
	new Float:velocity[3]
	pev(ent, pev_velocity, velocity)
	new ent_speed  = floatround(vector_length(velocity))
	if (ent_speed <= 0) //當槍榴彈的速度降為0時(即停止狀態),就設定引爆槍榴彈
	{
		M203_grenade_detonate(ent)
		return;
	}
	

	if (get_pcvar_num(cvar_M203_flag_ptd) == 0)
	{
		if (ent_speed <= 50) //當槍榴彈的速度降為低於50以下時,就設定槍榴彈改變移動狀態為非彈跳狀態
			set_pev(ent, pev_movetype, MOVETYPE_TOSS)
		else 
		{
			//當槍榴彈有撞到東西的時候,設定一次隨機改變物件角度.(模擬彈跳時旋轉)
			//或者是自從第一次碰撞過東西之後,每;隔一段時間也會隨機改變角度
			if (pev(ent, pev_iuser3) == 1 || (pev(ent, pev_iuser2) == 1 && param[4] <= 0))
			{
				set_pev(ent, pev_iuser3, 0)
				
				new Float:angles[3]
				angles[0] = random_float(-90.0, 90.0)
				angles[1] = random_float(0.0, 359.0)
				angles[2] = 0.0
				set_pev(ent, pev_angles, angles)
				
				param[4] = 1
			}
			
			if (pev(ent, pev_iuser2) == 1)
				param[4]--
		}
	}
	
	param[1]--
	
	set_task(0.1, "M203_grenade_process", TASK_ID_1, param, 5)
}

public M203_grenade_detonate(ent)
{
	if (!pev_valid(ent))
		return;

	new Float:origin[3]
	pev(ent, pev_origin, origin)
	create_explosion_effect(origin)
	create_blast_effect(origin)
	engfunc(EngFunc_EmitSound, ent, CHAN_VOICE, GrenadeExplode_Sound[random_num(0, sizeof GrenadeExplode_Sound - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)

	new attacker = pev(ent, pev_iuser1)
	if (!round_end)
		grenade_explode_damage(attacker, origin)
	
	engfunc(EngFunc_RemoveEntity, ent)
}

public client_command(id)
{
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	new cmd_string[32]
	read_argv(0, cmd_string, 31)
	
	if ((equal(cmd_string, "buyammo1") || equal(cmd_string, "buyammo2")) && use_m203[id])
	{
		M203_buy_ammo(id)
		return PLUGIN_HANDLED_MAIN;
	}
	
	return PLUGIN_CONTINUE;
}

public M203_buy_ammo(id)
{
	if (!is_user_alive(id) || !g_has_ssvd[id] || !use_m203[id])
		return PLUGIN_HANDLED;
	
	if (m203_shoot[id])
		return PLUGIN_HANDLED;
	
	new m203_max_ammo = get_pcvar_num(cvar_M203_MaxAmmo)
	if (m203_ammo[id] >= m203_max_ammo)
	{
		client_print(id, print_chat, "[ZP] 你無法再攜帶更多的槍榴彈!")
		return PLUGIN_HANDLED;
	}
	
	new money = zp_get_user_ammo_packs(id)
	if (money < g_m203_ammo_cost)
	{
		client_print(id, print_chat, "[ZP] 你沒有足夠的子彈包來購買槍榴彈. (需要%d子彈包)", g_m203_ammo_cost)
		return PLUGIN_HANDLED;
	}
	
	zp_set_user_ammo_packs(id, money - g_m203_ammo_cost)
	m203_ammo[id] = min(m203_ammo[id] + g_m203_ammo_num, m203_max_ammo)
	engfunc(EngFunc_EmitSound, id, CHAN_ITEM, BuyGrenade_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	show_M203_ammo_msg(id)
	
	return PLUGIN_HANDLED;
}

public event_CurWeapon(id)
{
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	new weap_id, weap_clip, weap_bpammo
	weap_id = get_user_weapon(id, weap_clip, weap_bpammo)
	
	if (g_has_ssvd[id])
	{
		if (weap_id != CSW_M4A1)
		{
			if (user_weapon[id] == CSW_M4A1)
			{
				client_print(id, print_center, "")
				
				if (use_m203[id])
				{
					use_m203[id] = false
					m203_reload[id] = false
					clear_M203_ammo_msg(id)
				}
			}
		} 
		else 
		{
			set_super_m4a1_model(id)
		}
	}
	
	user_weapon[id] = weap_id
	
	return PLUGIN_CONTINUE;
}

public set_super_m4a1_model(id)
{
	set_pev(id, pev_viewmodel2, SuperMan_SVD_V_Model)
	set_pev(id, pev_weaponmodel2, SuperMan_SVD_P_Model)
}

public set_normal_m4a1_model(id)
{
	set_pev(id, pev_viewmodel2, M4A1_V_Model)
	set_pev(id, pev_weaponmodel2, M4A1_P_Model)
}

public show_M203_ammo_msg(id)
{
	if (m203_ready[id])
		set_hudmessage(0, 200, 200, 0.90, 0.90, 0, 6.0, 0.8, 0.0, 0.0, -1)
	else
		set_hudmessage(200, 0, 0, 0.90, 0.90, 0, 6.0, 0.8, 0.0, 0.0, -1)
	
	ShowSyncHudMsg(id, g_msgSync, "槍榴彈彈藥:%d發", m203_ammo[id])
}

public clear_M203_ammo_msg(id)
{
	set_hudmessage(0, 0, 0, 0.01, 0.64, 0, 6.0, 0.8, 0.0, 0.0, -1)
	ShowSyncHudMsg(id, g_msgSync, "             ")
}

public grenade_hit_damage(victim, attacker, damage, ptr)
{
	if (!is_user_alive(victim))
		return;
	
	if (fm_get_user_godmode(victim) || get_user_godmode(victim))
		return;
	
	if (!zp_get_user_zombie(victim))
	{
		if (get_pcvar_num(cvar_M203_dmg_fd) == 1)
		{
			if (zp_get_user_survivor(victim))
				damage = floatround(float(damage) * Damage_Survivor_Multiplier)
			else
				damage = floatround(float(damage) * Damage_Human_Multiplier)
			
			new armor = get_user_armor(victim)
			new Float:damage_armor_rate, damage_armor
			damage_armor_rate = (3.0 / 4.0) //對人類護甲造成傷害的乘數. (護甲傷害值 = 總傷害值 * 乘數)
			damage_armor = floatround(float(damage) * damage_armor_rate)
			
			// 計算扣除護甲傷害值後,剩下對血量所造成的傷害值.(這是模擬護甲防護的效果)
			if (damage_armor > 0 && armor > 0)
			{
				if (armor > damage_armor)
				{
					damage -= damage_armor
					fm_set_user_armor(victim, armor - damage_armor)
				} 
				else 
				{
					damage -= armor
					fm_set_user_armor(victim, 0)
				}
			}
		}
		if (get_pcvar_num(cvar_M203_dmg_fd) == 0)
		{
			damage = floatround(float(damage) * 0)
		}
	}

	if (damage > 0)
	{
		new hp = get_user_health(victim)
		if (hp > damage)
		{
			fm_fakedamage(victim, "M203_Grenade", float(0), DMG_BULLET)
			set_user_health(victim, hp - damage)
			screen_fade(victim, 0.2)
			screen_shake(victim, 6, 1, 5)
		} 
		else 
			M203_grenade_detonate(ptr)
	}
}

public grenade_explode_damage(attacker, Float:hit_origin[3])
{
	new Float:target_origin[3]
	new max_dmgrange = get_pcvar_num(cvar_M203_DmgRange)
	new i
	for (i = 1; i <= maxplayers; i++)
	{
		if (!is_user_alive(i))
			continue;

		if (fm_get_user_godmode(i) || get_user_godmode(i))
			continue;

		pev(i, pev_origin, target_origin)
		new dist = floatround(get_distance_f(hit_origin, target_origin))
		if (dist > max_dmgrange)
			continue;

		new hp = get_user_health(i)
		new damage = get_pcvar_num(cvar_M203_MaxDmg)
		new temp = damage - get_pcvar_num(cvar_M203_MinDmg)
		damage -= floatround(float(temp) * float(dist) / float(max_dmgrange))

		if (!zp_get_user_zombie(i))
		{
			if (get_pcvar_num(cvar_M203_dmg_fd) == 0)
				damage = floatround(float(damage) * 0)

			if (get_pcvar_num(cvar_M203_dmg_fd) == 1)
			{
				if (zp_get_user_survivor(i))
					damage = floatround(float(damage) * Damage_Survivor_Multiplier)
				else
					damage = floatround(float(damage) * Damage_Human_Multiplier)
				
				new armor = get_user_armor(i)
				new Float:damage_armor_rate, damage_armor
				damage_armor_rate = (3.0 / 4.0) //對人類護甲造成傷害的乘數. (護甲傷害值 = 總傷害值 * 乘數)
				damage_armor = floatround(float(damage) * damage_armor_rate)
					
				// 計算扣除護甲傷害值後,剩下對血量所造成的傷害值.(這是模擬護甲防護的效果)
				if (damage_armor > 0 && armor > 0)
				{
					if (armor > damage_armor)
					{
						damage -= damage_armor
						fm_set_user_armor(i, armor - damage_armor)
					} 
					else 
					{
						damage -= armor
						fm_set_user_armor(i, 0)
					}
				}
			}
		}
		
		if (damage > 0)
		{
			new Float:velocity[3]

			new knockback = get_pcvar_num(cvar_M203_Explode_Knockback)
			if (knockback > 0)
			{
				get_speed_vector_point_entity(hit_origin, i, knockback, velocity)
				set_pev(i, pev_velocity, velocity)
			}
			
			if (hp > damage)
			{
			//	fm_fakedamage(i, "M203_Grenade", float(damage), DMG_BLAST)

				set_user_health(i, hp - damage)

				fm_fakedamage(i, "M203_Grenade", float(0), DMG_BLAST)
				particle_burst_effect(target_origin)
				screen_shake(i, 6, 1, 5)
			} 
			else 
				user_be_killed(attacker, i, 0, "M203_grenade")
		}
	}
}

public user_be_killed(attacker, victim, headshot, weapon[])
{
	new attacker_frags = get_user_frags(attacker)
	new attacker_ammopack = zp_get_user_ammo_packs(attacker)
	
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
	ExecuteHamB(Ham_Killed, victim, attacker, 2) // set last param to 2 if you want victim to gib
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
	SendDeathMsg(attacker, victim, 0, weapon)
	
	if (get_user_team(attacker) == get_user_team(victim))
	{
		attacker_frags -= 1
		attacker_ammopack = max(attacker_ammopack - 1, 0)
	} 
	else 
	{
		attacker_frags += get_pcvar_num(cvar_M203_KilledFrags)
		attacker_ammopack += get_pcvar_num(cvar_M203_KilledAmmopack)
	}
	
	fm_set_user_frags(attacker, attacker_frags)
	zp_set_user_ammo_packs(attacker, attacker_ammopack)
	
	FixDeadAttrib(victim, (is_user_alive(victim) ? 0 : 1))
	Update_ScoreInfo(victim, get_user_frags(victim), get_user_deaths(victim))
	FixDeadAttrib(attacker, (is_user_alive(attacker) ? 0 : 1))
	Update_ScoreInfo(attacker, get_user_frags(attacker), get_user_deaths(attacker))
	
	// log killed information 
	new attacker_name[32], victim_name[32], attacker_authid[32], victim_authid[32], attacker_team[10], victim_team[10]
	
	get_user_name(attacker, attacker_name, charsmax(attacker_name))
	get_user_team(attacker, attacker_team, charsmax(attacker_team))
	get_user_authid(attacker, attacker_authid, charsmax(attacker_authid))
 	
	get_user_name(victim, victim_name, charsmax(victim_name))
	get_user_team(victim, victim_team, charsmax(victim_team))
	get_user_authid(victim, victim_authid, charsmax(victim_authid))
	
	log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
		attacker_name, get_user_userid(attacker), attacker_authid, attacker_team, 
 		victim_name, get_user_userid(victim), victim_authid, victim_team, weapon)
}


public Item_AttachToPlayer(weapon, id)
{
     if (!g_has_ssvd[id])
           return;

     if (fm_get_weapon_known(weapon))
           return;

     if (!get_pcvar_num(cvar_ssvd_wmc))
           return;

     
     cs_set_weapon_ammo(weapon, get_pcvar_num(cvar_ssvd_wmc))
}


public Item_PostFrame(weapon)
{
	if (!pev_valid(weapon))
		return;

	static owner
	owner = pev(weapon, pev_owner)

	static iMaxClip, fInReload, iClip, iBpAmmo, Float:flNextAttack
	iMaxClip = get_pcvar_num(cvar_ssvd_wmc)
	fInReload = get_weapon_in_reload(weapon)
	iClip = cs_get_weapon_ammo(weapon)
	iBpAmmo = cs_get_user_bpammo(owner, CSW_M4A1)
	flNextAttack = get_user_next_attack(owner)

	if (g_has_ssvd[owner] && iMaxClip && iMaxClip != get_pcvar_num(cvar_m4a1_wmc))
	{
		if (fInReload && flNextAttack <= 0.0)
		{
			new j = min(iMaxClip - iClip, iBpAmmo)
			cs_set_weapon_ammo(weapon, iClip + j)
			cs_set_user_bpammo(owner, CSW_M4A1, iBpAmmo-j)

			set_weapon_in_reload(weapon, 0)
			fInReload = 0
		}

		static iButton
		iButton = pev(owner, pev_button)

		if ((iButton & IN_ATTACK2 && get_weapon_next_sec_attack(weapon) <= 0.0)
		|| (iButton & IN_ATTACK && get_weapon_next_pri_attack(weapon) <= 0.0))
			return;

		if (iButton & IN_RELOAD && !fInReload)
		{
			if (iClip >= iMaxClip)
			{
				set_pev(owner, pev_button, iButton & ~IN_RELOAD)
				if (cs_get_weapon_silen(weapon))
					SendWeaponAnim(owner, 0)
				else
					SendWeaponAnim(owner, 7)
			}
		}
		else if (iClip == get_pcvar_num(cvar_m4a1_wmc))
		{
			if (iBpAmmo)
			{
				set_user_next_attack(owner, 3.05) //數值參考g_fDelay[iId]
				if (cs_get_weapon_silen(weapon))
					SendWeaponAnim(owner, 4) //數值參考g_iReloadAnims[iId]
				else
					SendWeaponAnim(owner, 11) //數值參考g_iReloadAnims[iId]
				set_weapon_in_reload(weapon, 1)
				set_weapon_idle_time(weapon, 3.05 + 0.5) //數值參考g_fDelay[iId] + 0.5
			}
		}
	}
}

public client_connect(id)
{
	reset_vars(id)
}

public client_disconnect(id)
{
	reset_vars(id)
}

public event_RoundStart()
{
	freeze_time_over = false
	round_end = false
	
	for (new i = 1; i <= 32; i++)
	{
		if (is_user_alive(i))
		{
			if (g_has_ssvd[i] && get_user_weapon(i) == CSW_M4A1)
				set_normal_m4a1_model(i)
		}
		
		reset_vars(i)
	}
}


public logevent_RoundStart()
{
	freeze_time_over = true
}

public logevent_RoundEnd()
{
	round_end = true
	remove_task(TASK_CHOOSE_HERO)
}

public zp_round_started(gamemode, id)
{
	#if defined SUPPORT_BOT_TO_USE
	for (new i = 1; i <= maxplayers; i++)
	{
		if (!is_user_bot(i) || !is_user_alive(i) || zp_get_user_zombie(i) || zp_get_user_survivor(i) || g_has_ssvd[i])
			continue;
		
		set_task(3.0, "bot_random_buy_ssvd", BOT_TASK_ID_1)
	}
	#endif
	
	if (gamemode != MODE_NEMESIS && gamemode != MODE_SURVIVOR)
	{
		g_round_ssvd = 0
		remove_task(TASK_CHOOSE_HERO)
		set_task(0.5, "choose_a_hero", TASK_CHOOSE_HERO, _, _, "b")
	}
}

public choose_a_hero()
{
	new id
	while (!round_end && get_alive_players() > 1 && g_round_ssvd == 0)
	{
		id = random_num(1, maxplayers)
		if (is_user_connected(id) && is_user_alive(id) && !zp_get_user_zombie(id))
		{
			g_round_ssvd++
			give_user_ssvd(id)
			
			new name[32]
			get_user_name(id, name, 31)
			
			for (new i = 1; i <= maxplayers; i++)
			{
				if (!is_user_connected(i))
					continue;
				
				if (i == id)
					client_print(i, print_center, "您被選定為英雄")
				else 
					client_print(i, print_center, "[%s]被選為英雄", name)
			}
		}
	}
	
	if (round_end || g_round_ssvd > 0)
		remove_task(TASK_CHOOSE_HERO)
}

get_alive_players()
{
	new alive_players = 0
	for (new i = 1; i <= maxplayers; i++)
	{
		if (is_user_connected(i) && is_user_alive(i))
			alive_players++
	}
	
	return alive_players;
}

#if defined SUPPORT_BOT_TO_USE
public bot_random_buy_ssvd(taskid)
{
	new id = BOT_USER_ID_1
	
	if (!is_user_bot(id) || !is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id) || g_has_ssvd[id])
		return;
	
	if (has_custom_weapons(id, BOT_USE_WEAPONS_BIT_SUM))
		return;
	
	new ammo_packs = zp_get_user_ammo_packs(id)
	if (ammo_packs < (g_item_cost + 5))
		return;
	
	new bool:buy_item
	// 設定讓BOT有20%機率會選擇購買英雄戰擊
	buy_item = (random_float(0.0, 1.0) > 0.8) ? true : false
	if (buy_item)
	{
		zp_set_user_ammo_packs(id, ammo_packs - g_item_cost)
		give_user_ssvd(id)
	}
}

public bot_use_m203(id)
{
	new target, hitzone, distance
	target = get_valid_aim_target(id, hitzone, distance)
	if (target > 0)
	{
		if (m203_ammo[id] <= 0)
		{
			if (use_m203[id])
				set_M203_mode_off(id)
			
			bot_random_buy_grenade(id)
			
			return;
		}
		
		//設定BOT在和所瞄準目標距離大於400且小於1800時,才會選擇使用槍榴彈攻擊,以免炸到自已或打不到遠處目標
		if ((400 <= distance <= 1800) && m203_ready[id])
		{
			if (!use_m203[id] && !g_svd_mode_ian[id])
				set_M203_mode_on(id)

 			if (use_m203[id])
			{
				new Float:time = get_gametime()
				if (time >= bot_next_attack_time[id])
				{
					new view_dist = get_forward_view_dist(id)
					if (m203_ready[id] && view_dist >= 100 && freeze_time_over && !m203_shoot[id])
					{
						M203_lanuch_grenade(id)
						bot_next_attack_time[id] = time + 1.0
					}
				}
			}
		}
		//設定BOT在和所瞄準目標距離大於800,且未備妥槍榴彈時,則會進行填裝槍榴彈來準備攻擊
		else if (distance >= 800 && !m203_ready[id])
		{
			if(!g_svd_mode_ian[id] && !use_m203[id])
				set_M203_mode_on(id)
		}
		else 
		{
			if (!g_svd_mode_ian[id] && use_m203[id])
				set_M203_mode_off(id)
		}
	}
	else 
	{
		if (m203_ammo[id] > 0 && !m203_ready[id])
		{
			if(!g_svd_mode_ian[id] && !use_m203[id])
				set_M203_mode_on(id)
		} 
		else 
		{
			if (!g_svd_mode_ian[id] && use_m203[id])
				set_M203_mode_off(id)
		}
	}
}

bot_random_buy_grenade(id)
{
	new money = zp_get_user_ammo_packs(id)
	if (money >= g_m203_ammo_cost + 10) //設定BOT擁有的子彈包數量要有多預留10個子彈包才會購買槍榴彈.
	{
		new Float:temp = random_float(0.0, 1.0)
		if (temp > 0.7) //設定BOT購買槍榴彈的機率只有30%
		{
			zp_set_user_ammo_packs(id, money - g_m203_ammo_cost)
			m203_ammo[id] += g_m203_ammo_num
		}
	}
}

reset_vars(id)
{
	g_has_ssvd[id] = false
	use_m203[id] = false
	m203_ammo[id] = 0
	m203_ready[id] = false
	m203_shoot[id] = false
	g_mod_ab_ing[id] = false

/*  伺服器lag bug
	zp_set_player_model(id, 1)
	sex_player_model_set(id, 1)
*/
}

stock drop_primary_weapons(id)
{
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock fm_give_weapon(id, const weapon[], use_silen = 0)
{
	if (!equal(weapon, "weapon_", 7))
		return;
	
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, weapon))
	if (!pev_valid(ent)) return;
	
	static Float:originF[3]
	pev(id, pev_origin, originF)
	set_pev(ent, pev_origin, originF)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	
	if (equal(weapon[7], "usp") || equal(weapon[7], "m4a1"))
		cs_set_weapon_silen(ent, use_silen, 0)
	
	static save
	save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, id)
	if (pev(ent, pev_solid) != save)
		return;
	
	engfunc(EngFunc_RemoveEntity, ent)
}

stock fm_give_item(index, const item[]) 
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent))
		return 0
	
	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	
	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent
	
	engfunc(EngFunc_RemoveEntity, ent)
	
	return -1
}

#if (defined SUPPORT_BOT_TO_USE)
stock bool:has_custom_weapons(id, const bitsum)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if ((1<<weaponid) & bitsum)
			return true;
	}
	
	return false;
}

stock fm_find_ent_by_class(index, const classname[])
{
	return engfunc(EngFunc_FindEntityByString, index, "classname", classname) 
}

stock fm_kill_entity(index)
{
	set_pev(index, pev_flags, pev(index, pev_flags) | FL_KILLME);
	
	return 1;
}
#endif

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && (pev(entity, pev_owner) != owner)) {}
	
	return entity;
}

stock set_weapon_next_sec_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_FlNextSecondaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_next_pri_attack(entity)
{
	return get_pdata_float(entity, OFFSET_FlNextPrimaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_pri_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_FlNextPrimaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock get_weapon_in_reload(entity)
{
	return get_pdata_int(entity, OFFSET_WeapInReload, OFFSET_LINUX_WEAPONS);
}

stock set_weapon_in_reload(entity, reload_flag)
{
	return set_pdata_int(entity, OFFSET_WeapInReload, reload_flag, OFFSET_LINUX_WEAPONS);
}

stock Float:get_user_next_attack(id)
{
	return get_pdata_float(id, OFFSET_FlNextAttack, OFFSET_LINUX)
}

stock set_user_next_attack(id, Float:time)
{
	set_pdata_float(id, OFFSET_FlNextAttack, time, OFFSET_LINUX)
}

stock set_weapon_idle_time(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_FlTimeWeaponIdle, time, OFFSET_LINUX_WEAPONS)
}

stock SendWeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(iAnim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock get_forward_view_dist(id)
{
	new iOrigin1[3], iOrigin2[3]
	get_user_origin(id, iOrigin1, 0)
	get_user_origin(id, iOrigin2, 3)
	new dist = get_distance(iOrigin1, iOrigin2)
	
	return dist;
}

stock is_ent_stuck(ent)
{
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	engfunc(EngFunc_TraceHull, originF, originF, 0, HULL_HEAD, ent, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

/*
stock fm_set_user_health(index, health)
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);
	
	return 1;
}
*/

stock fm_set_user_armor(index, armor)
{
	set_pev(index, pev_armorvalue, float(armor));
	
	return 1;
}

stock fm_set_user_frags(index, frags)
{
	set_pev(index, pev_frags, float(frags));
	
	return 1;
}

stock fm_fakedamage(victim, const classname[], Float:takedmgdamage, damagetype)
{
	new class[] = "trigger_hurt";
	new entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, class));
	if (!entity)
		return 0;
	
	new value[16];
	float_to_str(takedmgdamage * 2, value, sizeof value - 1);
	fm_set_kvd(entity, "dmg", value, class);
	
	num_to_str(damagetype, value, sizeof value - 1);
	fm_set_kvd(entity, "damagetype", value, class);
	
	fm_set_kvd(entity, "origin", "8192 8192 8192", class);
	dllfunc(DLLFunc_Spawn, entity);
	
	set_pev(entity, pev_classname, classname);
	dllfunc(DLLFunc_Touch, entity, victim);
	engfunc(EngFunc_RemoveEntity, entity);
	
	return 1;
}

stock fm_set_kvd(entity, const key[], const value[], const classname[] = "")
{
	if (classname[0])
	{
		set_kvd(0, KV_ClassName, classname);
	} 
	else 
	{
		new class[32];
		pev(entity, pev_classname, class, sizeof class - 1);
		set_kvd(0, KV_ClassName, class);
	}
	
	set_kvd(0, KV_KeyName, key);
	set_kvd(0, KV_Value, value);
	set_kvd(0, KV_fHandled, 0);
	
	return dllfunc(DLLFunc_KeyValue, entity, 0);
}

stock get_speed_vector_point_entity(const Float:point[3], ent, speed, Float:new_velocity[3])
{
	if (!pev_valid(ent))
		return 0;
	
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	
	new_velocity[0] = origin[0] - point[0];
	new_velocity[1] = origin[1] - point[1];
	new_velocity[2] = origin[2] - point[2];
	
	static Float:num
	num = float(speed) / vector_length(new_velocity);
	
	new_velocity[0] *= num;
	new_velocity[1] *= num;
	new_velocity[2] *= num;
	
	return 1;
}

stock SendDeathMsg(attacker, victim, headshot, const weapon[]) // Send Death Message
{
	message_begin(MSG_BROADCAST, g_msgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(headshot) // headshot flag [1 or 0]
	write_string(weapon) // killer's weapon
	message_end()
}

stock FixDeadAttrib(id, dead_flag = 0) // Fix Dead Attrib on scoreboard
{
	message_begin(MSG_BROADCAST, g_msgScoreAttrib)
	write_byte(id) // id
	write_byte(dead_flag) // attrib
	message_end()
}

stock Update_ScoreInfo(id, frags, deaths) // Update Player's Frags and Deaths
{
	// Update scoreboard with attacker's info
	message_begin(MSG_BROADCAST, g_msgScoreInfo)
	write_byte(id) // id
	write_short(frags) // frags
	write_short(deaths) // deaths
	write_short(0) // class?
	write_short(get_user_team(id)) // team
	message_end()
}

stock screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude) // 振幅
	write_short((1<<12)*duration) // 時間
	write_short((1<<12)*frequency) // 頻率
	message_end()
}

stock screen_fade(id, Float:time)
{
	// Add a blue tint to their screen
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
	write_short((1<<12)*1) // duration
	write_short(floatround((1<<12)*time)) // hold time
	write_short(0x0000) // fade type
	write_byte(200) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(150) // alpha
	message_end()
}

stock particle_burst_effect(const Float:originF[3])
{
	// Particle burst
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_PARTICLEBURST) // TE id: 122
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_short(50) // radius
	write_byte(70) // color
	write_byte(3) // duration (will be randomized a bit)
	message_end()
}

stock create_beam_follow(entity)
{
	//Entity add colored trail
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id: 22
	write_short(entity) // entity
	write_short(g_trailSpr) // sprite
	write_byte(15) // life
	write_byte(1) // width
	write_byte(255) // r
	write_byte(255) // g
	write_byte(255) // b
	write_byte(255) // brightness
	message_end()
}

stock create_explosion_effect(const Float:originF[3])
{
	// Additive sprite, 2 dynamic lights, flickering particles, explosion sound, move vertically 8 pps
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_EXPLOSION) // TE id: 3
	engfunc(EngFunc_WriteCoord, originF[0]) // position.x
	engfunc(EngFunc_WriteCoord, originF[1]) // position.y
	engfunc(EngFunc_WriteCoord, originF[2]) // position.z
	write_short(g_explodeSpr) // sprite index
	write_byte(30) // scale in 0.1's
	write_byte(15) // framerate
	write_byte(0) // flags
	message_end()
}

stock create_blast_effect(const Float:originF[3])
{
	// Cylinder that expands to max radius over lifetime
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id: 21
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2] + 200) // z axis
	write_short(g_blastSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(5) // life
	write_byte(10) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(255) // green
	write_byte(192) // blue
	write_byte(128) // brightness
	write_byte(0) // speed
	message_end()
}

stock fm_get_aim_vector(index, view_distance, Float:view_vector[3], Float:view_origin[3])
{
	new Float:start[3], Float:view_ofs[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);
	
	new Float:vector[3];
	pev(index, pev_v_angle, vector);
	engfunc(EngFunc_MakeVectors, vector);
	global_get(glb_v_forward, vector);
	xs_vec_mul_scalar(vector, float(view_distance), view_vector);
	xs_vec_add(start, view_vector, view_origin);
	
	return 1;
}

stock fm_get_user_godmode(index)
{
	new Float:val;
	pev(index, pev_takedamage, val);
	
	return (val == DAMAGE_NO);
}

stock get_valid_aim_target(id, &hitzone, &distance)
{
	new target, aim_hitzone
	get_user_aiming(id, target, aim_hitzone)
	if (!(1 <= target <= 32) || !is_user_alive(target) || !zp_get_user_zombie(target))
		return 0;
	
	hitzone = aim_hitzone
	new Float:origin1[3], Float:origin2[3]
	pev(id, pev_origin, origin1)
	pev(target, pev_origin, origin2)
	distance = floatround(get_distance_f(origin1, origin2), floatround_round)
	
	return target;
}

stock set_vector_change_angle2(const Float:velocity[3], Float:angle, Float:vertical_angle, Float:new_velocity[3])
{
	new Float:v_angles[3]
	vector_to_angle(velocity, v_angles)
	
	v_angles[1] += angle
	while (v_angles[1] < 0.0)
		v_angles[1] += 360.0
	
	v_angles[2] += vertical_angle
	while (v_angles[2] < 0.0)
		v_angles[2] += 360.0
	
	new Float:v_length
	v_length  = vector_length(velocity)
	
	new Float:temp
	temp = v_length * floatcos(v_angles[2], degrees)
	
	new_velocity[0] = temp * floatcos(v_angles[1], degrees)
	new_velocity[1] = temp * floatsin(v_angles[1], degrees)
	new_velocity[2] = v_length * floatsin(v_angles[2], degrees)
}
#endif

stock fm_get_user_model(player, model[], len)
{
	get_user_info(player, "model", model, len)
}

stock fm_set_user_model(id, const model[])
{
	set_user_info(id, "model", model)
}

stock fm_set_user_model_index(id, value)
{
	set_pdata_int(id, OFFSET_MODELINDEX, value, OFFSET_LINUX)
}

stock fm_get_weapon_ammo(entity)
{
	return get_pdata_int(entity, OFFSET_iClipAmmo, OFFSET_LINUX_WEAPONS);
}

stock fm_get_weaponid(entity)
{
	return get_pdata_int(entity, OFFSET_iWeapId, OFFSET_LINUX_WEAPONS);
}

stock fm_get_aim_origin(index, Float:origin[3])
{
	new Float:start[3], Float:view_ofs[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);
	
	new Float:dest[3];
	pev(index, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);
	
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0);
	get_tr2(0, TR_vecEndPos, origin);
	
	return 1;
}

stock fm_get_weapon_known(entity)
{
	return get_pdata_int(entity, m_flKnown, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_next_sec_attack(entity)
{
	return get_pdata_float(entity, m_flNextSecondaryAttack, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_next_attack_dealy(entity)
{
	return get_pdata_float(entity, m_flNextPrimaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_attack_dealy(entity, Float:time)
{
	set_pdata_float(entity, m_flNextPrimaryAttack, time, OFFSET_LINUX_WEAPONS)
}

#if defined SUPPORT_CZBOT
// CZBot support
new bool:BotHasDebug = false
public client_putinserver(id)
{
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
	
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}
#endif