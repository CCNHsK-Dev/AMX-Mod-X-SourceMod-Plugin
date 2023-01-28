
/*
	#define FLA_ZP_NNE		// 支援 ZP 燃燒彈 (在最前面加上 // 即取消對ZP 燃燒彈的技援)

	***********要更改 ZP************ By" HsK
*/

#include <amxmodx>
#include <xs>
#include <fun>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

/*  15/7/1010 */

#define PLUGIN	"[ZP] ZM: Hazmat Zombie & HM: Fire Weapon  [L4D2]"
#define VERSION	"1.1"
#define AUTHOR	"HsK"

#define FLA_ZP_NNE		// 支援 ZP 燃燒彈 (在最前面加上 // 即取消對ZP 燃燒彈的技援)

#define FLAME_DURATION args[0]
#define FLAME_ATTACKER args[1]

const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux
const OFFSET_iWeapId = 43
const OFFSET_iClipAmmo = 51

new const WEAPON_CLASSNAME[][] = { "", "weapon_p228", "", "weapon_scout", "", "weapon_xm1014", "", "weapon_mac10",
	"weapon_aug", "", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas",
	"weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
	"weapon_tmp", "weapon_g3sg1", "", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" }

// Zombie
new const zclass_name[] = { "L4D2_Hazmat" }
new const zclass_info[] = { "不怕火焰" }
new const zclass_model[] = { "winkler_himik" }
new const zclass_clawmodel[] = { "v_HimikHandsNew.mdl" }
const zclass_health = 5000
const zclass_speed = 280
const Float:zclass_gravity = 0.8
const Float:zclass_knockback = 0.1

new g_zclass_hazmat

//------------------------------------------------------------------------------
// Hm item

new g_item_name[] = { "火焰子彈" } 	//道具名稱
new g_item_cost = 1 			//購買"火焰子彈"要花多少子彈包

new g_itemid_fire_weapon
new g_fire_weapon[33] = 0
new cvar_fire_ammo_max, cvar_firl_ammo_buy
new cvar_fireduration, cvar_firedamage, cvar_fireslowdown

new g_flameSpr, g_smokeSpr, g_msgSync
new cvar_botquota
new bool:BotHasDebug = false
new g_bot_buy[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	//火焰子彈
	cvar_fire_ammo_max = register_cvar("zp_fire_ammo_max", "90")		//火焰子彈, 最多有多小
	cvar_firl_ammo_buy = register_cvar("zp_fire_ammo_buy", "30")		//買一次火焰子彈可得到多小

	cvar_fireduration = register_cvar("zp_fire_fireduration", "10")		// 燃燒時間
	cvar_firedamage = register_cvar("zp_fire_damage", "10") 		// 燃燒傷害 [每0.2秒]
	cvar_fireslowdown = register_cvar("zp_fire_slowdown", "0.7") 		// 燃燒減慢速度 (0.5 = 速度減一半) [0-關閉]

	g_itemid_fire_weapon = zp_register_extra_item(g_item_name, g_item_cost, ZP_TEAM_HUMAN)

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")

	for (new i = 0; i < sizeof WEAPON_CLASSNAME; i++)
	{
		if (strlen(WEAPON_CLASSNAME[i]) == 0)
			continue;
		
		RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_CLASSNAME[i], "fw_WeapPriAttack")
	}

	g_msgSync = CreateHudSyncObj()

	cvar_botquota = get_cvar_pointer("bot_quota")
}

public plugin_precache()
{
	g_zclass_hazmat = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)

	g_flameSpr = precache_model("sprites/flame.spr")
	g_smokeSpr = precache_model("sprites/black_smoke3.spr")
}

public zp_user_infected_post(id, infector)
{
	if (zp_get_user_zombie_class(id) == g_zclass_hazmat)
	{
		#if defined FLA_ZP_NNE
		zp_set_zombie_flame(id, 1)
		#endif
		client_print(id, print_chat, "[ZP] 你是L4D2的Hazmat..你不怕火焰子彈效果!")
	}
}

public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_itemid_fire_weapon)
		buy_ammo(id)
}

buy_ammo(id)
{
	new buy_packs

	if (g_bot_buy[id])
		buy_packs = g_item_cost / 2
	else
		buy_packs = g_item_cost


	if (g_fire_weapon[id] == get_pcvar_num(cvar_fire_ammo_max))
	{
		zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + buy_packs)
		client_print(id, print_chat, "[ZP] 火焰子彈巳滿, 不用再買!!")
		return
	}

	if (get_pcvar_num(cvar_fire_ammo_max) > get_pcvar_num(cvar_firl_ammo_buy))
	{
		new ammo = g_fire_weapon[id] + get_pcvar_num(cvar_firl_ammo_buy)

		if (ammo > get_pcvar_num(cvar_fire_ammo_max))
			g_fire_weapon[id] = get_pcvar_num(cvar_fire_ammo_max)
		else
			g_fire_weapon[id] = ammo

		client_print(id, print_chat, "[ZP] 你買了%d粒火焰子彈!!", get_pcvar_num(cvar_firl_ammo_buy))
	}
	else
	{
		g_fire_weapon[id] = get_pcvar_num(cvar_fire_ammo_max)
		client_print(id, print_chat, "[ZP] 你已補充火焰子彈!!")
	}
	
	if (g_bot_buy[id])
		zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - buy_packs)
}

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	if (is_user_bot(id) && g_bot_buy[id])
	{
		if (g_fire_weapon[id] < get_pcvar_num(cvar_firl_ammo_buy) / 2)
		{
			switch (random_num(1, 3))
			{
				case 1: g_bot_buy[id] = false
				case 2..3:
				{
					new packs = zp_get_user_ammo_packs(id)
					if (packs > g_item_cost / 2)
					{
						g_bot_buy[id] = true
						buy_ammo(id)
					}
				}
			}
		}
	}

	if (!is_user_bot(id))
	{
		if (g_bot_buy[id])
			g_bot_buy[id] = false
	}

	#if defined FLA_ZP_NNE
	if (zp_get_user_zombie(id))
	{
		if ((zp_get_user_zombie_class(id) == g_zclass_hazmat))
			zp_set_zombie_flame(id, 1)
		else
			zp_set_zombie_flame(id, 0)
	}
	#endif

	return FMRES_IGNORED;
}

