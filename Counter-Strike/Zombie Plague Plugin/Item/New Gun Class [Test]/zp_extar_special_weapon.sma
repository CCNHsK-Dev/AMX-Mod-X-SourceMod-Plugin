/*=======================================================================================================
========================================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <xs>

#define PLUGIN_NAME	"[ZP] TEST  [by 暴槍]"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_AUTHOR	"HsK"

//========================================================================================================

#define SUPPORT_BOT_TO_USE		//支援BOT使用.(在最前面加上 // 即取消對BOT的技援)
#define SUPPORT_CZBOT			//支援CZBot的使用.(在最前面加上 // 即取消這項設定)

//#define IN_ZP

#if defined IN_ZP
#include <zombieplague>
#endif

#if defined SUPPORT_BOT_TO_USE
// Bot Task ID
#define TASK_BOT_BUY_WEAPON	3344

// Bot Use Weapon Bitsums #設定BOT如果持有那些槍就不會再購買或撿取武器
const BOT_USE_WEAPONS_BIT_SUM = (1<<CSW_SG550)|(1<<CSW_AWP)|(1<<CSW_M249)|(1<<CSW_G3SG1)
#endif

#if defined SUPPORT_CZBOT
// CZBot support
new cvar_botquota
new bool:BotHasDebug = false
#endif

//========================================================================================================

new const g_item_name[] = { "TEST" } 	//特殊道具名稱
new const g_item_cost = 10 			//特殊道具價格(子彈包)
new const g_ammo_cost = 1			//特殊道具的子彈的價格(子彈包)
new const g_ammo_amount = 6			//購買一次特殊道具的子彈的數量

// Weapon Attrib Items
#define SPECIAL_WEAPON_NAME	"TEST"		//特殊武器的名稱
#define SPECIAL_WEAPON_ID	CSW_AK47		//特殊武器所使用的原始武器ID
#define SPECIAL_WEAPON_CLASS	"weapon_ak47"		//特殊武器所使用的原始武器Class名稱
#define SPECIAL_WEAPON_ENTITY	"SPECIAL_M4A1_ENTITY"	//特殊武器的物件名稱

//========================================================================================================

// Custom Settings
new const Weapon_MaxClip = 60			//武器的子彈量(當設定小於0時,代表使用預設子彈量)
new const Weapon_MaxBpammo = 600 		//武器的備用子彈最大數量

new const Float:Weapon_ReloadDelay = 2.1	//武器裝彈時間(單位:秒)(當設定小於0.0時,代表使用預設裝彈時間)

new const Float:Damage_head = 180.0		//命中頭部的傷害值數值
new const Float:Damage_chest = 55.0		//命中胸部的傷害值數值
new const Float:Damage_stomach = 50.0		//命中腹部的傷害值數值
new const Float:Damage_arm = 21.0		//命中手部傷害值數值
new const Float:Damage_leg = 22.0		//命中腳部的傷害值數值

new const Float:FireRate_Multiplier = 0.0 	//射擊間距[秒] (當設定小於0.0時為無作用)

new const KnockBack_Effect = 1 			//武器的擊退效果[1=開啟/0=關閉]
new const KnockBack_With_Damage = 1		//是否使用武器造成的傷害值為擊退效果乘數.(傷害值越大,擊退力越強)[1=使用,0=不使用]
new const Float:KnockBack_Power = 18.0		//武器的擊退力量(力量數值越大,擊退力越強)(當設定小於0.0時,為不使用擊退力量設定)
new const Float:KnockBack_Duck = 0.5		//當被攻擊的玩家蹲下時,所受到的擊退效果乘數.(當設定值為0.0時,代表蹲下時不會受擊退效果影響)
new const Float:KnockBack_Distance = 500.0	//玩家受擊退效果影響的最遠有效距離
new const KnockBack_Zvel = 0			//擊退效果是否影響玩家的垂直向量[1=影響,0=不影響]

//========================================================================================================

//動作
new const Draw_Anim = 0				//取出槍的動作
new const Draw_Silent_Anim = 0			//取出槍的動作 (用滅聲管的情況下)

new const Attack_Anim = 0			//開火的動作
new const Attack_Silent_Anim = 0		//開火的動作 (在用滅聲管的情況下)

new const Idle_Anim = 0				//取槍的動作
new const Idle_Anim_M4A1 = 0			//取槍的動作 (M4A1 在沒用滅聲管的情況下)
new const Idle_Anim_USP = 0			//取槍的動作 (USP 在沒用滅聲管的情況下)

new const Reload_Anim = 0			//裝彈的動作 
new const Silent_Reload_Anim_M4A1 = 0		//裝彈的動作 (M4A1 在用滅聲管的情況下)
new const Silent_Reload_Anim_USP = 0		//裝彈的動作 (USP  在沒用滅聲管的情況下)

// Models
new const SWEAPON_V_Model[] = { "models/v_sak47.mdl" } 	//v_模型
new const SWEAPON_P_Model[] = { "models/p_ak47.mdl" } 	//p_模型
new const SWEAPON_W_Model[] = { "models/w_ak47.mdl" } 	//w_模型

// Sounds
new const BuyAmmo_Sound[] = { "items/9mmclip1.wav" } 		//購買子彈時的聲音
new const weapons_sound[] = { "weapons/m4a1-1.wav" }		//開火的聲音
new const weapons_silent_sound [] = { "weapons/dbarrel-1.wav" }	//開火的聲音 (M4A1 or USP 在用滅聲管的情況下)

//========================================================================================================


// CS Weapon PData Offsets
const OFFSET_iWeaponId = 43
const OFFSET_iWeaponKnown = 44
const OFFSET_flNextPrimaryAttack = 46
const OFFSET_flNextSecondaryAttack = 47
const OFFSET_flTimeWeaponIdle = 48
const OFFSET_iClipAmmo = 51
const OFFSET_iInReload = 54
const OFFSET_iInSpecialReload = 55
const OFFSET_iWeaponSilent = 74

// CS Weapon CBase Offsets (win32)
const OFFSET_iWeaponOwner = 41

// CS Player PData Offsets (win32)
const OFFSET_flNextAttack = 83

// Linux Diff's
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux
const OFFSET_LINUX = 5

new const GUNSHOT_DECALS[] = {41, 42, 43, 44, 45}

// Weapon Bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|
	(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|
	(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const SHOTGUNS_BITSUM = (1<<CSW_M3)|(1<<CSW_XM1014)
const SILENT_WEAPON_BITSUM = (1<<CSW_USP)|(1<<CSW_M4A1)

// Ammo IDs for weapons
new const WEAPON_AMMOID[CSW_P90+1] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10,
			1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }

// Ammo Type Names for weapons
new const AMMOTYPE[CSW_P90+1][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// Default Max Clip for weapons
new const DEFAULT_MAXCLIP[CSW_P90+1] = { -1, 13, -1, 10, -1, 7, -1, 30, 30, -1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, -1, 7, 30, 30, -1, 50 }

// Default Max BP ammo for weapons
new const DEFAULT_MAXBPAMMO[CSW_P90+1] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

// Weapons w_ model
new const WEAPONS_W_MODEL[CSW_P90+1][] = { "", "w_p228.mdl", "", "w_scout.mdl", "", "w_xm1014.mdl", "", "w_mac10.mdl",
	"w_aug.mdl", "", "w_elite.mdl", "w_fiveseven.mdl", "w_ump45.mdl", "w_sg550.mdl", "w_galil.mdl", "w_famas.mdl",
	"w_usp.mdl", "w_glock18.mdl", "w_awp.mdl", "w_mp5.mdl", "w_m249.mdl", "w_m3.mdl", "w_m4a1.mdl",
	"w_tmp.mdl", "w_g3sg1.mdl", "", "w_deagle.mdl", "w_sg552.mdl", "w_ak47.mdl", "w_knife.mdl", "w_p90.mdl" }

#if !(SPECIAL_WEAPON_ID & SHOTGUNS_BITSUM)
new const Float:RELOAD_DELAYTIME[CSW_P90+1] = { 0.00, 2.70, 0.00, 2.00, 0.00, 0.55, 0.00, 3.15, 3.30, 0.00, 4.50, 2.70, 3.50, 
	3.35, 2.45, 3.30, 2.70, 2.20, 2.50, 2.63, 4.70, 0.55, 3.05, 2.12, 3.50, 0.00, 2.20, 3.00, 2.45, 0.00, 3.40 }
#endif

// Item id
new g_itemid_sweapon

// Cvars
new cvar_one_round

// Vars
new g_msgAmmoPickup
new g_maxplayers
new bool:has_sweapon[33] = { false, ... }
new sweapon_clip[33] = { 0, ... }, sweapon_bpammo[33] = { 0, ... }, origin_weapon_bpammo[33] = { 0, ... }
new user_drop[33] = { -1, ... }, Float:drop_time[33] = { 0.0, ... }
new user_weapon[33] = { 0, ... }

#if !(SPECIAL_WEAPON_ID & SHOTGUNS_BITSUM)
new user_reload_weapon[33] =  { -1, ... }
#endif

public plugin_init()
{
	// Register Plugin
	register_plugin (PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR )
	
	#if defined IN_ZP
	g_itemid_sweapon = zp_register_extra_item(g_item_name, g_item_cost, ZP_TEAM_HUMAN)
	#endif

	register_clcmd("say /g_gun", "buy_gg")
	
	// Register Cvars
	cvar_one_round = register_cvar("sweapon_oneround", "0") 		//購買後只能在該回合使用[1=是/0=否]
	
	// Register Ham Forward
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, SPECIAL_WEAPON_CLASS, "fw_WeapPriAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, SPECIAL_WEAPON_CLASS, "fw_WeaponPriAttack_Post", 1)
	RegisterHam(Ham_Item_Deploy, SPECIAL_WEAPON_CLASS, "fw_ItemDeploy_Post", 1)
	RegisterHam(Ham_GiveAmmo, "player", "fw_GiveAmmo")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)

	#if !(SPECIAL_WEAPON_ID & SHOTGUNS_BITSUM)
	RegisterHam(Ham_Item_PostFrame, SPECIAL_WEAPON_CLASS, "fw_Item_PostFrame")
	#else
	RegisterHam(Ham_Weapon_WeaponIdle, SPECIAL_WEAPON_CLASS, "fw_Shotgun_WeaponIdle")
	RegisterHam(Ham_Item_PostFrame, SPECIAL_WEAPON_CLASS, "fw_Shotgun_PostFrame")
	#endif
	
	RegisterHam(Ham_Item_AttachToPlayer, SPECIAL_WEAPON_CLASS, "fw_Item_AttachToPlayer")
	
	#if !(SPECIAL_WEAPON_ID & SHOTGUNS_BITSUM)
	RegisterHam(Ham_Item_PostFrame, SPECIAL_WEAPON_CLASS, "fw_Item_PostFrame_1", 1)
	RegisterHam(Ham_Weapon_Reload, SPECIAL_WEAPON_CLASS, "fw_WeaponReload_1", 1)
	#else
	RegisterHam(Ham_Item_PostFrame, SPECIAL_WEAPON_CLASS, "Shotgun_WeaponReload_1", 1)
	#endif
	
	// Register Fakemeta Forward
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_Touch, "fw_Touch")
	
	// Regsiter Event
	register_event("TextMsg", "event_game_restart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")
	register_event("CurWeapon", "event_cur_weapon", "be", "1=1")
	register_event("AmmoX", "event_ammo_x", "be")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	// Get Message ID
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	
	// Get Maxplayers
	g_maxplayers = get_maxplayers()
	
	#if defined SUPPORT_CZBOT
	// CZBot support
	cvar_botquota = get_cvar_pointer("bot_quota")
	#endif
}

public plugin_precache()
{
	precache_model(SWEAPON_V_Model)
	precache_model(SWEAPON_P_Model)
	precache_model(SWEAPON_W_Model)
	precache_sound(BuyAmmo_Sound)
	precache_sound(weapons_sound)
	precache_sound(weapons_silent_sound)
}

//*==================================================================================================================================
// 購買特殊武器和子彈

#if defined IN_ZP
public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_itemid_sweapon)
	{
		if (has_sweapon[id] && user_has_weapon(id, SPECIAL_WEAPON_ID))
		{
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + g_item_cost)
			client_print(id, print_chat, "[ZP] 你已經擁有%s了.", SPECIAL_WEAPON_NAME)
			return PLUGIN_CONTINUE;
		}
		
		give_user_weapon(id)
		client_print(id, print_chat, "[ZP] 你已購買了一把%s.", SPECIAL_WEAPON_NAME)
	}
	
	return PLUGIN_CONTINUE;
}
#endif

public buy_gg(id)
{
	if (!is_user_alive(id))
		return PLUGIN_HANDLED

	if (has_sweapon[id] && user_has_weapon(id, SPECIAL_WEAPON_ID))
		return PLUGIN_HANDLED

	give_user_weapon(id)

	return PLUGIN_HANDLED;
}

give_user_weapon(id)
{
	if (((1<<SPECIAL_WEAPON_ID) & PRIMARY_WEAPONS_BIT_SUM) && has_custom_weapons(id, PRIMARY_WEAPONS_BIT_SUM))
		drop_weapons(id, 1)
	else if (((1<<SPECIAL_WEAPON_ID) & SECONDARY_WEAPONS_BIT_SUM) && has_custom_weapons(id, SECONDARY_WEAPONS_BIT_SUM))
		drop_weapons(id, 2)
	
	has_sweapon[id] = true
	fm_give_item(id, SPECIAL_WEAPON_CLASS)
	add_ammo(id, Weapon_MaxBpammo) //購買特殊武器後,也給予一些備用子彈
	
	new weap_ent = fm_find_ent_by_owner(-1, SPECIAL_WEAPON_CLASS, id)
	sweapon_clip[id] = cs_get_weapon_ammo(weap_ent)
	
	engclient_cmd(id, SPECIAL_WEAPON_CLASS)
}

public client_command(id)
{
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	new cmd_string[32]
	read_argv(0, cmd_string, 31)
	if (equal(cmd_string, "buyammo1") || equal(cmd_string, "buyammo2"))
	{
		new weap_id = get_user_weapon(id)
		
		// 當玩家正在使用特殊武器時,設定讓玩家購買特殊武器的備用子彈.
		if (has_sweapon[id] && weap_id == SPECIAL_WEAPON_ID)
		{
			buy_weapon_ammo(id)
			return PLUGIN_HANDLED_MAIN;
		}
		
		// 當玩家擁有特殊武器時,若是當正在使用其它武器並購買其備用子彈時,且備用子彈數已滿,
		// 就防止玩家繼續購買其它備用子彈.(因為ZP是購買一次子彈即購買了所有武器的備用子彈)
		if (has_sweapon[id] && user_has_weapon(id, SPECIAL_WEAPON_ID) && 
		DEFAULT_MAXBPAMMO[weap_id] > 2 && cs_get_user_bpammo(id, weap_id) >= DEFAULT_MAXBPAMMO[weap_id])
		{
			return PLUGIN_HANDLED_MAIN;
		}
	}
	
	return PLUGIN_CONTINUE;
}

buy_weapon_ammo(id)
{
	if (!is_user_alive(id) || !has_sweapon[id] || get_user_weapon(id) != SPECIAL_WEAPON_ID)
		return PLUGIN_HANDLED;
	
	if (cs_get_user_bpammo(id, SPECIAL_WEAPON_ID) >= Weapon_MaxBpammo)
		return PLUGIN_HANDLED;
	#if defined IN_ZP
	new money = zp_get_user_ammo_packs(id)
	if (money < g_ammo_cost)
		return PLUGIN_HANDLED;
	
	zp_set_user_ammo_packs(id, money - g_ammo_cost)
	#endif
	add_ammo(id, g_ammo_amount)
	
	client_print(id, print_chat, "你購買了%s的子彈.", SPECIAL_WEAPON_NAME)
	
	return 1;
}

add_ammo(id, amount)
{
	new give_ammo = min(amount, (Weapon_MaxBpammo - sweapon_bpammo[id]))
	
	// Flash ammo in hud
	message_begin(MSG_ONE_UNRELIABLE, g_msgAmmoPickup, _, id)
	write_byte(WEAPON_AMMOID[SPECIAL_WEAPON_ID]) // ammo id
	write_byte(give_ammo) // ammo amount
	message_end()
	
	emit_sound(id, CHAN_ITEM, BuyAmmo_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	sweapon_bpammo[id] += give_ammo
	
	if (get_user_weapon(id) == SPECIAL_WEAPON_ID)
		cs_set_user_bpammo(id, SPECIAL_WEAPON_ID, sweapon_bpammo[id])
}

public fw_GiveAmmo(id, amount, const ammo_type[], max_ammo)
{
	// 防止玩家由非購買子彈的管道取得備用子彈
	if (equal(ammo_type, AMMOTYPE[SPECIAL_WEAPON_ID]))
	{
		if (has_sweapon[id] && get_user_weapon(id) == SPECIAL_WEAPON_ID)
			return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

//*==================================================================================================================================
// 武器造成傷害和擊退力,以及射擊速率設定

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	if (cs_get_user_team(victim) == cs_get_user_team(attacker))
		return HAM_IGNORED;
	
	if (!(damage_type & DMG_BULLET))
		return HAM_IGNORED;
	
	if (!has_sweapon[attacker] || (get_user_weapon(attacker) != SPECIAL_WEAPON_ID))
		return HAM_IGNORED;

	static use_weapon, hitzone
	get_user_attacker(victim, use_weapon, hitzone)
	
	switch (hitzone)
	{
		case 1: SetHamParamFloat(4, damage = Damage_head)
		case 2: SetHamParamFloat(4, damage = Damage_chest)
		case 3: SetHamParamFloat(4, damage = Damage_stomach)
		case 4: SetHamParamFloat(4, damage = Damage_arm)
		case 5: SetHamParamFloat(4, damage = Damage_arm)
		case 6: SetHamParamFloat(4, damage = Damage_leg)
		case 7 :SetHamParamFloat(4, damage = Damage_leg)
	}
	SetHamParamFloat(4, damage)
	
	return HAM_IGNORED;
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// If knockback disabled
	if (!KnockBack_Effect)
		return HAM_IGNORED;
	
	// Non-player damage or self damage
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	// Prevent friendly fire
	if (cs_get_user_team(attacker) == cs_get_user_team(victim))
		return HAM_IGNORED;
	
	// Not bullet damage
	if (!(damage_type & DMG_BULLET))
		return HAM_IGNORED;
	
	if (!has_sweapon[attacker] || (get_user_weapon(attacker) != SPECIAL_WEAPON_ID))
		return HAM_IGNORED;
	
	// Get victim flags
	static victimflags
	victimflags = pev(victim, pev_flags)
	
	// Zombie is ducking on ground
	if (KnockBack_Duck == 0.0 && (victimflags & FL_DUCKING) && (victimflags & FL_ONGROUND))
		return HAM_IGNORED;
	
	// Get distance between players
	static Float:origin1F[3], Float:origin2F[3]
	pev(victim, pev_origin, origin1F)
	pev(attacker, pev_origin, origin2F)
	
	// Max distance exceeded
	if (get_distance_f(origin1F, origin2F) > KnockBack_Distance)
		return HAM_IGNORED;
	
	// Get victim's velocity
	static Float:velocity[3]
	pev(victim, pev_velocity, velocity)
	
	// Use damage on knockback calculation
	if (KnockBack_With_Damage)
		xs_vec_mul_scalar(direction, damage, direction)
	
	// Use weapon power on knockback calculation
	if (KnockBack_Power)
		xs_vec_mul_scalar(direction, KnockBack_Power, direction)
	
	// Apply ducking knockback multiplier
	if ((victimflags & FL_DUCKING) && (victimflags & FL_ONGROUND))
		xs_vec_mul_scalar(direction, KnockBack_Duck, direction)
	
	// Add up the new vector
	xs_vec_add(velocity, direction, direction)
	
	// Should knockback also affect vertical velocity?
	if (!KnockBack_Zvel)
		direction[2] = velocity[2]
	
	// Set the knockback'd victim's velocity
	set_pev(victim, pev_velocity, direction)
	
	SetHamParamVector(4, Float:{0.0, 0.0, 0.0})
	
	return HAM_IGNORED;
}

public fw_WeaponPriAttack_Post(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	static owner
	owner = pev(weapon, pev_owner)
	
	if (!has_sweapon[owner])
		return HAM_IGNORED;
	
	if (FireRate_Multiplier > 0.0)
	{
		// Fire Rate Set
		static Float:next_pri_attack_time
		next_pri_attack_time = get_weapon_next_pri_attack(weapon) - get_weapon_next_pri_attack(weapon) + FireRate_Multiplier
		set_weapon_next_pri_attack(weapon, next_pri_attack_time)
	}
	
	return HAM_IGNORED;
}

public fw_WeapPriAttack(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;

	static weap_id
	weap_id = fm_get_weaponid(weapon)
	if (weap_id != SPECIAL_WEAPON_ID)
		return HAM_IGNORED;

	static owner
	owner = pev(weapon, pev_owner)
	if (!has_sweapon[owner])
		return HAM_IGNORED;

	if (fm_get_weapon_ammo(weapon) > 0)
	{
		if (!get_weapon_use_silent(weapon))
			SendWeaponAnim(owner, Attack_Anim)
		else
			SendWeaponAnim(owner, Attack_Silent_Anim)

		if (weap_id != CSW_USP && weap_id != CSW_M4A1 || !get_weapon_use_silent(weapon))
			emit_sound(owner, CHAN_AUTO, weapons_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		else if (weap_id == CSW_USP || weap_id == CSW_M4A1 && get_weapon_use_silent(weapon))
			emit_sound(owner, CHAN_AUTO, weapons_silent_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)

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

stock fm_get_weapon_ammo(entity)
{
	return get_pdata_int(entity, OFFSET_iClipAmmo, OFFSET_LINUX_WEAPONS);
}

//*==================================================================================================================================
// 武器丟棄和撿取

public fw_SetModel(entity, const model[])
{
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	new owner
	owner = pev(entity, pev_owner)
	
	if (equal(model[7], "w_weaponbox.mdl"))
	{
		user_drop[owner] = entity;
		return FMRES_IGNORED;
	}
	
	if (user_drop[owner] == entity)
	{
		if (has_sweapon[owner] && equal(model[7], WEAPONS_W_MODEL[SPECIAL_WEAPON_ID]))
		{
			fm_call_think(entity)
			
			if (!is_user_alive(owner))
				drop_sweapon(owner, 1, 0)
			else
				drop_sweapon(owner, 0, 1)
			
			drop_time[owner] = get_gametime()
			has_sweapon[owner] = false
		}
	}
	
	user_drop[owner] = -1
	
	return FMRES_IGNORED;
}

public fw_Touch(ptr, ptd)
{
	if (!pev_valid(ptr) || !pev_valid(ptd))
		return FMRES_IGNORED;
	
	new classname[32]
	pev(ptr, pev_classname, classname, charsmax(classname))
	
	if (!equal(classname, SPECIAL_WEAPON_ENTITY))
		return FMRES_IGNORED;

	if (!(1 <= ptd <= 32) || !is_user_alive(ptd))
		return FMRES_IGNORED;

	#if defined IN_ZP
	if (zp_get_user_zombie(ptd) || zp_get_user_survivor(ptd))
		return FMRES_IGNORED;
	#endif
	
	#if defined SUPPORT_BOT_TO_USE
	if (is_user_bot(ptd))
	{
		if (has_custom_weapons(ptd, BOT_USE_WEAPONS_BIT_SUM))
			return FMRES_IGNORED;
		
		if (has_sweapon[ptd])
			return FMRES_IGNORED;
		
		if (((1<<SPECIAL_WEAPON_ID) & PRIMARY_WEAPONS_BIT_SUM) && has_custom_weapons(ptd, PRIMARY_WEAPONS_BIT_SUM))
			drop_weapons(ptd, 1)
		else if (((1<<SPECIAL_WEAPON_ID) & SECONDARY_WEAPONS_BIT_SUM) && has_custom_weapons(ptd, SECONDARY_WEAPONS_BIT_SUM))
			drop_weapons(ptd, 2)
	}
	#endif
	
	if ((((1<<SPECIAL_WEAPON_ID) & PRIMARY_WEAPONS_BIT_SUM) && has_custom_weapons(ptd, PRIMARY_WEAPONS_BIT_SUM)) ||
	(((1<<SPECIAL_WEAPON_ID) & SECONDARY_WEAPONS_BIT_SUM) && has_custom_weapons(ptd, SECONDARY_WEAPONS_BIT_SUM)))
		return FMRES_IGNORED;
	
	if (get_gametime() - drop_time[ptd] < 0.5)
		return FMRES_IGNORED;
	
	has_sweapon[ptd] = true
	fm_give_item(ptd, SPECIAL_WEAPON_CLASS)
	
	static weap_clip, weap_bpammo, weap_ent
	weap_clip = pev(ptr, pev_iuser3)
	weap_bpammo = min(sweapon_bpammo[ptd] + pev(ptr, pev_iuser4), Weapon_MaxBpammo)
	weap_ent = fm_find_ent_by_owner(-1, SPECIAL_WEAPON_CLASS, ptd)
	
	cs_set_weapon_ammo(weap_ent, weap_clip)
	sweapon_bpammo[ptd] = weap_bpammo
	
	if (get_user_weapon(ptd) == SPECIAL_WEAPON_ID)
		cs_set_user_bpammo(ptd, SPECIAL_WEAPON_ID, weap_bpammo)
	
	engfunc(EngFunc_RemoveEntity, ptr)
	
	client_print(ptd, print_chat, "[ZP] 你撿到了一把%s.", SPECIAL_WEAPON_NAME)
	
	return FMRES_IGNORED;
}

public drop_sweapon(id, store_bpammo, drop_type)
{
	// create a entity for weapon
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if (!pev_valid(ent)) return 0;
	
	// set weapon's info and states
	set_pev(ent, pev_classname, SPECIAL_WEAPON_ENTITY)
	set_pev(ent, pev_iuser1, 0) // hasn't bounced yet
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_TOSS)
	
	// set weapon entity's size
	new Float:mins[3] = { -16.0, -16.0, -16.0 }
	new Float:maxs[3] = { 16.0, 16.0, 16.0 }
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	// remember weapon's clip and bpammo
	set_pev(ent, pev_iuser3, sweapon_clip[id])
	
	if (store_bpammo)
	{
		set_pev(ent, pev_iuser4, sweapon_bpammo[id])
		sweapon_bpammo[id] = 0
	}
	else
	{
		set_pev(ent, pev_iuser4, 0)
	}
	
	cs_set_user_bpammo(id, SPECIAL_WEAPON_ID, origin_weapon_bpammo[id])
	
	// get player's angle and set weapon's angle
	new Float:angles[3]
	pev(id, pev_angles, angles)
	angles[0] = angles[2] = 0.0
	set_pev(ent, pev_angles, angles)
	
	// set weapon's model
	engfunc(EngFunc_SetModel, ent, SWEAPON_W_Model)
	
	// get player's origin and set weapon's origin
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	// set weapon's drop origin, angles and velocity
	if (drop_type)
	{
		new Float:velocity[3]
		velocity_by_aim(id, 15, velocity)
		origin[0] += velocity[0]
		origin[1] += velocity[1]
		origin[2] += velocity[2]
		set_pev(ent, pev_origin, origin)
		velocity_by_aim(id, 400, velocity)
		set_pev(ent, pev_velocity, velocity)
	}
	else
	{
		new Float:drop_angle = random_float(0.0, 360.0)
		origin[0] += 15.0 * floatcos(drop_angle, degrees)
		origin[1] += 15.0 * floatsin(drop_angle, degrees)
		set_pev(ent, pev_origin, origin)
	}
	
	return 1;
}

//*==================================================================================================================================
// 武器模型設定,以及彈匣子彈數量和備用子彈數量設定

public fw_ItemDeploy_Post(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	// Get weapon's owner
	static owner
	//owner = pev(weapon, pev_owner)
	owner = fm_cs_get_weapon_ent_owner(weapon)
	
	if (has_sweapon[owner])
		return HAM_IGNORED;

	set_sweapon_model(owner)

	if (!get_weapon_use_silent(weapon))
		SendWeaponAnim(owner, Draw_Anim)
	else
		SendWeaponAnim(owner, Draw_Silent_Anim)

	return HAM_IGNORED;
}

public event_cur_weapon(id)
{
	// Player not alive
	if (!is_user_alive(id))
		return;
	
	new weap_id, weap_clip, weap_bpammo
	weap_id = get_user_weapon(id, weap_clip, weap_bpammo)
	
	if (has_sweapon[id])
	{
		if (weap_id == SPECIAL_WEAPON_ID)
		{
			set_sweapon_model(id)
			
			if (user_weapon[id] != SPECIAL_WEAPON_ID)
				cs_set_user_bpammo(id, SPECIAL_WEAPON_ID, sweapon_bpammo[id])
			
			sweapon_clip[id] = weap_clip
			
			#if defined SUPPORT_CZBOT
			if (is_user_bot(id) && sweapon_clip[id] == 0 && sweapon_bpammo[id] == 0)
				buy_weapon_ammo(id)
			#endif
		}
		else if (!user_has_weapon(id, SPECIAL_WEAPON_ID))
		{
			has_sweapon[id] = false
			cs_set_user_bpammo(id, SPECIAL_WEAPON_ID, origin_weapon_bpammo[id])
		}
	}
	
	user_weapon[id] = weap_id
}

public event_ammo_x(id)
{
	// Player not alive
	if (!is_user_alive(id))
		return;
	
	// Get ammo type
	new ammo_type = read_data(1)
	
	// Unknown ammo type
	if (ammo_type >= 15)
		return;
	
	// Get bpammo amount
	new bpammo = read_data(2)
	
	if (ammo_type != WEAPON_AMMOID[SPECIAL_WEAPON_ID])
		return;
	
	if (has_sweapon[id] && get_user_weapon(id) == SPECIAL_WEAPON_ID)
		sweapon_bpammo[id] = bpammo
	else
		origin_weapon_bpammo[id] = bpammo
	
	
}

set_sweapon_model(id)
{
	set_pev(id, pev_viewmodel2, SWEAPON_V_Model)
	set_pev(id, pev_weaponmodel2, SWEAPON_P_Model)
}

//*==================================================================================================================================
// 武器自訂彈匣所能裝填的子彈數量設定

public fw_Item_AttachToPlayer(iEnt, id)
{
	if (Weapon_MaxClip <= 0)
		return;
	
	if (fm_get_weapon_known(iEnt))
		return;
	
	if (!has_sweapon[id])
		return;
	
	cs_set_weapon_ammo(iEnt, Weapon_MaxClip)
}

#if !(SPECIAL_WEAPON_ID & SHOTGUNS_BITSUM)
public fw_Item_PostFrame(iEnt)
{
	if (Weapon_MaxClip <= 0)
		return;
	
	static id
	id = fm_get_ent_owner(iEnt)
	
	if (!has_sweapon[id])
		return;
	
	static iId
	iId = fm_get_weaponid(iEnt)
	
	static fInReload
	fInReload = get_weapon_in_reload(iEnt)
	
	static Float:flNextAttack
	flNextAttack = get_user_next_attack(id)
	
	static iBpAmmo
	iBpAmmo = cs_get_user_bpammo(id, iId)
	
	static iClip
	iClip = cs_get_weapon_ammo(iEnt)
	
	if (fInReload && flNextAttack <= 0.0)
	{
		new j = min(Weapon_MaxClip - iClip, iBpAmmo)
		cs_set_weapon_ammo(iEnt, iClip + j)
		cs_set_user_bpammo(id, iId, iBpAmmo-j)
		
		set_weapon_in_reload(iEnt, 0)
		fInReload = 0
	}
	
	static iButton
	iButton = pev(id, pev_button)
	
	if ((iButton & IN_ATTACK2 && get_weapon_next_sec_attack(iEnt) <= 0.0)
	|| (iButton & IN_ATTACK && get_weapon_next_pri_attack(iEnt) <= 0.0))
	{
		return;
	}
	
	if (iButton & IN_RELOAD && !fInReload)
	{
		if (iClip >= Weapon_MaxClip)
		{
			set_pev(id, pev_button, iButton & ~IN_RELOAD)
			
			if (SILENT_WEAPON_BITSUM & (1<<iId) && !get_weapon_use_silent(iEnt))
				SendWeaponAnim(id, iId == CSW_USP ? Idle_Anim_USP : Idle_Anim_M4A1)
			else
				SendWeaponAnim(id, Idle_Anim)
		}
		else if (iClip == DEFAULT_MAXCLIP[iId])
		{
			if (iBpAmmo)
			{
				set_user_next_attack(id, RELOAD_DELAYTIME[iId])
				
				if (SILENT_WEAPON_BITSUM & (1<<iId) && get_weapon_use_silent(iEnt))
					SendWeaponAnim(id, iId == CSW_USP ? Silent_Reload_Anim_USP : Silent_Reload_Anim_M4A1)
				else
					SendWeaponAnim(id, Reload_Anim)
				
				set_weapon_in_reload(iEnt, 1)
				set_weapon_idle_time(iEnt, RELOAD_DELAYTIME[iId] + 0.5)
				
				ExecuteHamB(Ham_Weapon_Reload, iEnt)
			}
		}
	}
}
#else
public fw_Shotgun_WeaponIdle(iEnt)
{
	if (Weapon_MaxClip <= 0)
		return;
	
	if (get_weapon_idle_time(iEnt) > 0.0)
		return;
	
	static id
	id = fm_get_ent_owner(iEnt)
	
	if (!has_sweapon[id])
		return;
	
	static iId
	iId = fm_get_weaponid(iEnt)
	
	static iClip
	iClip = cs_get_weapon_ammo(iEnt)
	
	static fInSpecialReload
	fInSpecialReload = get_weapon_in_special_reload(iEnt)
	
	if (!iClip && !fInSpecialReload)
		return;
	
	if (fInSpecialReload)
	{
		static iBpAmmo
		iBpAmmo = cs_get_user_bpammo(id, CSW_M3)
			
		static iDftMaxClip
		iDftMaxClip = DEFAULT_MAXCLIP[iId]
			
		if (iClip < Weapon_MaxClip && iClip == iDftMaxClip && iBpAmmo)
		{
			Shotgun_Reload(iEnt, iId, Weapon_MaxClip, iClip, iBpAmmo, id)
			return;
		}
		else if (iClip == Weapon_MaxClip && iClip != iDftMaxClip)
		{
			SendWeaponAnim(id, Reload_Anim)
				
			set_weapon_in_special_reload(iEnt, 0)
			set_weapon_idle_time(iEnt, 1.5)
		}
	}
	
	return;
}

public fw_Shotgun_PostFrame(iEnt)
{
	if (Weapon_MaxClip <= 0)
		return;
	
	static id
	id = fm_get_ent_owner(iEnt)
	
	if (!has_sweapon[id])
		return;
	
	static iId
	iId = fm_get_weaponid(iEnt)
	
	static iBpAmmo
	iBpAmmo = cs_get_user_bpammo(id, CSW_M3)
	
	static iClip
	iClip = cs_get_weapon_ammo(iEnt)
	
	// Support for instant reload (used for example in my plugin "Reloaded Weapons On New Round")
	if (get_weapon_in_reload(iEnt) && get_user_next_attack(id) <= 0.0 )
	{
		new j = min(Weapon_MaxClip - iClip, iBpAmmo)
		cs_set_weapon_ammo(iEnt, iClip + j)
		cs_set_user_bpammo(id, CSW_M3, iBpAmmo - j)
		
		set_weapon_in_reload(iEnt, 0)
		return;
	}
	
	static iButton
	iButton = pev(id, pev_button)
	
	if (iButton & IN_ATTACK && get_weapon_next_pri_attack(iEnt) <= 0.0 )
		return;
	
	if (iButton & IN_RELOAD)
	{
		if (iClip >= Weapon_MaxClip)
		{
			set_pev(id, pev_button, iButton & ~IN_RELOAD) // still this fucking animation
			set_weapon_next_pri_attack(iEnt, 0.5)  // Tip ?
		}
		else if (iClip == DEFAULT_MAXCLIP[iId])
		{
			if (iBpAmmo)
				Shotgun_Reload(iEnt, iId, Weapon_MaxClip, iClip, iBpAmmo, id)
		}
	}
}

Shotgun_Reload(iEnt, iId, Weapon_MaxClip, iClip, iBpAmmo, id)
{
	if (iBpAmmo <= 0 || iClip == Weapon_MaxClip)
		return;
	
	if (get_weapon_next_pri_attack(iEnt) > 0.0)
		return;
	
	switch (get_weapon_in_special_reload(iEnt))
	{
		case 0:
		{
			SendWeaponAnim(id, Reload_Anim)
			set_weapon_in_special_reload(iEnt, 1)
			set_user_next_attack(id, 0.55)
			set_weapon_idle_time(iEnt, 0.55)
			set_weapon_next_pri_attack(iEnt, 0.55)
			set_weapon_next_sec_attack(iEnt, 0.55)
			
			ExecuteHamB(Ham_Weapon_Reload, iEnt)
			
			return;
		}
		case 1:
		{
			if (get_weapon_idle_time(iEnt) > 0.0)
				return;
			
			set_weapon_in_special_reload(iEnt, 2)
			emit_sound(id, CHAN_ITEM, random_num(0, 1) ? "weapons/reload1.wav" : "weapons/reload3.wav", 1.0, ATTN_NORM, 0, 85 + random_num(0, 0x1f))
			SendWeaponAnim(id, Reload_Anim)
			set_weapon_idle_time(iEnt, iId == CSW_XM1014 ? 0.30 : 0.45)
		}
		default:
		{
			cs_set_weapon_ammo(iEnt, iClip + 1)
			cs_set_user_bpammo(id, CSW_M3, iBpAmmo-1)
			set_weapon_in_special_reload(iEnt, 1)
		}
	}
}
#endif

//*==================================================================================================================================
// 武器裝彈速度

#if !(SPECIAL_WEAPON_ID & SHOTGUNS_BITSUM)
public fw_Item_PostFrame_1(weapon)
{
	if (Weapon_ReloadDelay <= 0.0)
		return HAM_IGNORED;
	
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	static id
	id = pev(weapon, pev_owner)
	
	if (!has_sweapon[id])
		return HAM_IGNORED;
	
	static weap_id
	weap_id = fm_get_weaponid(weapon)
	
	if (get_weapon_in_reload(weapon))
	{
		user_reload_weapon[id] = weap_id
	}
	else
	{
		if (user_reload_weapon[id] != -1)
		{
			if (weap_id == user_reload_weapon[id])
			{
				if (weap_id == CSW_USP && !get_weapon_use_silent(weapon))
					SendWeaponAnim(id, Idle_Anim_USP)
				else if (weap_id == CSW_M4A1 && !get_weapon_use_silent(weapon))
					SendWeaponAnim(id, Idle_Anim_M4A1)
				else
					SendWeaponAnim(id, Idle_Anim)
			}
		}
		
		user_reload_weapon[id] = -1
	}
	
	return HAM_IGNORED;
}

public fw_WeaponReload_1(weapon)
{
	if (Weapon_ReloadDelay <= 0.0)
		return HAM_IGNORED;
	
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	if (!get_weapon_in_reload(weapon))
		return HAM_IGNORED;
	
	static id
	id = pev(weapon, pev_owner)
	
	if (!has_sweapon[id])
		return HAM_IGNORED;
	
	set_user_next_attack(id, Weapon_ReloadDelay)
	set_weapon_idle_time(weapon, Weapon_ReloadDelay + 0.5)
	
	return HAM_IGNORED;
}
#else
public Shotgun_WeaponReload_1(weapon)
{
	if (Weapon_ReloadDelay <= 0.0)
		return HAM_IGNORED;
	
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	static weap_id
	weap_id = fm_get_weaponid(weapon)
	
	static id
	id = pev(weapon, pev_owner)
	
	if (!has_sweapon[id])
		return HAM_IGNORED;
	
	static button
	button = pev(id, pev_button)
	
	static Float:weap_next_pri_attack_time
	weap_next_pri_attack_time = get_weapon_next_pri_attack(weapon)
	
	if ((button & IN_ATTACK) && weap_next_pri_attack_time <= 0.0 )
		return HAM_IGNORED;
	
	static weap_special_reload
	weap_special_reload = get_weapon_in_special_reload(weapon)
	
	static Float:weap_idle_time
	weap_idle_time = get_weapon_idle_time(weapon)
	
	if (weap_special_reload == 2)
	{
		if ((weap_id == CSW_M3 && weap_idle_time == 0.45) || (weap_id == CSW_XM1014 && weap_idle_time == 0.30))
		{
			set_weapon_idle_time(weapon, Weapon_ReloadDelay)
		}
	}
	
	return HAM_IGNORED;
}
#endif

//*==================================================================================================================================
// 其它項目
/*
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	static weapon_id
	weapon_id = get_user_weapon(id)
	if (weapon_id != SPECIAL_WEAPON_ID)
		return FMRES_IGNORED;

	if (!has_sweapon[id])
		return FMRES_IGNORED;

	if (!is_user_bot(id))
	{
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.01)
	}
	else
	{
		id = cd_handle
		set_cd(id, CD_flNextAttack, get_gametime() + 0.01)
	}

	return FMRES_IGNORED;
}*/

