/////////////////////////////////////////////////////////////////////////////
///////////這喪屍是 彷 CSO , 啟示錄 模式中的   巨獸雷比亞////////////////////
////////////////巨獸雷比亞  可使用地震波攻擊和使用衝擊技能攻擊///////////////
///////////////這喪屍由 MyChat數位男女會員:sk@.@  寫出 (原創)////////////////
/////////////////////感謝 MyChat數位男女會員:yymmychat 協助//////////////////
////////////////////////   和幫忙令此喪屍支援bot    /////////////////////////
/////////////////////////////////////////////////////////////////////////////
/*                        	 更新日誌
*       		v1.1 : 加入支持bot使用
*       v1.2 : 改良BOT使用技能的支援,加強選擇使用技能的判斷項目
* v1.3 : 更新讓衝擊技能的使用,也可以向下方衝擊和增加普通功擊  功擊力加乘
*                       v1.4 : 更新雷比亞的衝擊動作 
*              使用衝擊技能時,會先往上跳躍一小段距離,然後再做衝刺動作
*為防上往下衝時容易因為會先卡到地面衝擊動作被中斷了 衝擊時還是會往原先瞄準的位置點往前衝擊
*                     v1.4b : 這個版本是不會受到槍枝武器攻擊而麻痺
*/

/* 4/2/2010 */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

#define PLUGIN	"[ZP] Class: Phobos Zombie"
#define VERSION	"1.4b"
#define AUTHOR	"MyChat數位男女會員:sk@.@"

#define SUPPORT_BOT_TO_USE	//支援BOT使用.(在最前面加上 // 即取消對BOT的技援)
#define SUPPORT_CZBOT		//支援CZBot的使用.(在最前面加上 // 即取消這項設定)
#define CANT_USE_LONG_JUMP	//無法使用長跳.(在最前面加上 // 即取消這項設定)

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

new const zclass_name[] = { "巨獸雷比亞" }
new const zclass_info[] = { "撞飛人類,令人類武器掉下" }
new const zclass_model[] = { "zombie_source" }
new const zclass_clawmodel[] = { "v_knife_zombie.mdl" }
const zclass_health = 15000
const zclass_speed = 200
const Float:zclass_gravity = 1.0
const Float:zclass_knockback = 0.1

#define TASK_SHOCKWAVE	5678
#define TASK_CHARGE	6789

new const sound_shockwave[] = { "garg/gar_stomp1.wav" } //喪屍使用地震波時的音效
new const sound_charge1[] = { "garg/gar_attack2.wav" }	//喪屍使用衝擊技能時的音效(1)
new const sound_charge2[] = { "houndeye/he_blast3.wav" } //喪屍使用衝擊技能時的音效(2)
new const sound_hit_body[][] = { "hornet/ag_hornethit1.wav", "hornet/ag_hornethit2.wav", 
	"hornet/ag_hornethit3.wav" } //使用衝擊技能撞擊身體時的音效

const Float:How_High_Invalid_Attack = 60.0 //在地震波攻擊範圍內的目標,若高度和攻擊者相差超出多少則判定攻擊無效.(人物模型的高度是72.0)
const Float:Survivor_Damage_Multiplier = 0.5	//倖存者受到衝擊傷害的乘數

new g_zclass_leibiya
new g_shockwaveSpr, g_trailSpr
new g_shockwave_range, g_shockwave_delay, g_shockwave_cooldown, g_charge_speed, g_charge_height, g_charge_delay, 
	g_charge_cooldown, g_charge_damage, g_damage_multiplier
new g_maxplayers
new bool:hit_key[33]
new bool:use_shockwave[33], bool:sw_cooldown_started[33], Float:start_origin[33][3], bool:start_falling[33]
new bool:use_charge[33], charge_step[33], bool:ch_cooldown_started[33], Float:show_trail_time[33]
new Float:user_velocity[33][3]
new Float:skill_over_time[33]
new user_damage_hitzone[33]

#if defined CANT_USE_LONG_JUMP
new bool:charge_jump[33]
#endif

#if defined SUPPORT_BOT_TO_USE
new bot_do_attack[33]

enum {
	BOT_DO_NOTHING = 0,
	BOT_DO_SHOCKWAVE,
	BOT_DO_CHARGE
}
#endif

