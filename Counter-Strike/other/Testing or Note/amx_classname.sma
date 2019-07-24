
#include <amxmodx>
#include <engine>

/*  22/4/2012  */

public plugin_init() 
{
	register_plugin("Get Entity Class Name", "1.0", "HsK");
}

public client_PostThink(id)
{
	if (!is_user_alive(id) || is_user_bot(id))
		return;

	new ent, classname[32], origin_g[3], Float:origin[3];
	get_user_origin(id, origin_g, 3);
	origin[0] = origin_g[0] * 1.0;
	origin[1] = origin_g[1] * 1.0;
	origin[2] = origin_g[2] * 1.0;

	while ((is_valid_ent(ent = FIND_ENTITY_IN_SPHERE(ent, origin, 20))))
	{
		entity_get_string(ent, EV_SZ_classname, classname, 31);

		if ( equal(classname, "weapon", 6) || equal(classname, "player", 6) || equal(classname, "item_", 5) || equal(classname, "ammo_", 5) ||
		equal(classname, "info_", 5) || equal(classname, "env_", 4) || equal(classname, "monster_", 8) )
			continue;

		if (equal(classname, "func_", 5) && !(equal(classname, "func_wall")))
			continue;

		client_print(id, print_center, "aim-entity [id[%d] classname[%s]]", ent, classname);
		return;
	}
	client_print(id, print_center, "aim-entity [null]");

	return;
}

stock FIND_ENTITY_IN_SPHERE(ent, Float:origin[3], dis)
	return find_ent_in_sphere(ent, origin, float(dis));

