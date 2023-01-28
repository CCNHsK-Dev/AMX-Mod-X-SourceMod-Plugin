/////////////////////////////////////////////////////////////////////////////
//////////這喪屍是 彷 CSO , 龍牙刃插件 (附冰龍M4A1和煉獄CV-47插件)///////////
///////////////只要身上有龍牙刃 冰龍M4A1和煉獄CV-47換彈時間減小!!////////////
///////////////這插件由 MyChat數位男女會員:sk@.@  寫出 (原創)////////////////
/////////////////////////////////////////////////////////////////////////////
/*                                 更新日誌
*                            v1.1 : 加入支援BOT
*                           v1.2 : 支援CSO 專屬mdl
*/

/* 12/2/2010 */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN  "[ZP] Extra:Buy Aralia_Knife and AK47 , M4A1"
#define VERSION "1.2"
#define AUTHOR  "MyChat數位男女會員:sk@.@"

//-------------------------------------------------------------------------------------------------------

#define SUPPORT_BOT_TO_USE			//支援BOT使用.(在最前面加上 // 即取消對BOT的技援)

#if defined SUPPORT_BOT_TO_USE

#define TASK_BOT_BUY_ITEM	3344

// Bot use weapon bitsums #設定BOT如果持有那些槍就不會再購買或撿取"冰龍M4A1"或"煉獄CV-47"
const BOT_USE_WEAPONS_BIT_SUM = (1<<CSW_M4A1)|(1<<CSW_AK47)|(1<<CSW_SG550)|(1<<CSW_AWP)|(1<<CSW_M249)|(1<<CSW_G3SG1)

#endif

//-------------------------------------------------------------------------------------------------------

#define TASK_CHECK_WEAPON	98765

// Primary Weapons bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|
	(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|
	(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

// Weapons Offsets (Win32)
const OFFSET_iWeapId = 43
const OFFSET_flTimeWeaponIdle = 48
const OFFSET_iWeapInReload = 54
const OFFSET_flNextAttack = 83

// Linux diff's
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_LINUX = 5

//-------------------------------------------------------------------------------------------------------

new g_item_name[] = { "龍牙刃" }
new g_itemid_aralia_knife, g_aralia_knife_cost
new g_has_aralia_knife[33]

new const AraliaKnife_P_Model[] = "models/zombie_plague/p_knifedragon.mdl" //龍牙刃的 p_ 模型
new const AraliaKnife_V_Model[] = "models/zombie_plague/v_knifedragon.mdl" //龍牙刃的 v_ 模型
new const Get_Item_Sound[] = "items/knifedragon_draw.wav" //得到龍牙刃時的音效

//-------------------------------------------------------------------------------------------------------

new g_item1_name[] = { "冰龍M4A1" }
new g_itemid_icem4a1, g_icem4a1_cost
new g_has_icem4a1[33]

new const ICEM4A1_Classname[] = "ICEM4A1_ENTITY" //冰龍M4A1的物件名稱(***不可更改此項目名稱***)

const Float:ICEM4A1_Reload_Time = 2.3	//冰龍M4A1的裝彈時間(單位:秒)(***不可更改此項目設定值***)

new const ICEM4A1_P_Model[] = "models/zombie_plague/p_m4a1dragon.mdl" //冰龍M4A1的 p_ 模型
new const ICEM4A1_V_Model[] = "models/zombie_plague/v_m4a1dragon.mdl" //冰龍M4A1的 v_ 模型
new const ICEM4A1_W_Model[] = "models/zombie_plague/w_m4a1dragon.mdl" //冰龍M4A1的 w_ 模型

//-------------------------------------------------------------------------------------------------------

new g_item2_name[] = { "煉獄CV-47" }
new g_itemid_hellak47, g_hellak47_cost
new g_has_hellak47[33]

new const HELLAK47_Classname[] = "HELLAK47_ENTITY" //煉獄CV-47的物件名稱(***不可更改此項目名稱***)

const Float:HELLAK47_Reload_Time = 1.9	//煉獄CV-47的裝彈時間(單位:秒)(***不可更改此項目設定值***)

new const HELLAK47_P_Model[] = "models/zombie_plague/p_ak47dragon.mdl" //煉獄CV-47的 p_ 模型
new const HELLAK47_V_Model[] = "models/zombie_plague/v_ak47dragon.mdl" //煉獄CV-47的 v_ 模型
new const HELLAK47_W_Model[] = "models/zombie_plague/w_ak47dragon.mdl" //煉獄CV-47的 w_ 模型

//-------------------------------------------------------------------------------------------------------

new user_drop[33]
new user_clip[33], user_bpammo[33]
new use_silencer[33]
new Float:drop_time[33]

public plugin_init()
{
        register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_aralia_knife_cost = register_cvar("zp_aralia_knife_cost", "5")	//買龍牙刃要花多少子彈包
	g_icem4a1_cost = register_cvar("zp_icem4a1_cost", "10")			//買冰龍M4A1要花多少子彈包
	g_hellak47_cost = register_cvar("zp_hellak47_cost", "10")		//買煉獄CV-47要花多少子彈包
	
	g_itemid_aralia_knife = zp_register_extra_item(g_item_name, get_pcvar_num(g_aralia_knife_cost), ZP_TEAM_HUMAN)
	g_itemid_icem4a1 = zp_register_extra_item(g_item1_name, get_pcvar_num(g_icem4a1_cost), ZP_TEAM_HUMAN)
	g_itemid_hellak47 = zp_register_extra_item(g_item2_name, get_pcvar_num(g_hellak47_cost), ZP_TEAM_HUMAN)
	
	RegisterHam(Ham_Item_PostFrame, "weapon_m4a1", "fw_Item_PostFrame", 1)
	RegisterHam(Ham_Weapon_Reload, "weapon_m4a1", "fw_WeaponReload", 1)
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "fw_WeaponReload", 1)
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_Touch, "fw_Touch")
	
	register_event("CurWeapon", "event_cur_weapon", "be", "1=1")
	register_event("DeathMsg", "event_death", "a")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
}