#if defined SUPPORT_CZBOT
// CZBot support
new cvar_botquota
new bool:BotHasDebug = false
#endif

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_shockwave_range = register_cvar("zp_leibiya_shockwave_range", "320") 		//使用地震波攻擊的有效範圍距離
	g_shockwave_delay = register_cvar("zp_leibiya_shockwave_delay", "0.3")		//使用地震波攻擊時,落地後到發生作用的延遲時間(單位:秒)
	g_shockwave_cooldown = register_cvar("zp_leibiya_shockwave_cooldown", "15.0")	//使用地震波攻擊後的冷卻時間(單位:秒)
	g_charge_speed = register_cvar("zp_leibiya_charge_speed", "900") 		//使用衝擊技能攻擊時的速度
	g_charge_height = register_cvar("zp_leibiya_charge_height", "250") 		//使用衝擊技能攻擊時的跳躍高度
	g_charge_delay = register_cvar("zp_leibiya_charge_delay", "0.3")		//使用衝擊技能攻擊時,發動技能後到技能效果出現時的延遲時間(單位:秒)
	g_charge_cooldown = register_cvar("zp_leibiya_charge_cooldown", "15.0")		//使用衝擊技能攻擊後的冷卻時間(單位:秒)
	g_charge_damage = register_cvar("zp_leibiya_charge_damage", "400")		//使用衝擊技能攻擊時,造成傷害的數值
	g_damage_multiplier = register_cvar("zp_leibiya_damage_multiplier", "1.5")	//使用爪子攻擊時,造成傷害數值的乘數
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	register_forward(FM_Touch, "fwd_Touch")
	register_forward(FM_PlayerPreThink, "fwd_PlayerPreThink")
	register_forward(FM_PlayerPreThink, "fwd_PlayerPreThink_1", 1)
	register_forward(FM_PlayerPostThink, "fwd_PlayerPostThink_1", 1)
	
	register_event("ResetHUD", "event_NewRound", "be")
	register_event("DeathMsg", "event_Death", "a")
	
	g_maxplayers = get_maxplayers()
	
	#if defined SUPPORT_CZBOT
	// CZBot support
	cvar_botquota = get_cvar_pointer("bot_quota")
	#endif
}

