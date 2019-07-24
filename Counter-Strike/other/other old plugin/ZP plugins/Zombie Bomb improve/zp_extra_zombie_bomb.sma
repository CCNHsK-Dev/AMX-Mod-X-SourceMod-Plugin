
#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

/*  18/8/2012   */

#define SUPPORT_BOT_TO_USE		//支援BOT使用.(在最前面加上 // 即取消對BOT的技援)

#define Plugin    "[ZP] Extra Item: Jumping Zombie [Bot can use ]"
#define Version	  "1.0 [1.2]"
#define Author    "NiHiLaNTh [HsK]"

new const g_PlayerModel[] = "models/zombie_plague/p_grenade_knock.mdl"
new const g_ViewModel[] = "models/zombie_plague/v_grenade_infect_WB.mdl"
new const g_WorldModel[] = "models/zombie_plague/w_grenade_knock.mdl"

new const g_SoundBombExplode[][] = { "zombi/zombi_bomb_exp.wav" }	//爆炸sound
new const g_SoundBombBO[][] = { "zombi/zombi_bomb_deploy.wav" }		//取出sound

new const g_szItemName[] = "狂暴手榴彈" 
new const g_iItemPrice = 1

#define RADIUS        300		//影響地帶

new g_iNadeID
new g_MaxPlayers, g_msgAmmoPickup 
new g_iJumpingNadeCount[33]
new g_iExplo
// CvarS
new cvar_speed

#if defined SUPPORT_BOT_TO_USE
new g_bot_use[33], Float:bot_a[33]
#endif

public plugin_init()
{
	register_plugin(Plugin, Version, Author)

	cvar_speed = register_cvar("zp_zombiebomb_knockback", "1000")	//彈走的力度

	g_iNadeID = zp_register_extra_item (g_szItemName, g_iItemPrice, ZP_TEAM_ZOMBIE)

	register_event("CurWeapon", "EV_CurWeapon", "be", "1=1")
	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0")
//	register_event("DeathMsg", "event_Death", "a") 

	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")

	#if defined SUPPORT_BOT_TO_USE
	register_forward(FM_PlayerPreThink, "fwd_PlayerPreThink")
	#endif

	g_msgAmmoPickup = get_user_msgid("AmmoPickup")

	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model (g_PlayerModel)
	precache_model (g_ViewModel)
	precache_model (g_WorldModel)

	new i
    	for (i = 0; i < sizeof g_SoundBombExplode; i++)
        	precache_sound(g_SoundBombExplode[i])
	for (i =0; i< sizeof g_SoundBombBO; i++)
		precache_sound(g_SoundBombBO[i])

	precache_sound("items/9mmclip1.wav")
	precache_sound("items/gunpickup2.wav")

    	g_iExplo = precache_model("sprites/deimosexp.spr")	// Spr
}

public client_connect(id) g_iJumpingNadeCount[id] = 0

public zp_extra_item_selected(id, Item)
{
	if (Item == g_iNadeID)
	{
		if (g_iJumpingNadeCount[id] >= 5)
		{
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + g_iItemPrice)
			client_print(id, print_chat, "[ZP] 你不能取得更多 狂暴手榴彈 !")
			return PLUGIN_HANDLED;
		}

		give_zp_item(id)
	}

	return PLUGIN_CONTINUE
}

