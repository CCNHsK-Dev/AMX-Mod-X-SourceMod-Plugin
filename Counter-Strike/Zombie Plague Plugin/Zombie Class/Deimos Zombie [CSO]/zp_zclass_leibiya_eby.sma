#include <amxmodx>
#include <xs>
#include <fun>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

/* 17/4/2010 */

#define PLUGIN	"[ZP] Class: Lei Biya Evolution body Zombie (CSO)"
#define VERSION	"1.3"
#define AUTHOR	"HsK"

#define TASK_ID_1 ent+7777

#define SUPPORT_BOT_TO_USE		//支援BOT使用.(在最前面加上 // 即取消對BOT的技援)

new const shockwave_Model[] = { "models/zombie_plague/w_shockwaveball.mdl" }

new const shockwave_att_Sound[] = { "zombi/deimos_skill_start.wav" }			//光束發出前  揮尾巴聲音

new const shockwave_det_Sound[] = { "zombi/zombi_bomb_exp.wav" }			//光束爆炸的聲音

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

new const zclass_name[] = { "雷比亞進化體" }
new const zclass_info[] = { "發出光波,令人類武器掉下" }
new const zclass_model[] = { "zp_leibiya_eby" }
new const zclass_clawmodel[] = { "v_knife_zombideimos.mdl" }
const zclass_health = 5000
const zclass_speed = 200
const Float:zclass_gravity = 1.0
const Float:zclass_knockback = 0.1

new g_zclass_leibiya_eby
new g_trailSpr, g_explodeSpr
new cooldown[33]
new cvar_shockwave_radius, cvar_shockwave_speed, cvar_cooldown_time, cvar_attshoc_cool_time

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	cvar_shockwave_radius = register_cvar("zp_shockwave_radius", "80")  	 	//光波範圍
	cvar_shockwave_speed = register_cvar("zp_shockwave_speed", "1800")  	 	//光波速度
	cvar_cooldown_time = register_cvar("zp_cooldown_time", "10") 			//光波冷卻

	cvar_attshoc_cool_time = register_cvar("zp_attshoc_cool_time", "0.5") 		//按鍵後..多小秒後出現 光波  [1=1s  , 0.5=0.5s]

	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_CmdStart, "fw_CmdStart")

	register_event("ResetHUD", "event_NewRound", "be")
	register_event("DeathMsg", "event_Death", "a")
}

public plugin_precache()
{
	g_zclass_leibiya_eby = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)

	precache_model(shockwave_Model)
	precache_sound(shockwave_det_Sound)
	precache_sound(shockwave_att_Sound)

	g_trailSpr = precache_model("sprites/smoke.spr")
	g_explodeSpr = precache_model("sprites/zombie_plague/deimosexp.spr")	//爆炸spr
}

public zp_user_infected_post(id, infector)
{
	if (zp_get_user_zombie_class(id) == g_zclass_leibiya_eby)
	{
		client_print(id, print_chat, "[ZP] 準心對準人類按R可使用光波,令人類武器掉下!")
	}
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	if (!zp_get_user_zombie(id) || (zp_get_user_zombie_class(id) != g_zclass_leibiya_eby))
		return FMRES_IGNORED;
	
	if (zp_get_user_nemesis(id))
		return FMRES_IGNORED;

	static button
	button = get_uc(uc_handle, UC_Buttons)
	
	if (button & IN_RELOAD)
	{
		if (!cooldown[id])
		{
			att_shockwave(id)
			cooldown[id] = true
			set_task(get_pcvar_float(cvar_cooldown_time), "cooldown_off", id)
		}
		if (cooldown[id])
		{
			client_print(id, print_center, "技能尚未準備好，你還不能使用'光波'技能。")
		}
	}

	#if defined SUPPORT_BOT_TO_USE
	new enemy, body
	get_user_aiming(id, enemy, body)
	
	if (is_user_bot(id) && (1 <= enemy <= 32) && !zp_get_user_zombie(enemy))
	{
		if (!cooldown[id])
		{
			att_shockwave(id)
			cooldown[id] = true
			set_task(get_pcvar_float(cvar_cooldown_time), "cooldown_off", id)
		}
	}
	#endif

	return FMRES_IGNORED;
}

public cooldown_off(id)
{
	cooldown[id] = false
	client_print(id, print_center, "'光波'技能已冷卻完!!")
}

public fw_Touch(ptr, ptd)
{
	if (!pev_valid(ptr))
		return FMRES_IGNORED;
	
	new classname[32]
	pev(ptr, pev_classname, classname, charsmax(classname))
	
	if (equal(classname, "shockwave_Model"))
		shockwave_detonate(ptr)
	
	return FMRES_IGNORED;
}

