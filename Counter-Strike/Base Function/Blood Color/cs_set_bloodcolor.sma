
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

/*  4/11/2011  */

#define PLUGIN_NAME 	"Blood Color"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_AUTHOR	"HsK"

new g_bloodSpr, cvar_BloodColor;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	cvar_BloodColor = register_cvar("amx_blood_color","71");

	RegisterHam(Ham_BloodColor,"player","fw_BloodColor");
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
}

public plugin_precache()
{
	g_bloodSpr = precache_model("sprites/blood.spr");
}

public fw_BloodColor(id)
{
	SetHamReturnInteger(get_pcvar_num(cvar_BloodColor));
	return HAM_SUPERCEDE;
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker) return HAM_IGNORED;

	if (!is_user_connected(victim) || !is_user_connected(attacker)) return HAM_IGNORED;

	if (get_tr2(tracehandle, TR_iHitgroup) == HIT_HEAD)
	{
		set_tr2(tracehandle,TR_vecEndPos,{8192.0, 8192.0, 8192.0});

		new origin[3]; get_user_origin(victim, origin, 1);
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(101);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2]);
		write_coord(random_num(-1, 1)); 
		write_coord(random_num(-1, 1)); 
		write_coord(random_num(-1, 0)); 
		write_byte(get_pcvar_num(cvar_BloodColor)); 
		write_byte(random_num(70,80)); 
		message_end();

		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(115);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2]);
		write_short(g_bloodSpr);
		write_short(g_bloodSpr);
		write_byte(get_pcvar_num(cvar_BloodColor));
		write_byte(15);
		message_end();
	}

	return HAM_IGNORED;
}

new Debug;
public client_putinserver(id)
{
	if(Debug == 1) return;
	new classname[32];
	pev(id,pev_classname,classname,31);

	if(!equal(classname,"player"))
	{
		Debug=1;
		remove_task(id+9950);
		set_task(1.0,"_Debug",id+9950);
	}
}
public _Debug(taskid)
{
	new id = taskid-9950;
	RegisterHamFromEntity(Ham_BloodColor, id,"fw_BloodColor");
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack");
}

