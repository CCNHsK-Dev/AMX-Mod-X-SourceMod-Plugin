
#include <amxmodx>
#include <zombieplague>

new g_classname[33][32], infector_player[33]
new const new_model[] = {"models/player/zombie_swarm/zombie_swarm.mdl"}

public plugin_precache()
{
	register_plugin("[ZP] Remix TesT", "1.0", "HsK")
	precache_model(new_model)
}

public zp_user_frozen_post(id)
{
	zp_get_user_class_name(id, g_classname[id])    //g_classname[id] = class name
	zp_set_user_class_name(id, "Frozen..")  // Frozen = new class name
	client_print(id, print_chat, "oh...no..., frozen!")
}

public zp_user_unfrozen(id)
{
	zp_set_user_class_name(id, g_classname[id])  // re set class name
	client_print(id, print_chat, "oh...ya..., unfrozen!")
}

public zp_user_fire_post(id)
	client_print(id, print_chat, "oh...on..., fire!!!!!!")

public zp_user_infected_post(id, infector)
{
	infector_player[infector] += 1
	if (infector_player[infector] != 3)
		client_print(id, print_chat, "if you infector 3 player, you will use new player model!")
	else
	{
		client_print(infector, print_chat, "you can use new model! ^^")
		zp_set_player_model(infector, new_model) // set player model
		infector_player[infector] = 0
	}
}