public client_connect(id)
{
	has_sweapon[id] = false
	sweapon_bpammo[id] = 0
}

public client_disconnect(id)
{
	has_sweapon[id] = false
	sweapon_bpammo[id] = 0
}

public event_game_restart()
{
	for (new i = 1; i <= 32; i++)
	{
		has_sweapon[i] = false
	}
}

public event_round_start()
{
	remove_all_sweapon()
	
	set_task(0.1, "reset_players_weapon")
}

public reset_players_weapon()
{
	if (get_pcvar_num(cvar_one_round))
	{
		for (new i = 1; i <= g_maxplayers; i++)
		{
			if (has_sweapon[i])
			{
				has_sweapon[i] = false
				
				if (is_user_connected(i) && is_user_alive(i) && get_user_weapon(i) == SPECIAL_WEAPON_ID)
				{
					reset_weapon_model(i)
				}
			}
			
			sweapon_bpammo[i] = 0
		}
	}
	else
	{
		for (new i = 1; i <= g_maxplayers; i++)
		{
			if (is_user_connected(i) && is_user_alive(i) && has_sweapon[i] && !user_has_weapon(i, SPECIAL_WEAPON_ID))
			{
				has_sweapon[i] = false
			}
		}
	}
}

remove_all_sweapon()
{
	new ent = -1
	while((ent = fm_find_ent_by_class(ent, SPECIAL_WEAPON_ENTITY)) != 0)
	{
		engfunc(EngFunc_RemoveEntity, ent)
	}
}

