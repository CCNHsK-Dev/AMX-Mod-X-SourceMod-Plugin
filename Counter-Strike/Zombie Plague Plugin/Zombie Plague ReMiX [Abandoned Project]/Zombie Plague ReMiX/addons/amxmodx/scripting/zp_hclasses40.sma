#include <amxmodx>
#include <zombieplague>

// Human  Attributes
new const name[] = "Trooper" // name
new const info[] = "Health" // description
new const model[] = "Trooper" // model
const health = 250 // health
const speed = 230 // speed
const Float:gravity = 0.20 // gravity

// Human  Attributes
new const name2[] = "Jennifer" // name
new const info2[] = "Speed" // description
new const model2[] = "jennifer" // model
const health2 = 150 // health
const speed2 = 250 // speed
const Float:gravity2 = 0.20 // gravity

// Class IDs
new g_hclassid1, g_hclassid2

public plugin_precache()
{
	register_plugin("[ZP] Additional Human Classes", "1.0", "HsK")

	g_hclassid1 = zp_register_human_class(name, info, model, health, speed, gravity)	
	g_hclassid2 = zp_register_human_class(name2, info2, model2, health2, speed2, gravity2)	
}

public zp_user_humanized_class_post(id)
{
	if (zp_get_user_human_class(id) == g_hclassid1)
		client_print(id, print_chat, "you is are Trooper")
	if (zp_get_user_human_class(id) == g_hclassid2)
		client_print(id, print_chat, "you is are Jennifer")
}
