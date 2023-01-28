
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_plague_advance>

#define PLUGIN	"[ZP / ZPA] Zombie Boss level (n...g....)"
#define VERSION	"1.0"
#define AUTHOR	"HsK"

#define TASK_MUSIC1		1919199
#define TASK_MUSIC2		9191919
#define TASK_BOSSMODEL		7212729

new const ass1round_sound[] = { "zombiehell/zh_intro.mp3" } 			//1級刺客 的場景音樂
const Float:ass1round_duration = 23.0 						//1級刺客 的場景音樂的聲音長度(單位:秒)
new const ass2round_sound[] = { "zombiehell/test_sound77.mp3" } 		//2級刺客 的場景音樂
const Float:ass2round_duration = 45.0 						//2級刺客 的場景音樂的聲音長度(單位:秒)
new const ass3round_sound[] = { "zombiehell/HS_Scenario_Ready.mp3" } 		//3級刺客 的場景音樂
const Float:ass3round_duration = 20.0 						//3級刺客 的場景音樂的聲音長度(單位:秒)
new const nem1round_sound[] = { "zombiehell/zh_intro.mp3" } 			//1級復仇者 的場景音樂
const Float:nem1round_duration = 23.0 						//1級復仇者 的場景音樂的聲音長度(單位:秒)
new const nem2round_sound[] = { "zombiehell/in_cs.mp3" } 			//2級復仇者 的場景音樂
const Float:nem2round_duration = 28.0 						//2級復仇者 的場景音樂的聲音長度(單位:秒)

new const infemode_sound[] = { "zombiehell/in_cs.mp3" }				//一般感染模式 的場景音樂
const Float:infemode_duration = 28.0 						//一般感染模式 的場景音樂的聲音長度(單位:秒)
new const nemmode_sound[] = { "zombiehell/in_cs.mp3" }				//復仇者模式 的場景音樂
const Float:nemmode_duration = 28.0 						//復仇者模式 的場景音樂的聲音長度(單位:秒)
new const assmode_sound[] = { "zombiehell/in_cs.mp3" }				//刺客模式 的場景音樂
const Float:assmode_duration = 28.0 						//刺客模式 的場景音樂的聲音長度(單位:秒)
new const surmode_sound[] = { "zombiehell/in_cs.mp3" }				//倖存者模式 的場景音樂
const Float:surmode_duration = 28.0 						//倖存者模式 的場景音樂的聲音長度(單位:秒)
new const snimode_sound[] = { "zombiehell/in_cs.mp3" }				//狙擊手模式 的場景音樂
const Float:snimode_duration = 28.0 						//狙擊手模式 的場景音樂的聲音長度(單位:秒)
new const nnmode_sound[] = { "zombiehell/in_cs.mp3" }				//其他模式 的場景音樂
const Float:nnmode_duration = 28.0 						//其他模式 的場景音樂的聲音長度(單位:秒)

new const killboss_sound[] = { "zombiehell/in_cs.mp3" }				//其他模式 的場景音樂
const Float:killboss_duration = 28.0 						//其他模式 的場景音樂的聲音長度(單位:秒)

new const ASS_LV1_MODEL[] = { "zombie_fat" } 					//1級刺客的人物模型
new const ASS_Knife_Model_1V[] = { "models/zombie_plague/v_knife_zombieab.mdl" }//1級刺客刀的V檔
new const ASS_Knife_Model_1P[] = { "models/stinger/p_hegrenade.mdl" }		//1級刺客刀的p檔

new const ASS_LV2_MODEL[] = { "zombie_fast" } 					//2級刺客的人物模型
new const ASS_Knife_Model_2V[] = { "models/zombie_plague/v_zomesz.mdl" }		//2級刺客刀的V檔
new const ASS_Knife_Model_2P[] = { "models/stinger/p_hegrenade.mdl" }		//2級刺客刀的p檔

new const ASS_LV3_MODEL[] = { "zombie_dog" } 					//3級刺客的人物模型
new const ASS_Knife_Model_3V[] = { "models/zombie_plague/v_knife_zombieab.mdl" }		//3級刺客刀的V檔
new const ASS_Knife_Model_3P[] = { "models/stinger/p_hegrenade.mdl" }		//3級刺客刀的p檔