public plugin_precache()
{
	precache_model(AraliaKnife_P_Model)
	precache_model(AraliaKnife_V_Model)
	precache_sound(Get_Item_Sound)
	
	precache_model(ICEM4A1_P_Model)
	precache_model(ICEM4A1_V_Model)
	precache_model(ICEM4A1_W_Model)

	precache_model(HELLAK47_P_Model)
	precache_model(HELLAK47_V_Model)
	precache_model(HELLAK47_W_Model)
}

public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_itemid_aralia_knife)
	{
		if (g_has_aralia_knife[id])
		{
			new ammo_packs = zp_get_user_ammo_packs(id)
			zp_set_user_ammo_packs(id, ammo_packs + get_pcvar_num(g_aralia_knife_cost))
			client_print(id, print_chat, "[ZP] 你已有%s了!!!", g_item_name)
			return PLUGIN_CONTINUE;
		}
		
		g_has_aralia_knife[id] = true
		
		if (get_user_weapon(id) == CSW_KNIFE)
			set_aralia_knife_model(id)
		else
			engclient_cmd(id, "weapon_knife")
		
		emit_sound(id, CHAN_ITEM, Get_Item_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		client_print(id, print_chat, "[ZP] 你購買了%s了!如果使用 %s 或 %s ,換彈時間減小!!", g_item_name, g_item1_name, g_item2_name)
		client_print(id, print_chat, "[ZP] 如果沒有被感染或死亡,%s便不會消失!!!", g_item_name)
	}
	
	if (itemid == g_itemid_icem4a1)
	{
		if (g_has_icem4a1[id] && user_has_weapon(id, CSW_M4A1))
		{
			new ammo_packs = zp_get_user_ammo_packs(id)
			zp_set_user_ammo_packs(id, ammo_packs + get_pcvar_num(g_icem4a1_cost))
			client_print(id, print_chat, "[ZP] 你已有%s!!!", g_item1_name)
			return PLUGIN_CONTINUE;
		}
		
		drop_primary_weapons(id)
		g_has_icem4a1[id] = true
		fm_give_item(id, "weapon_m4a1")
		cs_set_user_bpammo(id, CSW_M4A1, 90)
		engclient_cmd(id, "weapon_m4a1")
		
		new weapon_ent = fm_find_ent_by_owner(-1, "weapon_m4a1", id)
		user_clip[id] = cs_get_weapon_ammo(weapon_ent)
		user_bpammo[id] = cs_get_user_bpammo(id, CSW_M4A1)
		
		client_print(id, print_chat, "[ZP] 你購買了%s了!如果身上有%s,換彈時間減小!!", g_item1_name, g_item_name)
		client_print(id, print_chat, "[ZP] 如果沒有被感染或死亡,%s便不會消失!!!", g_item1_name)
		client_print(id, print_chat, "[ZP] 但%s攻擊力和普通M4A1一樣!!", g_item1_name)
	}
	
	if (itemid == g_itemid_hellak47)
	{
		if (g_has_hellak47[id] && user_has_weapon(id, CSW_AK47))
		{
			new ammo_packs = zp_get_user_ammo_packs(id)
			zp_set_user_ammo_packs(id, ammo_packs + get_pcvar_num(g_hellak47_cost))
			client_print(id, print_chat, "[ZP] 你已有%s了!!!", g_item2_name)
			return PLUGIN_CONTINUE;
		}
		
		drop_primary_weapons(id)
		g_has_hellak47[id] = true
		fm_give_item(id, "weapon_ak47")
		cs_set_user_bpammo(id, CSW_AK47, 90)
		engclient_cmd(id, "weapon_ak47")
		
		new weapon_ent = fm_find_ent_by_owner(-1, "weapon_ak47", id)
		user_clip[id] = cs_get_weapon_ammo(weapon_ent)
		user_bpammo[id] = cs_get_user_bpammo(id, CSW_AK47)
		
		client_print(id, print_chat, "[ZP] 你購買了%s了!如果身上有%s,換彈時間減小!!", g_item2_name, g_item_name)
		client_print(id, print_chat, "[ZP] 如果沒有被感染或死亡,%s便不會消失!!!", g_item2_name)
		client_print(id, print_chat, "[ZP] 但%s攻擊力和普通AK47一樣!!", g_item2_name)
	}
	
	return PLUGIN_CONTINUE;
}

