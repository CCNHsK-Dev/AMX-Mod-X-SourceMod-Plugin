#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

/* 20/4/2010 */

#define PLUGIN	"[ZP] Precision shooting"
#define VERSION	"0.1"
#define AUTHOR	"MyChat數位男女會員:sk@.@"

#define SUPPORT_BOT_TO_USE	//支援BOT使用.(在最前面加上 // 即取消對BOT的技援)

#define PRECSHOOT_SPR  //是否在精準射擊時出現spr (在最前面加上 // 即取消對BOT的技援)

new const g_precshoot_name[] = { "精準射擊" }
new g_itemid_precshoot, g_precshoot_cost
new g_has_precshoot[33], precshoot_on[33], precshoot_cooldown[33], bot_precshoot_no[33], bot_precshoot[33], id_precshoot[33]
new cvar_cooldown_precshoot, cvar_time_precshoot, cvar_botquota

#if defined PRECSHOOT_SPR
new g_radioSpr
new const prompt_spr[] = { "sprites/zombie_plague/zb_skill_headshot.spr" } //精準射擊時,玩家頭上所顯示的 sprite 圖示.
#endif

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_precshoot_cost = register_cvar("zp_precshoot_cost", "5")      	  	//買精準射擊要花多少子彈包
	cvar_cooldown_precshoot = register_cvar("zp_cooldown_precshoot", "10")		// 冷卻時間
	cvar_time_precshoot = register_cvar("zp_time_precshoot", "6")			// 使用時間

	g_itemid_precshoot = zp_register_extra_item(g_precshoot_name, get_pcvar_num(g_precshoot_cost), ZP_TEAM_HUMAN)

	register_event("ResetHUD", "event_round_start", "be")
	register_event("DeathMsg", "event_death", "a")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink")

	cvar_botquota = get_cvar_pointer("bot_quota")

	register_clcmd("f5on", "zp_precshoot_on")
}

public plugin_precache()
{
	#if defined PRECSHOOT_SPR
	g_radioSpr = engfunc(EngFunc_PrecacheModel, prompt_spr)
	#endif
}

public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_itemid_precshoot)
	{
		if (g_has_precshoot[id])
		{
			new ammo_packs = zp_get_user_ammo_packs(id)
			zp_set_user_ammo_packs(id, ammo_packs + get_pcvar_num(g_precshoot_cost))
			client_print(id, print_chat, "[ZP] 你已有精準射擊了!!按 F5 開始...效果持續 %d 秒 , 冷卻 %d 秒!!", floatround(get_pcvar_float(cvar_time_precshoot)), floatround(get_pcvar_float(cvar_cooldown_precshoot)))
		}
		else
		{
			g_has_precshoot[id] = true
			client_print(id, print_chat, "[ZP] 你已買精準射擊了!!按 F5 開始...效果持續 %d 秒 , 冷卻 %d 秒!!", floatround(get_pcvar_float(cvar_time_precshoot)), floatround(get_pcvar_float(cvar_cooldown_precshoot)))
			client_cmd(id, "bind f5 f5on")
		}
	}
}

public fw_PlayerPostThink(id)
{
	if (is_user_bot(id))
	{
		if (is_user_alive(id) && !zp_get_user_zombie(id) && !bot_precshoot[id])
		{
			bot_precshoot[id] = true

			new random = random_num(0, 1)
			switch (random)
			{
				case 0:
				{
					g_has_precshoot[id] = true
				}
				case 1:
				{
					bot_precshoot_no[id] = true
				}
			}
		}
		if (zp_get_user_zombie(id))
		{
			precshoot_on[id] = false
		}

		#if defined SUPPORT_BOT_TO_USE
		if (bot_precshoot[id])
		{
			if (g_has_precshoot[id] && !precshoot_on[id] && !zp_get_user_zombie(id) && is_user_alive(id))
			{
				new enemy, body
	                	get_user_aiming(id, enemy, body)
	                
				if ((1 <= enemy <= 32) && zp_get_user_zombie(enemy) && !precshoot_cooldown[id])
				{
					precshoot_on[id] = true
					precshoot_cooldown[id] = true

					set_task(get_pcvar_float(cvar_cooldown_precshoot), "reset_cooldown", id)
					set_task(get_pcvar_float(cvar_time_precshoot), "precshoot_off", id)
				}
			}
		}
		#endif
	}

	if (zp_get_user_zombie(id))
	{
		precshoot_on[id] = false
	}

	#if defined PRECSHOOT_SPR
	if (precshoot_on[id])
	{
		show_spr(id)
	}
	#endif
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (precshoot_on[attacker])
	{
		if (get_tr2(tracehandle, TR_iHitgroup) != HIT_HEAD) set_tr2(tracehandle, TR_iHitgroup, HIT_HEAD)
	}
}

public zp_user_infected_post(id, infector)
{
	if (zp_get_user_zombie(infector))
	{
		precshoot_on[infector] = false
		id_precshoot[infector] = false
	}
}

public zp_precshoot_on(id)
{
	if (g_has_precshoot[id] && !precshoot_on[id] && !zp_get_user_zombie(id) && is_user_alive(id))
	{
		if (!precshoot_cooldown[id])
		{
			precshoot_on[id] = true
			precshoot_cooldown[id] = true
			id_precshoot[id] = true

			set_task(get_pcvar_float(cvar_cooldown_precshoot), "reset_cooldown", id)
			set_task(get_pcvar_float(cvar_time_precshoot), "precshoot_off", id)

			client_print(id, print_center, "你已使用'精準射擊'!!")
		}
		else
		{
			client_print(id, print_center, "冷卻未完成!!你還不能使用'精準射擊'!!")
		}
	}
}

public precshoot_off(id)
{
	if (id_precshoot[id] || bot_precshoot[id])
	{
		precshoot_on[id] = false
		client_print(id, print_center, "'精準射擊'效果完結!!")
	}
}

public reset_cooldown(id)
{
	if(id_precshoot[id] || bot_precshoot[id])
	{
		precshoot_cooldown[id] = false
		client_print(id, print_center, "'精準射擊'冷卻完了!!")
	}
}

public event_round_start(id)
{
	precshoot_cooldown[id] = false
	precshoot_on[id] = false
	id_precshoot[id] = false

	if (bot_precshoot[id])
	{
		bot_precshoot[id] = false
		g_has_precshoot[id] = false
		bot_precshoot_no[id] = false
	}
}

public event_death()
{
	new id = read_data(2)

	precshoot_cooldown[id] = false
	precshoot_on[id] = false
	if (bot_precshoot[id])
	{
		bot_precshoot[id] = false
		g_has_precshoot[id] = false
		bot_precshoot_no[id] = false
	}
}

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
}

#if defined PRECSHOOT_SPR
stock show_spr(id)
{
	static Float:origin[3]
	pev(id, pev_origin, origin)
	engfunc(EngFunc_MessageBegin,MSG_BROADCAST,SVC_TEMPENTITY,origin,0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord,origin[0])
	engfunc(EngFunc_WriteCoord,origin[1])
	engfunc(EngFunc_WriteCoord,origin[2]+30)
	write_short(g_radioSpr)
	write_byte(12)
	write_byte(255)
	message_end()
}
#endif
