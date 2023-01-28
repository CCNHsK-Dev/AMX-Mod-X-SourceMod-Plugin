
#include <amxmodx>
#include <zombieplague>

new g_itemid1, g_itemid2

new g_item1_name[] = {"item1"}
new g_cost1 = 5  // cost 

new g_item2_name[] = {"item2"}
new cvar_cost2

public plugin_init()
{
	register_plugin("[ZP] Additional Extra Items", "1.0", "HsK")

/*===============================*/
	g_itemid1 = zp_register_extra_item(g_item1_name, g_cost1, ZP_TEAM_HUMAN)
	/* item 1 is human item , this cannot use cvar set cost */
/*===============================*/
/*===============================*/
	cvar_cost2 = register_cvar("zp_item2_cost", "6") // cost [cvar]

	g_itemid2 = zp_register_extra_item(g_item2_name, get_pcvar_num(cvar_cost2), ZP_TEAM_ZOMBIE, 1, "zp_item2_cost")
	/* item 2 is zombie item , this can use cvar set cost 
		last "" is cvar , you can go to amxx.cfg  [zp_item2_cost 1 ] test ^^ */
/*===============================*/
}

public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_itemid1)
		client_print(id, print_chat, "you buy %s", g_item1_name)

	if (itemid == g_itemid2)
		client_print(id, print_chat, "you buy %s", g_item2_name)
}