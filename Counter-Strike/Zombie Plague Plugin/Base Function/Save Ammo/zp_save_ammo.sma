
#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <nvault>

/*  30/8/2010  */

#define PLUGIN	"[ZP] Can Auto Save Ammo"
#define VERSION	"0.1.0"
#define AUTHOR	"HsK"

new g_save, g_ammo[33], g_ammo_can_save[33]
new cvar_save_in

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("DeathMsg","event_deathmsg","a")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")

	cvar_save_in = register_cvar("zp_ammo_save_in", "0")			// 0 = name / 1 = ip / 2 = steam id

	g_save = nvault_open("g_ammo_save")
}

// Save Ammo
public zp_user_infected_post(id, infector)
{
	if (g_ammo_can_save[infector])
		Save_Ammo_date(infector)
	
	if (g_ammo_can_save[id])
		Save_Ammo_date(id)
}

public zp_extra_item_selected(id, itemid)
{
	if (g_ammo_can_save[id])
		Save_Ammo_date(id)
}

public event_deathmsg()
{
	new killer = read_data(1)
	new victim = read_data(2)

	if (!killer && !victim)
		return PLUGIN_CONTINUE;

	if (g_ammo_can_save[killer])
		Save_Ammo_date(killer)
			
	if (g_ammo_can_save[victim])
		Save_Ammo_date(victim)

	return PLUGIN_CONTINUE;
}

public fw_PlayerPreThink(id)
{
	if (g_ammo_can_save[id])
	{
		new ammo_packs = zp_get_user_ammo_packs(id)
		g_ammo[id] = ammo_packs
	}

	return FMRES_IGNORED;
}

public client_disconnect(id)
{
	if(g_ammo_can_save[id])
		Save_Ammo_date(id)
}

public client_putinserver(id)
	set_task(2.0, "now_can_save", id)

public now_can_save(id)
{
	Load_Ammo_date(id)
	set_task(0.5, "can_save_true", id)
}

public can_save_true(id)
	g_ammo_can_save[id] = true

public Save_Ammo_date(id)
{
	new vaultkey[64], vaultdata[256]

	switch (get_pcvar_num(cvar_save_in))
	{
		case 0:
		{
			new name[33];
			get_user_name(id,name,32)
			
			format(vaultkey, 63, "%s-/", name)
		}
		case 1:
		{
			new player_ip[33]
			get_user_ip(id, player_ip, 32);

			format(vaultkey, 63, "%s-/", player_ip)
		}
		case 2:
		{
			new AuthID[33];
			get_user_authid(id, AuthID, 32);
			
			formatex(vaultkey, 64, "%s-/", AuthID);
		}
	}

	format(vaultdata, 255, "%i#", g_ammo[id])
	
	nvault_set(g_save, vaultkey, vaultdata)
	return PLUGIN_CONTINUE;
}

public Load_Ammo_date(id)
{
	new vaultkey[64], vaultdata[256]

	switch (get_pcvar_num(cvar_save_in))
	{
		case 0:
		{
			new name[33];
			get_user_name(id,name,32)
			
			format(vaultkey, 63, "%s-/", name)
		}
		case 1:
		{
			new player_ip[33]
			get_user_ip(id, player_ip, 32);

			format(vaultkey, 63, "%s-/", player_ip)
		}
		case 2:
		{
			new AuthID[33];
			get_user_authid(id, AuthID, 32);
			
			formatex(vaultkey, 64, "%s-/", AuthID);
		}
	}

	format(vaultdata, 255, "%i#", g_ammo[id])
	
	nvault_get(g_save, vaultkey, vaultdata, 255)
	replace_all(vaultdata, 255, "#", " ")
	
	new playammo[32]
	parse(vaultdata, playammo, 31)
	g_ammo[id] = str_to_num(playammo)
	
	set_ammo(id)
	
	return PLUGIN_CONTINUE;
}

public set_ammo(id)
{
	zp_set_user_ammo_packs(id, g_ammo[id])
	client_print(id, print_chat, "Your Ammo is  :  %d ", g_ammo[id])
}