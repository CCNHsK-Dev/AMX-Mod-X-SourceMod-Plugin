
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "[L4D2] Ammo Setting",
	author = "HsK",
	description = "Ammo setting",
	version = "1.0",
	url = "http://www.youtube.com/user/mikeg234bbq"  /* This is my youtube acc */
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName,"left4dead2",false))
		SetFailState("This plugin is for left4dead2 only.");
}

public OnClientPutInServer(client)
	SDKHook(client, SDKHook_PostThink, SDK_PostThink);

public OnClientDisconnect(client)
	SDKUnhook(client, SDKHook_PostThink, SDK_PostThink);

public SDK_PostThink (client)
{
	if (!IsClientConnected (client) || !IsPlayerAlive (client)) // Is a Player?
		return;

	if (GetClientTeam (client) != 2) // Is not Zombie?
		return;

	new weapon = -1;
	new String:Weapon_Name[32];

	for (new i = 0; i <= 7; i++)
	{
		weapon = GetPlayerWeaponSlot (client, i);
		if (weapon == -1)
			continue;

		GetEdictClassname(weapon, Weapon_Name, sizeof(Weapon_Name));

		if (StrEqual(Weapon_Name, "weapon_chainsaw"))
			SetEntProp(weapon, Prop_Send, "m_iClip1", 30);
		else if (StrEqual(Weapon_Name, "weapon_rifle_m60"))
		{
			SetEntProp(weapon, Prop_Data, "m_iClip1", 150);
			//SetEntData(client, (FindSendPropInfo("CTerrorPlayer", "m_iAmmo"))+(12), 160);
		}
		else if (StrEqual(Weapon_Name, "weapon_grenade_launcher"))
		{
			SetEntProp(weapon, Prop_Data, "m_iClip1", 2);
			//SetEntData(client, (FindSendPropInfo("CTerrorPlayer", "m_iAmmo"))+(68), 1);  // <- this is ok
		}
		else if (!(StrEqual(Weapon_Name, "weapon_melee")))
		{
			new cheatsoff = GetCommandFlags("give");
			SetCommandFlags("give", cheatsoff & ~FCVAR_CHEAT);
			FakeClientCommand(client, "give ammo");
			SetCommandFlags("give",cheatsoff|FCVAR_CHEAT);
		}
	}
}