public fw_Item_PostFrame(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	static id
	id = pev(weapon, pev_owner)
	
	if (!g_has_icem4a1[id])
		return HAM_IGNORED;
	
	use_silencer[id] = cs_get_weapon_silen(weapon)
	
	return HAM_IGNORED;
}

public fw_WeaponReload(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;
	
	if (!get_weapon_in_reload(weapon))
		return HAM_IGNORED;
	
	static id
	id = pev(weapon, pev_owner)
	
	if (!g_has_aralia_knife[id])
		return HAM_IGNORED;
	
	static weapon_id
	weapon_id = fm_get_weaponid(weapon)
	
	if ((weapon_id == CSW_M4A1 && !g_has_icem4a1[id]) || (weapon_id == CSW_AK47 && !g_has_hellak47[id]))
		return HAM_IGNORED;
	
	static Float:next_attack_time
	next_attack_time = (weapon_id == CSW_M4A1) ? ICEM4A1_Reload_Time : HELLAK47_Reload_Time
	
	if (next_attack_time <= 0.0 || next_attack_time > get_user_next_attack(id))
		return HAM_IGNORED;
	
	set_user_next_attack(id, next_attack_time)
	set_weapon_idle_time(weapon, next_attack_time + 0.5)
	set_pev(id, pev_frame, 200.0)
	
	if (weapon_id == CSW_M4A1)
	{
		if (cs_get_weapon_silen(weapon))
			SendWeaponAnim(id, 14)
		else
			SendWeaponAnim(id, 15)
	}
	else
	{
		SendWeaponAnim(id, 6)
	}
	
	return HAM_IGNORED;
}

public fw_SetModel(entity, const model[])
{
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	static id
	id = pev(entity, pev_owner)
	
	if (equal(model[7], "w_weaponbox.mdl"))
	{
		user_drop[id] = entity;
		return FMRES_IGNORED;
	}
	
	if (user_drop[id] == entity)
	{
		if (g_has_icem4a1[id] && equal(model[7], "w_m4a1.mdl"))
		{
			new link_weapon = find_weapon_by_entity(entity)
			if (link_weapon != -1)
				fm_kill_entity(link_weapon)
			
			fm_kill_entity(entity)
			
			if (!is_user_alive(id) || zp_get_user_zombie(id))
				drop_weapon(id, "weapon_m4a1", ICEM4A1_Classname, ICEM4A1_W_Model, 1, 0)
			else
				drop_weapon(id, "weapon_m4a1", ICEM4A1_Classname, ICEM4A1_W_Model, 0, 1)
			
			drop_time[id] = get_gametime()
			g_has_icem4a1[id] = false
			user_drop[id] = -1
		}
		else if (g_has_hellak47[id] && equal(model[7], "w_ak47.mdl"))
		{
			new link_weapon = find_weapon_by_entity(entity)
			if (link_weapon != -1)
				fm_kill_entity(link_weapon)
			
			fm_kill_entity(entity)
			
			if (!is_user_alive(id) || zp_get_user_zombie(id))
				drop_weapon(id, "weapon_ak47", HELLAK47_Classname, HELLAK47_W_Model, 1, 0)
			else
				drop_weapon(id, "weapon_ak47", HELLAK47_Classname, HELLAK47_W_Model, 0, 1)
			
			drop_time[id] = get_gametime()
			g_has_hellak47[id] = false
		}
	}
	
	user_drop[id] = -1
	
	return FMRES_IGNORED;
}