public plugin_precache()
{
	precache_sound(sound_shockwave)
	precache_sound(sound_charge1)
	precache_sound(sound_charge2)
	
	new i
	for (i = 0; i < sizeof sound_hit_body; i++)
		precache_sound(sound_hit_body[i])
	
	g_shockwaveSpr = precache_model("sprites/shockwave.spr")
	g_trailSpr = precache_model("sprites/smoke.spr")
	
	g_zclass_leibiya = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

public zp_user_infected_post(id, infector)
{
	if (zp_get_user_zombie_class(id) == g_zclass_leibiya && !zp_get_user_nemesis(id))
	{
		client_print(id, print_chat, "[巨獸雷比亞] 按R可使用地震波,令旁邊人類的武器掉下!!!")
		client_print(id, print_chat, "[巨獸雷比亞] 按G可使用衝擊技能,被撞擊的人會受到嚴重傷害!!!")
		client_print(id, print_chat, "[巨獸雷比亞] 被擊中只會有一半傷害..但擊中左手則3倍傷害!!")
	}
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Non-player damage or self damage
	//if (victim == attacker || !is_user_connected(attacker))
	//	return HAM_IGNORED;
	
	// Check hit zone
	user_damage_hitzone[victim] = get_tr2(tracehandle, TR_iHitgroup)
	
 	//* Hit zones of body are as bits:
 	//* 1 - head
 	//* 2 - chest
 	//* 3 - stomach
 	//* 4 - left arm
 	//* 5 - right arm
 	//* 6 - left leg
 	//* 7 - right leg
	
	return HAM_IGNORED;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	if (zp_get_user_zombie(attacker) == zp_get_user_zombie(victim))
		return HAM_IGNORED;
	
	if (zp_get_user_zombie(attacker) && zp_get_user_zombie_class(attacker) == g_zclass_leibiya && !zp_get_user_nemesis(attacker))
	{
		if (damage > 0.0)
		{
			damage *= get_pcvar_float(g_damage_multiplier)
			SetHamParamFloat(4, damage)
		}
	}
	
	if (zp_get_user_zombie(victim) && zp_get_user_zombie_class(victim) == g_zclass_leibiya && !zp_get_user_nemesis(victim))
	{
		if (damage > 0.0)
		{
			if (user_damage_hitzone[victim] == 4) //受到武器攻擊,被射到左手時
			{
				damage *= 3.0 //受到傷害的數值變成3倍
			}
			else  //受到武器攻擊,被射到其它部位時
			{
				damage *= 0.5 //受到傷害的數值減半
			}
			
			SetHamParamFloat(4, damage)
		}
	}
	
	return HAM_IGNORED;
}

public client_command(id)
{
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	if (!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_leibiya || zp_get_user_nemesis(id))
		return PLUGIN_CONTINUE;
	
	new cmd_string[32]
	read_argv(0, cmd_string, charsmax(cmd_string))
	
	if (equal(cmd_string, "drop"))
	{
		user_do_charge(id)
		return PLUGIN_HANDLED_MAIN;
	}
	
	return PLUGIN_CONTINUE;
}

public user_do_charge(id)
{
	if (!use_charge[id] && !use_shockwave[id] && is_user_on_ground(id))
	{
		if (!ch_cooldown_started[id])
		{
			// 設定使用一項技能過後,必需經過1.0秒才能再度使用技能.
			if (get_gametime() - skill_over_time[id] >= 1.0)
			{
				use_charge[id] = true
				charge_step[id] = 1 //設定衝擊技能效果在第1階段狀態
				emit_sound(id, CHAN_VOICE, sound_charge1, 1.0, ATTN_NORM, 0, PITCH_HIGH)
				
				new args[1]
				args[0] = id
				
				// 設定使用衝擊技能後,延遲衝擊技能效果出現的時間
				set_task(get_pcvar_float(g_charge_delay), "user_do_charge_2", id+TASK_CHARGE, args, sizeof args)
			}
		}
		else
		{
			client_print(id, print_chat, "[巨獸雷比亞] 衝擊技能冷卻時間還未結束!")
		}
	}
}

public user_do_charge_2(args[1])
{
	new id = args[0]
	
	charge_step[id] = 2 //設定衝擊技能效果在第2階段狀態
	emit_sound(id, CHAN_VOICE, sound_charge2, 1.0, ATTN_NORM, 0, PITCH_HIGH)
	
	#if defined CANT_USE_LONG_JUMP
	charge_jump[id] = true
	#endif
	
	new Float:origin[3], Float:aim_origin[3], Float:velocity[3], speed, hull, Float:temp_origin[3], Float:temp
	
	pev(id, pev_origin, origin)
	fm_get_aim_origin(id, aim_origin)
	
	set_pev(id, pev_solid, SOLID_NOT)
	
	// Get whether the player is crouching
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	xs_vec_copy(origin, temp_origin)
	temp = 50.0
	temp_origin[2] += temp
	
	while (!is_hull_vacant(temp_origin, hull) && temp > 0.0)
	{
		temp -= 5.0
		temp_origin[2] -= 5.0
	}
	
	if (temp > 0.0)
	{
		origin[2] += temp
		set_pev(id, pev_origin, origin)
	}
	
	set_pev(id, pev_solid, SOLID_SLIDEBOX)
	
	speed = get_pcvar_num(g_charge_speed)
	xs_vec_sub(aim_origin, origin, velocity)
	temp = vector_length(velocity)
	temp = (temp == 0.0 ? 1.0 : temp)
	xs_vec_mul_scalar(velocity, (speed / temp), velocity)
	velocity[2] += get_pcvar_float(g_charge_height)
	temp = vector_length(velocity)
	temp = (temp == 0.0 ? 1.0 : temp)
	xs_vec_mul_scalar(velocity, (speed / temp), velocity)
	set_pev(id, pev_velocity, velocity)
	
	create_beam_follow(id)
	show_trail_time[id] = get_gametime()
	
	client_print(id, print_chat, "[巨獸雷比亞] 你已使用了衝擊技能,撞擊前方的人類!!!")
}

public fwd_Touch(ptr, ptd)
{
	if (!pev_valid(ptr) || !pev_valid(ptd))
		return FMRES_IGNORED;
	
	if (!is_user_connected(ptr) || !is_user_alive(ptr) || 
	!zp_get_user_zombie(ptr) || zp_get_user_zombie_class(ptr) != g_zclass_leibiya || zp_get_user_nemesis(ptr))
		return FMRES_IGNORED;
	
	if (!is_user_connected(ptd) || !is_user_alive(ptd) || zp_get_user_zombie(ptd))
		return FMRES_IGNORED;
	
	if (use_charge[ptr])
	{
		static Float:origin1[3], Float:origin2[3], Float:velocity[3]
		pev(ptr, pev_origin, origin1)
		pev(ptd, pev_origin, origin2)
		
		particle_burst_effect(origin2)
		emit_sound(ptr, CHAN_BODY, sound_hit_body[random_num(0, (sizeof sound_hit_body - 1))], 1.0, ATTN_NORM, 0, PITCH_HIGH)
		
		get_speed_vector_point_entity(origin1, ptd, 500, velocity)
		velocity[2] = floatmax(velocity[2], 200.0)
		set_pev(ptd, pev_velocity, velocity)
		
		static damage
		damage = get_pcvar_num(g_charge_damage)
		
		if (zp_get_user_survivor(ptd))
			damage *= Survivor_Damage_Multiplier
		
		damage_user(ptd, ptr, damage, DMG_BULLET, "Zombie_Charge")
	}
	
	return FMRES_IGNORED;
}

damage_user(victim, attacker, damage, damage_type, const weapon[])
{
	new armor = get_user_armor(victim)
	new Float:damage_armor_rate, damage_armor
	damage_armor_rate = (1.0 / 3.0) //對人類護甲造成傷害的乘數. (護甲傷害值 = 總傷害值 * 乘數)
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
	
	new health = get_user_health(victim)
	
	if (health > damage)
	{
		set_user_takedamage(victim, damage, damage_type)
	}
	else
	{
		fm_user_silentkill(victim)
		SendDeathMsg(attacker,victim, 0, weapon)
		fm_set_user_frags(attacker, get_user_frags(attacker) + 1)
		zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + 1)
		FixDeadAttrib(victim)
		Update_ScoreInfo(victim, get_user_frags(victim), get_user_deaths(victim))
		FixDeadAttrib(attacker)
		Update_ScoreInfo(attacker, get_user_frags(attacker), get_user_deaths(attacker))
	}
}

