/////////////////////////////////////////////////////////////////////////////
////////////////////////////////錯覺喪屍/////////////////////////////////////
/////////////////這血性喪屍是本人突然間想到的-3-   想到便做了////////////////
///////////////////////////它按R後  會制做分身和穩身/////////////////////////
/////////////////////////////////////////////////////////////////////////////
///////////////這喪屍由 MyChat數位男女會員:sk@.@  寫出 (原創)////////////////
/////////////////////////////////////////////////////////////////////////////
/*                        	 更新日誌
*        		   v1.1 : 加入隱形效果
*                        v1.2 : 限制技能使用次數
*                      v1.3 : 加入 分身技能 冷卻時間
*                      v1.4 : 修正 分身不被射死的 BUG
*                           v1.5 : 新增支援 BOT
*/

/* 5/2/2010 */

#include <amxmodx>
#include <fakemeta_util>
#include <engine>
#include <fun>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define PLUGIN	"[ZP] Class: illusion Zombie"
#define VERSION	"1.5"
#define AUTHOR	"MyChat數位男女會員:sk@.@"

#define SUPPORT_BOT_TO_USE	//支援BOT使用.(在最前面加上 // 即取消對BOT的技援)

new const zclass_name[] = { "錯覺喪屍" }
new const zclass_info[] = { "按R產生分身和隱形" }
new const zclass_model[] = { "zombie_source" }
new const zclass_clawmodel[] = { "v_knife_zombie.mdl" }
const zclass_health = 1500
const zclass_speed = 200
const Float:zclass_gravity = 1.0
const Float:zclass_knockback = 0.5

new const sionzom_model[] = "models/player/zombie_source/zombie_source.mdl"  //錯覺分身mdl

new g_zclass_sionzom
new cvar_sionzom_health, cvar_sionzom_animation, cvar_sionzom_limit, cvar_sionzom_cooldown, cvar_sionzom2_time, cvar_sionzom_die
new gCounter[33], g_nosee[33]
new Float:g_Use_Time[33]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	cvar_sionzom_die = register_cvar( "zp_sionzom_die", "1" ) // 分身會不會死???  (1=會  0=不會)
	cvar_sionzom_health = register_cvar("zp_sionzom_health", "100") // 錯覺分身血量 (100 = 100)
	cvar_sionzom_limit = register_cvar("zp_sionzom_spawn_limit", "3") //錯覺分身最多幾個 (3 = 3個)
	cvar_sionzom_cooldown = register_cvar("zp_sionzom_cooldown", "30")  //制做錯覺分身需冷卻時間  (1.0 = 1秒)
	cvar_sionzom2_time = register_cvar("zp_sionzom2_time", "15")  //制做錯覺分身後穩身時間  (1.0 = 1秒)
	

	cvar_sionzom_animation = register_cvar("zp_sionzom_animation", "1")

	register_think("npc_sionzom", "npc_think")

	register_event("DeathMsg", "event_Death", "a")
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
}

public plugin_precache()
{
	g_zclass_sionzom = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback )
	precache_model(sionzom_model)
}

public zp_user_infected_post(id, infector)
{
	if(zp_get_user_zombie_class(id) == g_zclass_sionzom && !zp_get_user_nemesis(id))
	{
		client_print(id, print_chat, "[錯覺喪屍] 按 R  可制造一個錯覺分身 和隱形%d秒!!", floatround(get_pcvar_float(cvar_sionzom2_time)))
		client_print(id, print_chat, "[錯覺喪屍] 最多可制造%d個錯覺分身!!每制造1個需冷卻%d秒!!", get_pcvar_num(cvar_sionzom_limit), floatround(get_pcvar_float(cvar_sionzom_cooldown)))
		gCounter[id] = 0
		g_nosee[id] = false
	}
}