public fw_Touch(ptr, ptd)
{
	if (!pev_valid(ptr) || !pev_valid(ptd))
		return FMRES_IGNORED;
	
	if (!(1 <= ptd <= 32) || !is_user_connected(ptd) || !is_user_alive(ptd) || zp_get_user_zombie(ptd) || zp_get_user_survivor(ptd))
		return FMRES_IGNORED;
	
	new classname[32]
	pev(ptr, pev_classname, classname, charsmax(classname))
	
	#if defined SUPPORT_BOT_TO_USE
	if (is_user_bot(ptd))
	{
		if (has_custom_weapons(ptd, BOT_USE_WEAPONS_BIT_SUM))
			return FMRES_IGNORED;
		
		if (g_has_icem4a1[ptd] || g_has_hellak47[ptd])
			return FMRES_IGNORED;
		
		if (equal(classname, ICEM4A1_Classname) || equal(classname, HELLAK47_Classname))
			drop_primary_weapons(ptd)
	}
	#endif
	
	if (has_custom_weapons(ptd, PRIMARY_WEAPONS_BIT_SUM))
		return FMRES_IGNORED;
	
	if (get_gametime() - drop_time[ptd] < 0.5)
		return FMRES_IGNORED;
	
	if (equal(classname, ICEM4A1_Classname))
	{
		g_has_icem4a1[ptd] = true
		//fm_give_item(ptd, "weapon_m4a1")
		fm_give_weapon(ptd, "weapon_m4a1", pev(ptr, pev_iuser4))
		user_clip[ptd] = pev(ptr, pev_iuser2)
		user_bpammo[ptd] = min(cs_get_user_bpammo(ptd, CSW_M4A1) + pev(ptr, pev_iuser3), 90)
		new weapon_ent = fm_find_ent_by_owner(-1, "weapon_m4a1", ptd)
		cs_set_weapon_ammo(weapon_ent, user_clip[ptd])
		cs_set_user_bpammo(ptd, CSW_M4A1, user_bpammo[ptd])
		engfunc(EngFunc_RemoveEntity, ptr)
		client_print(ptd, print_chat, "[ZP] 你撿到了一把%s!", g_item1_name)
		
		#if defined SUPPORT_BOT_TO_USE
		if (is_user_bot(ptd) && !!g_has_aralia_knife[ptd])
		{
			remove_task(ptd+TASK_BOT_BUY_ITEM)
			set_task(1.0, "bot_random_buy_knife", ptd+TASK_BOT_BUY_ITEM)
		}
		#endif
	}
	else if (equal(classname, HELLAK47_Classname))
	{
		g_has_hellak47[ptd] = true
		fm_give_item(ptd, "weapon_ak47")
		user_clip[ptd] = pev(ptr, pev_iuser2)
		user_bpammo[ptd] = min(cs_get_user_bpammo(ptd, CSW_AK47) + pev(ptr, pev_iuser3), 90) 
		new weapon_ent = fm_find_ent_by_owner(-1, "weapon_ak47", ptd)
		cs_set_weapon_ammo(weapon_ent, user_clip[ptd])
		cs_set_user_bpammo(ptd, CSW_AK47, user_bpammo[ptd])
		engfunc(EngFunc_RemoveEntity, ptr)
		client_print(ptd, print_chat, "[ZP] 你撿到了一把%s!!", g_item2_name)
		
		#if defined SUPPORT_BOT_TO_USE
		if (is_user_bot(ptd) && !!g_has_aralia_knife[ptd])
		{
			remove_task(ptd+TASK_BOT_BUY_ITEM)
			set_task(1.0, "bot_random_buy_knife", ptd+TASK_BOT_BUY_ITEM)
		}
		#endif
	}
	
	return FMRES_IGNORED;
}

public event_cur_weapon(id)
{
	if (!is_user_alive(id))
		return;
	
	set_aralia_knife_model(id)
	set_icem4a1_model(id)
	set_hellak47_model(id)
	
	new weapon, clip, bpammo
	weapon = get_user_weapon(id, clip, bpammo)
	
	if ((g_has_icem4a1[id] && weapon == CSW_M4A1) || (g_has_hellak47[id] && weapon == CSW_AK47))
	{
		user_clip[id] = clip
		user_bpammo[id] = bpammo
	}
}

