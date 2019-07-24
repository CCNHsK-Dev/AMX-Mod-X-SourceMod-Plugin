
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>

/* 5/8/2011  */

new const weapon_msgname[][] = { "", "p228", "", "scout", "", "xm1014", "", "mac10", "aug", "", "elite", "fiveseven", 
	"ump45", "sg550", "galil", "famas", "usp", "glock18", "awp", "mp5navy", "m249", "m3", "m4a1",
	"tmp", "g3sg1", "", "deagle", "sg552", "ak47", "", "p90" }

new bool:BotHasDebug = false, cvar_botquota
new player_model[33][32], player_modelnnn[33][250]
new g_kill[33], g_die[33], g_att[33][2], g_DenT[33], g_kill_nHs[33]
new bool:g_PNHD[33] // player not hs die xD'
new g_SplayER[33] // Dead player see?

public plugin_init() 
{
	register_plugin("HS MoD", "1.0", "HsK")

	register_forward(FM_PlayerPreThink,"fw_PlayerPreThink")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData", 1)
	register_forward(FM_EmitSound, "fw_EmitSound")

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

	cvar_botquota = get_cvar_pointer("bot_quota")
}

public fw_PlayerPreThink(id)
{
	if (has_custom_weapons(id, (1<<CSW_HEGRENADE)))
	{
		set_pdata_int(id, 388, 0);
		return FMRES_IGNORED;
	}

	if (!is_user_alive(id))
	{
		new SI = pev(id, pev_iuser2)

		if (g_PNHD[SI])
		{
			g_SplayER[id] = SI; engfunc(EngFunc_SetView, id, g_DenT[SI]); 
		}
		if (!g_PNHD[g_SplayER[id]])
		{
			engfunc(EngFunc_SetView, id, g_SplayER[id]); g_SplayER[id] = 0;
		}

		return FMRES_IGNORED;
	}

	if (g_SplayER[id]) g_SplayER[id] = 0

	if (g_DenT[id] != 0 && g_PNHD[id])
	{
		engfunc(EngFunc_SetView, id, g_DenT[id])
		set_pev(id, pev_iuser2, g_DenT[id])
		set_pev(id, pev_iuser3, g_DenT[id])
	}

	return FMRES_IGNORED;
}

public fw_UpdateClientData(id, sendweapons, cd_handle)
{
	if (g_PNHD[id])
	{
		set_cd(cd_handle, CD_Flags, get_gametime() + 0.007);  
		set_cd(cd_handle, CD_Health, get_gametime() + 0.007);  
		set_cd(cd_handle, CD_Weapons, get_gametime() + 0.007);  
		set_cd(cd_handle, CD_iUser1, get_gametime() + 0.007);  
	}

	return FMRES_HANDLED;
}

public fw_EmitSound(ent, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	new classname[32]
	pev(ent, pev_classname, classname ,31)

	if (!(equal(classname, "PLAYER_DIE_MOD"))) return FMRES_IGNORED;

	for (new player = 1; player <= 32; player++)
	{
		if (is_user_connected(player) && g_PNHD[player] && g_DenT[player] == ent)
			client_cmd(player, "spk ^"%s^"", sample)
	}

	return FMRES_IGNORED;
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker || !is_user_connected(attacker))	return HAM_IGNORED;

	g_att[attacker][0] += 1;

	if (get_tr2(tracehandle, TR_iHitgroup) != 1)
	{
		if (get_user_health(victim) <= damage)
		{
			if (has_custom_weapons(victim, (1<<CSW_C4))) set_task(3.1, "give_c4", victim)

			if (get_user_team(victim) == get_user_team(attacker))
				spawn_victim(victim, get_user_weapon(victim), 
				attacker, get_pdata_int(attacker, 115), get_user_weapon(attacker), 1)
			else
				spawn_victim(victim, get_user_weapon(victim), 
				attacker, get_pdata_int(attacker, 115), get_user_weapon(attacker), 0)
		}

		return HAM_IGNORED;
	}

	g_att[attacker][1] += 1;

	return HAM_IGNORED;
}

public fw_PlayerKilled(victim, attacker, shouldgib) g_kill_nHs[attacker] += 1;

public spawn_victim(id, weapon, i, i_money, i_weapon, tk)
{
	new die_sounD[32]
	format(die_sounD, 31, "player/die%d.wav", random_num(1, 3))
	emit_sound(id, CHAN_BODY, die_sounD, 1.0, ATTN_NORM, 0, PITCH_NORM)

	get_user_info(id, "model", player_model[id], sizeof player_model[] - 1);
	formatex(player_modelnnn[id], sizeof player_modelnnn[] - 1, "models/player/%s/%s.mdl", 
	player_model[id], player_model[id]);

	if (!tk) g_kill[i] += 1; else g_kill[i] -= 1;
	g_die[id] += 1;
	g_PNHD[id] = true

	set_pdata_int(i, 115, i_money);
	message_begin(MSG_ONE, get_user_msgid("Money"), {0,0,0}, i);
	write_long(i_money);
	write_byte(0);
	message_end();

	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
	write_byte(i)
	write_byte(id)
	write_byte(0)
	write_string(weapon_msgname[i_weapon])
	message_end()

	new ent = player_die_ent(id)

	ExecuteHamB(Ham_CS_RoundRespawn, id)
	set_pev(id, pev_takedamage, DAMAGE_NO);

	engfunc(EngFunc_SetOrigin, id, {8192.0, 8192.0, 8192.0})
	if (ent != 0)
	{
		engfunc(EngFunc_SetView,id,ent)
		g_DenT[id] = ent

		new die_sounD[32]
		format(die_sounD, 31, "player/die%d.wav", random_num(1, 3))
		client_cmd(id, "spk ^"%s^"", die_sounD)
	}

	set_task(3.0, "vic_set", id)
}