public fw_WeapPriAttack(weapon)
{
	if (!pev_valid(weapon))
		return HAM_IGNORED;

	if (fm_get_weaponid(weapon) == CSW_KNIFE)
		return HAM_IGNORED;

	static owner
	owner = pev(weapon, pev_owner)
	
	if (fm_get_weapon_ammo(weapon) > 0 && g_fire_weapon[owner] > 0)
	{
		g_fire_weapon[owner] -= 1
		hud_firl_ammo(owner)
	}

	return HAM_IGNORED;
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (!g_fire_weapon[attacker])
		return HAM_IGNORED;

	if ((get_user_weapon(attacker) == CSW_KNIFE))
		return HAM_IGNORED;

	// Non-player damage or self damage
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED;

	// Prevent friendly fire
	if (zp_get_user_zombie(attacker) == zp_get_user_zombie(victim))
		return HAM_IGNORED;

	// Victim isn't a normal zombie
	if (!zp_get_user_zombie(victim))
		return HAM_IGNORED;

	if (!(damage_type & DMG_BULLET))
		return HAM_IGNORED;

	if ((zp_get_user_zombie_class(victim) == g_zclass_hazmat))
		return FMRES_IGNORED;

	vic_fire(victim, attacker)

	return HAM_IGNORED;
}

vic_fire(id, i)
{
	static params[2]
	params[0] = get_pcvar_num(cvar_fireduration) * 5 // duration
	params[1] = i; // attacker

	set_task(0.2, "burning_flame", id, params, sizeof params)
}

public burning_flame(args[2], id)
{
	if (!is_user_alive(id))
		return;

	static Float:originF[3]
	pev(id, pev_origin, originF)

	if ((pev(id, pev_flags) & FL_INWATER) || FLAME_DURATION < 1)
	{
		// Smoke sprite
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_SMOKE) // TE id
		engfunc(EngFunc_WriteCoord, originF[0]) // x
		engfunc(EngFunc_WriteCoord, originF[1]) // y
		engfunc(EngFunc_WriteCoord, originF[2]-50.0) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		return;
	}

	if ((pev(id, pev_flags) & FL_ONGROUND) && get_pcvar_float(cvar_fireslowdown) > 0.0)
	{
		static Float:velocity[3]
		pev(id, pev_velocity, velocity)
		xs_vec_mul_scalar(velocity, get_pcvar_float(cvar_fireslowdown), velocity)
		set_pev(id, pev_velocity, velocity)
	}

	static health
	health = pev(id, pev_health)

	if (health > get_pcvar_float(cvar_firedamage))
		fm_set_user_health(id, health - floatround(get_pcvar_float(cvar_firedamage)))
	else
		ExecuteHamB(Ham_Killed, id, FLAME_ATTACKER, 0)

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPRITE) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]+random_float(-5.0, 5.0)) // x
	engfunc(EngFunc_WriteCoord, originF[1]+random_float(-5.0, 5.0)) // y
	engfunc(EngFunc_WriteCoord, originF[2]+random_float(-10.0, 10.0)) // z
	write_short(g_flameSpr) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()
	
	// Decrease burning duration counter
	FLAME_DURATION -= 1

	new Float:firl_time
	if (0.2 > get_pcvar_num(cvar_fireduration))
		firl_time = get_pcvar_num(cvar_fireduration) - 0.1
	else
		firl_time = 0.2

	// Keep sending flame messages
	set_task(firl_time, "burning_flame", id, args, sizeof args)
}


public hud_firl_ammo(id)
{
	set_hudmessage(0, 200, 200, 0.90, 0.90, 0, 6.0, 0.8, 0.0, 0.0, -1)
	ShowSyncHudMsg(id, g_msgSync, "火焰子彈彈藥:%d發", g_fire_weapon[id])
}

public zp_round_started(gamemode, id) set_task (0.1, "bot_buy")

public bot_buy()
{
	for (new id = 1; id <= 32; id++)
	{
		if (!is_user_connected(id) && !is_user_bot(id) || !is_user_alive(id))
			continue;

		if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
			continue;

		if (g_fire_weapon[id])
			continue;

		g_bot_buy[id] = false

		new packs = zp_get_user_ammo_packs(id)
		if (packs > g_item_cost / 2)
			set_task(random_float(1.3, 12.0), "bot_buy_anno", id)
	}
}

public bot_buy_ammo(id)
{
	switch (random_num(1, 3))
	{
		case 1: g_bot_buy[id] = false
		case 2: g_bot_buy[id] = false
		case 3: 
		{
			new packs = zp_get_user_ammo_packs(id)
			if (packs > g_item_cost / 2)
			{
				g_bot_buy[id] = true
				buy_ammo(id)
			}
		}
	}
}

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
}

stock fm_set_user_health(id, health)
	(health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);

stock fm_get_weaponid(entity)
	return get_pdata_int(entity, OFFSET_iWeapId, OFFSET_LINUX_WEAPONS);

stock fm_get_weapon_ammo(entity)
	return get_pdata_int(entity, OFFSET_iClipAmmo, OFFSET_LINUX_WEAPONS);