new const NEM_LV1_MODEL[] = { "zombie_blocker" } 					//1級復仇者的人物模型
new const NEM_Knife_Model_1V[] = { "models/zombie_plague/v_zomesz.mdl" }		//1級復仇者刀的V檔
new const NEM_Knife_Model_1P[] = { "models/stinger/p_hegrenade.mdl" }		//1級復仇者刀的p檔

new const NEM_LV2_MODEL[] = { "zh_corpse" } 					//2級復仇者的人物模型
new const NEM_Knife_Model_2V[] = { "models/zombie_plague/v_knife_zombieab.mdl" }		//2級復仇者刀的V檔
new const NEM_Knife_Model_2P[] = { "models/stinger/p_hegrenade.mdl" }		//2級復仇者刀的p檔

new g_player_model[33][32]
new modelindex_asslv1[sizeof ASS_LV1_MODEL], modelindex_asslv2[sizeof ASS_LV2_MODEL], modelindex_asslv3[sizeof ASS_LV3_MODEL]
new modelindex_nemlv1[sizeof NEM_LV1_MODEL], modelindex_nemlv2[sizeof NEM_LV2_MODEL]

new bool:g_assassin[33], bool:g_nemesis[33], bool:boss_player[33]
new g_ass_level[33] = -1, g_nem_level[33] = -1

new cvar_ass_up1lvhp, cvar_ass_up2lvhp, cvar_ass_up3lvhp
new cvar_ass_1lvhp, cvar_ass_2lvhp, cvar_ass_3lvhp

new cvar_nem_up1lvhp, cvar_nem_up2lvhp
new cvar_nem_1lvhp, cvar_nem_2lvhp
new cvar_assinfected, cvar_assinfarmor

new round_asslv1, round_asslv2, round_asslv3, round_nemlv1, round_nemlv2
new now_music[64]

new assinfected, assinfarmor
new g_ass_die, g_nem_die

new cvar_botquota
new bool:BotHasDebug = false

new haveboss

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	cvar_assinfected = register_cvar("zp_assinfected", "1")		//開啟刺客感染 [1=感染 / 2=復仇者 / 3=刺客]
	cvar_assinfarmor = register_cvar("zp_assinfarmor", "1")		//刺客感染會否無視護甲 [1=無視護甲]

	//刺客
	cvar_ass_up1lvhp = register_cvar("zp_ass_up1lvhp", "500")	//刺客 血量小於xx 升級為 1級刺客 
	cvar_ass_1lvhp = register_cvar("zp_ass_1lvhp", "3000")		//1級刺客 血量

	cvar_ass_up2lvhp = register_cvar("zp_ass_up2lvhp", "1000")	//1級刺客 血量小於xx 升級為 2級刺客 
	cvar_ass_2lvhp = register_cvar("zp_ass_2lvhp", "4000")		//2級刺客 血量

	cvar_ass_up3lvhp = register_cvar("zp_ass_up3lvhp", "1500")	//2級刺客 血量小於xx 升級為 3級刺客 
	cvar_ass_3lvhp = register_cvar("zp_ass_3lvhp", "5000")		//3級刺客 血量

	//復仇者
	cvar_nem_up1lvhp = register_cvar("zp_nem_up1lvhp", "500")	//復仇者 血量小於xx 升級為 1級復仇者 
	cvar_nem_1lvhp = register_cvar("zp_nem_1lvhp", "3000")		//1級復仇者 血量

	cvar_nem_up2lvhp = register_cvar("zp_nem_up2lvhp", "1000")	//1級復仇者 血量小於xx 升級為 2級復仇者 
	cvar_nem_2lvhp = register_cvar("zp_nem_2lvhp", "4000")		//2級復仇者 血量

	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_event("DeathMsg","event_deathmsg","a")

	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged")

	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")

	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")

	cvar_botquota = get_cvar_pointer("bot_quota")

	assinfected = get_pcvar_num(cvar_assinfected)
	assinfarmor = get_pcvar_num(cvar_assinfarmor)
}