public fwd_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	if (!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_leibiya || zp_get_user_nemesis(id))
		return FMRES_IGNORED;
	
	#if defined CANT_USE_LONG_JUMP
	if (!charge_jump[id])
	{
		static Float:velocity[3], Float:speed, Float:temp
		pev(id, pev_velocity, velocity)
		speed = vector_length(velocity)
		speed = (speed == 0.0 ? 1.0 : speed)
		temp = float(zclass_speed) * 1.5 //預設基本跳躍時的速度為行走時的最大速度的1.5倍 (此為參考數值,可視情況做調整)
		
		if (speed > temp)
		{
			xs_vec_mul_scalar(velocity, (temp / speed), velocity)
			set_pev(id, pev_velocity, velocity)
		}
	}
	#endif
	
	// 設定喪屍不會受攻擊而停頓.
	pev(id, pev_velocity, user_velocity[id])
	
	if (use_charge[id])
	{
		// 當衝擊技能效果在第1階段時,設定凍結玩家的行動狀態.
		if (charge_step[id] == 1)
		{
			set_pev(id, pev_velocity, Float:{ 0.0, 0.0, 0.0 })
			set_pev(id, pev_maxspeed, 1.0)
		}
		
		// 當喪屍使用衝擊技能,且效果出現之後,若是落到地面上或是速度小於100時則設定結束衝擊技能效果.
		if ((is_user_on_ground(id) || (fm_get_speed(id) < 100)) && !task_exists(id+TASK_CHARGE))
		{
			static args[1]
			args[0] = id
			set_task(0.6, "charge_over", id+TASK_CHARGE, args, sizeof args) //設定延遲0.6秒結束衝擊技能效果
		}
	}
	
	return FMRES_IGNORED;
}

public charge_over(args[1])
{
	new id = args[0]
	
	skill_over_time[id] = get_gametime()
	
	kill_beam(id)
	use_charge[id] = false
	charge_step[id] = 0
	ch_cooldown_started[id] = true
	
	// 開漿衝擊技能使用後的冷卻時間倒數
	set_task(get_pcvar_float(g_charge_cooldown), "charge_cooldown_over", id+TASK_CHARGE, args, sizeof args)
}

