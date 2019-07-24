
#include <amxmodx>
#include <amxmisc>
#include <zombieplague>

/*  12/8/2010   */

#define PLUGIN "[ZP] Countdown"
#define VERSION " 0.0.1 "
#define AUTHOR " HsK "

#define S_TIME 20			//Countdown Time

#define TASK_MAKEZOMBIE 7654

new g_time
new const countdown_sound[S_TIME][] = { "zpfb/one.wav", "zpfb/two.wav", "zpfb/three.wav", "zpfb/four.wav", "zpfb/five.wav", " ", " ", " ", " ", " ",
	"", "", "", "", "", "", "", "", "", ""}

new const RounD_SounD[] = { "zpfb/CSOzombi_start.wav" }

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
}

public plugin_precache()
{
	new i
	for (i = 0; i < sizeof countdown_sound; i++)
	{
		if(!equali(countdown_sound[i], " ") && !equali(countdown_sound[i], "") && !equali(countdown_sound[i], "0")) precache_sound(countdown_sound[i])
	}

	if(!equali(RounD_SounD, " ") && !equali(RounD_SounD, "") && !equali(RounD_SounD, "0")) precache_sound(RounD_SounD)
}

public event_round_start()
{
	if(!equali(RounD_SounD, " ") && !equali(RounD_SounD, "") && !equali(RounD_SounD, "0")) PlaySound(RounD_SounD)

	g_time = S_TIME
	remove_task(TASK_MAKEZOMBIE)
	set_task(0.0, "zp_round_countdown", TASK_MAKEZOMBIE)
}

public zp_round_countdown(taskid)
{
	if (g_time == 0) return;

	remove_task(TASK_MAKEZOMBIE)
	g_time -= 1
	set_task(1.0, "zp_round_countdown", TASK_MAKEZOMBIE)

	if (g_time != 0)
	{
		client_print(0, print_center,"**Infection on %i**", g_time)
		if(!equali(countdown_sound[g_time-1], " ") && !equali(countdown_sound[g_time-1], "") && !equali(countdown_sound[g_time-1], "0"))
			PlaySound(countdown_sound[g_time-1])
	}
}

public zp_round_started()
{
	if (g_time != 0) g_time = 0
	remove_task(TASK_MAKEZOMBIE)
}

public zp_round_ended()
{
	if (g_time != 0) g_time = 0
	remove_task(TASK_MAKEZOMBIE)
}

PlaySound(const sound[]) client_cmd(0, "spk ^"%s^"", sound)