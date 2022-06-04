#pragma tabsize 0

#include <cstrike>
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define BANTIME 1440

static char sPrefix[] = "VAC";

TopMenu g_hTopMenu = null;

enum struct player
{
	char ActionSelect[64];
	any ActionPlayer; // 
	bool BlockSpec;
	any StatusCheck;
	char Discord[64];
	
	char SteamID[64];
}

enum StatusCheckEnum
{
	STATUS_WAITDISCORD = 0,
	STATUS_WAITCALL = 1,
	STATUS_CHECKING = 2,
	STATUS_RESULT = 3,
}

// player g_ePlayer[MAXPLAYERS + 1];
// any player_info[MAXPLAYERS + 1][player];

player player_info[MAXPLAYERS];


int g_iTime[MAXPLAYERS+1],
	g_iMessenger[MAXPLAYERS+1],
	TimeToReady = 15;

bool g_bIsSended[MAXPLAYERS+1];

public void OnMapStart()
{
	char file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof file, "configs/overlay_downloads2.ini");
	File fileh = OpenFile(file, "r");
	if (fileh != null)
	{
		char sBuffer[256];
		char sBuffer_full[PLATFORM_MAX_PATH];

		while(ReadFileLine(fileh, sBuffer, sizeof sBuffer ))
		{
			TrimString(sBuffer);
			if ( sBuffer[0]  && sBuffer[0] != '/' && sBuffer[1] != '/' )
			{
				FormatEx(sBuffer_full, sizeof(sBuffer_full), "materials/%s", sBuffer);
				if (FileExists(sBuffer_full))
				{
					PrecacheDecal(sBuffer, true);
					AddFileToDownloadsTable(sBuffer_full);
				}
				else
				{
					PrintToServer("[OS] File does not exist, check your path to overlay! %s", sBuffer_full);
				}
			}
		}
		delete fileh;
	}
}

public void OnPluginStart()
{
	if (LibraryExists("adminmenu"))
    {
        TopMenu hTopMenu;
        if ((hTopMenu = GetAdminTopMenu()) != null)
        {
            OnAdminMenuReady(hTopMenu);
        }
    }
	
	RegAdminCmd("sm_cheatscheck", cmd_CheckCheats, ADMFLAG_BAN);
	
	CreateTimer(0.1, Timer_GiveOverlay, _, TIMER_REPEAT);
	
	AddCommandListener(Command_JoinTeam, "jointeam");
}

public Action Command_JoinTeam(client, const char[] command, args)
{
	//char strTeam[8];
	//GetCmdArg(1, strTeam, sizeof(strTeam));
	//int team = StringToInt(strTeam);
	if(player_info[client].BlockSpec) // player_info[client].BlockSpec
	{
		CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] {LIGHTRED}Вам запрещено покидать режим спектора!", sPrefix);
		return Plugin_Handled;
	}
	return Plugin_Continue;
} 

public Action Timer_GiveOverlay(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			int client;
			int clientChoose
			for(int x = 1; x <= MaxClients; x++)
			{
				if(IsClientInGame(x))
				{
					if(player_info[x].ActionPlayer == GetClientUserId(i) && StrEqual(player_info[x].ActionSelect, "CheckCheats"))
					{
						client = x;
						clientChoose = GetClientOfUserId(player_info[x].ActionPlayer);

						if (g_iTime[clientChoose] && GetTime() >= g_iTime[clientChoose])
						{
							BanPlayer(clientChoose);
						}
					}
				}
			}
			if(clientChoose)
			{
				GiveOverlay(clientChoose, "overlay_cheats/ban_cheats_v10");

				if (!g_bIsSended[clientChoose])
				{
					SendMenu(clientChoose);
					g_bIsSended[clientChoose] = true;
					CGOPrintToChat(clientChoose, "[{LIGHTGREEN}%s{DEFAULT}] Ваша задача выбрать мессенджер и указать ник.", sPrefix);
				}
			}
			if(client)
			{
				Menu_PanelCheck(client);
			}
		}
	}
}