public charge_cooldown_over(args[1])
{
	new id = args[0]
	
	if (ch_cooldown_started[id])
		client_print(id, print_center, "[巨獸雷比亞] 冷卻時間%.1f秒己過,你己經可以再使用衝擊技能了!", 
			get_pcvar_float(g_charge_cooldown))
	
	ch_cooldown_started[id] = false
}

public fwd_PlayerPreThink_1(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	if (!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_leibiya || zp_get_user_nemesis(id))
		return FMRES_IGNORED;
	
	// 設定喪屍不會受攻擊而停頓.
	static Float:tempvel[3]
	pev(id, pev_basevelocity, tempvel)
	xs_vec_add(user_velocity[id], tempvel, user_velocity[id])
	set_pev(id, pev_velocity, user_velocity[id])
	
	if (use_charge[id] && charge_step[id] == 2)
	{
		static Float:current_time
		current_time = get_gametime()
		if (current_time - show_trail_time[id] >= 1.0)
		{
			create_beam_follow(id)
			show_trail_time[id] = current_time
		}
	}
	
	#if defined SUPPORT_BOT_TO_USE
	if (is_user_bot(id))
	{
		if (bot_do_attack[id] == BOT_DO_SHOCKWAVE)
		{
			if (!use_shockwave[id] && !use_charge[id] && !sw_cooldown_started[id] && is_user_on_ground(id))
			{
				// 設定使用一項技能過後,必需經過1.0秒才能再度使用技能.
				if (get_gametime() - skill_over_time[id] >= 1.0)
				{
					use_shockwave[id] = true
					start_falling[id] = false
					
					pev(id, pev_origin, start_origin[id])
					
					static Float:velocity[3]
					pev(id, pev_velocity, velocity)
					velocity[2] = 320.0
					set_pev(id, pev_velocity, velocity)
				}
			}
		}
		
		return FMRES_IGNORED;
	}
	#endif
	
	static button
	button = pev(id, pev_button)
	
	if (button & IN_RELOAD)
	{
		if (!hit_key[id])
		{
			if (!use_shockwave[id] && !use_charge[id] && is_user_on_ground(id))
			{
				if (!sw_cooldown_started[id])
				{
					// 設定使用一項技能過後,必需經過1.0秒才能再度使用技能.
					if (get_gametime() - skill_over_time[id] >= 1.0)
					{
						use_shockwave[id] = true
						start_falling[id] = false
						
						pev(id, pev_origin, start_origin[id])
						
						static Float:velocity[3]
						pev(id, pev_velocity, velocity)
						velocity[2] = 320.0
						set_pev(id, pev_velocity, velocity)
						
						client_print(id, print_chat, "[巨獸雷比亞] 你已使用了地震波,令旁邊人類的武器掉下!!!")
					}
				}
				else
				{
					client_print(id, print_chat, "[巨獸雷比亞] 地震波技能冷卻時間還未結束!")
				}
			}
		}
		
		hit_key[id] = true
	}
	else
	{
		hit_key[id] = false
	}
	
	return FMRES_IGNORED;
}

public fwd_PlayerPostThink_1(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	if (!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_leibiya || zp_get_user_nemesis(id))
		return FMRES_IGNORED;
	
	if (use_shockwave[id])
	{
		static Float:cur_origin[3]
		pev(id, pev_origin, cur_origin)
		
		if (!start_falling[id])
		{
			if (floatabs(cur_origin[2] - start_origin[id][2]) >= 50.0)
			{
				start_falling[id] = true
			}
		}
		else
		{
			static Float:cur_velocity[3]
			pev(id, pev_velocity, cur_velocity)
			cur_velocity[2] = floatmin(cur_velocity[2], -200.0)
			set_pev(id, pev_velocity, cur_velocity)
		}
		
		if (is_user_on_ground(id))
		{
			skill_over_time[id] = get_gametime()
			
			use_shockwave[id] = false
			emit_sound(id, CHAN_VOICE, sound_shockwave, 1.0, ATTN_NORM, 0, PITCH_HIGH)
			
			static Float:delay
			delay = get_pcvar_float(g_shockwave_delay)
			
			static args[1]
			args[0] = id
			
			if (delay > 0.0)
			{
				fm_set_rendering(id, kRenderFxGlowShell, 130, 139, 253, kRenderNormal, 1)
				
				// 搜尋攻擊有效範圍內的玩家(設定延遲發生作用)
				set_task(delay, "search_in_range_target", id+TASK_SHOCKWAVE, args, sizeof args)
			}
			else
			{
				search_in_range_target(args) //搜尋攻擊有效範圍內的玩家
			}
			
			sw_cooldown_started[id] = true
			
			// 開始地震波技能使用後的冷卻時間倒數
			set_task(get_pcvar_float(g_shockwave_cooldown), "shockwave_cooldown_over", id+TASK_SHOCKWAVE, args, sizeof args)
		}
	}
	
	#if defined CANT_USE_LONG_JUMP
	if (is_user_on_ground(id))
	{
		charge_jump[id] = false
	}
	#endif
	
	return FMRES_IGNORED;
}