set_aralia_knife_model(id)
{
	if (g_has_aralia_knife[id] && get_user_weapon(id) == CSW_KNIFE)
	{
		set_pev(id, pev_viewmodel2, AraliaKnife_V_Model)
		set_pev(id, pev_weaponmodel2, AraliaKnife_P_Model)
	}
}

set_icem4a1_model(id)
{
	if (g_has_icem4a1[id] && get_user_weapon(id) == CSW_M4A1)
	{
		set_pev(id, pev_viewmodel2, ICEM4A1_V_Model)
		set_pev(id, pev_weaponmodel2, ICEM4A1_P_Model)
	}
}

set_hellak47_model(id)
{
	if (g_has_hellak47[id] && get_user_weapon(id) == CSW_AK47)
	{
		set_pev(id, pev_viewmodel2, HELLAK47_V_Model)
		set_pev(id, pev_weaponmodel2, HELLAK47_P_Model)
	}
}

drop_weapon(id, const weapon[], const classname[], const weapon_model[], store_bpammo, drop_type)
{
	// create a entity for weapon
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!ent) return 0;
	
	set_pev(ent, pev_classname, classname)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_iuser1, 0) // hasn't bounced yet
	
	// set weapon entity's size
	new Float:mins[3] = { -16.0, -16.0, -16.0 }
	new Float:maxs[3] = { 16.0, 16.0, 16.0 }
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	// set weapon's states
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_TOSS)
	
	// remember norecoil weapon's clip and bpammo
	set_pev(ent, pev_iuser2, user_clip[id])
	
	if (store_bpammo)
	{
		set_pev(ent, pev_iuser3, user_bpammo[id])
		
		new weapon_id = get_weaponid(weapon)
		cs_set_user_bpammo(id, weapon_id, 0)
	}
	else
	{
		set_pev(ent, pev_iuser3, 0)
	}
	
	set_pev(ent, pev_iuser4, use_silencer[id])
	
	// get player's angle and set weapon's angle
	new Float:angles[3]
	pev(id, pev_angles, angles)
	angles[0] = angles[2] = 0.0
	set_pev(ent, pev_angles, angles)
	
	// set weapon's model
	if (strlen(weapon_model) > 0)
	{
		engfunc(EngFunc_SetModel, ent, weapon_model)
	}
	else
	{
		new model[32]
		format(model, 31, "models/w_%s.mdl", weapon[7])
		engfunc(EngFunc_SetModel, ent, model)
	}
	
	// get player's origin and set weapon's origin
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	// set norecoil weapon's drop origin, angles and velocity
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

remove_weapon()
{
	new ent = -1
	while((ent = fm_find_ent_by_class(ent, ICEM4A1_Classname)) > 0)
	{
		engfunc(EngFunc_RemoveEntity, ent)
	}
	
	ent = -1
	while((ent = fm_find_ent_by_class(ent, HELLAK47_Classname)) > 0)
	{
		engfunc(EngFunc_RemoveEntity, ent)
	}
}

public zp_user_infected_post(id, infector)
{
	g_has_aralia_knife[id] = false
}

public client_connect(id)
{
	g_has_aralia_knife[id] = false
	g_has_icem4a1[id] = false
	g_has_hellak47[id] = false
}

public client_disconnect(id)
{
	g_has_aralia_knife[id] = false
	g_has_icem4a1[id] = false
	g_has_hellak47[id] = false
}

public event_death()
{
	new id = read_data(2)
	if (!(1 <= id <= 32))
		return;
	
	g_has_aralia_knife[id] = false
}

public event_round_start()
{
	remove_weapon()
	set_task(0.1, "check_players_weapon", TASK_CHECK_WEAPON)
}

public check_players_weapon()
{
	for (new id = 1; id <= 32; id++)
	{
		if (!is_user_connected(id) || !is_user_alive(id))
			continue;
		
		if (g_has_aralia_knife[id])
		{
			client_print(id, print_chat, "[ZP] 你的%s還可以使用!", g_item_name)
		}
		
		if (g_has_icem4a1[id] && user_has_weapon(id, CSW_M4A1))
		{
			client_print(id, print_chat, "[ZP] 你的%s還可以使用!", g_item1_name)
		}
		else
		{
			g_has_icem4a1[id] = false
		}
		
		if (g_has_hellak47[id] && user_has_weapon(id, CSW_AK47))
		{
			client_print(id, print_chat, "[ZP] 你的%s還可以使用!", g_item2_name)
		}
		else
		{
			g_has_hellak47[id] = false
		}
	}
}

