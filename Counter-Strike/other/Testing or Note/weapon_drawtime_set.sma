
/*================================================================================

/* 13/3/2011 */

換出武器 至 可開槍前的凍結時間 設定
(內定=-1, 1.0 = 1秒)

[設定變數]			[預設值]
weap_p228_drawtime		-1.0
weap_scout_drawtime		-1.0
weap_xm1014_drawtime		-1.0
weap_mac10_drawtime		-1.0
weap_aug_drawtime		-1.0
weap_elite_drawtime		-1.0
weap_fiveseven_drawtime		-1.0
weap_ump45_drawtime		-1.0
weap_sg550_drawtime		-1.0
weap_galil_drawtime		-1.0
weap_famas_drawtime		-1.0
weap_usp_drawtime		-1.0
weap_glock18_drawtime		-1.0
weap_awp_drawtime		-1.0
weap_mp5navy_drawtime		-1.0
weap_m249_drawtime		-1.0
weap_m3_drawtime		-1.0
weap_m4a1_drawtime		-1.0
weap_tmp_drawtime		-1.0
weap_g3sg1_drawtime		-1.0
weap_deagle_drawtime		-1.0
weap_sg552_drawtime		-1.0
weap_ak47_drawtime		-1.0
weap_knife_drawtime		-1.0
weap_p90_drawtime		-1.0

================================================================================*/

#include <amxmodx>
#include <fakemeta>

#define PLUGIN_NAME	"[CS] Weapon Draw Time Set"
#define VERSION	"1.0"
#define AUTHOR	"HsK"

new const weapon_drawtime[][] = {
	"-1.0",	//-----
	"-1.0",	//p228
	"-1.0",	//-----
	"-1.0",	//scout
	"-1.0",	//-----
	"-1.0",	//xm1014
	"-1.0",	//-----
	"-1.0",	//mac10
	"-1.0",	//aug
	"-1.0",	//-----
	"-1.0",	//elites
	"-1.0",	//fiveseven
	"-1.0",	//ump45
	"-1.0",	//sg550
	"-1.0",	//galil
	"-1.0",	//famas
	"-1.0",	//usp
	"-1.0",	//glock
	"-1.0",	//awp
	"-1.0",	//mp5navy
	"-1.0",	//m249
	"-1.0",	//m3
	"-1.0",	//m4a1
	"-1.0",	//tmp
	"-1.0",	//g3sg1
	"-1.0",	//-----
	"-1.0",	//deagle
	"-1.0",	//sg552
	"-1.0",	//ak47
	"-1.0", //-----
	"-1.0"	//p90
}

new const weapon_classname[][] = { "", "weapon_p228", "", "weapon_scout", "", "weapon_xm1014", "", "weapon_mac10",
	"weapon_aug", "", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas",
	"weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
	"weapon_tmp", "weapon_g3sg1", "", "weapon_deagle", "weapon_sg552", "weapon_ak47", "", "weapon_p90" }

new g_weap_drawtime[sizeof weapon_classname], g_newuse[33]

public plugin_init()
{
	register_plugin(PLUGIN_NAME, VERSION, AUTHOR)
	
	new cvar_string[32]
	for (new i = 0; i < sizeof weapon_classname; i++)
	{
		if (!weapon_classname[i][0]) continue;
		
		formatex(cvar_string, charsmax(cvar_string), "weap_%s_drawtime", weapon_classname[i][7])
		g_weap_drawtime[i] = register_cvar(cvar_string, weapon_drawtime[i])
	}
	
	register_event("CurWeapon","event_CurWeapon", "be", "1=1")
}

public event_CurWeapon(id)
{
	static weapon_id
	weapon_id = read_data(2)
	
	if (g_newuse[id] == weapon_id) return;
	
	g_newuse[id] = weapon_id
	
	if (!weapon_classname[weapon_id][0]) return; //避免沒 register_cvar 要設定作用的武器也進入以下設定
	
	new weapon = fm_find_ent_by_owner(-1, weapon_classname[weapon_id], id)
	
	if (!pev_valid(weapon)) return;
	
	new Float:draw_time = get_pcvar_float(g_weap_drawtime[weapon_id])
	
	if (draw_time == -1.0) return;
	
	set_S1_attack(id, weapon, draw_time)
}

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && (pev(entity, pev_owner) != owner)) {}
	
	return entity;
}

stock set_S1_attack(id, entity, Float:time)
{
	set_pdata_float(entity, 46, time, 4)
	set_pdata_float(entity, 47, time, 4)
//	set_pdata_float(entity, 48, time, 4)
	set_pdata_float(id, 83, time, 5)
}