void SendMenu(int iClient)
{
	Menu hMenu = new Menu(TopMenuMenuHandler);

	hMenu.SetTitle("Выберите мессенджер\n ");

	hMenu.AddItem(NULL_STRING, "Дискорд");
	hMenu.AddItem(NULL_STRING, "Скайп\n ");

	hMenu.AddItem(NULL_STRING, "Отказаться от проверки(Не, ну это бан)");

	hMenu.ExitButton = false;
	hMenu.Display(iClient, 0);
}

public int TopMenuMenuHandler(Menu hMenu, MenuAction action, int iClient, int iPick)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
	}
	else if (action == MenuAction_Select)
	{
		switch(iPick)
		{
			case 0:
			{
				g_iMessenger[iClient] = 1;
				CGOPrintToChat(iClient, "[{LIGHTGREEN}%s{DEFAULT}] Введите правильно: *Дискорд (не забудьте про #)*", sPrefix);
			}
			case 1:
			{
				g_iMessenger[iClient] = 2;
				CGOPrintToChat(iClient, "[{LIGHTGREEN}%s{DEFAULT}] Введите правильно: Скайп", sPrefix);
			}
			case 2:
			{
				BanPlayer(iClient);
			}
		} 
	}
}

void BanPlayer(int iClient)
{
	if(IsClientValid(iClient))
	{
		ServerCommand("sm_addban %d \"%s\" %s", BANTIME, player_info[iClient].SteamID, "ОТКАЗ ОТ ПРОВЕРКИ!");
	}
}

public void OnClientPostAdminCheck(int client)
{
    if(IsClientValid(client))
    {
			GetClientAuthId(client, AuthId_Steam2, player_info[client].SteamID, 63);
			//PrintToServer("**** OnClientPostAdminCheck => %N, clientID: %d [%s]", client, client, player_info[client].SteamID);
		}
}

public void OnClientConnected(int client)
{
	player_info[client].ActionSelect[0] = '\0';
	g_iTime[client] = 0;
	g_iMessenger[client] = 0;
	player_info[client].ActionPlayer = 0;
	player_info[client].BlockSpec = g_bIsSended[client] = false;
	player_info[client].StatusCheck = 0;
	player_info[client].Discord[0] = '\0';
}

public void OnClientDisconnect(int client)
{
	if(StrEqual(player_info[client].ActionSelect, "CheckCheats"))
	{
		int clientChoose = GetClientOfUserId(player_info[client].ActionPlayer)
		if(clientChoose)
		{
			CGOPrintToChat(clientChoose, "[{LIGHTGREEN}%s{DEFAULT}] Администратор покинул сервер. Проверка отменена", sPrefix);
			player_info[clientChoose].BlockSpec = false;
			player_info[clientChoose].Discord[0] = 0;
			g_iMessenger[clientChoose] = g_iTime[clientChoose] = 0;
			g_bIsSended[clientChoose] = false;
		}
		player_info[client].ActionPlayer = 0;
		player_info[client].ActionSelect[0] = '\0';
		player_info[client].BlockSpec = false;
		player_info[client].StatusCheck = 0;
	}
	
	if(HaveCheck(client))
	{
		int clientChoose;
		
		for(int x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x))
			{
				if(player_info[x].ActionPlayer == GetClientUserId(client) && StrEqual(player_info[x].ActionSelect, "CheckCheats"))
				{
					client = x;
					clientChoose = GetClientOfUserId(player_info[x].ActionPlayer);
				}
			}
		}
		
		CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] Игрок, которого вы проверяли, вышел с сервера", sPrefix);
		
		player_info[client].ActionPlayer = 0;
		player_info[client].ActionSelect[0] = '\0';
		
		GiveOverlay(clientChoose, "");
		BanPlayer(clientChoose);
		
		player_info[client].SteamID[0] = '\0';
	}
}

public Action cmd_CheckCheats(int client, any args)
{
	Menu_CheckCheats_PlayerChoose(client);
}