public search_in_range_target(args[1])
{
	new id = args[0]
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	create_blast(origin)
	fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255) //取消發光
	
	new Float:origin1[3], Float:origin2[3], Float:range, Float:velocity[3]
	pev(id, pev_origin, origin1)
	
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if ((i == id) || !is_user_connected(i) || !is_user_alive(i) || zp_get_user_zombie(i))
			continue;
		
		pev(i, pev_origin, origin2);
		range = get_distance_f(origin1, origin2)
		
		if (range > get_pcvar_float(g_shockwave_range))
			continue;
		
		if (floatabs(origin2[2] - origin1[2]) > How_High_Invalid_Attack)
			continue;
		
		screen_shake(id, 12, 4, 10)
		
		get_speed_vector_point_entity(origin1, i, 300, velocity)
		velocity[2] = floatmax(velocity[2], 150.0)
		set_pev(i, pev_velocity, velocity)
		
		if (!zp_get_user_survivor(i)) //設定若當玩家是倖存者時不會掉下手上的槍
			drop_current_weapon(i) //玩家丟掉目前手上的槍
	}
}

public shockwave_cooldown_over(args[1])
{
	new id = args[0]
	
	if (sw_cooldown_started[id])
		client_print(id, print_center, "[巨獸雷比亞] 冷卻時間%.1f秒己過,你己經可以再使用地震波了!", 
			get_pcvar_float(g_shockwave_cooldown))
	
	sw_cooldown_started[id] = false
}

public zp_user_humanized_post(id)
{
	if (use_charge[id])
		kill_beam(id)
	
	reset_vars(id)
	remove_task(id+TASK_SHOCKWAVE)
	remove_task(id+TASK_CHARGE)
	fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
}

public client_connect(id)
{
	reset_vars(id)
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	if (use_charge[id])
		kill_beam(id)
	
	reset_vars(id)
	return PLUGIN_CONTINUE;
}

public event_NewRound(id)
{
	if (use_charge[id])
		kill_beam(id)
	
	reset_vars(id)
	remove_task(id+TASK_SHOCKWAVE)
	remove_task(id+TASK_CHARGE)
	fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
}

public event_Death()
{
	new id = read_data(2)
	if (!(1 <= id <= g_maxplayers))
		return;
	
	if (use_charge[id])
		kill_beam(id)
	
	reset_vars(id)
	remove_task(id+TASK_SHOCKWAVE)
	remove_task(id+TASK_CHARGE)
	fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
}

reset_vars(id)
{
	hit_key[id] = false
	use_shockwave[id] = false
	sw_cooldown_started[id] = false
	use_charge[id] = false
	charge_step[id] = 0
	ch_cooldown_started[id] = false
	
	#if defined CANT_USE_LONG_JUMP
	charge_jump[id] = false
	#endif
}

stock screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, id)
	write_short((1<<12)*amplitude) // 振幅
	write_short((1<<12)*duration) // 時間
	write_short((1<<12)*frequency) // 頻率
	message_end()
}

