
#include <amxmodx>
#include <zombieplague>

// Zombie  Attributes
new const name[] = { "Zombie1" } // name
new const info[] = { "Health" } // description
new const model[] = { "zombie_source" } // model
new const clawmodel[] = { "v_knife_zombie.mdl" } // claw model
const health = 3500 // health
const speed = 250 // speed
const Float:gravity = 0.8 // gravity
const Float:knockback = 0.5 // knockback
new const being_hit[] = { "zombie_plague/reloading04.wav" } // being hit sound
new const dies[] = { "zombie_plague/zombie_die4.wav"} // die hit sound
new const falls[] = { "zombie_plague/zombie_fall1.wav" } // fall hit sound

// Zombie  Attributes
new const name2[] = { "Zombie2" } // name
new const info2[] = { "Speed" } // description
new const model2[] = { "zombie_source" } // model
new const clawmodel2[] = { "v_knife_zombie.mdl" } // claw model
const health2 = 2000 // health
const speed2 = 300 // speed
const Float:gravity2 = 0.8 // gravity
const Float:knockback2 = 0.5 // knockback
new const being_hit2[] = { "zombie_plague/reloading04.wav" } // being hit sound
new const dies2[] = { "zombie_plague/zombie_die4.wav"} // die hit sound
new const falls2[] = { "zombie_plague/zombie_fall1.wav" } // fall hit sound

// Class IDs
new g_zclassid1, g_zclassid2

public plugin_precache()
{
	register_plugin("[ZP] Default Zombie Classes", "1.0", "HsK")

	g_zclassid1 = zp_register_zombie_class(name, info, model, clawmodel, health, speed, gravity, knockback)
	g_zclassid2 = zp_register_zombie_class(name2, info2, model2, clawmodel2, health2, speed2, gravity2, knockback2)
	zp_register_zombie_sound(g_zclassid1, being_hit, dies, falls)
	zp_register_zombie_sound(g_zclassid2, being_hit2, dies2, falls2)
}

public zp_user_infected_post(id, infector)
{
	if (zp_get_user_zombie_class(id) == g_zclassid1)
		client_print(id, print_chat, "you is are zombie1")
	if (zp_get_user_zombie_class(id) == g_zclassid2)
		client_print(id, print_chat, "you is are zombie2")
}
