
/* 正
 This plugin can get player model index  and makes the plugin set the model index serverside offset
  but , you will note.... if your models have messed up hitboxes 
this plugin may cause your server insane lag....
  and this plugin will set your server all player model index serverside
  so you will ensure your server all player model models have not messed up hitboxes ^^

  video: http://www.youtube.com/watch?v=yafd8hQPS1c
*/

#include <amxmodx>
#include <fakemeta>

/*  28/7/2010  */

#define PLUGIN	"Player model index debug"
#define VERSION "1.1"
#define AUTHOR	"HsK"

new cvar_modeldebug, g_play_player[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	cvar_modeldebug = register_cvar("set_modelindex", "1")
	if (get_pcvar_num(cvar_modeldebug))
	{
		register_forward(FM_PlayerPostThink, "fw_PlayerPostThink")
		register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged");
	}
}

public fw_PlayerPostThink(id)
{
	if (!is_user_alive(id) || !fm_get_user_team(id) && g_play_player[id] && get_pcvar_num(cvar_modeldebug))
		g_play_player[id] = 0

	if (is_user_alive(id) && fm_get_user_team(id) && !g_play_player[id] && get_pcvar_num(cvar_modeldebug))
	{
		g_play_player[id] = 1
		set_task(0.7, "CanGetModeL", id)
	}
}

public CanGetModeL(id) g_play_player[id] = 2

public fw_ClientUserInfoChanged(id)
{ 
	if (g_play_player[id] == 2 && get_pcvar_num(cvar_modeldebug))
	{
		static g_player_current_model[32], model_name[250];
		get_user_info(id, "model", g_player_current_model, sizeof g_player_current_model - 1);

		formatex(model_name, sizeof model_name - 1, "models/player/%s/%s.mdl", g_player_current_model, g_player_current_model);
		set_pdata_int(id, 491, engfunc(EngFunc_PrecacheModel, model_name), 5);
	}
}

stock fm_get_user_team(id)
	return get_pdata_int(id, 114, 5);