public Action OnClientSayCommand(int client, const char[] sCommand, const char[] NameDiscord)
{
	if(HaveCheck(client))
	{
		if (!g_iMessenger[client])
		{
			CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] Сначала выберите тип мессенджера.", sPrefix);
			return Plugin_Handled;
		}

		int clientChoose;
		for (int x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x))
			{
				if(player_info[x].ActionPlayer == GetClientUserId(client) && StrEqual(player_info[x].ActionSelect, "CheckCheats"))
				{
					client = x;
					clientChoose = GetClientOfUserId(player_info[x].ActionPlayer);
				}
			}
		}	

		if (player_info[client].StatusCheck == STATUS_WAITDISCORD)
		{
			if (g_iMessenger[clientChoose] == 1)
			{
				bool HaveSharp = false;
				for (int i = 0; i < strlen(NameDiscord); i++)
				{
					if(NameDiscord[i] == '#')
					{
						HaveSharp = true;
					}
				}

				strcopy(player_info[clientChoose].Discord, 100, NameDiscord);

				if (HaveSharp)
				{
					CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] Игрок {LIGHTGREEN}%N {DEFAULT} ввел свой discord: {LIGHTGREEN}%s", sPrefix, clientChoose, NameDiscord);
					CGOPrintToChat(clientChoose, "[{LIGHTGREEN}%s{DEFAULT}] Вы успешно ввели дискорд: %s", sPrefix, NameDiscord);
					player_info[client].StatusCheck++;
					return Plugin_Handled;
				}
				else
				{
					CGOPrintToChat(clientChoose, "[{LIGHTGREEN}%s{DEFAULT}] Введите правильно: *Дискорд (не забудьте про #)*", sPrefix);
					return Plugin_Handled;
				}
			}
			else if (g_iMessenger[clientChoose] == 2)
			{
				strcopy(player_info[clientChoose].Discord, 100, NameDiscord);
				player_info[client].StatusCheck++;

				CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] Игрок {LIGHTGREEN}%N {DEFAULT} ввел свой скайп: {LIGHTGREEN}%s", sPrefix, clientChoose, NameDiscord);
				CGOPrintToChat(clientChoose, "[{LIGHTGREEN}%s{DEFAULT}] Вы успешно ввели скайп: %s", sPrefix, NameDiscord);
			}
		}

		return Plugin_Continue;
	}

	return Plugin_Continue;
}

bool HaveCheck(int client)
{
	for(int x = 1; x <= MaxClients; x++)
	{
		if(IsClientInGame(x))
		{
			if(player_info[x].ActionPlayer == GetClientUserId(client) && StrEqual(player_info[x].ActionSelect, "CheckCheats"))
			{
				return true;
			}
		}
	}

	return false;
}

public void Menu_PanelCheck(int client)
{
	int clientChoose = GetClientOfUserId(player_info[client].ActionPlayer);
	
	char temp[1280];
	
	Menu hMenu = new Menu(MenuHandler_PanelCheck);
	Format(temp, sizeof(temp), "Панель проверки на читы\n \nПроверяется: %N\n \nСтатус проверки: %s", clientChoose, GetStatus(player_info[client].StatusCheck, g_iMessenger[clientChoose] == 1 ? false:true));
	
	hMenu.SetTitle(temp);
	
	if(player_info[client].StatusCheck == STATUS_WAITDISCORD)
	{
		Format(temp, sizeof(temp), "%s\n ", temp);
		hMenu.SetTitle(temp);
		hMenu.AddItem("Notif", "Напомнить о нике");
	}
	
	else if(player_info[client].StatusCheck == STATUS_WAITCALL)
	{
		Format(temp, sizeof(temp), "Звонок был принят\n \n%s игрока: %s\n ", g_iMessenger[clientChoose] == 1 ? "discord":"skype",player_info[clientChoose].Discord);
		hMenu.AddItem("Status", temp);
	}
	
	else if(player_info[client].StatusCheck == STATUS_CHECKING)
	{
		hMenu.AddItem("Status", "Проверка окончена");
	}
	
	else if(player_info[client].StatusCheck == STATUS_RESULT)
	{
		hMenu.AddItem("GoodResult", "Читы не обнаружены");
		hMenu.AddItem("BadResult", "Были найдены читы");
	}
	
	if(!player_info[clientChoose].BlockSpec)
	{
		if(GetClientTeam(clientChoose) != CS_TEAM_SPECTATOR)
		{
			hMenu.AddItem("ToSpec", "Переместить в наблюдатели");
		}
		
		else
		{
			hMenu.AddItem("BlockSpec", "Заблокировать переход");
		}
	}
	
	hMenu.AddItem("GoodResult", "Принудительно окончить проверку");
	
	hMenu.ExitButton = false;
	hMenu.Display(client, 0);
}