public plugin_precache()
{
	new i, model[100]
	for (i = 0; i < sizeof ASS_LV1_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", ASS_LV1_MODEL, ASS_LV1_MODEL)
		modelindex_asslv1[i] = precache_model(model)
	}
	for (i = 0; i < sizeof ASS_LV2_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", ASS_LV2_MODEL, ASS_LV2_MODEL)
		modelindex_asslv2[i] = precache_model(model)
	}
	for (i = 0; i < sizeof ASS_LV3_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", ASS_LV3_MODEL, ASS_LV3_MODEL)
		modelindex_asslv3[i] = precache_model(model)
	}
	for (i = 0; i < sizeof NEM_LV1_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", NEM_LV1_MODEL, NEM_LV1_MODEL)
		modelindex_nemlv1[i] = precache_model(model)
	}
	for (i = 0; i < sizeof NEM_LV2_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", NEM_LV2_MODEL, NEM_LV2_MODEL)
		modelindex_nemlv2[i] = precache_model(model)
	}

	precache_model(ASS_Knife_Model_1V)
	precache_model(ASS_Knife_Model_1P)
	precache_model(ASS_Knife_Model_2V)
	precache_model(ASS_Knife_Model_2P)
	precache_model(ASS_Knife_Model_3V)
	precache_model(ASS_Knife_Model_3P)

	precache_model(NEM_Knife_Model_1V)
	precache_model(NEM_Knife_Model_1P)
	precache_model(NEM_Knife_Model_2V)
	precache_model(NEM_Knife_Model_2P)

	precache_sound(ass1round_sound)
	precache_sound(ass2round_sound)
	precache_sound(ass3round_sound)
	precache_sound(nem1round_sound)
	precache_sound(nem2round_sound)

	precache_sound(infemode_sound)
	precache_sound(nemmode_sound)
	precache_sound(assmode_sound)
	precache_sound(surmode_sound)
	precache_sound(snimode_sound)
	precache_sound(nnmode_sound)

	precache_sound(killboss_sound)
}

public plugin_natives()
{
	register_native("zps_ass_level", "native_ass_level", 1)
	register_native("zps_nem_level", "native_nem_level", 1)

	register_native("zps_round_asslv1", "native_round_asslv1", 1)
	register_native("zps_round_asslv2", "native_round_asslv2", 1)
	register_native("zps_round_asslv3", "native_round_asslv3", 1)
	register_native("zps_round_nemlv1", "native_round_nemlv1", 1)
	register_native("zps_round_nemlv2", "native_round_nemlv2", 1)

	register_native("zps_assinfected", "native_assinfected", 1)
	register_native("zps_assinfarmor", "native_assinfarmor", 1)

	register_native("zps_nem_die", "native_nem_die", 1)
	register_native("zps_ass_die", "native_ass_die", 1)

	register_native("zps_spawn_nemass", "native_spawn_nemass", 1)
}

public logevent_round_end()
{
	gaming_round(0, 0)
	haveboss = 0
	g_nem_die = false
	g_ass_die = false

	for (new id = 1; id <= 32; id++)
	{
		if (!is_user_connected(id))
			continue;

		off_the_plugin(id)
	}
}

public event_deathmsg()
{
	new victim = read_data(2)
	if (haveboss && boss_player[victim])
	{
		set_hudmessage(200, 0, 0, -1.0, 0.17, 1, 0.0, 3.0, 2.0, 4.0, 1)
		
		if (g_nemesis[victim])
		{
			g_nem_die = true
			show_hudmessage (0, "NEMESIS DIE, ZOMBIE CAN NOT SPAWN")
			gaming_round(50, 50)
		}
		if (g_assassin[victim])
		{
			g_ass_die = true
			show_hudmessage (0, "ASSASSIN DIE, ZOMBIE CAN NOT SPAWN")
			gaming_round(50, 50)
		}
	}
}

public fw_PlayerPreThink(id)
{
	if (!is_user_connected(id))
		return FMRES_IGNORED;

	if (!zp_get_user_nemesis(id) && !zp_get_user_assassin(id))
	{
		off_the_plugin(id)
		return FMRES_IGNORED;
	}

	if (!is_user_alive(id))
	{
		off_the_plugin(id)
		return FMRES_IGNORED;
	}

	on_the_plugin(id)

	return FMRES_IGNORED;
}