public att_shockwave(id)
{
	SendWeaponAnim(id, 2)
	emit_sound(id, CHAN_WEAPON, shockwave_att_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_task(get_pcvar_float(cvar_attshoc_cool_time), "shockwave", id)
}

public shockwave(id)
{
	new ent = create_entity("info_target")
	if (ent == 0) return;
	
	// set entity's status
	entity_set_string(ent,EV_SZ_classname,"shockwave_Model")
	entity_set_int(ent,EV_INT_movetype,MOVETYPE_FLY)
	entity_set_int(ent,EV_INT_solid,SOLID_BBOX)
	entity_set_int(ent,EV_INT_sequence,1)

	// set entity's model
	entity_set_model(ent,shockwave_Model)
	
	// set entity's size
	entity_set_size(ent,Float:{-0.0, -0.0, -0.0},Float:{0.0, 0.0, 0.0})
	
	// get player's origin and set entity's origin
	new Float:origin[3], Float:Fire[3]
	entity_get_vector(id,EV_VEC_origin,origin)
	entity_get_vector(id,EV_VEC_origin,Fire)
	entity_set_origin(ent, Fire)
	
	// set entity's velocity
	new Float:velocity[3]
	VelocityByAim(id,get_pcvar_num(cvar_shockwave_speed),velocity)
	
	// set entity's angle same as player's angle
	new Float:angles[3]
	entity_set_edict(ent,EV_ENT_owner,id)
	entity_set_float(ent,EV_FL_takedamage,1.0)
	vector_to_angle(velocity, angles)
	entity_set_vector(ent,EV_VEC_velocity,velocity)
	entity_set_vector(ent,EV_VEC_angles,angles)

	set_pev(ent, pev_iuser2, id)
	
	create_beam_follow(ent, 255, 255, 0, 255)
	
	new param[1]
	param[0] = ent
	set_task(0.0, "shockwave_ball_process", TASK_ID_1, param, 1)
}

public shockwave_detonate(ent)
{
	if (!pev_valid(ent))
		return;
	
	new Float:origin[3]
	pev(ent, pev_origin, origin)

	shockwave_i(origin)
	create_explosion_effect(origin)
	emit_sound(ent, CHAN_WEAPON, shockwave_det_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)

	engfunc(EngFunc_RemoveEntity, ent)
}

public shockwave_ball_process(param[1])
{
	new ent = param[0]
	
	if (!pev_valid(ent))
		return;
	
	create_beam_follow(ent, 255, 255, 0, 255)
	
	set_task(0.0, "shockwave_ball_process", TASK_ID_1, param, 1)
}

public event_death()
{
	new id = read_data(2)

	cooldown[id] = false
}

public event_NewRound(id)
{
	cooldown[id] = false
}

stock SendWeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(iAnim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock shockwave_i(Float:hit_origin[3])
{
	new Float:target_origin[3], Origin[3]
	for (new i = 1; i <= 32; i++)
	{
		if (!zp_get_user_zombie(i))
		{
			if (!is_user_alive(i))
				continue;
			
			get_user_origin(i,Origin)
			pev(i, pev_origin, target_origin)
			new dist = floatround(get_distance_f(hit_origin, target_origin))
			if (dist > get_pcvar_float(cvar_shockwave_radius))
				continue;

			if (!zp_get_user_survivor(i))
				drop_current_weapon(i)
		}
	}
}

stock create_beam_follow(entity, red, green, blue, brightness)
{
	//Entity add colored trail
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id
	write_short(entity) // entity
	write_short(g_trailSpr) // sprite
	write_byte(10) // life
	write_byte(3) // width
	write_byte(red) // r
	write_byte(green) // g
	write_byte(blue) // b
	write_byte(brightness) // brightness
	message_end()
}

stock create_explosion_effect(const Float:originF[3])
{
	//engfunc(EngFunc_MessageBegin,MSG_BROADCAST,SVC_TEMPENTITY,origin,0)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_EXPLOSION) // TE id: 3
	engfunc(EngFunc_WriteCoord, originF[0]) // position.x
	engfunc(EngFunc_WriteCoord, originF[1]) // position.y
	engfunc(EngFunc_WriteCoord, originF[2]) // position.z
	write_short(g_explodeSpr) // sprite index
	write_byte(20) // scale in 0.1's
	write_byte(15) // framerate
	write_byte(0) // flags
	message_end()
}
stock drop_current_weapon(id) 
{
	static weapon_id, clip, ammo
	weapon_id = get_user_weapon(id, clip, ammo)
	
	if (((1<<weapon_id) & PRIMARY_WEAPONS_BIT_SUM) || ((1<<weapon_id) & SECONDARY_WEAPONS_BIT_SUM))
	{
		static weapon_name[32]
		get_weaponname(weapon_id, weapon_name, sizeof weapon_name - 1)
		engclient_cmd(id, "drop", weapon_name)
	}
}