stock drop_primary_weapons(id)
{
	static weapons[32], num, i, weaponid
	num = 0
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

stock fm_get_weaponid(entity)
{
	return get_pdata_int(entity, OFFSET_iWeapId, OFFSET_LINUX_WEAPONS);
}

stock get_weapon_in_reload(entity)
{
	return get_pdata_int(entity, OFFSET_iWeapInReload, OFFSET_LINUX_WEAPONS);
}

stock set_weapon_idle_time(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flTimeWeaponIdle, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_user_next_attack(id)
{
	return get_pdata_float(id, OFFSET_flNextAttack, OFFSET_LINUX)
}

stock set_user_next_attack(id, Float:time)
{
	set_pdata_float(id, OFFSET_flNextAttack, time, OFFSET_LINUX)
}

stock SendWeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(iAnim)
	write_byte(pev(id, pev_body))
	message_end()
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

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && (pev(entity, pev_owner) != owner)) {}
	
	return entity;
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

stock find_weapon_by_entity(entity)
{
	new start_ent, max_ents
	start_ent = get_maxplayers() + 1
	max_ents = global_get(glb_maxEntities)
	
	new i, classname[32]
	for (i = start_ent; i <= max_ents; i++)
	{
		if (!pev_valid(i))
			continue;
		
		pev(i, pev_classname, classname, sizeof classname - 1)
		if (!equal(classname, "weapon_", 7))
			continue;
		
		if (entity == pev(i, pev_owner))
			return i;
	}
	
	return -1;
}

#if defined SUPPORT_BOT_TO_USE
public zp_round_started(gamemode, id)
{
	for (new i = 1; i <= 32; i++)
	{
		if (!is_user_connected(i) || !is_user_bot(i) || !is_user_alive(i) || zp_get_user_zombie(i) || zp_get_user_survivor(i))
			continue;
		
		if (!(g_has_icem4a1[i] || g_has_hellak47[i]) && !has_custom_weapons(i, BOT_USE_WEAPONS_BIT_SUM))
		{
			remove_task(i+TASK_BOT_BUY_ITEM)
			set_task(5.0, "bot_random_buy_gun", i+TASK_BOT_BUY_ITEM)
		}
		else if ((g_has_icem4a1[i] || g_has_hellak47[i]) && !g_has_aralia_knife[i])
		{
			remove_task(i+TASK_BOT_BUY_ITEM)
			set_task(5.0, "bot_random_buy_knife", i+TASK_BOT_BUY_ITEM)
		}
	}
}

public bot_random_buy_gun(taskid)
{
	new id = taskid - TASK_BOT_BUY_ITEM
	
	if (!is_user_bot(id) || !is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return;
	
	if (!(g_has_icem4a1[id] || g_has_hellak47[id]) && !has_custom_weapons(id, BOT_USE_WEAPONS_BIT_SUM))
	{
		if (random_num(1, 100) > 70)
		{
			new buy_weapon_id = (random_num(0, 1) == 1) ? g_itemid_icem4a1 : g_itemid_hellak47
			new ammo_packs = zp_get_user_ammo_packs(id)
			new buy_cost = (buy_weapon_id == g_itemid_icem4a1) ? get_pcvar_num(g_icem4a1_cost) : get_pcvar_num(g_hellak47_cost)
			
			if (ammo_packs >= (buy_cost + 5))
			{
				zp_extra_item_selected(id, buy_weapon_id)
			}
		}
	}
	
	if ((g_has_icem4a1[id] || g_has_hellak47[id]) && !g_has_aralia_knife[id])
	{
		remove_task(id+TASK_BOT_BUY_ITEM)
		set_task(1.0, "bot_random_buy_knife", id+TASK_BOT_BUY_ITEM)
	}
}

public bot_random_buy_knife(taskid)
{
	new id = taskid - TASK_BOT_BUY_ITEM
	
	if (!is_user_bot(id) || !is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return;
	
	if ((g_has_icem4a1[id] || g_has_hellak47[id]) && !g_has_aralia_knife[id])
	{
		if (random_num(1, 100) > 50)
		{
			zp_extra_item_selected(id, g_itemid_aralia_knife)
		}
	}
}
#endif