public message_cur_weapon(msg_id, msg_dest, id)
{
	if (!is_user_alive(id) || get_msg_arg_int(1) != 1)
		return;
	
	if (!g_assassin[id] && !g_nemesis[id])
		return;
	
	if (g_ass_level[id] != 0 && g_nem_level[id] != 0)
		return;

	static weap_id
	weap_id = get_msg_arg_int(2)
	
	if (weap_id == CSW_KNIFE) set_knife_model(id)
}

public fw_takedamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!is_user_connected(victim))
		return HAM_IGNORED;

	if (!g_nemesis[victim] && !g_assassin[victim])
		return HAM_IGNORED;

	for (new i = 1; i <= 32; i++)
	{
		if (!is_user_alive(i) || !g_assassin[i] && !g_nemesis[i])
			continue;

		if (g_ass_level[i] > 0 || g_nem_level[i] > 0 && haveboss == 0)
		{
			haveboss += 1
			boss_player[i] = true

			break;
		}
	}

	if (haveboss != 0 && !boss_player[victim])
		return HAM_IGNORED;

	if (g_assassin[victim])
	{
		if (g_ass_level[victim] == 0)
		{
			if (get_user_health(victim) <= get_pcvar_float(cvar_ass_up1lvhp))
				blevelup(victim, 1, 1)
		}
		else if (g_ass_level[victim] == 1)
		{
			if (get_user_health(victim) <= get_pcvar_float(cvar_ass_up2lvhp))
				blevelup(victim, 1, 2)
		}
		else if (g_ass_level[victim] == 2)
		{
			if (get_user_health(victim) <= get_pcvar_float(cvar_ass_up3lvhp))
				blevelup(victim, 1, 3)
		}
	}

	if (g_nemesis[victim])
	{
		if (g_nem_level[victim] == 0)
		{
			if (get_user_health(victim) <= get_pcvar_float(cvar_nem_up1lvhp))
				blevelup(victim, 2, 1)
		}
		else if (g_nem_level[victim] == 1)
		{
			if (get_user_health(victim) <= get_pcvar_float(cvar_nem_up2lvhp))
				blevelup(victim, 2, 2)
		}
	}

	return HAM_IGNORED;
}

public fw_ClientUserInfoChanged(id)
{
	if ((g_assassin[id] || g_nemesis[id]) && (g_nem_level[id] != 0 && g_ass_level[id] != 0))
	{
		static current_model[32]
		fm_get_user_model(id, current_model, charsmax(current_model))
		
		if (!equal(current_model, g_player_model[id]))
			fm_set_user_model(id, g_player_model[id])
	}
}

blevelup(id, boss, uplv)
{
	if (boss == 1) //刺客 
	{
		if (!g_assassin[id]) return;

		set_hudmessage(255, 150, 20, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)

		if (g_ass_level[id] == 0 && uplv == 1)
		{
			g_ass_level[id] += 1
			fm_set_user_health(id, get_pcvar_num(cvar_ass_1lvhp))
			show_hudmessage(0, "G-1 Detected!!")
			set_knife_model(id)
			remove_task(TASK_BOSSMODEL)
			set_task(0.3, "set_user_model", id+TASK_BOSSMODEL)

			gaming_round(uplv, 2)
		}

		if (g_ass_level[id] == 1 && uplv == 2)
		{
			g_ass_level[id] += 1
			fm_set_user_health(id, get_pcvar_num(cvar_ass_2lvhp))
			show_hudmessage(0, "G-2 Detected!!")
			set_knife_model(id)
			remove_task(TASK_BOSSMODEL)
			set_task(0.3, "set_user_model", id+TASK_BOSSMODEL)

			gaming_round(uplv, 2)
		}

		if (g_ass_level[id] == 2 && uplv == 3)
		{
			g_ass_level[id] += 1
			fm_set_user_health(id, get_pcvar_num(cvar_ass_3lvhp))
			show_hudmessage(0, "G-3 Detected!!")
			set_knife_model(id)
			remove_task(TASK_BOSSMODEL)
			set_task(0.3, "set_user_model", id+TASK_BOSSMODEL)

			gaming_round(uplv, 2)
		}
	}
	else if (boss == 2)
	{
		if (!g_nemesis[id]) return;

		if (g_nem_level[id] == 0 && uplv == 1)
		{
			g_nem_level[id] += 1
			fm_set_user_health(id, get_pcvar_num(cvar_nem_1lvhp))
			show_hudmessage(0, "N-1 Detected!!")
			set_knife_model(id)
			remove_task(TASK_BOSSMODEL)
			set_task(0.3, "set_user_model", id+TASK_BOSSMODEL)

			gaming_round(uplv + 3, 2)
		}

		if (g_nem_level[id] == 1 && uplv == 2)
		{
			g_nem_level[id] += 1
			fm_set_user_health(id, get_pcvar_num(cvar_nem_2lvhp))
			show_hudmessage(0, "N-2 Detected!!")
			set_knife_model(id)
			remove_task(TASK_BOSSMODEL)
			set_task(0.3, "set_user_model", id+TASK_BOSSMODEL)

			gaming_round(uplv + 3, 2)
		}
	}
}

