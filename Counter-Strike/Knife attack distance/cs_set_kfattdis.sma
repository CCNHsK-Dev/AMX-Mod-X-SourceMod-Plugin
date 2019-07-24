
#include <amxmodx>
#include <xs>
#include <fakemeta>

/*  20/9/2011  */

#define PLUGIN_NAME 	"[Cs] Knife attack distance"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_AUTHOR	"HsK"

new g_knatt[33];

// Cvars
new cvar_knattdis_s, cvar_knattdis_b;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	cvar_knattdis_s = register_cvar("amx_knattdis_s", "-500");	// 輕刀距離 (0=不變 , 可改比普通 CS 小刀更短的距離, -x可打後方)
	cvar_knattdis_b = register_cvar("amx_knattdis_b", "500");	// 重刀距離 (0=不變 , 可改比普通 CS 小刀更短的距離, -x可打後方)

	register_forward(FM_TraceLine, "fw_TraceLine");
	register_forward(FM_TraceHull, "fw_TraceHull");
}

public fw_TraceLine(Float:vecStart[3], Float:vecEnd[3], conditions, id, ptr)
{
	if (!is_user_alive(id)) return FMRES_IGNORED;

	static Float:flFraction, wead_id;
	wead_id = get_user_weapon(id);

	if (wead_id != CSW_KNIFE) return FMRES_IGNORED;

	static Float:vecAngles[3], Float:vecForward[3], attack_mod, Float:Distance;
	pev(id, pev_v_angle, vecAngles);
	engfunc(EngFunc_MakeVectors, vecAngles);

	global_get(glb_v_forward, vecForward);

	attack_mod = floatround((vecStart[0]-vecEnd[0])/vecForward[0]);

	if (attack_mod == -48) Distance = get_pcvar_float(cvar_knattdis_s);
	else if (attack_mod == -32) Distance = get_pcvar_float(cvar_knattdis_b);
	else
	{
		g_knatt[id] = 0;
		return FMRES_IGNORED;
	}

	if (Distance == 0) return FMRES_IGNORED;

	if ((attack_mod == -48 && Distance < 48.0) || (attack_mod == -32 && Distance < 32.0))
		g_knatt[id] = 2;
	else g_knatt[id] = 1;

	get_tr2(ptr, TR_flFraction, flFraction);

	if ((g_knatt[id] == 1 && flFraction >= 1.0) || g_knatt[id] == 2)
	{
		xs_vec_mul_scalar(vecForward, Distance, vecForward);
		xs_vec_add(vecStart, vecForward, vecEnd);

		engfunc(EngFunc_TraceLine, vecStart, vecEnd, conditions, id, ptr);
		return FMRES_SUPERCEDE;
	}
	else g_knatt[id] = 0;

	return FMRES_SUPERCEDE;
}

public fw_TraceHull(Float:vecStart[3], Float:vecEnd[3], conditions, hull, id, ptr)
{
	if (!is_user_alive(id)) return FMRES_IGNORED;

	if (g_knatt[id])
	{
		if (g_knatt[id] == 1) return FMRES_IGNORED;
		else return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}