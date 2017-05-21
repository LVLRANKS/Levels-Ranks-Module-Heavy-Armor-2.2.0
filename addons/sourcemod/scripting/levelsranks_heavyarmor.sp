#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo & R1KO"

int		g_iHeavyArmorLevel,
		g_iHeavyArmorActivator[MAXPLAYERS+1];
Handle	g_hHeavyArmor = null;

public Plugin myinfo = {name = "[LR] Module - Heavy Armor", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("[%s Heavy Armor] Плагин работает только на CS:GO", PLUGIN_NAME);
	}
}

public void OnPluginStart()
{
	LR_ModuleCount();
	HookEvent("player_spawn", PlayerSpawn);
	g_hHeavyArmor = RegClientCookie("LR_HeavyArmor", "LR_HeavyArmor", CookieAccess_Private);
	LoadTranslations("levels_ranks_heavyarmor.phrases");
	
	for(int iClient = 1; iClient <= MaxClients; iClient++)
    {
		if(IsClientInGame(iClient))
		{
			if(AreClientCookiesCached(iClient))
			{
				OnClientCookiesCached(iClient);
			}
		}
	}
}

public void OnMapStart() 
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/heavyarmor.ini");
	KeyValues hLR_HA = new KeyValues("LR_HeavyArmor");

	if(!hLR_HA.ImportFromFile(sPath) || !hLR_HA.GotoFirstSubKey())
	{
		SetFailState("[%s Heavy Armor] : фатальная ошибка - файл не найден (%s)", PLUGIN_NAME, sPath);
	}

	hLR_HA.Rewind();

	if(hLR_HA.JumpToKey("Settings"))
	{
		g_iHeavyArmorLevel = hLR_HA.GetNum("rank", 0);
	}
	else SetFailState("[%s Heavy Armor] : фатальная ошибка - секция Settings не найдена", PLUGIN_NAME);
	delete hLR_HA;
}

public void PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{	
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(iClient) && !g_iHeavyArmorActivator[iClient] && LR_GetClientRank(iClient) >= g_iHeavyArmorLevel)
	{
		GivePlayerItem(iClient, "item_heavyassaultsuit");
	}
}

public void LR_OnMenuCreated(int iClient, int iRank, Menu& hMenu)
{
	if(iRank == g_iHeavyArmorLevel)
	{
		char sText[64];
		SetGlobalTransTarget(iClient);

		if(LR_GetClientRank(iClient) >= g_iHeavyArmorLevel)
		{
			switch(g_iHeavyArmorActivator[iClient])
			{
				case 0: FormatEx(sText, sizeof(sText), "%t", "HA_On");
				case 1: FormatEx(sText, sizeof(sText), "%t", "HA_Off");
			}

			hMenu.AddItem("ArmorGiver", sText);
		}
		else
		{
			FormatEx(sText, sizeof(sText), "%t", "HA_RankClosed", g_iHeavyArmorLevel);
			hMenu.AddItem("ArmorGiver", sText, ITEMDRAW_DISABLED);
		}
	}
}

public void LR_OnMenuItemSelected(int iClient, int iRank, const char[] sInfo)
{
	if(iRank == g_iHeavyArmorLevel)
	{
		if(strcmp(sInfo, "ArmorGiver") == 0)
		{
			switch(g_iHeavyArmorActivator[iClient])
			{
				case 0: g_iHeavyArmorActivator[iClient] = 1;
				case 1: g_iHeavyArmorActivator[iClient] = 0;
			}
			
			LR_MenuInventory(iClient);
		}
	}
}

public void OnClientCookiesCached(int iClient)
{
	char sCookie[8];
	GetClientCookie(iClient, g_hHeavyArmor, sCookie, sizeof(sCookie));
	g_iHeavyArmorActivator[iClient] = StringToInt(sCookie);
} 

public void OnClientDisconnect(int iClient)
{
	if(AreClientCookiesCached(iClient))
	{
		char sBuffer[8];
		
		FormatEx(sBuffer, sizeof(sBuffer), "%i", g_iHeavyArmorActivator[iClient]);
		SetClientCookie(iClient, g_hHeavyArmor, sBuffer);		
	}
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);
		}
	}
}