public zp_round_started(gamemode, id)
{
	if (gamemode == MODE_INFECTION)
		gaming_round(1, 1)
	else if (gamemode == MODE_NEMESIS)
		gaming_round(2, 1)
	else if (gamemode == MODE_ASSASSIN)
		gaming_round(3, 1)
	else if (gamemode == MODE_SURVIVOR)
		gaming_round(4, 1)
	else if (gamemode == MODE_SNIPER)
		gaming_round(5, 1)
	else if (gamemode != MODE_NONE)
		gaming_round(6, 1)
}

new Float: music_time = 0.0, Float: play_time = 0.0, debug_music1, debug_music2, newmodeformusic
public gaming_round(game, gamemode)
{
	StopSound(0, now_music)

	music_time = 0.0
	play_time = 0.0
	round_asslv1 = false
	round_asslv2 = false
	round_asslv3 = false
	round_nemlv1 = false
	round_nemlv2 = false
	debug_music1 = false
	debug_music2 = false

	if (game == 0)
	{
		debug_music1 = true
		debug_music2 = true
		return;
	}

	if (game == 50 && gamemode == 50)
	{
		debug_music1 = true
		debug_music2 = true
		music_time = killboss_duration
		newmodeformusic = 50
		remove_task(TASK_MUSIC1)
		set_task(0.2, "mode_music_play", TASK_MUSIC1)
		return;
	}

	if (gamemode == 1)
		mode_music(game)
	if (gamemode == 2)
		boss_music(game)
}

public boss_music(game)
{
	switch (game)
	{
		case 1:
		{
			round_asslv1 = true
			music_time = ass1round_duration
		}
		case 2:
		{
			round_asslv2 = true
			music_time = ass2round_duration
		}
		case 3:
		{
			round_asslv3 = true
			music_time = ass3round_duration
		}
		case 4:
		{
			round_nemlv1 = true
			music_time = nem1round_duration
		}
		case 5:
		{
			round_nemlv2 = true
			music_time = nem2round_duration
		}
	}

	remove_task(TASK_MUSIC2)
	set_task(0.2, "game_music_play", TASK_MUSIC2)
}

public mode_music(game)
{
	newmodeformusic = 0
	switch (game)
	{
		case 1: music_time = infemode_duration
		case 2: music_time = nemmode_duration
		case 3: music_time = assmode_duration
		case 4: music_time = surmode_duration
		case 5: music_time = snimode_duration
		case 6: music_time = nnmode_duration
	}
	if (1 <= game <= 6)newmodeformusic = game

	remove_task(TASK_MUSIC1)
	set_task(0.2, "mode_music_play", TASK_MUSIC1)
}

public mode_music_play()
{
	if (!(debug_music1 && debug_music2 && music_time == killboss_duration && newmodeformusic == 50))	
	{
		if (debug_music1)
			return;

		if (!(1 <= newmodeformusic <= 6))
			return;

		if (round_asslv1 || round_asslv2 || round_asslv3 || round_nemlv1 || round_nemlv2)
			return;
	}

	play_time -= 1.0

	remove_task(TASK_MUSIC1)
	set_task(1.0, "mode_music_play", TASK_MUSIC1)

	if (play_time >= 1.0)
		return;

	play_time = music_time + 1.0

	switch (newmodeformusic)
	{
		case 1: PlaySound(0, infemode_sound)
		case 2: PlaySound(0, nemmode_sound)
		case 3: PlaySound(0, assmode_sound)
		case 4: PlaySound(0, surmode_sound)
		case 5: PlaySound(0, snimode_sound)
		case 6: PlaySound(0, nnmode_sound)
		case 50: PlaySound(0, killboss_sound)
	}
}