stock create_blast(const Float:originF[3])
{
	// Largest ring (大的光環)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id (TE 的代碼)
	engfunc(EngFunc_WriteCoord, originF[0]) // x (X 座標)
	engfunc(EngFunc_WriteCoord, originF[1]) // y (Y 座標)
	engfunc(EngFunc_WriteCoord, originF[2]) // z (Z 座標)
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis (X 軸)
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis (Y 軸)
	//engfunc(EngFunc_WriteCoord, originF[2]+400.0) // z axis (Z 軸)
	engfunc(EngFunc_WriteCoord, originF[2]+get_pcvar_float(g_shockwave_range)) // z axis (Z 軸)
	write_short(g_shockwaveSpr) // sprite (Sprite 物件代碼)
	write_byte(0) // startframe (幀幅開始)
	write_byte(0) // framerate (幀幅頻率)
	write_byte(3) // life (時間長度)
	write_byte(30) // width (寬度)
	write_byte(0) // noise (響聲)
	write_byte(130) // red (顏色 R)
	write_byte(139) // green (顏色 G)
	write_byte(253) // blue (顏色 B)
	write_byte(200) // brightness (顏色亮度)
	write_byte(0) // speed (速度)
	message_end()
	
	// Medium ring (中的光環)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	//engfunc(EngFunc_WriteCoord, originF[2]+300.0) // z axis
	engfunc(EngFunc_WriteCoord, originF[2]+(get_pcvar_float(g_shockwave_range)*2.0/3.0))
	write_short(g_shockwaveSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(3) // life
	write_byte(30) // width
	write_byte(0) // noise
	write_byte(130) // red
	write_byte(139) // green
	write_byte(253) // blue
	write_byte(100) // brightness
	write_byte(0) // speed
	message_end()
	
	// Smallest ring (小的光環)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	//engfunc(EngFunc_WriteCoord, originF[2]+200.0) // z axis
	engfunc(EngFunc_WriteCoord, originF[2]+(get_pcvar_float(g_shockwave_range)/3.0))
	write_short(g_shockwaveSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(30) // width
	write_byte(0) // noise
	write_byte(130) // red
	write_byte(139) // green
	write_byte(253) // blue
	write_byte(50) // brightness
	write_byte(0) // speed
	message_end()
}

stock create_beam_follow(entity)
{
	//Entity add colored trail
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id: 22
	write_short(entity) // entity
	write_short(g_trailSpr) // sprite
	write_byte(10) // life
	write_byte(10) // width
	write_byte(139) // r
	write_byte(139) // g
	write_byte(253) // b
	write_byte(255) // brightness
	message_end()
}

stock kill_beam(entity)
{
	// Kill all beams attached to entity
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_KILLBEAM) // TE id: 99
	write_short(entity)
	message_end()
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

stock bool:is_user_on_ground(index)
{
	if (pev(index, pev_flags) & FL_ONGROUND)
		return true;
	
	return false;
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
	
	if (new_velocity[2] > 1500.0)
		new_velocity[2] = 1500.0
	else if (new_velocity[2] < -200.0)
		new_velocity[2] = -200.0
	
	return 1;
}

stock fm_get_speed(entity)
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	
	return floatround(vector_length(velocity));
}

stock particle_burst_effect(const Float:originF[3])
{
	// Particle burst
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_PARTICLEBURST) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_short(50) // radius
	write_byte(70) // color
	write_byte(3) // duration (will be randomized a bit)
	message_end()
}

stock set_user_takedamage(index, damage, damage_type)
{
	new Float:origin[3], iOrigin[3]
	pev(index, pev_origin, origin)
	FVecIVec(origin, iOrigin)
	
	message_begin(MSG_ONE, get_user_msgid("Damage"), _, index)
	write_byte(21) // damage save
	write_byte(20) // damage take
	write_long(damage_type) // damage type
	write_coord(iOrigin[0]) // position.x
	write_coord(iOrigin[1]) // position.y
	write_coord(iOrigin[2]) // position.z
	message_end()
	
	fm_set_user_health(index, max(get_user_health(index) - damage, 0))
}

stock fm_set_user_health(index, health)
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);
	
	return 1;
}

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

stock fm_user_silentkill(index)
{
	static msgid = 0;
	new msgblock;
	if (!msgid)
	{
		msgid = get_user_msgid("DeathMsg");
	}
	msgblock = get_msg_block(msgid);
	set_msg_block(msgid, BLOCK_ONCE);
	
	new Float:frags;
	pev(index, pev_frags, frags);
	set_pev(index, pev_frags, ++frags);
	dllfunc(DLLFunc_ClientKill, index);
	
	set_msg_block(msgid, msgblock);
	
	return 1;
}

stock SendDeathMsg(attacker, victim, headshot, const weapon[]) // Send Death Message
{
	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(headshot) // headshot flag [1 or 0]
	write_string(weapon) // killer's weapon
	message_end()
}