public int MenuHandler_PanelCheck(Menu hMenu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[128];
			hMenu.GetItem(item, info, sizeof(info));
			int clientChoose = GetClientOfUserId(player_info[client].ActionPlayer);
			
			if(clientChoose)
			{
				if(StrEqual(info, "ToSpec"))
				{
					ChangeClientTeam(clientChoose, CS_TEAM_SPECTATOR);
					CGOPrintToChat(clientChoose, "[{LIGHTGREEN}%s{DEFAULT}] Администратор переместил Вас в наблюдатели", sPrefix);
					CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] Вы успешно перенесли в наблюдатели игрока {LIGHTGREEN}%N", sPrefix, clientChoose);
				}
				else if(StrEqual(info, "Notif"))
				{
					CGOPrintToChat(clientChoose, "[{LIGHTGREEN}%s{DEFAULT}] Ваша задача выбрать мессенджер и указать ник.", sPrefix);
					CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] Вы успешно напомнили игроку о том что он должен ввести ник {LIGHTGREEN}%N", sPrefix, clientChoose);
					SendMenu(clientChoose);
					g_bIsSended[clientChoose] = true;
				}
				else if(StrEqual(info, "BlockSpec"))
				{
					CGOPrintToChat(clientChoose, "[{LIGHTGREEN}%s{DEFAULT}] Вам был заблокирован переход за другую команду", sPrefix);
					CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] Вы успешно заблокировали игроку {LIGHTGREEN}%N {DEFAULT}переход за другую команду", sPrefix, clientChoose);
					player_info[clientChoose].BlockSpec = true;
				}
				else if(StrEqual(info, "Status"))
				{
					player_info[client].StatusCheck++;
				}
				else if(StrEqual(info, "GoodResult"))
				{
					CGOPrintToChat(clientChoose, "[{LIGHTGREEN}%s{DEFAULT}] У Вас не обнаружено читов, проверка окончена!", sPrefix);
					CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] Вы успешно окончили проверку (читы не обнаружены)", sPrefix);
					player_info[client].ActionPlayer = 0;
					player_info[client].ActionSelect[0] = '\0';
					player_info[client].StatusCheck = 0;
					player_info[clientChoose].Discord[0] = 0;
					player_info[clientChoose].BlockSpec = g_bIsSended[clientChoose] = false;
					GiveOverlay(clientChoose, "");
					
				}
				else if(StrEqual(info, "BadResult"))
				{
					CGOPrintToChat(clientChoose, "[{LIGHTGREEN}%s{DEFAULT}] У Вас были найдены читы, проверка окончена!", sPrefix);
					CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] Вы успешно окончили проверку (читы обнаружены)", sPrefix);
					player_info[client].ActionPlayer = 0;
					player_info[client].ActionSelect[0] = '\0';
					player_info[client].StatusCheck = 0;
					player_info[clientChoose].Discord[0] = 0;
					GiveOverlay(clientChoose, "");
				}
			}
		}
	}
}