give_zp_item(id)
{
        if (!zp_get_user_zombie(id) || zp_get_user_nemesis(id)) return;

	new iBpAmmo = cs_get_user_bpammo(id, CSW_SMOKEGRENADE)
		
	if (g_iJumpingNadeCount[id] >= 1)
	{
		cs_set_user_bpammo(id, CSW_SMOKEGRENADE, iBpAmmo+1)

		emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		AmmoPickup(id,13,1)

		g_iJumpingNadeCount[id]++
	}
	else
	{
		give_item(id,"weapon_smokegrenade")

		emit_sound(id, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		AmmoPickup(id, 13, 1)

		g_iJumpingNadeCount[id] = 1
	}
}

public zp_user_infected_post(id)
{
	if(zp_get_user_nemesis(id)) g_iJumpingNadeCount[id] = 0              //復仇不可得到 跳彈
	else
	{
		give_item(id, "weapon_smokegrenade")
		g_iJumpingNadeCount[id] = 1

		emit_sound(id, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		AmmoPickup(id, 13, 1)
	}
}

public zp_user_humanized_post(id) g_iJumpingNadeCount[id] = 0

#if defined SUPPORT_BOT_TO_USE
public fwd_PlayerPreThink(id)
{
	if (!is_user_bot(id))
	{
		g_bot_use[id] = false
		return FMRES_IGNORED;
	}

        if (!zp_get_user_zombie(id) || zp_get_user_nemesis(id))
	{
		g_bot_use[id] = false
		return FMRES_IGNORED;
	}

	new target, hitzone
	get_user_aiming(id, target, hitzone)

	if (!(1 <= target <= 32) || !is_user_alive(target) || zp_get_user_zombie(target)) return FMRES_IGNORED;

	new origin[3], target_origin[3], distance, Float:velocity[3]
	get_user_origin(id, origin)
	get_user_origin(target, target_origin)
	distance = get_distance(origin, target_origin)
	fm_get_aim_vector(id, 20, velocity)

	if (!(300 <= distance <= 1000)) return FMRES_IGNORED;

	if (g_iJumpingNadeCount[id] == 0)
	{
		if (g_bot_use[id]) g_bot_use[id] = false

		new ammo = zp_get_user_ammo_packs(id)
		new bot_buy = random_num(1, 50)
		if (bot_buy == 1 || bot_buy == 2 && ammo > g_iItemPrice + 3)
		{
			give_zp_item(id)
			zp_set_user_ammo_packs(id, ammo - g_iItemPrice)
		}
		else return FMRES_IGNORED;
	}

	if (!g_bot_use[id])
	{
		new will_use[33]

		will_use[id]=random_num(1, 10)
		if (will_use[id] < 3)
			return FMRES_IGNORED;
		else
			g_bot_use[id] = true
	}
	if (300 <= distance <= 500) bot_a[id]=16.0
	else if (501 <= distance <= 700) bot_a[id]=17.0
	else if (701 <= distance <= 1000) bot_a[id]=18.0
	else if (1001 <= distance <= 1300) bot_a[id]=19.0
	else if (1301 <= distance <= 1500) bot_a[id]=20.0

	if (g_bot_use[id])
	{
		engclient_cmd(id, "weapon_smokegrenade")
		set_vector_change_angle2(velocity, 0.0, bot_a[id], velocity)
		set_pev(id, pev_button, (pev(id, pev_button) | IN_ATTACK))
	}

	return FMRES_IGNORED;
}
#endif

public EV_CurWeapon(id)
{
	if (!is_user_alive(id) || !zp_get_user_zombie(id))
		return PLUGIN_CONTINUE

	new weap_id = get_user_weapon(id)

	if (g_iJumpingNadeCount[id] > 0 && weap_id == CSW_SMOKEGRENADE)
	{
		set_pev(id, pev_viewmodel2, g_ViewModel)
		set_pev(id, pev_weaponmodel2, g_PlayerModel)

		emit_sound(id, CHAN_WEAPON, g_SoundBombBO[random_num(0, sizeof g_SoundBombBO-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}

	return PLUGIN_CONTINUE
}

public event_RoundStart() arrayset(g_iJumpingNadeCount, 0, 33)
/*
public event_Death()
{
	new id = read_data(2)
	if (!(1 <= id <= 32)) return;

	set_task(5.0, "off_bomb", id)
}

public off_bomb(id) g_iJumpingNadeCount[id] = 0
*/
public fw_SetModel(Entity, const Model[])
{
	if (Entity < 0) return FMRES_IGNORED

	if(pev(Entity, pev_dmgtime) == 0.0) return FMRES_IGNORED

	new iOwner = entity_get_edict(Entity, EV_ENT_owner)    

	if (g_iJumpingNadeCount[iOwner] >= 1 && equal (Model[7], "w_sm", 4) && zp_get_user_zombie(iOwner))
	{

		#if defined SUPPORT_BOT_TO_USE
		if (g_bot_use[iOwner])
		{
			new Float:velocity[3]
			fm_get_aim_vector(iOwner, 30, velocity)
			g_bot_use[iOwner] = false
			set_vector_change_angle2(velocity, 0.0, bot_a[iOwner], velocity)
		}
		#endif

		set_pev(Entity, pev_flTimeStepSound, 0)
	        set_pev(Entity, pev_flTimeStepSound, 26517)

		g_iJumpingNadeCount[iOwner]--

		entity_set_model(Entity, g_WorldModel)
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}

public fw_ThinkGrenade(Entity)
{
	if (!pev_valid(Entity)) return HAM_IGNORED

	static Float:dmg_time
	pev(Entity, pev_dmgtime, dmg_time)

	if (dmg_time > get_gametime()) return HAM_IGNORED

	if (pev(Entity, pev_flTimeStepSound) == 26517)
	{
		jumping_explode(Entity)
		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

public jumping_explode(Entity)
{
	if (Entity < 0)
		return;

	static Float:flOrigin[3]
	pev(Entity, pev_origin, flOrigin)

	//爆炸 Spr
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0)
	write_byte(TE_SPRITE)
    	engfunc(EngFunc_WriteCoord, flOrigin[0])
   	engfunc(EngFunc_WriteCoord, flOrigin[1])
    	engfunc(EngFunc_WriteCoord, flOrigin[2] + 45.0)
    	write_short(g_iExplo)
    	write_byte(35)
    	write_byte(186)
    	message_end()

	//爆炸sound
    	emit_sound(Entity, CHAN_WEAPON, g_SoundBombExplode[random_num(0, sizeof g_SoundBombExplode-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	//爆炸影響
    	for (new i = 1; i < g_MaxPlayers; i++)
    	{
        	if (!is_user_alive(i))
            		continue

        	new Float:flVictimOrigin[3]
        	pev(i, pev_origin, flVictimOrigin)

        	new Float:flDistance = get_distance_f(flOrigin, flVictimOrigin)

        	if (flDistance <= RADIUS)
        	{
			new hp = get_user_health(i)
			new damage = 50
			new temp = damage - 5
			damage -= floatround(float(temp) * flDistance / float(RADIUS))

			new armor = get_user_armor(i)
			new Float:damage_armor_rate, damage_armor
			damage_armor_rate = (3.0 / 4.0) //對人類護甲造成傷害的乘數. (護甲傷害值 = 總傷害值 * 乘數)
			damage_armor = floatround(float(damage) * damage_armor_rate)

			if (damage_armor > 0 && armor > 0)
			{
				if (armor > damage_armor)
				{
					damage -= damage_armor
					set_user_armor(i, armor - damage_armor)
				} 
				else 
				{
					damage -= armor
					set_user_armor(i, 0)
				}
			}

			if (damage > 0)
			{
				if (hp > damage)
					set_user_health(i, hp - damage)
				else 
					set_user_health(i, 1)
			}

            		static Float:flSpeed
            		flSpeed = get_pcvar_float(cvar_speed)

            		static Float:flNewSpeed
            		flNewSpeed = flSpeed * (1.0 - (flDistance / RADIUS))

            		static Float:flVelocity[3]
            		get_speed_vector(flOrigin, flVictimOrigin, flNewSpeed, flVelocity) //彈走的向量
            		set_pev(i, pev_velocity,flVelocity)

			screen_shake(i, 12, 7, 12)
        	}
    	}

	engfunc(EngFunc_RemoveEntity, Entity)
}

public AmmoPickup(id, AmmoID, AmmoAmount)	//得到 跳彈時的圖標
{
	message_begin(MSG_ONE, g_msgAmmoPickup, _, id)
	write_byte(AmmoID)
	write_byte(AmmoAmount)
	message_end()
}

stock screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, id)
	write_short((1<<12)*amplitude) // 振幅
	write_short((1<<12)*duration) // 時間
	write_short((1<<12)*frequency) // 頻率
	message_end()
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
    	new_velocity[2] = origin2[2] - origin1[2]
    	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
    	new_velocity[0] *= num
    	new_velocity[1] *= num
    	new_velocity[2] *= num
    
    	return 1;
}

stock fm_get_aim_vector(index, view_distance, Float:view_vector[3])
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
	
	return 1;
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
