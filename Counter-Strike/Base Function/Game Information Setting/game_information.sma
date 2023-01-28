#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

/* 19/8/2010  */

new g_MsgServerName, g_pointerHostname, g_szHostname[64]

new const ser_name[] = { "CCN_HsK CS" }
new const ser_gamename[] = { "CCN_HsK Server" }

public plugin_init() 
{
	register_plugin("Game Information", "1.1", "HsK")

	g_pointerHostname = get_cvar_pointer("hostname")
	g_MsgServerName = get_user_msgid("ServerName")
	Set_Server()
}

public plugin_end()
{
	if(strlen(g_szHostname))
	{
		set_pcvar_string(g_pointerHostname, g_szHostname)
	}
}

public Set_Server()
{
	Set_server_name()
	register_forward(FM_GetGameDescription, "GameDesc_NamE")

	set_task(15.0, "exec_game_set")
}

public exec_game_set()
{
	new configsDir[64]
	get_configsdir(configsDir, 63)
	
	server_cmd("exec %s/game_set.cfg", configsDir)

	Set_server_name()
	register_forward(FM_GetGameDescription, "GameDesc_NamE")
}

public GameDesc_NamE() 
{
	forward_return(FMV_STRING, ser_gamename)
	return FMRES_SUPERCEDE
}  

public Set_server_name()
{
	get_pcvar_string(g_pointerHostname, g_szHostname, 63)

	static szHostname[64]
	formatex(szHostname, 63, "%s", ser_name)

	message_begin(MSG_BROADCAST, g_MsgServerName)
	write_string(szHostname)
	message_end()

	set_pcvar_string(g_pointerHostname, szHostname)

	return PLUGIN_CONTINUE;
}