public void Menu_CheckCheats_PlayerChoose(int client)
{
	AdminId aid = GetUserAdmin(client);
	if(aid == INVALID_ADMIN_ID)
	{
		return;
	}
	
	if(StrEqual(player_info[client].ActionSelect, "CheckCheats") && HaveCheck(GetClientOfUserId(player_info[client].ActionPlayer)))
	{
		CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] Вы уже проверяете на читы игрока {LIGHTGREEN}%N", sPrefix, GetClientOfUserId(player_info[client].ActionPlayer));
	}
	else
	{
		char temp[128];
		char temp2[128];
		Menu hMenu = new Menu(MenuHandler_CheckCheats_PlayerChoose);
		hMenu.SetTitle("Выберите игрока,\nкоторого хотите проверить на читы:\n ");
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Format(temp, sizeof(temp), "%i", GetClientUserId(i));
				Format(temp2, sizeof(temp2), "%N", i);
				
				AdminId cId = GetUserAdmin(i);
				int iBannedAdminLevel = 0;
				
				if(cId != INVALID_ADMIN_ID)
				{
					iBannedAdminLevel = GetAdminImmunityLevel(cId);
				}
				
				hMenu.AddItem(temp, temp2, (HaveCheck(i) || (GetAdminImmunityLevel(aid) <= iBannedAdminLevel) ) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
		}
		hMenu.Display(client, 0);
	}
}

public int MenuHandler_CheckCheats_PlayerChoose(Menu hMenu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[128];
			hMenu.GetItem(item, info, sizeof(info));
			int clientChoose = GetClientOfUserId(StringToInt(info));
			if(clientChoose)
			{
				strcopy(player_info[client].ActionSelect, 63, info);
				MakeVerify(client, clientChoose);
			}
			else
			{
				CGOPrintToChat(client, "[{LIGHTGREEN}%s{DEFAULT}] Игрок вышел с сервера", sPrefix);
			}
		}
	}
}

public void MakeVerify(int client, int clientChoose)
{
	strcopy(player_info[client].ActionSelect, 100, "CheckCheats");
	player_info[client].ActionPlayer = GetClientUserId(clientChoose);
	CGOPrintToChatAll("[{LIGHTGREEN}%s{DEFAULT}] Администратор {LIGHTGREEN}%N {DEFAULT}вызвал на проверку на читы игрока {LIGHTGREEN}%N", sPrefix, client, clientChoose);
	CGOPrintToChat(clientChoose, "[{LIGHTGREEN}%s{DEFAULT}] {LIGHTRED}ВНИМАНИЕ! {DEFAULT}Администратор {LIGHTGREEN}%N {DEFAULT}вызвал Вас на проверку на читы!", sPrefix, client, TimeToReady);

	g_iTime[clientChoose] = GetTime()+600;
}

public void GiveOverlay(int client, char[] path)
{
	ClientCommand(client, "r_screenoverlay \"%s\"", path);
}

public void OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);

    if (hTopMenu == g_hTopMenu)
    {
        return;
    }

    g_hTopMenu = hTopMenu;
	
	TopMenuObject hMyCategory = g_hTopMenu.AddCategory("check_category", Handler_Admin_CheckCheats, "check_admin", ADMFLAG_BAN, "Проверить на читы");
	
	if (hMyCategory != INVALID_TOPMENUOBJECT)
    {
        g_hTopMenu.AddItem("check_cheats", Handler_Admin_CheckCheats2, hMyCategory, "check_cheats", ADMFLAG_BAN, "check_cheats");
	}
}

public void Handler_Admin_CheckCheats(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int client, char[] sBuffer, int maxlength)
{
    switch (action)
    {
		case TopMenuAction_DisplayOption:
		{
			FormatEx(sBuffer, maxlength, "Проверка на читы");
		}
		case TopMenuAction_DisplayTitle:
		{
			FormatEx(sBuffer, maxlength, "Выберите действие:\n ");
		}
    }
}

public void Handler_Admin_CheckCheats2(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int client, char[] sBuffer, int maxlength)
{
    switch (action)
    {
			case TopMenuAction_DisplayOption:
			{
					FormatEx(sBuffer, maxlength, "Проверить игрока на читы");
			}
			case TopMenuAction_SelectOption:
			{
					Menu_CheckCheats_PlayerChoose(client);
			}
    }
}