stock FixDeadAttrib(id) // Fix Dead Attrib on scoreboard
{
	message_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"))
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}

stock Update_ScoreInfo(id, frags, deaths) // Update Player's Frags and Deaths
{
	// Update scoreboard with attacker's info
	//message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
	message_begin(MSG_ALL, get_user_msgid("ScoreInfo"))
	write_byte(id) // id
	write_short(frags) // frags
	write_short(deaths) // deaths
	write_short(0) // class?
	write_short(get_user_team(id)) // team
	message_end()
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

// Checks if a space is vacant (credits to VEN) ##檢查該座標點是否是閒置空間的地點
stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

#if defined SUPPORT_BOT_TO_USE
public client_PreThink(id)
{
	if (!is_user_bot(id) || !is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	if (!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_leibiya || zp_get_user_nemesis(id))
		return PLUGIN_CONTINUE;
	
	static target, hitzone
	get_user_aiming(id, target, hitzone)
	
	if ((1 <= target <= g_maxplayers) && is_user_alive(target) && !zp_get_user_zombie(target))
	{
		static Float:origin1[3], Float:origin2[3], Float:range
		pev(id, pev_origin, origin1)
		pev(target, pev_origin, origin2)
		range = get_distance_f(origin1, origin2)
		
		static bool:found_charge_target, bool:found_shockewave_target
		found_charge_target = false
		found_shockewave_target = false
		
		if (range <= 350.0)
			found_charge_target = true
		
		if ((range <= (get_pcvar_float(g_shockwave_range) - 36.0)) && 
		(floatabs(origin2[2] - origin1[2]) <= (How_High_Invalid_Attack - 18.0)))
		{
			found_shockewave_target = true
		}
		
		if (found_charge_target && found_shockewave_target)
		{
			static shockwave_targets
			shockwave_targets = get_shockwave_valid_targets(id)
			
			if ((shockwave_targets > 1 && is_can_use_shockwave(id)) || 
			(!is_can_use_charge(id) && is_can_use_shockwave(id)))
			{
				bot_do_attack[id] = BOT_DO_SHOCKWAVE
			}
			else if (is_can_use_charge(id))
			{
				bot_do_attack[id] = BOT_DO_CHARGE
			}
			else
			{
				bot_do_attack[id] = BOT_DO_NOTHING
			}
		}
		else if (found_charge_target && is_can_use_charge(id))
		{
			bot_do_attack[id] = BOT_DO_CHARGE
		}
		else if (found_shockewave_target && is_can_use_shockwave(id))
		{
			bot_do_attack[id] = BOT_DO_SHOCKWAVE
		}
		else
		{
			bot_do_attack[id] = BOT_DO_NOTHING
		}
	}
	else
	{
		bot_do_attack[id] = BOT_DO_NOTHING
	}
	
	if (bot_do_attack[id] == BOT_DO_CHARGE)
	{
		user_do_charge(id)
	}
	
	return PLUGIN_CONTINUE;
}

get_shockwave_valid_targets(id)
{
	new target_num, Float:origin1[3], Float:origin2[3], Float:range
	target_num = 0
	pev(id, pev_origin, origin1)
	
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_connected(i) || !is_user_alive(i) || zp_get_user_zombie(i) || zp_get_user_survivor(i))
			continue;
		
		pev(i, pev_origin, origin2)
		range = get_distance_f(origin1, origin2)
		
		if ((range <= (get_pcvar_float(g_shockwave_range) - 36.0)) &&
		(floatabs(origin2[2] - origin1[2]) <= (How_High_Invalid_Attack - 18.0)))
		{
			target_num++
		}
	}
	
	return target_num;
}

is_can_use_shockwave(id)
{
	if (!use_shockwave[id] && !use_charge[id] && !sw_cooldown_started[id] && is_user_on_ground(id) && 
	get_gametime() - skill_over_time[id] >= 1.0)
	{
		return 1;
	}
	
	return 0;
}

is_can_use_charge(id)
{
	if (!use_charge[id] && !use_shockwave[id] && !ch_cooldown_started[id] && is_user_on_ground(id) && 
	get_gametime() - skill_over_time[id] >= 1.0)
	{
		return 1;
	}
	
	return 0;
}
#endif

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
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}
#endif

