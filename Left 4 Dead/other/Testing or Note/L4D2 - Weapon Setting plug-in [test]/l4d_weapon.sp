
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "[L4D/L4D2] Weapon Setting",
	author = "HsK",
	description = "Weapon setting",
	version = "1.0",
	url = "http://hsk-game.blogspot.hk/"  /* This is my blog */
};

#pragma semicolon 1

new loadWeapon = -1;
new String:g_weaponName[30][512], g_weaponSkill[30][5];

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName,"left4dead",false) && !StrEqual(ModName,"left4dead2",false))
		SetFailState("This plugin is for Left 4 Dead/Left 4 Dead 2 only.");

	HookEvent("weapon_reload", Event_WeaponReload);
}

public OnConfigsExecuted()
	loadWeaponSetting ();

public OnClientPutInServer(client)
	SDKHook(client, SDKHook_PostThink, SDK_PostThink);

public OnClientDisconnect(client)
	SDKUnhook(client, SDKHook_PostThink, SDK_PostThink);

public loadWeaponSetting ()
{
	new String:path[255];
	Format(path, sizeof(path), "cfg/l4d_weapon_setting.cfg");

	new Handle:file = OpenFile(path, "rt");
	if (file == INVALID_HANDLE) return;

	loadWeapon = 0;
	new String:linedata[512];
	new String:Setting_value[2][256];

	while (!IsEndOfFile(file) && ReadFileLine(file, linedata, sizeof(linedata)))
	{
		TrimString(linedata);

		if(!linedata[0] || linedata[0] == ';' || (linedata[0] == '/' && linedata[1] == '/')) continue;

		ExplodeString(linedata, "=", Setting_value, 2, 256);
		TrimString(Setting_value[0]);
		TrimString(Setting_value[1]);

		g_weaponName[loadWeapon] = Setting_value[0];

		new String:skill_class[5][10];
		ExplodeString(Setting_value[1], ",", skill_class, 5, 10);

		g_weaponSkill[loadWeapon][0] = StringToInt(skill_class[0]);
		g_weaponSkill[loadWeapon][1] = StringToInt(skill_class[1]);
		g_weaponSkill[loadWeapon][2] = StringToInt(skill_class[2]);
		g_weaponSkill[loadWeapon][3] = StringToInt(skill_class[3]);
		g_weaponSkill[loadWeapon][4] = StringToInt(skill_class[4]);

		PrintToServer ("LID: %d weapon Name: %s, skill: %d %d %d %d %d", 
		loadWeapon, g_weaponName[loadWeapon], g_weaponSkill[loadWeapon][0], g_weaponSkill[loadWeapon][1], g_weaponSkill[loadWeapon][2],
		g_weaponSkill[loadWeapon][3], g_weaponSkill[loadWeapon][4]);

		loadWeapon++;
	}

	CloseHandle(file);
}

public SDK_PostThink (client)
{
	if (!IsClientConnected (client) || !IsPlayerAlive (client)) // Is a Player?
		return;

	if (GetClientTeam (client) != 2) // Is not Zombie?
		return;

	for (new i = 0; i < loadWeapon; i++)
	{
		if ((GetPlayerWeaponID (client, g_weaponName[i])) != -1)
		{
			if (g_weaponSkill[i][0] != 0)
			{
				if (StrEqual(g_weaponName[i], "weapon_grenade_launcher"))
					SetEntData(client, (FindSendPropInfo("CTerrorPlayer", "m_iAmmo"))+(68), 1); 
				else
				{
					new cheatsoff = GetCommandFlags("give");
					SetCommandFlags("give", cheatsoff & ~FCVAR_CHEAT);
					FakeClientCommand(client, "give ammo");
					SetCommandFlags("give",cheatsoff|FCVAR_CHEAT);
				}
			}

			if (g_weaponSkill[i][1] != 0)
				SetEntProp(GetPlayerWeaponID (client, g_weaponName[i]), Prop_Data, "m_iClip1", 100);
		}
	}
}

public Action:Event_WeaponReload (Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Handled;
/*
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:Weapon_Name[32];
	GetClientWeapon(client, Weapon_Name, sizeof(Weapon_Name));

	for (new i = 0; i < loadWeapon; i++)
	{
		if (!(StrEqual(g_weaponName[i], Weapon_Name)))
			continue;

		if (g_weaponSkill[i][1] == 1)
			return Plugin_Stop;

		if (g_weaponSkill[i][3] != 0)
		{
			if ((GetEntProp (GetPlayerWeaponID (client, Weapon_Name), Prop_Data, "m_iClip1")) >= g_weaponSkill[i][3])
				return Plugin_Stop;
		}
	}

	return Plugin_Continue;
*/
}

// Get Player have not the weapon and get this id
stock GetPlayerWeaponID (client, String:ClassName[])
{
	new weapon = -1;
	new String:Weapon_Name[32];

	for (new i = 0; i <= 7; i++)
	{
		weapon = GetPlayerWeaponSlot (client, i);
		if (weapon == -1)
			continue;

		GetEdictClassname(weapon, Weapon_Name, sizeof(Weapon_Name));

		if (StrEqual(Weapon_Name, ClassName))
			break;

		weapon = -1;
	}

	return weapon;
}