char[] GetStatus(int status, bool bType)
{
	char status2[100];
	switch(status)
	{
		case STATUS_WAITDISCORD:
		{
			strcopy(status2, sizeof(status2), !bType ? "Ожидание Дискорда" : "Ожидание Скайпа");
		}
		case STATUS_WAITCALL:
		{
			strcopy(status2, sizeof(status2), "Ожидание звонка");
		}
		case STATUS_CHECKING:
		{
			strcopy(status2, sizeof(status2), "Проверка на читы");
		}
		case STATUS_RESULT:
		{
			strcopy(status2, sizeof(status2), "Результат проверки");
		}
	}
	return status2;
}

public void OnLibraryRemoved(const char[] szName)
{
    if (StrEqual(szName, "adminmenu"))
    {
        g_hTopMenu = null;
    }
}

/**************************************************************************
 *                             CS:GO COLORS                               *
 *                     Автор: Феникс(komashchenko)                        *
 *                            Version: 1.6                                *
 *                  http://zizt.ru/  http://hlmod.ru/                     *
 * 03.07.2014 - V1.0: Релиз                                               *
 * 13.10.2014 - V1.1: Обнова                                              *
 * 24.10.2014 - V1.2: Обнова                                              *
 * 17.11.2014 - V1.3: Исправление ошибок                                  *
 * 23.12.2015 - V1.4: Исправление ошибок, Обнова                          *
 * 02.12.2018 - V1.5: Немного переработал, убрал лишнее                   *
 * 04.12.2018 - V1.6: Исправление ошибки с файлами перевода               *
 **************************************************************************/

#define ZCOLOR 14
static char g_sBuf[2048];

static const char color_t[ZCOLOR][] = {"{DEFAULT}", "{RED}", "{LIGHTPURPLE}", "{GREEN}", "{LIME}", "{LIGHTGREEN}", "{LIGHTRED}", "{GRAY}", "{LIGHTOLIVE}", "{OLIVE}", "{LIGHTBLUE}", "{BLUE}", "{PURPLE}", "{GRAYBLUE}"},
	color_c[ZCOLOR][] = {"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x10", "\x0B", "\x0C", "\x0E", "\x0A"};


public void CGOPrintToChat(int iClient, const char[] message, any ...)
{
	SetGlobalTransTarget(iClient);
	VFormat(g_sBuf, sizeof g_sBuf, message, 3);
	
	int iLastStart = 0, i = 0;
	for(; i < ZCOLOR; i++)
	{
		ReplaceString(g_sBuf, sizeof g_sBuf, color_t[i], color_c[i], false);
	}
	
	i = 0;
	
	while(g_sBuf[i])
	{
		if(g_sBuf[i] == '\n')
		{
			g_sBuf[i] = 0;
			PrintToChat(iClient, " %s", g_sBuf[iLastStart]);
			iLastStart = i+1;
		}
		
		i++;
	}
	
	PrintToChat(iClient, " %s", g_sBuf[iLastStart]);
}

public void CGOPrintToChatAll(const char[] message, any ...)
{
	int iLastStart = 0, i = 0;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) if(IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		SetGlobalTransTarget(iClient);
		VFormat(g_sBuf, sizeof g_sBuf, message, 2);
		
		for(i = 0; i < ZCOLOR; i++)
		{
			ReplaceString(g_sBuf, sizeof g_sBuf, color_t[i], color_c[i], false);
		}
		
		iLastStart = 0, i = 0;
		
		while(g_sBuf[i])
		{
			if(g_sBuf[i] == '\n')
			{
				g_sBuf[i] = 0;
				PrintToChat(iClient, " %s", g_sBuf[iLastStart]);
				iLastStart = i+1;
			}
			
			i++;
		}
		
		PrintToChat(iClient, " %s", g_sBuf[iLastStart]);
	}
}

stock bool IsClientValid(int client)
{
    return (0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client);
}