public game_music_play()
{
	if (debug_music2)
		return;

	if (g_nem_die || g_ass_die)
		return;

	if (!round_asslv1 && !round_asslv2 && !round_asslv3 && !round_nemlv1 && !round_nemlv2)
		return;

	play_time -= 1.0

	remove_task(TASK_MUSIC2)
	set_task(1.0, "game_music_play", TASK_MUSIC2)

	if (play_time >= 1.0)
		return;

	play_time = music_time + 1.0

	if (round_asslv1) PlaySound(0, ass1round_sound)
	if (round_asslv2) PlaySound(0, ass2round_sound)
	if (round_asslv3) PlaySound(0, ass3round_sound)
	if (round_nemlv1) PlaySound(0, nem1round_sound)
	if (round_nemlv2) PlaySound(0, nem2round_sound)
}

public set_knife_model(id)
{
	if (!g_assassin[id] && !g_nemesis[id])
		return;

	if (g_assassin[id])
	{
		switch (g_ass_level[id])
		{
			case 1:
			{
				set_pev(id, pev_viewmodel2, ASS_Knife_Model_1V)
				set_pev(id, pev_weaponmodel2, ASS_Knife_Model_1P)
			}
			case 2:
			{
				set_pev(id, pev_viewmodel2, ASS_Knife_Model_2V)
				set_pev(id, pev_weaponmodel2, ASS_Knife_Model_2P)
			}
			case 3:
			{
				set_pev(id, pev_viewmodel2, ASS_Knife_Model_3V)
				set_pev(id, pev_weaponmodel2, ASS_Knife_Model_3P)
			}
		}
		return;
	}

	switch (g_nem_level[id])
	{
		case 1:
		{
			set_pev(id, pev_viewmodel2, NEM_Knife_Model_1V)
			set_pev(id, pev_weaponmodel2, NEM_Knife_Model_1P)
		}
		case 2:
		{
			set_pev(id, pev_viewmodel2, NEM_Knife_Model_2V)
			set_pev(id, pev_weaponmodel2, NEM_Knife_Model_2P)
		}
	}
}

public set_user_model(taskid)
{
	new id = taskid - TASK_BOSSMODEL

	if (!g_assassin[id] && !g_nemesis[id])
		return;

	new SetModel, goodset
	if (g_assassin[id])
	{
		switch (g_ass_level[id])
		{
			case 1: 
			{
				SetModel = random_num(0, sizeof ASS_LV1_MODEL)
				goodset = 1
			}
			case 2: 
			{
				SetModel = random_num(0, sizeof ASS_LV2_MODEL)
				goodset = 2
			}
			case 3: 
			{
				SetModel = random_num(0, sizeof ASS_LV3_MODEL)
				goodset = 3
			}
		}
	}
	if (g_nemesis[id])
	{
		switch (g_nem_level[id])
		{
			case 1:
			{
				SetModel = random_num(0, sizeof NEM_LV1_MODEL)
				goodset = 4
			}
			case 2:
			{
				SetModel = random_num(0, sizeof NEM_LV2_MODEL)
				goodset = 5
			}
		}
	}

	if (SetModel > 0)
	{
		if (g_nem_level[id] != 0 && g_ass_level[id] != 0)
		{
			new index = SetModel - 1
			switch (goodset)
			{
				case 1:
				{
					copy(g_player_model[id], charsmax(g_player_model[]), ASS_LV1_MODEL)
					fm_set_user_model(id, g_player_model[id])
					fm_set_user_model_index(id, modelindex_asslv1[index])
				}
				case 2:
				{
					copy(g_player_model[id], charsmax(g_player_model[]), ASS_LV2_MODEL)
					fm_set_user_model(id, g_player_model[id])
					fm_set_user_model_index(id, modelindex_asslv2[index])
				}
				case 3:
				{
					copy(g_player_model[id], charsmax(g_player_model[]), ASS_LV3_MODEL)
					fm_set_user_model(id, g_player_model[id])
					fm_set_user_model_index(id, modelindex_asslv3[index])
				}
				case 4:
				{
					copy(g_player_model[id], charsmax(g_player_model[]), NEM_LV1_MODEL)
					fm_set_user_model(id, g_player_model[id])
					fm_set_user_model_index(id, modelindex_nemlv1[index])
				}
				case 5:
				{
					copy(g_player_model[id], charsmax(g_player_model[]), NEM_LV2_MODEL)
					fm_set_user_model(id, g_player_model[id])
					fm_set_user_model_index(id, modelindex_nemlv2[index])
				}
			}
		}
	}
}