reset_weapon_model(id)
{
	new weap_id, weap_clip, weap_bpammo
	weap_id = get_user_weapon(id, weap_clip, weap_bpammo)
	
	new weap_name[32], weap_ent
	get_weaponname(weap_id, weap_name, charsmax(weap_name))
	ExecuteHamB(Ham_Item_Deploy, (weap_ent = fm_find_ent_by_owner(-1, weap_name, id)))
	
	if (DEFAULT_MAXCLIP[weap_id])
	{
		weap_clip = min(weap_clip, DEFAULT_MAXCLIP[weap_id])
		cs_set_weapon_ammo(weap_ent, weap_clip)
	}
}

#if defined IN_ZP
#if defined SUPPORT_BOT_TO_USE
public zp_round_started(gamemode, id)
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_connected(i) || !is_user_bot(i) || !is_user_alive(i) || zp_get_user_zombie(i) || has_sweapon[i])
			continue;
		
		if (zp_get_user_survivor(i))
			continue;
		
		set_task(3.0, "bot_random_buy_sweapon", TASK_BOT_BUY_WEAPON)
	}
}

public bot_random_buy_sweapon(taskid)
{
	new id = taskid - TASK_BOT_BUY_WEAPON
	
	if (!is_user_bot(id) || !is_user_alive(id) || has_sweapon[id])
		return;
	
	if (has_custom_weapons(id, BOT_USE_WEAPONS_BIT_SUM))
		return;
	
	new money = zp_get_user_ammo_packs(id)
	// 設定BOT只有在所擁有的金錢數量大於 "購買特殊武器的價格+5個子彈包" 時,才會選擇購買特殊武器.
	if (money < (g_item_cost + 5))
		return;
	
	// 設定讓BOT有20%機率會選擇購買特殊武器
	if (random_float(0.0, 1.0) > 0.8)
	{
		zp_set_user_ammo_packs(id, money - g_item_cost)
		give_user_weapon(id)
	}
}
#endif
#endif

