#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

/*  4/4/2011 */

#define PLUGIN_NAME 	"Weapon Sound Black and Reset"
#define PLUGIN_VERSION	"1.0 beta2"
#define PLUGIN_AUTHOR	"HsK"

new const weapon_class[][] = { "", "weapon_p228", "", "weapon_scout", "", "weapon_xm1014", "", "weapon_mac10",
	"weapon_aug", "", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas",
	"weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
	"weapon_tmp", "weapon_g3sg1", "", "weapon_deagle", "weapon_sg552", "weapon_ak47", "", "weapon_p90" }

new const WEAPON_NAME[CSW_P90+1][] = { "", "CSW_P228", "", "CSW_SCOUT", "", "CSW_XM1014", "", "CSW_MAC10",
	"CSW_AUG", "", "CSW_ELITE", "CSW_FIVESEVEN", "CSW_UMP45", "CSW_SG550", "CSW_GALIL", "CSW_FAMAS", 
	"CSW_USP", "CSW_GLOCK18", "CSW_AWP", "CSW_MP5NAVY", "CSW_M249", "CSW_M3", "CSW_M4A1",
	"CSW_TMP", "CSW_G3SG1", "", "CSW_DEAGLE", "CSW_SG552", "CSW_AK47", "", "CSW_P90"
}

new Array:P228_sound, Array:scout_sound, Array:xm1014_sound, Array:mac10_sound, Array:aug_sound, Array:elite_sound, 
Array:fiveseven_sound, Array:ump45_sound, Array:sg550_sound, Array:galil_sound, Array:famas_sound, Array:usp_sound, 
Array:glock18_sound, Array:awp_sound, Array:mp5navy_sound, Array:m249_sound, Array:m3_sound, Array:m4a1_sound, Array:tmp_sound, 
Array:g3sg1_sound, Array:deagle_sound, Array:sg552_sound, Array:ak47_sound, Array:p90_sound, Array:m4a1_silen_sound,
Array:usp_silen_sound

new weapon_sound_back[CSW_P90+1], back_1sound[33]
new g_h_guns[33], g_EliteAnim[33]

new g_blood, g_bloodspray, g_smokeSpr

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	register_forward(FM_UpdateClientData, "fw_UpdateClientData", 1)
	register_forward(FM_PlaybackEvent, "fwd_PlaybackEvent")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")


	new i
	for (i = 0; i < sizeof weapon_class; i++)
	{
		if (strlen(weapon_class[i]) == 0) continue;

		RegisterHam(Ham_Weapon_PrimaryAttack, weapon_class[i], "fw_WeapPriAttack")
	}

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Post", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_Post", 1)
}

public plugin_natives()
{
	register_native("get_back_weapsound", "native_get_back_weapsound", 1)
	register_native("set_back_weapsound", "native_set_back_weapsound", 1)
}