off_the_plugin(id)
{
	g_nemesis[id] = false
	g_nem_level[id] = -1

	g_assassin[id] = false
	g_ass_level[id] = -1

	if (boss_player[id])
		boss_player[id] = false
}

on_the_plugin(id)
{
	if (zp_get_user_nemesis(id) && !g_nemesis[id])
	{
		g_nemesis[id] = true
		g_nem_level[id] = 0
		boss_player[id] = false
		g_assassin[id] = false
		g_ass_level[id] = -1
	}
	if (zp_get_user_assassin(id) && !g_assassin[id])
	{
		g_assassin[id] = true
		g_ass_level[id] = 0
		boss_player[id] = false
		g_nemesis[id] = false
		g_nem_level[id] = -1
	}
}

public client_putinserver(id)
{
	off_the_plugin(id)

	if (is_user_bot(id))
	{
		if (!cvar_botquota || !is_user_bot(id) || BotHasDebug)
			return
	
		new classname[32]
		pev(id, pev_classname, classname, 31)
	
		if (!equal(classname, "player"))
			set_task(0.1, "_Debug", id)
	}
}

public _Debug(id)
{
	// Make sure it's a CZ bot and it's still connected
	if (!get_pcvar_num(cvar_botquota) || !is_user_connected(id))
		return;
	
	BotHasDebug = true
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_takedamage")
}

public native_round_asslv1()
{
	return round_asslv1;
}

public native_round_asslv2()
{
	return round_asslv2;
}

public native_round_asslv3()
{
	return round_asslv3;
}

public native_round_nemlv1()
{
	return round_nemlv1;
}

public native_round_nemlv2()
{
	return round_nemlv2;
}

public native_ass_level(id)
{
	return g_ass_level[id];
}

public native_nem_level(id)
{
	return g_nem_level[id];
}

public native_assinfected()
{
	return assinfected;
}

public native_assinfarmor()
{
	return assinfarmor;
}

public native_nem_die()
{
	return g_nem_die;
}

public native_ass_die()
{
	return g_ass_die;
}

public native_spawn_nemass(id)
{
	new g_assnem = random_num(1,2)

	if (g_assnem == 1)
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id)
		zp_make_user_assassin(id)
		gaming_round(3, 1)
		
        	set_hudmessage(200, 0, 0, -1.0, 0.17, 0, 0.0, 3.0, 2.0, 1.0, -1)
		show_hudmessage (0, "!!!ASSASSIN IN THE GAME!!!")
	}

	else if (g_assnem == 2)
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id)
		zp_make_user_nemesis(id)
		gaming_round(2, 1)
        
        	set_hudmessage(200, 0, 0, -1.0, 0.17, 0, 0.0, 3.0, 2.0, 1.0, -1)
		show_hudmessage (0, "!!!NEMESIS IN THE GAME!!!")
	}
	
	return 1;
}

stock fm_set_user_health(index, health) 
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);

	return 1;
}

stock fm_set_user_model(id, const model[])
{
	set_user_info(id, "model", model)
}

stock fm_set_user_model_index(id, value)
{
	set_pdata_int(id, 491, value, 5)
}

stock fm_get_user_model(player, model[], len)
{
	get_user_info(player, "model", model, len)
}

stock PlaySound(id, const sound[])
{
	copy(now_music, charsmax(now_music), sound)
//	client_print(0, print_chat, "%s %s", now_music, sound)

	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

stock StopSound(id, const sound[])
{
//	client_cmd(id, "mp3 stop; stopsound")

	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 stop ^"sound/%s^"", sound)
	else
		client_cmd(id, "stopsound") 
}