//*==================================================================================================================================
// Stocks

stock drop_weapons(id, dropwhat) // dropwhat: 1 = primary weapon , 2 = secondary weapon
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || 
		(dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon name
			static wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			
			// Drop weapon
			engclient_cmd(id, "drop", wname)
		}
	}
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

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && (pev(entity, pev_owner) != owner)) {}
	
	return entity;
}

stock fm_find_ent_by_class(index, const classname[])
{
	return engfunc(EngFunc_FindEntityByString, index, "classname", classname) 
}

stock fm_call_think(entity)
{
	return dllfunc(DLLFunc_Think, entity)
}

stock SendWeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(iAnim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_iWeaponOwner, OFFSET_LINUX_WEAPONS);
}

stock Float:get_weapon_next_pri_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextPrimaryAttack, OFFSET_LINUX_WEAPONS);
}

stock set_weapon_next_pri_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextPrimaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock fm_get_ent_owner(entity)
{
	return get_pdata_cbase(entity, OFFSET_iWeaponOwner, OFFSET_LINUX_WEAPONS);
}

stock fm_get_weaponid(entity)
{
	return get_pdata_int(entity, OFFSET_iWeaponId, OFFSET_LINUX_WEAPONS);
}

stock fm_get_weapon_known(entity)
{
	return get_pdata_int(entity, OFFSET_iWeaponKnown, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_next_sec_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextSecondaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_sec_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextSecondaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_idle_time(entity)
{
	return get_pdata_float(entity, OFFSET_flTimeWeaponIdle, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_idle_time(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flTimeWeaponIdle, time, OFFSET_LINUX_WEAPONS)
}

stock get_weapon_in_reload(entity)
{
	return get_pdata_int(entity, OFFSET_iInReload, OFFSET_LINUX_WEAPONS);
}

stock set_weapon_in_reload(entity, reload_flag)
{
	set_pdata_int(entity, OFFSET_iInReload, reload_flag, OFFSET_LINUX_WEAPONS);
}

stock get_weapon_in_special_reload(entity)
{
	return get_pdata_int(entity, OFFSET_iInSpecialReload, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_in_special_reload(entity, special_reload_flag)
{
	set_pdata_int(entity, OFFSET_iInSpecialReload, special_reload_flag, OFFSET_LINUX_WEAPONS)
}

stock get_weapon_use_silent(entity)
{
	return get_pdata_int(entity, OFFSET_iWeaponSilent, OFFSET_LINUX_WEAPONS)
}

stock Float:get_user_next_attack(id)
{
	return get_pdata_float(id, OFFSET_flNextAttack, OFFSET_LINUX)
}

stock set_user_next_attack(id, Float:time)
{
	set_pdata_float(id, OFFSET_flNextAttack, time, OFFSET_LINUX)
}

//*==================================================================================================================================
// CZBot Debug

#if defined SUPPORT_CZBOT
// CZBot support
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
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHamFromEntity(Ham_GiveAmmo, id, "fw_GiveAmmo")
}
#endif