public plugin_precache()
{
	P228_sound = ArrayCreate(64, 1)
	scout_sound = ArrayCreate(64, 1)
	xm1014_sound = ArrayCreate(64, 1)
	mac10_sound = ArrayCreate(64, 1)
	aug_sound = ArrayCreate(64, 1)
	elite_sound = ArrayCreate(64, 1)
	fiveseven_sound = ArrayCreate(64, 1)
	ump45_sound = ArrayCreate(64, 1)
	sg550_sound = ArrayCreate(64, 1)
	galil_sound = ArrayCreate(64, 1)
	famas_sound = ArrayCreate(64, 1)
	usp_sound = ArrayCreate(64, 1)
	glock18_sound = ArrayCreate(64, 1)
	awp_sound = ArrayCreate(64, 1)
	mp5navy_sound = ArrayCreate(64, 1)
	m249_sound = ArrayCreate(64, 1)
	m3_sound = ArrayCreate(64, 1)
	m4a1_sound = ArrayCreate(64, 1)
	tmp_sound = ArrayCreate(64, 1)
	g3sg1_sound = ArrayCreate(64, 1)
	deagle_sound = ArrayCreate(64, 1)
	sg552_sound = ArrayCreate(64, 1)
	ak47_sound = ArrayCreate(64, 1)
	p90_sound = ArrayCreate(64, 1)
	m4a1_silen_sound = ArrayCreate(64, 1)
	usp_silen_sound = ArrayCreate(64, 1)

	load_settings()

	new i, buffer[100]

        g_blood = precache_model("sprites/blood.spr")
        g_bloodspray = precache_model("sprites/bloodspray.spr")
	g_smokeSpr = precache_model("sprites/xsmoke4.spr")

	for (i = 0; i < ArraySize(P228_sound); i++)
	{
		ArrayGetString(P228_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(scout_sound); i++)
	{
		ArrayGetString(scout_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(xm1014_sound); i++)
	{
		ArrayGetString(xm1014_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(mac10_sound); i++)
	{
		ArrayGetString(mac10_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(aug_sound); i++)
	{
		ArrayGetString(aug_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(elite_sound); i++)
	{
		ArrayGetString(elite_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(fiveseven_sound); i++)
	{
		ArrayGetString(fiveseven_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(ump45_sound); i++)
	{
		ArrayGetString(ump45_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sg550_sound); i++)
	{
		ArrayGetString(sg550_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(galil_sound); i++)
	{
		ArrayGetString(galil_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(famas_sound); i++)
	{
		ArrayGetString(famas_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(usp_sound); i++)
	{
		ArrayGetString(usp_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(glock18_sound); i++)
	{
		ArrayGetString(glock18_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(awp_sound); i++)
	{
		ArrayGetString(awp_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(mp5navy_sound); i++)
	{
		ArrayGetString(mp5navy_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(m249_sound); i++)
	{
		ArrayGetString(m249_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(m3_sound); i++)
	{
		ArrayGetString(m3_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(m4a1_sound); i++)
	{
		ArrayGetString(m4a1_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(tmp_sound); i++)
	{
		ArrayGetString(tmp_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(g3sg1_sound); i++)
	{
		ArrayGetString(g3sg1_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(deagle_sound); i++)
	{
		ArrayGetString(deagle_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sg552_sound); i++)
	{
		ArrayGetString(sg552_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(ak47_sound); i++)
	{
		ArrayGetString(ak47_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(p90_sound); i++)
	{
		ArrayGetString(p90_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(m4a1_silen_sound); i++)
	{
		ArrayGetString(m4a1_silen_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(usp_silen_sound); i++)
	{
		ArrayGetString(usp_silen_sound, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
}

new Debug
public client_putinserver(id)
{
	if(Debug == 1) return
	new classname[32]
	pev(id,pev_classname,classname,31)

	if(!equal(classname,"player"))
	{
		Debug=1
		remove_task(id+9950)
		set_task(1.0,"_Debug",id+9950)
	}
}
public _Debug(taskid)
{
	new id = taskid-9950
	RegisterHamFromEntity(Ham_TraceAttack,id,"fw_TraceAttack_Post",1)
}

public fw_TraceAttack_Post(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (1 <= attacker <= 32 && (weapon_sound_back[get_user_weapon(attacker)] || back_1sound[attacker]))
	{
		static Float:aimOrigin[3]

		get_tr2(tracehandle, TR_vecEndPos, aimOrigin)

		if (1 <= victim <= 32)
		{
			static Float:fEnd[3], Float:fRes[3], Float:fVel[3], res
			velocity_by_aim(attacker, 64, fVel)

	                fEnd[0] = aimOrigin[0]+fVel[0]
	                fEnd[1] = aimOrigin[1]+fVel[1]
	                fEnd[2] = aimOrigin[2]+fVel[2]

			engfunc(EngFunc_TraceLine, aimOrigin, fEnd, 0, 1, res)
			get_tr2(res, TR_vecEndPos, fRes)

			engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, aimOrigin, 0)
	                write_byte(TE_BLOODSPRITE)
			engfunc(EngFunc_WriteCoord,aimOrigin[0])
			engfunc(EngFunc_WriteCoord,aimOrigin[1])
			engfunc(EngFunc_WriteCoord,aimOrigin[2])
	                write_short(g_bloodspray)
	                write_short(g_blood)
	                write_byte(70)
	                write_byte(random_num(1,2))
	                message_end()
		}
		else set_message_DECAL(attacker, aimOrigin)

		back_1sound[attacker] = floatround(get_gametime())
        }
}

public fw_UpdateClientData(id, sendweapons, cd_handle)
{
	if (weapon_sound_back[get_user_weapon(id)] || back_1sound[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.007);  

	return FMRES_HANDLED;
}

public fwd_PlaybackEvent(iFlags, id)
{ 
	if (iFlags == 1 || back_1sound[id])	
		if (weapon_sound_back[get_user_weapon(id)]) return FMRES_SUPERCEDE; 

	return FMRES_IGNORED 
}

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED 

	if (g_h_guns[id] && !(pev(id, pev_button) & IN_ATTACK) && !(pev(id, pev_oldbuttons) & IN_ATTACK))
		g_h_guns[id] = false

	if (back_1sound[id] != 0)
		if (get_gametime() > back_1sound[id] + 0.5) back_1sound[id] = false

	return FMRES_IGNORED 
}

public fw_WeapPriAttack(weapon)
{
	if (!pev_valid(weapon) || !(fm_get_weapon_ammo(weapon) > 0)) return HAM_IGNORED;

	static owner, weap_id, sound[64]
	owner = pev(weapon, pev_owner)
	weap_id = fm_get_weaponid(weapon)

	if (g_h_guns[owner]) return HAM_IGNORED;

	if (!weapon_sound_back[weap_id] && !back_1sound[owner]) return HAM_IGNORED;

	switch (weap_id)
	{
		case CSW_P228:
		{
			g_h_guns[owner] = true

			SendWeaponAnim(owner, random_num(1, 3))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(P228_sound, random_num(0, ArraySize(P228_sound) - 1), sound, charsmax(sound))
		}
		case CSW_ELITE:
		{
			g_h_guns[owner] = true

			if (g_EliteAnim[owner] == 0) { SendWeaponAnim(owner, random_num(2, 6)); g_EliteAnim[owner] = 1;}
			else { SendWeaponAnim(owner, random_num(8, 12)); g_EliteAnim[owner] = 0;}

			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(elite_sound, random_num(0, ArraySize(elite_sound) - 1), sound, charsmax(sound))
		}
		case CSW_FIVESEVEN:
		{
			g_h_guns[owner] = true
			SendWeaponAnim(owner, random_num(1, 2))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(fiveseven_sound, random_num(0, ArraySize(fiveseven_sound) - 1), sound, charsmax(sound))
		}
		case CSW_USP:
		{
			g_h_guns[owner] = true
			if (fm_get_weapon_silen(weapon))
				SendWeaponAnim(owner, random_num(1, 3))
			else
				SendWeaponAnim(owner, random_num(9, 11))

			if (weapon_sound_back[weap_id] == 2)
			{
				if (fm_get_weapon_silen(weapon))
					ArrayGetString(usp_sound, random_num(0, ArraySize(usp_sound) - 1), sound, charsmax(sound))
				else
					ArrayGetString(usp_silen_sound, random_num(0, ArraySize(usp_silen_sound) - 1), 
					sound, charsmax(sound))
			}
		}
		case CSW_DEAGLE:
		{
			g_h_guns[owner] = true
			SendWeaponAnim(owner, random_num(1, 2))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(deagle_sound, random_num(0, ArraySize(deagle_sound) - 1), sound, charsmax(sound))
		}
		case CSW_GLOCK18:
		{
			g_h_guns[owner] = true
			if (fm_get_weapon_burst(weapon))
				SendWeaponAnim(owner, random_num(3, 4))
			else
				SendWeaponAnim(owner, 5)
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(glock18_sound, random_num(0, ArraySize(glock18_sound) - 1), sound, charsmax(sound))
		}

		case CSW_SCOUT:
		{
			SendWeaponAnim(owner, random_num(1, 2))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(scout_sound, random_num(0, ArraySize(scout_sound) - 1), sound, charsmax(sound))
		}
		case CSW_XM1014:
		{
			SendWeaponAnim(owner, random_num(1, 2))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(xm1014_sound, random_num(0, ArraySize(xm1014_sound) - 1), sound, charsmax(sound))
		}
		case CSW_MAC10:
		{
			SendWeaponAnim(owner, random_num(3, 5))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(mac10_sound, random_num(0, ArraySize(mac10_sound) - 1), sound, charsmax(sound))
		}
		case CSW_AUG:
		{
			SendWeaponAnim(owner, random_num(3, 5))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(aug_sound, random_num(0, ArraySize(aug_sound) - 1), sound, charsmax(sound))
		}
		case CSW_UMP45:
		{
			SendWeaponAnim(owner, random_num(3, 5))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(ump45_sound, random_num(0, ArraySize(ump45_sound) - 1), sound, charsmax(sound))
		}
		case CSW_SG550:
		{
			SendWeaponAnim(owner, random_num(1, 2))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(sg550_sound, random_num(0, ArraySize(sg550_sound) - 1), sound, charsmax(sound))
		}
		case CSW_GALIL:
		{
			SendWeaponAnim(owner, random_num(3, 5))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(galil_sound, random_num(0, ArraySize(galil_sound) - 1), sound, charsmax(sound))
		}
		case CSW_FAMAS:
		{
			if (fm_get_weapon_burst(weapon))
				SendWeaponAnim(owner, random_num(3, 4))
			else
				SendWeaponAnim(owner, 5)

			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(famas_sound, random_num(0, ArraySize(famas_sound) - 1), sound, charsmax(sound))
		}
		case CSW_AWP:
		{
			SendWeaponAnim(owner, random_num(1, 3))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(awp_sound, random_num(0, ArraySize(awp_sound) - 1), sound, charsmax(sound))
		}
		case CSW_MP5NAVY:
		{
			SendWeaponAnim(owner, random_num(3, 5))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(mp5navy_sound, random_num(0, ArraySize(mp5navy_sound) - 1), sound, charsmax(sound))
		}
		case CSW_M249:
		{
			SendWeaponAnim(owner, random_num(1, 2))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(m249_sound, random_num(0, ArraySize(m249_sound) - 1), sound, charsmax(sound))
		}
		case CSW_M3:
		{
			SendWeaponAnim(owner, random_num(1, 2))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(m3_sound, random_num(0, ArraySize(m3_sound) - 1), sound, charsmax(sound))
		}
		case CSW_M4A1:
		{
			if (fm_get_weapon_silen(weapon))
				SendWeaponAnim(owner, random_num(1, 3))
			else
				SendWeaponAnim(owner, random_num(8, 10))

			if (weapon_sound_back[weap_id] == 2)
			{
				if (fm_get_weapon_silen(weapon))
					ArrayGetString(m4a1_sound, random_num(0, ArraySize(m4a1_sound) - 1), sound, charsmax(sound))
				else
					ArrayGetString(m4a1_silen_sound, random_num(0, ArraySize(m4a1_silen_sound) - 1), 
					sound, charsmax(sound))
			}
		}
		case CSW_TMP:
		{
			SendWeaponAnim(owner, random_num(3, 5))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(tmp_sound, random_num(0, ArraySize(tmp_sound) - 1), sound, charsmax(sound))
		}
		case CSW_G3SG1:
		{
			SendWeaponAnim(owner, random_num(1, 2))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(g3sg1_sound, random_num(0, ArraySize(g3sg1_sound) - 1), sound, charsmax(sound))
		}
		case CSW_SG552:
		{
			SendWeaponAnim(owner, random_num(3, 5))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(sg552_sound, random_num(0, ArraySize(sg552_sound) - 1), sound, charsmax(sound))
		}
		case CSW_AK47:
		{
			SendWeaponAnim(owner, random_num(3, 5))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(ak47_sound, random_num(0, ArraySize(ak47_sound) - 1), sound, charsmax(sound))
		}
		case CSW_P90:
		{
			SendWeaponAnim(owner, random_num(3, 5))
			if (weapon_sound_back[weap_id] == 2)
				ArrayGetString(p90_sound, random_num(0, ArraySize(p90_sound) - 1), sound, charsmax(sound))
		}
	}

	if (weapon_sound_back[weap_id] == 2)
		emit_sound(owner, CHAN_WEAPON, sound, 1.0, ATTN_NONE, 0, PITCH_NORM)

	return HAM_IGNORED;
}

stock set_message_DECAL(id, Float:aimOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, aimOrigin, 0)
	write_byte(TE_WORLDDECAL)
	engfunc(EngFunc_WriteCoord,aimOrigin[0])
	engfunc(EngFunc_WriteCoord,aimOrigin[1])
	engfunc(EngFunc_WriteCoord,aimOrigin[2])
	write_byte(random_num(41, 45))
	message_end()

	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, aimOrigin, 0)
	write_byte(TE_GUNSHOTDECAL)
	engfunc(EngFunc_WriteCoord,aimOrigin[0])
	engfunc(EngFunc_WriteCoord,aimOrigin[1])
	engfunc(EngFunc_WriteCoord,aimOrigin[2])
	write_short(id)
	write_byte(random_num(41, 45))
	message_end()

	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, aimOrigin, 0)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord,aimOrigin[0])
	engfunc(EngFunc_WriteCoord,aimOrigin[1])
	engfunc(EngFunc_WriteCoord,aimOrigin[2])
	message_end()

	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, aimOrigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord,aimOrigin[0])
	engfunc(EngFunc_WriteCoord,aimOrigin[1])
	engfunc(EngFunc_WriteCoord,aimOrigin[2])
	write_short(g_smokeSpr) 
	write_byte(7) 
	write_byte(60)
	message_end()
}

load_settings()
{
	new path[64]
	get_configsdir(path, 63);
	format(path, 63, "%s/new_weapon_sound.ini", path);
	
	if (!file_exists(path))
	{
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return;
	}

	new file, linedata[1024], key[64], value[960], section

	file = fopen(path, "rt")

	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata))

		replace(linedata, charsmax(linedata), "^n", "")

		if (!linedata[0] || linedata[0] == ';') continue;

		if (linedata[0] == '[')
		{
			section++
			continue;
		}

		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')

		trim(key)
		trim(value)
		
		switch (section)
		{
			case 1:
			{
				if (equal(key, "P228 OFF SOUND")) weapon_sound_back[CSW_P228] = read_flags(value)
				else if (equal(key, "SCOUT OFF SOUND")) weapon_sound_back[CSW_SCOUT] = read_flags(value)
				else if (equal(key, "XM1014 OFF SOUND")) weapon_sound_back[CSW_XM1014] = read_flags(value)
				else if (equal(key, "MAC10 OFF SOUND")) weapon_sound_back[CSW_MAC10] = read_flags(value)
				else if (equal(key, "AUG OFF SOUND")) weapon_sound_back[CSW_AUG] = read_flags(value)
				else if (equal(key, "ELITE OFF SOUND")) weapon_sound_back[CSW_ELITE] = read_flags(value)
				else if (equal(key, "FIVESEVEN OFF SOUND")) weapon_sound_back[CSW_FIVESEVEN] = read_flags(value)
				else if (equal(key, "UMP45 OFF SOUND")) weapon_sound_back[CSW_UMP45] = read_flags(value)
				else if (equal(key, "SG550 OFF SOUND")) weapon_sound_back[CSW_SG550] = read_flags(value)
				else if (equal(key, "GALIL OFF SOUND")) weapon_sound_back[CSW_GALIL] = read_flags(value)
				else if (equal(key, "FAMAS OFF SOUND")) weapon_sound_back[CSW_FAMAS] = read_flags(value)
				else if (equal(key, "USP OFF SOUND")) weapon_sound_back[CSW_USP] = read_flags(value)
				else if (equal(key, "GLOCK18 OFF SOUND")) weapon_sound_back[CSW_GLOCK18] = read_flags(value)
				else if (equal(key, "AWP OFF SOUND")) weapon_sound_back[CSW_AWP] = read_flags(value)
				else if (equal(key, "MP5 OFF SOUND")) weapon_sound_back[CSW_MP5NAVY] = read_flags(value)
				else if (equal(key, "M249 OFF SOUND")) weapon_sound_back[CSW_M249] = read_flags(value)
				else if (equal(key, "M3 OFF SOUND")) weapon_sound_back[CSW_M3] = read_flags(value)
				else if (equal(key, "M4A1 OFF SOUND")) weapon_sound_back[CSW_M4A1] = read_flags(value)
				else if (equal(key, "TMP OFF SOUND")) weapon_sound_back[CSW_TMP] = read_flags(value)
				else if (equal(key, "G3SG1 OFF SOUND")) weapon_sound_back[CSW_G3SG1] = read_flags(value)
				else if (equal(key, "DEAGLE OFF SOUND")) weapon_sound_back[CSW_DEAGLE] = read_flags(value)
				else if (equal(key, "SG552 OFF SOUND")) weapon_sound_back[CSW_SG552] = read_flags(value)
				else if (equal(key, "AK47 OFF SOUND")) weapon_sound_back[CSW_AK47] = read_flags(value)
				else if (equal(key, "P90 OFF SOUND")) weapon_sound_back[CSW_P90] = read_flags(value)
			}
			case 2:
			{
				if (equal(key, "P228 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(P228_sound, key)
					}
				}
				else if (equal(key, "SCOUT NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(scout_sound, key)
					}
				}
				else if (equal(key, "XM1014 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(xm1014_sound, key)
					}
				}
				else if (equal(key, "MAC10 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(mac10_sound, key)
					}
				}

				else if (equal(key, "AUG NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(aug_sound, key)
					}
				}
				else if (equal(key, "ELITE NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(elite_sound, key)
					}
				}
				else if (equal(key, "FIVESEVEN NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(fiveseven_sound, key)
					}
				}
				else if (equal(key, "UMP45 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(ump45_sound, key)
					}
				}
				else if (equal(key, "SG550 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(sg550_sound, key)
					}
				}
				else if (equal(key, "GALIL NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(galil_sound, key)
					}
				}
				else if (equal(key, "FAMAS NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(famas_sound, key)
					}
				}
				else if (equal(key, "USP NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(usp_sound, key)
					}
				}
				else if (equal(key, "GLOCK18 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(glock18_sound, key)
					}
				}
				else if (equal(key, "AWP NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(awp_sound, key)
					}
				}

				else if (equal(key, "MP5 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(mp5navy_sound, key)
					}
				}
				else if (equal(key, "M249 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(m249_sound, key)
					}
				}
				else if (equal(key, "M3 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(m3_sound, key)
					}
				}
				else if (equal(key, "M4A1 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(m4a1_sound, key)
					}
				}
				else if (equal(key, "TMP NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(tmp_sound, key)
					}
				}
				else if (equal(key, "G3SG1 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(g3sg1_sound, key)
					}
				}
				else if (equal(key, "DEAGLE NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(deagle_sound, key)
					}
				}
				else if (equal(key, "SG552 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(sg552_sound, key)
					}
				}
				else if (equal(key, "AK47 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(ak47_sound, key)
					}
				}
				else if (equal(key, "P90 NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(p90_sound, key)
					}
				}
				else if (equal(key, "M4A1 SILEN NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(m4a1_silen_sound, key)
					}
				}
				else if (equal(key, "USP SILEN NEW SOUND"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)

						ArrayPushString(usp_silen_sound, key)
					}
				}
			}
		}
	}
	if (file) fclose(file)

	set_nnann()
}

public set_nnann()
{
	for (new i = 0; i < sizeof WEAPON_NAME; i++)
	{
		if (strlen(WEAPON_NAME[i]) == 0) continue;

		if (weapon_sound_back[i] == read_flags("0")) weapon_sound_back[i] = 0
		else if (weapon_sound_back[i] == read_flags("1")) weapon_sound_back[i] = 1
		else if (weapon_sound_back[i] == read_flags("2")) weapon_sound_back[i] = 2
	}
}

public native_get_back_weapsound(id)
	return weapon_sound_back[get_user_weapon(id)];

public native_set_back_weapsound(id)
{
	switch (weapon_sound_back[get_user_weapon(id)])
	{
		case 0: back_1sound[id] = true
		case 2: back_1sound[id] = true
	}
}

stock fm_get_weapon_ammo(entity) return get_pdata_int(entity, 51, 4);

stock fm_get_weaponid(entity) return get_pdata_int(entity, 43, 4);

stock SendWeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(iAnim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock fm_get_weapon_silen(index)
{
	new weapontype, silencemode;
	weapontype = get_pdata_int(index, 43, 4);
	silencemode = get_pdata_int(index, 74, 4);
	
	switch(weapontype) 
	{
		case CSW_USP:
		{
			if(silencemode & (1<<0))
				return 1;
		}
		
		case CSW_M4A1:
		{
			if(silencemode & (1<<2))
				return 1;
		}
	}
	
	return 0;
}

stock fm_get_weapon_burst(weaponID)
{
	new weapontype, firemode;
	weapontype = get_pdata_int(weaponID, 43, 4);
	firemode = get_pdata_int(weaponID, 74, 4);
	
	switch(weapontype)
	{
		case CSW_GLOCK18: 
		{
			if(firemode == 2)
				return 1;
		}
		
		case CSW_FAMAS:
		{
			if(firemode == 16)
				return 1;
		}
	}
	return 0;
}