public client_command(id)
{
	new arg[13]
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 

	new a = 0 
	do {
		if (equali("hegren", arg)) return PLUGIN_HANDLED 
	} while(++a < 34)
	
	return PLUGIN_CONTINUE 
} 

public vic_set(id)
{
	set_pev(id, pev_takedamage, DAMAGE_AIM);
	set_pev(id, pev_health, 100.0)
	ExecuteHamB(Ham_CS_RoundRespawn, id)
	engfunc(EngFunc_SetView, id, id)
	g_PNHD[id] = false
	g_DenT[id] = 0
}

public give_c4(id)
{
	fm_give_item(id, "weapon_c4")

	new plantskill = get_pdata_int(id, 193);

	plantskill |= (1<<8);
	set_pdata_int(id, 193, plantskill);

	message_begin(MSG_ONE, get_user_msgid("StatusIcon"), _, id);
	write_byte(1);
	write_string("c4");
	write_byte(0);
	write_byte(160);
	write_byte(0);
	message_end();

	message_begin(MSG_ALL, get_user_msgid("ScoreAttrib"));
	write_byte(id);
	write_byte(2);
	message_end();
}

player_die_ent(id)
{
	new Float:origin[3], Float:angles[3]
	pev(id, pev_origin, origin)
	pev(id, pev_angles, angles)
	angles[0] = 0.0
	angles[1] = random_float(87.0, 121.0)

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!ent) return 0;
	
	set_pev(ent, pev_classname, "PLAYER_DIE_MOD")
	set_pev(ent, pev_solid, 0)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_angles, angles)
	set_pev(ent, pev_sequence, random_num(106, 109))
	set_pev(ent, pev_animtime, get_gametime());
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_framerate, 1.0)

	engfunc(EngFunc_SetModel, ent, player_modelnnn[id])

	set_task(8.0, "remove_body", ent)

	return ent;
}

public show_KD_msg(id)
{
	set_hudmessage(200, 0, 0, 1.9, -1.0, 0, 6.0, 0.8, 0.0, 0.0, -1)
	ShowSyncHudMsg(id, CreateHudSyncObj(), "你的.. ^n殺敵數:%d , 爆頭殺敵數:%d ^n被殺數:%d , 爆頭被殺數:%d ^n你的爆頭機率:%2.f%% (%d/%d)",
	g_kill[id], g_kill_nHs[id], g_die[id], get_user_deaths(id), GeT_PEv(id), g_att[id][1], g_att[id][0])
}

Float:GeT_PEv(id)
{
	if (!g_att[id][1] || !g_att[id][0]) return (0.0)
	return (100.0 * float(g_att[id][1]) / float(g_att[id][0]))
}

public remove_body(ent)
	engfunc(EngFunc_RemoveEntity, ent)

public event_round_start()
{
	new classname[32], ent
	pev(ent, pev_classname, classname ,31)

	if ((equal(classname, "PLAYER_DIE_MOD")))
		engfunc(EngFunc_RemoveEntity, ent)

	for (new id = 1; id <= 32; id++)
	{
		if (!is_user_connected(id))
			continue;

		set_pev(id, pev_frags, float(g_kill_nHs[id]))
		g_SplayER[id] = 0
	}
}

public client_putinserver(id)
{
	g_kill[id] = 0; g_die[id] = 0; g_att[id][0] = 0; g_att[id][1] = 0; g_PNHD[id] = false; g_kill_nHs[id] = 0; g_SplayER[id] = 0;
	set_task(0.2, "show_KD_msg", id, _, _, "b")

	if (!is_user_bot(id) || !cvar_botquota || BotHasDebug) return;

	new classname[32]
	pev(id, pev_classname, classname, 31)
	
	if (!equal(classname, "player")) set_task(0.1, "_Debug", id)
}

public _Debug(id)
{
	if (!get_pcvar_num(cvar_botquota) || !is_user_connected(id)) return;
	
	BotHasDebug = true
	
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
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
		
		if ((1<<weaponid) & bitsum) return true;
	}
	
	return false;
}

stock fm_create_entity(const classname[])
	return engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))

stock fm_give_item(index, const item[])
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10)) return 0;
	
	new ent = fm_create_entity(item);
	if (!pev_valid(ent)) return 0;
	
	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);
	
	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save) return ent;
	
	engfunc(EngFunc_RemoveEntity, ent);
	
	return -1;
}