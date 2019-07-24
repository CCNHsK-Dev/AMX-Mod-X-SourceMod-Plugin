/*
	This is an edit of this plugin http://xtreme-jumps.eu/e107_plugins/forum/forum_viewtopic.php?102421 for ZP 4.3

	v0.2 by HsK 
		-自動穿人. 穿人實體. 更改代碼
*/
#include <amxmodx>
#include <fakemeta>
#include <zombieplague>

/*  15/3/2011  */

new bool:g_bSolid[33], bool:g_bHasSemiclip[33], Float:g_fOrigin[33][3]
new bool:g_changemodel[33], g_entmodel[33][3], player_model[33][32], player_modelnnn[33][250]

new g_iCvar[2]

public plugin_init( )
{
//	register_plugin( "[ZP] Antiblock", "0.1", "Maslyak" )
	register_plugin( "[ZP] Antiblock", "0.22", "Maslyak [0.2 by HsK]" )
	
	g_iCvar[0] = register_cvar( "semiclip_enabled", "1" )   // 插件開啟
	g_iCvar[1] = register_cvar( "semiclip_teamclip", "1" )  // 只可穿同隊
	
	if( get_pcvar_num( g_iCvar[0] ) )
	{
		register_event("DeathMsg","event_deathmsg","a")
		register_forward( FM_PlayerPreThink, "fwdPlayerPreThink" )
		register_forward( FM_PlayerPostThink, "fwdPlayerPostThink" )
		register_forward( FM_AddToFullPack, "fwdAddToFullPack_Post", 1 )
	}
}

public zp_user_infected_post(id) {
	Recover_User_Model(id); set_task(0.7, "test_get_model_time", id); }
public zp_user_humanized_post(id) {
	Recover_User_Model(id); set_task(0.7, "test_get_model_time", id); }
public event_deathmsg() Recover_User_Model(read_data(2))

public test_get_model_time(id) fm_get_model(id)

public fwdPlayerPreThink( plr )
{
	static id, last_think

	if( last_think > plr )
	{
		for( id = 1; id <= get_maxplayers(); id++ )
		{
			if( is_user_alive( id ) )
			{
				fm_get_model(id)
				g_bSolid[id] = pev( id, pev_solid ) == SOLID_SLIDEBOX ? true : false

				pev( id, pev_origin, g_fOrigin[id] )
			}
			else g_bSolid[id] = false
		}
	}

	last_think = plr

	if( g_bSolid[plr] )
	{
		for( id = 1; id <= get_maxplayers(); id++ )
		{
			if( g_bSolid[id] && get_distance_f( g_fOrigin[plr], g_fOrigin[id] ) <= 120 && id != plr )
			{
				if( get_pcvar_num( g_iCvar[1] ) && fm_get_user_team(plr) != fm_get_user_team(id) )
					return FMRES_IGNORED

				fm_get_model(id)

				set_pev( id, pev_solid, SOLID_NOT )
				g_bHasSemiclip[id] = true
			}
		}
	}

	return FMRES_IGNORED
}

public Recover_User_Model(id)
{
	if (get_pcvar_num(g_iCvar[0]))
	{
		g_entmodel[id][2] = false
		g_bSolid[id] = false
		g_bHasSemiclip[id] = false
		fm_remove_model_ents(id)
		fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
		g_changemodel[id] = false
	}
}

public fwdPlayerPostThink( plr )
{
	static id

	for( id = 1; id <= get_maxplayers(); id++ )
	{
		if( g_bHasSemiclip[id] )
		{
			set_pev( id, pev_solid, SOLID_SLIDEBOX )
			g_bHasSemiclip[id] = false
		}
	}
}

public fwdAddToFullPack_Post( es_handle, e, ent, host, hostflags, player, pset )
{
	if( player )
	{
		if( g_bSolid[host] && g_bSolid[ent] && get_distance_f( g_fOrigin[host], g_fOrigin[ent] ) <= 120 )
		{
			if (g_bSolid[ent] && is_user_alive(ent))
				fm_set_model_ent(ent)
			else
				if (g_changemodel[ent])
					Recover_User_Model(ent)

			if( get_pcvar_num( g_iCvar[1] ) && fm_get_user_team(host) != fm_get_user_team(ent))
				return FMRES_IGNORED
				
			set_es( es_handle, ES_Solid, SOLID_NOT ) // makes semiclip flawless
			set_es( es_handle, ES_RenderMode, kRenderTransAlpha )
			set_es( es_handle, ES_RenderAmt, 85 )
		}
	}
	
	return FMRES_IGNORED
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

stock fm_get_model(id)
{
	if (get_pcvar_num(g_iCvar[0]) && is_user_alive(id))
	{
		get_user_info(id, "model", player_model[id], sizeof player_model[] - 1);
		formatex(player_modelnnn[id], sizeof player_modelnnn[] - 1, "models/player/%s/%s.mdl", 
		player_model[id], player_model[id]);

		if (!g_entmodel[id][2]) set_task(1.0, "canuseau", id)
	}
}

public canuseau(id) g_entmodel[id][2] = true

stock fm_set_model_ent(id)
{
	if (!g_entmodel[id][2]) return;

	g_changemodel[id] = true
	static model[100]
	pev(id, pev_weaponmodel2, model, sizeof model - 1)
	fm_set_rendering(id, kRenderFxNone, 255, 255, 255, kRenderTransTexture, 0)
	
	if (!pev_valid(g_entmodel[id][1]))
	{
		g_entmodel[id][1] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		if (!pev_valid(g_entmodel[id][1])) return;
		
		set_pev(g_entmodel[id][1], pev_classname, "weapon_model")
		set_pev(g_entmodel[id][1], pev_movetype, MOVETYPE_FOLLOW)
		set_pev(g_entmodel[id][1], pev_aiment, id)
		set_pev(g_entmodel[id][1], pev_owner, id)
	}
	if (!pev_valid(g_entmodel[id][0]))
	{
		g_entmodel[id][0] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		if (!pev_valid(g_entmodel[id][0])) return;
		
		set_pev(g_entmodel[id][0], pev_classname, "player_model")
		set_pev(g_entmodel[id][0], pev_movetype, MOVETYPE_FOLLOW)
		set_pev(g_entmodel[id][0], pev_aiment, id)
		set_pev(g_entmodel[id][0], pev_owner, id)
	}
	
	engfunc(EngFunc_SetModel, g_entmodel[id][1], model)
	engfunc(EngFunc_SetModel, g_entmodel[id][0], player_modelnnn[id])
}

stock fm_remove_model_ents(id)
{
	if (pev_valid(g_entmodel[id][0]))
	{
		engfunc(EngFunc_RemoveEntity, g_entmodel[id][0])
		g_entmodel[id][0] = 0
	}
	if (pev_valid(g_entmodel[id][1]))
	{
		engfunc(EngFunc_RemoveEntity, g_entmodel[id][1])
		g_entmodel[id][1] = 0
	}
}

stock fm_get_user_team(id)
	return get_pdata_int(id, 114, 5);