public client_PreThink(id)
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_sionzom || zp_get_user_nemesis(id) || zp_get_user_survivor(id))
		return PLUGIN_HANDLED;

	new button = get_user_button(id)
	new oldbutton = get_user_oldbutton(id)
	
	if(!(oldbutton & IN_RELOAD) && (button & IN_RELOAD))
	{
		if (get_gametime() > g_Use_Time[id]) 
		{
			create_sionzom(id)
			g_Use_Time[id] = get_gametime() + get_pcvar_float(cvar_sionzom_cooldown)
		}
		else 
		{
			client_print(id,print_center,"技能尚未準備好,您還不能使用'錯覺分身'技能. [技能冷卻時間剩餘%2.1f秒]", g_Use_Time[id]-get_gametime())
		}
	}

	#if defined SUPPORT_BOT_TO_USE
	if (is_user_bot(id))
	{
		new enemy, body
                get_user_aiming(id, enemy, body)
                
		if ((1 <= enemy <= 32) && !zp_get_user_zombie(enemy))
		if (get_gametime() > g_Use_Time[id]) 
		{
			create_sionzom(id)
			g_Use_Time[id] = get_gametime() + get_pcvar_float(cvar_sionzom_cooldown)
		}
		else 
		{
			client_print(id,print_center,"技能尚未準備好,您還不能使用'錯覺分身'技能. [技能冷卻時間剩餘%2.1f秒]", g_Use_Time[id]-get_gametime())
		}
	}
	#endif

	return PLUGIN_HANDLED;
}

public create_sionzom(id)
{
	if(gCounter[id] >= get_pcvar_num(cvar_sionzom_limit))
	{
		client_print(id, print_chat, "[錯覺喪屍]你已不可制造錯覺分身!!!")
		return PLUGIN_HANDLED
	}

	new Float:origin[3]

	entity_get_vector(id, EV_VEC_origin,origin)

	new ent = create_entity("info_target")

	entity_set_origin(ent, origin)
	origin[1] += 50.0
	entity_set_origin(id,origin)
	entity_set_float(ent, EV_FL_takedamage, get_pcvar_float(cvar_sionzom_die))
	entity_set_float(ent, EV_FL_health, get_pcvar_float(cvar_sionzom_health))
	entity_set_string(ent, EV_SZ_classname, "npc_sionzom")
	entity_set_model(ent, sionzom_model)
	entity_set_int(ent, EV_INT_solid, 2)

	entity_set_byte(ent, EV_BYTE_controller1, 125)
	entity_set_byte(ent, EV_BYTE_controller2, 125)
	entity_set_byte(ent, EV_BYTE_controller3, 125)
	entity_set_byte(ent, EV_BYTE_controller4, 125)

	new Float:maxs[3] = {16.0, 16.0, 36.0}
	new Float:mins[3] = {-16.0, -16.0, -36.0}

	entity_set_size(ent, mins, maxs)
	entity_set_float(ent, EV_FL_animtime, 2.0)
	entity_set_float(ent, EV_FL_framerate, 1.0)
	entity_set_int(ent, EV_INT_sequence, get_pcvar_num(cvar_sionzom_animation))
	entity_set_float(ent,EV_FL_nextthink, halflife_time() + 0.01)

	drop_to_floor(ent)

	gCounter[id] ++
	client_print(id, print_chat, "[錯覺喪屍] 你已制造了%d個錯覺分身!!最多可制造%d個錯覺分身!!!", gCounter[id], get_pcvar_num(cvar_sionzom_limit))

	if(!g_nosee[id])
	{
		g_nosee[id] = true
		fm_set_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, 15)
		set_task(get_pcvar_float(cvar_sionzom2_time), "yessee", id)
		client_print(id, print_chat, "[錯覺喪屍]同時,你啟動了 隱形 技能!!!")
	}

	return 1
}

public yessee(id)
{
	if(g_nosee[id])
	{
		g_nosee[id] = false
		fm_set_rendering(id)
		client_print(id,print_center, "[錯覺喪屍]隱形技能已停止")
	}
}

public npc_think(id)
{
	entity_set_float(id, EV_FL_nextthink, halflife_time() + 0.01)
}

public event_new_round()
{
	new id = read_data(2)
	if (!(1 <= id <= 32))
		return;

	new ent = -1
	while((ent = find_ent_by_class(ent, "npc_sionzom")))
	{
		remove_entity(ent)
	}

	g_nosee[id] = false
	fm_set_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, 255)
}

public event_Death()
{
	new id = read_data(2)
	if (!(1 <= id <= 32))
		return;
	
	g_nosee[id] = false
	fm_set_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, 255)
}
