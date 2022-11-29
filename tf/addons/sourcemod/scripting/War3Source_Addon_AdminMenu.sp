// War3Source_Addon_AdminMenu.sp

#include <war3source>

#assert GGAMEMODE == MODE_WAR3SOURCE

public Plugin:myinfo=
{
	name="War3Source war3admin",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

public OnPluginStart()
{
	LoadTranslations("w3s._common.phrases");

	RegConsoleCmd("war3admin",War3Source_Admin,"Brings up the War3Source:EVO admin panel.");

	RegConsoleCmd("say war3admin",War3Source_Admin,"Brings up the War3Source:EVO admin panel.");
	RegConsoleCmd("say_team war3admin",War3Source_Admin,"Brings up the War3Source:EVO admin panel.");
}


public Action:War3Source_Admin(client,args)
{
	if(HasSMAccess(client,ADMFLAG_ROOT))
	{
		Handle adminMenu=CreateMenu(War3Source_Admin_Selected);
		SetMenuExitButton(adminMenu,true);
		SetMenuTitle(adminMenu,"%T","[War3Source:EVO] Select a player to administrate",client);

		char playername[64];
		char war3playerbuf[4];

		for(new x=1;x<=MaxClients;x++)
		{
			if(ValidPlayer(x)){

				Format(war3playerbuf,sizeof(war3playerbuf),"%d",x);
				GetClientName(x,playername,sizeof(playername));
				AddMenuItem(adminMenu,war3playerbuf,playername);
			}
		}
		DisplayMenu(adminMenu,client,MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public War3Source_Admin_Selected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		char SelectionInfo[4];
		char SelectionDispText[256];
		int SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		int target=StringToInt(SelectionInfo);
		if(ValidPlayer(target))
			War3Source_Admin_Player(client,target);
		else
			War3_ChatMessage(client,"%T","The player you selected has left the server",client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public War3Source_Admin_Player(client,target)
{
	Handle adminMenu_Player=CreateMenu(War3Source_Admin_Player_Select);
	SetMenuExitButton(adminMenu_Player,true);
	char playername[64];
	GetClientName(target,playername,sizeof(playername));

	SetMenuTitle(adminMenu_Player,"%T","[War3Source:EVO] Administration options for {player}",client,playername);

	char buf[4];
	Format(buf,sizeof(buf),"%d",target);
	new race=War3_GetRace(target);

	char details[64];
	char shopitem[64];
	char setrace[64];
	char resetskills[64];
	char managxp[64];
	char managlevel[64];
	char managgold[64];
	char managlvlbank[64];
	char managdiamond[64];
	char managplat[64];

	Format(details,sizeof(details),"%T","View detailed information",client);
	Format(shopitem,sizeof(shopitem),"%T","Give shop item",client);
	Format(setrace,sizeof(setrace),"%T","Set race",client);
	Format(resetskills,sizeof(resetskills),"%T","Reset skills",client);
	Format(managxp,sizeof(managxp),"%T","Increase/Decrease XP",client);
	Format(managlevel,sizeof(managlevel),"%T","Increase/Decrease Level",client);
	Format(managlvlbank,sizeof(managlvlbank),"%T","Levelbank Managing",client);
	Format(managgold,sizeof(managgold),"%T","Increase/Decrease Gold",client);
	Format(managdiamond,sizeof(managdiamond),"Increase/Decrease Diamonds",client);
	Format(managplat,sizeof(managplat),"Increase/Decrease Platinum",client);

	AddMenuItem(adminMenu_Player,buf,details);
	AddMenuItem(adminMenu_Player,buf,shopitem);
	AddMenuItem(adminMenu_Player,buf,setrace);
	if(race>0)
	{
		AddMenuItem(adminMenu_Player,buf,resetskills);
		AddMenuItem(adminMenu_Player,buf,managxp);
		AddMenuItem(adminMenu_Player,buf,managlevel);
		AddMenuItem(adminMenu_Player,buf,managlvlbank);
		AddMenuItem(adminMenu_Player,buf,managgold);
		AddMenuItem(adminMenu_Player,buf,managdiamond);
		AddMenuItem(adminMenu_Player,buf,managplat);
	}
	DisplayMenu(adminMenu_Player,client,MENU_TIME_FOREVER);

}

public War3Source_Admin_Player_Select(Handle:menu,MenuAction:action,client,selection)
{
	// This is gonna be fun... NOT.
	if(action==MenuAction_Select)
	{
		char SelectionInfo[4];
		char SelectionDispText[256];
		int SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		int target=StringToInt(SelectionInfo);


		char adminname[64];
		GetClientName(client,adminname,sizeof(adminname));
		if(ValidPlayer(target))
		{
			char targetname[64];
			GetClientName(target,targetname,sizeof(targetname));
			// What do they want to do with the player?
			switch(selection)
			{
				case 0:
				{
					// Player info selected
					War3Source_Admin_PlayerInfo(client,target);
				}
				case 1:
				{
					// Give shop item
					War3Source_Admin_GiveShopItem(client,target);
				}
				case 2:
				{
					// Set race
					War3Source_Admin_SetRace(client,target);
				}
				case 3:
				{
					// Reset skills
					new race=War3_GetRace(target);
					W3ClearSkillLevels(target,race);
					W3DoLevelCheck(target);

					War3_ChatMessage(target,"%T","Admin {admin} reset your skills",target,adminname);
					War3_ChatMessage(client,"%T","You reset player {player} skills",client,targetname);
				}
				case 4:
				{
					// Increase/Decrease XP
					War3Source_Admin_XP(client,target);
				}
				case 5:
				{
					// Increase/Decrease Level
					War3Source_Admin_Level(client,target);
				}
				case 6:
				{
					// Increase/Decrease Levelbank
					War3Source_Admin_Lvlbank(client,target);
				}
				case 7:
				{
					// Increase/Decrease Gold
					War3Source_Admin_Gold(client,target);
				}
				case 8:
				{
					// Increase/Decrease Gold
					War3Source_Admin_Diamond(client,target);
				}
				case 9:
				{
					// Increase/Decrease Gold
					War3Source_Admin_Platinum(client,target);
				}
			}
			if(selection==3)
				War3Source_Admin_Player(client,target);
		}
		else
			War3_ChatMessage(client,"%T","The player you selected has left the server",client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}

}

public War3Source_Admin_PlayerInfo(client,target)
{

	if(ValidPlayer(target,false))
	{
		SetTrans(client);
		Handle playerInfo=CreateMenu(War3Source_Admin_PI_Select);
		SetMenuExitButton(playerInfo,true);

		char playername[64];
		GetClientName(target,playername,sizeof(playername));
		int race=War3_GetRace(target);

		char race_name[64];
		War3_GetRaceName(race,race_name,sizeof(race_name));
		int gold=War3_GetGold(target);
		int diamonds=War3_GetDiamonds(target);
		int platinum=War3_GetPlatinum(target);
		int xp=War3_GetXP(target,race);
		int level=War3_GetLevel(target,race);
		int lvlbank=W3GetLevelBank(target);
		SetMenuTitle(playerInfo,"[War3Source:EVO] Info for %s.\n Race: %s\n XP: %d\n Level: %d\n Levelbank: %d\n Gold: %d\n Diamonds: %d\n Platinum: %d",playername,race_name,xp,level,lvlbank,gold,diamonds,platinum);
		char buf[4];
		Format(buf,sizeof(buf),"%d",target);

		char backmenu[64];

		Format(backmenu,sizeof(backmenu),"%T","Back to options",client);

		AddMenuItem(playerInfo,buf,backmenu);
		DisplayMenu(playerInfo,client,MENU_TIME_FOREVER);
	}
	else
		War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}

public War3Source_Admin_PI_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		char SelectionInfo[4];
		char SelectionDispText[256];
		int SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		int target=StringToInt(SelectionInfo);
		if(ValidPlayer(target))
			War3Source_Admin_Player(client,target);
		else
			War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}

}

public War3Source_Admin_XP(client,target)
{
	if(ValidPlayer(target,false))
	{
		Handle menu=CreateMenu(War3Source_Admin_XP_Select);
		SetMenuExitButton(menu,true);

		char playername[64];
		GetClientName(target,playername,sizeof(playername));

		SetMenuTitle(menu,"%T","[War3Source:EVO] Select an option for {player}",client,playername);
		char buf[4];
		Format(buf,sizeof(buf),"%d",target);

		char give100xp[64];
		char give1000xp[64];
		char give10000xp[64];
		char remove100xp[64];
		char remove1000xp[64];
		char remove10000xp[64];

		Format(give100xp,sizeof(give100xp),"Give 1000 XP",client);
		Format(give1000xp,sizeof(give1000xp),"Give 10000 XP",client);
		Format(give10000xp,sizeof(give10000xp),"Give 100000 XP",client);
		Format(remove100xp,sizeof(remove100xp),"Remove 1000 XP",client);
		Format(remove1000xp,sizeof(remove1000xp),"Remove 10000 XP",client);
		Format(remove10000xp,sizeof(remove10000xp),"Remove 100000 XP",client);

		AddMenuItem(menu,buf,give100xp);
		AddMenuItem(menu,buf,give1000xp);
		AddMenuItem(menu,buf,give10000xp);
		AddMenuItem(menu,buf,remove100xp);
		AddMenuItem(menu,buf,remove1000xp);
		AddMenuItem(menu,buf,remove10000xp);
		DisplayMenu(menu,client,MENU_TIME_FOREVER);
	}
	else
		War3_ChatMessage(client,"The player has disconnected from the server");

}

public War3Source_Admin_XP_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		char SelectionInfo[4];
		char SelectionDispText[256];
		int SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		int target=StringToInt(SelectionInfo);

		if(ValidPlayer(target,false))
		{
			int race=War3_GetRace(target);
			char adminname[64];
			GetClientName(client,adminname,sizeof(adminname));
			char targetname[64];
			GetClientName(target,targetname,sizeof(targetname));
			if(selection<3) // Give XP
			{
				int xpadd;
				switch(selection)
				{
					case 0:
						xpadd=1000;
					case 1:
						xpadd=10000;
					case 2:
						xpadd=100000;
				}
				int newxp=War3_GetXP(target,race)+xpadd;
				War3_SetXP(target,race,newxp);
				War3_ChatMessage(client,"%T","You gave {player} {amount} XP",client,targetname,xpadd);
				War3_ChatMessage(target,"%T","You recieved {amount} XP from admin {player}",target,xpadd,adminname);
				W3DoLevelCheck(target);
				War3Source_Admin_XP(client,target);
			}
			else
			{
				int xprem;
				switch(selection)
				{
					case 3:
						xprem=1000;
					case 4:
						xprem=10000;
					case 5:
						xprem=100000;
				}
				int newxp=War3_GetXP(target,race)-xprem;
				if(newxp<0)
					newxp=0;
				War3_SetXP(target,race,newxp);
				War3_ChatMessage(client,"%T","You removed {amount} XP from player {player}",client,xprem,targetname);
				War3_ChatMessage(target,"%T","&Admin {player} removed {amount} XP from you",target,adminname,xprem);
				War3Source_Admin_XP(client,target);
			}
		}
		else
			War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}

}

public War3Source_Admin_GiveShopItem(client,target)
{
	if(ValidPlayer(target,false))
	{
		SetTrans(client);
		Handle menu=CreateMenu(War3Source_Admin_GSI_Select);
		SetMenuExitButton(menu,true);
		char playername[64];
		GetClientName(target,playername,sizeof(playername));
		SetMenuTitle(menu,"%T","[War3Source:EVO] Select an item to give to {player}",client,playername);
		char itemname[64];
		char buf[4];
		Format(buf,sizeof(buf),"%d",target);
		int ItemsLoaded = W3GetItemsLoaded();
		for(int x=1;x<=ItemsLoaded;x++)
		{
			W3GetItemName(x,itemname,sizeof(itemname));
			AddMenuItem(menu,buf,itemname);
		}
		DisplayMenu(menu,client,MENU_TIME_FOREVER);
	}
	else
		War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}

public War3Source_Admin_GSI_Select(Handle:menu,MenuAction:action,client,selection)
{

	if(action==MenuAction_Select)
	{
		char SelectionInfo[4];
		char SelectionDispText[256];
		int SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		int target=StringToInt(SelectionInfo);
		if(ValidPlayer(target))
		{
			int item=selection+1; //hax
			if(!War3_GetOwnsItem(target,item))
			{
				W3SetVar(TheItemBoughtOrLost,item);
				W3CreateEvent(DoForwardClientBoughtItem,target);

				char itemname[64];
				W3GetItemName(item,itemname,sizeof(itemname));

				char adminname[64];
				GetClientName(client,adminname,sizeof(adminname));

				char targetname[64];
				GetClientName(target,targetname,sizeof(targetname));

				War3_ChatMessage(client,"%T","You gave {player} a {itemname}",client,targetname,itemname);
				War3_ChatMessage(target,"%T","You recieved a {itemname} from admin {player}",target,itemname,adminname);
			}
			else
			{
				War3_ChatMessage(client,"%T","The player already owns this item",client);
			}
			DisplayMenuAtItem(menu, client, GetMenuSelectionPosition(), 0);
		}
		else
		{
			War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
		}
	}
	else if(action == MenuAction_Cancel && selection == MenuCancel_ExitBack)
	{
		CloseHandle(menu);
	}
}

public War3Source_Admin_SetRace(client,target)
{
	if(ValidPlayer(target,false))
	{
		SetTrans(client);
		Handle menu=CreateMenu(War3Source_Admin_SetRace_Select);
		SetMenuExitButton(menu,true);
		char playername[64];

		GetClientName(target,playername,sizeof(playername));
		SetMenuTitle(menu,"%T","[War3Source:EVO] Select a race for {player}",client,playername);

		char racename[64];
		char buf[4];
		Format(buf,sizeof(buf),"%d",target);
		int RacesLoaded = War3_GetRacesLoaded();
		for(int x=1;x<=RacesLoaded;x++)
		{
			War3_GetRaceName(x,racename,sizeof(racename));
			AddMenuItem(menu,buf,racename);
		}
		DisplayMenu(menu,client,MENU_TIME_FOREVER);
	}
	else
		War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}

public War3Source_Admin_SetRace_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		char SelectionInfo[4];
		char SelectionDispText[256];
		new SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		new target=StringToInt(SelectionInfo);

		//selection++; // hacky, should work tho?
		new race=selection+1;
		if(target>-1)
		{

			W3SetPlayerProp(target,RaceChosenTime,GetGameTime());
			W3SetPlayerProp(target,RaceSetByAdmin,true);

			War3_SetRace(target,race);

			char racename[64];
			War3_GetRaceName(race,racename,sizeof(racename));
			char adminname[64];
			GetClientName(client,adminname,sizeof(adminname));
			char targetname[64];
			GetClientName(target,targetname,sizeof(targetname));
			War3_ChatMessage(client,"%T","You set player {player} to race {racename}",client,targetname,racename);
			War3_ChatMessage(target,"%T","Admin {player} set you to race {racename}",target,adminname,racename);
		}
		else
			War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}

}

public War3Source_Admin_Level(client,target)
{
	if(ValidPlayer(target))
	{
		Handle menu=CreateMenu(War3Source_Admin_Level_Select);
		SetMenuExitButton(menu,true);
		char playername[64];
		GetClientName(target,playername,sizeof(playername));
		SetMenuTitle(menu,"%T","&[War3Source:EVO] Select an option for {player}",client,playername);
		char buf[4];
		Format(buf,sizeof(buf),"%d",target);

		char givelevel[64];
		char removelevel[64];

		Format(givelevel,sizeof(givelevel),"%T","Give a level",client);
		Format(removelevel,sizeof(removelevel),"%T","Remove a level",client);

		AddMenuItem(menu,buf,givelevel);
		AddMenuItem(menu,buf,removelevel);
		DisplayMenu(menu,client,MENU_TIME_FOREVER);
	}
	else
		War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}

public War3Source_Admin_Level_Select(Handle:menu,MenuAction:action,client,selection)
{

	if(action==MenuAction_Select)
	{
		char SelectionInfo[4];
		char SelectionDispText[256];
		int SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		int target=StringToInt(SelectionInfo);
		if(ValidPlayer(target,false))
		{
			char adminname[64];
			GetClientName(client,adminname,sizeof(adminname));
			char targetname[64];
			GetClientName(target,targetname,sizeof(targetname));
			new race=War3_GetRace(target);
			if(selection==0)
			{
				// Give a level
				int newlevel=War3_GetLevel(target,race)+1;
				if(newlevel>W3GetRaceMaxLevel(race))
					War3_ChatMessage(client,"%T","Player {player} is already at the max level",client,targetname);
				else
				{
					War3_SetLevel(target,race,newlevel);
					W3DoLevelCheck(client);
					War3_ChatMessage(client,"%T","You gave player {player} a level",client,targetname);
					War3_ChatMessage(target,"%T","&Admin {player} gave you a level",target,adminname);
				}
			}
			else
			{
				// Remove a level
				int newlevel=War3_GetLevel(target,race)-1;
				if(newlevel<0)
					War3_ChatMessage(client,"%T","Player {player} is already level 0",client,targetname);
				else
				{
					War3_SetLevel(target,race,newlevel);
					W3ClearSkillLevels(target,race);

					War3_ChatMessage(client,"%T","You removed a level from player {player}",client,targetname);
					War3_ChatMessage(target,"%T","&Admin {player} removed a level from you, re-pick your skills",target,adminname);

					W3DoLevelCheck(target);
				}
			}
			War3Source_Admin_Level(client,target);
		}
		else
			War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}

}

public War3Source_Admin_Gold(client,target)
{

	if(ValidPlayer(target,false))
	{
		Handle menu=CreateMenu(War3Source_Admin_Gold_Select);
		SetMenuExitButton(menu,true);
		char playername[64];
		GetClientName(target,playername,sizeof(playername));
		SetMenuTitle(menu,"%T","&&[War3Source:EVO] Select an option for {player}",client,playername);
		char buf[4];
		Format(buf,sizeof(buf),"%d",target);

		char give1gold[64];
		char give5gold[64];
		char give10gold[64];
		char give100gold[64];
		char remove1gold[64];
		char remove5gold[64];
		char remove10gold[64];
		char remove100gold[64];

		Format(give1gold,sizeof(give1gold),"%T","Give 1 gold",client);
		Format(give5gold,sizeof(give5gold),"%T","Give 5 gold",client);
		Format(give10gold,sizeof(give10gold),"%T","Give 10 gold",client);
		Format(give100gold,sizeof(give100gold),"Give 100 gold",client);
		Format(remove1gold,sizeof(remove1gold),"%T","Remove 1 gold",client);
		Format(remove5gold,sizeof(remove5gold),"%T","Remove 5 gold",client);
		Format(remove10gold,sizeof(remove10gold),"%T","Remove 10 gold",client);
		Format(remove100gold,sizeof(remove100gold),"Remove 100 gold",client);

		AddMenuItem(menu,buf,give1gold);
		AddMenuItem(menu,buf,give5gold);
		AddMenuItem(menu,buf,give10gold);
		AddMenuItem(menu,buf,give100gold);
		AddMenuItem(menu,buf,remove1gold);
		AddMenuItem(menu,buf,remove5gold);
		AddMenuItem(menu,buf,remove10gold);
		AddMenuItem(menu,buf,remove100gold);
		DisplayMenu(menu,client,MENU_TIME_FOREVER);
	}
	else
		War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}

public War3Source_Admin_Gold_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		char SelectionInfo[4];
		char SelectionDispText[256];
		int SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		int target=StringToInt(SelectionInfo);
		if(ValidPlayer(target,false))
		{
			char adminname[64];
			GetClientName(client,adminname,sizeof(adminname));
			char targetname[64];
			GetClientName(target,targetname,sizeof(targetname));
			if(selection<4) // Give gold
			{
				int credadd;
				switch(selection)
				{
					case 0:
						credadd=1;
					case 1:
						credadd=5;
					case 2:
						credadd=10;
					case 3:
						credadd=100;
				}
				int newcred=War3_GetGold(target)+credadd;
				int maxgold=W3GetMaxGold(target);
				if(newcred>maxgold)
				{
					War3_ChatMessage(client,"Player has max gold!");
				}
				else
				{
					War3_SetGold(target,newcred);
					War3_ChatMessage(client,"%T","You gave {player} {amount} gold(s)",client,targetname,credadd);
					War3_ChatMessage(target,"%T","You recieved {amount} gold(s) from admin {player}",target,credadd,adminname);
					War3Source_Admin_Gold(client,target);
				}
			}
			else
			{
				int credrem;
				switch(selection)
				{
					case 4:
						credrem=1;
					case 5:
						credrem=5;
					case 6:
						credrem=10;
					case 7:
						credrem=100;
				}
				int newcred=War3_GetGold(target)-credrem;
				if(newcred<0)
					newcred=0;
				War3_SetGold(target,newcred);
				War3_ChatMessage(client,"%T","You removed {amount} gold(s) from player {player}",client,credrem,targetname);
				War3_ChatMessage(target,"%T","Admin {player} removed {amount} gold(s) from you",target,adminname,credrem);
				War3Source_Admin_Gold(client,target);
			}
		}
		else
			War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public War3Source_Admin_Diamond(client,target)
{

	if(ValidPlayer(target,false))
	{
		Handle menu=CreateMenu(War3Source_Admin_Diamond_Select);
		SetMenuExitButton(menu,true);
		char playername[64];
		GetClientName(target,playername,sizeof(playername));
		SetMenuTitle(menu,"%T","&&[War3Source:EVO] Select an option for {player}",client,playername);
		char buf[4];
		Format(buf,sizeof(buf),"%d",target);

		char give1diamond[64];
		char give5diamond[64];
		char give10diamond[64];
		char give100diamond[64];
		char remove1diamond[64];
		char remove5diamond[64];
		char remove10diamond[64];
		char remove100diamond[64];

		Format(give1diamond,sizeof(give1diamond),"Give 1 diamond",client);
		Format(give5diamond,sizeof(give5diamond),"Give 5 diamond",client);
		Format(give10diamond,sizeof(give10diamond),"Give 10 diamond",client);
		Format(give100diamond,sizeof(give100diamond),"Give 100 diamond",client);
		Format(remove1diamond,sizeof(remove1diamond),"Remove 1 diamond",client);
		Format(remove5diamond,sizeof(remove5diamond),"Remove 5 diamond",client);
		Format(remove10diamond,sizeof(remove10diamond),"Remove 10 diamond",client);
		Format(remove100diamond,sizeof(remove100diamond),"Remove 100 diamond",client);

		AddMenuItem(menu,buf,give1diamond);
		AddMenuItem(menu,buf,give5diamond);
		AddMenuItem(menu,buf,give10diamond);
		AddMenuItem(menu,buf,give100diamond);
		AddMenuItem(menu,buf,remove1diamond);
		AddMenuItem(menu,buf,remove5diamond);
		AddMenuItem(menu,buf,remove10diamond);
		AddMenuItem(menu,buf,remove100diamond);
		DisplayMenu(menu,client,MENU_TIME_FOREVER);
	}
	else
		War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}
public War3Source_Admin_Diamond_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		char SelectionInfo[4];
		char SelectionDispText[256];
		int SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		int target=StringToInt(SelectionInfo);
		if(ValidPlayer(target,false))
		{
			char adminname[64];
			GetClientName(client,adminname,sizeof(adminname));
			char targetname[64];
			GetClientName(target,targetname,sizeof(targetname));
			if(selection<4) // Give gold
			{
				int credadd;
				switch(selection)
				{
					case 0:
						credadd=1;
					case 1:
						credadd=5;
					case 2:
						credadd=10;
					case 3:
						credadd=100;
				}
				int newcred=War3_GetDiamonds(target)+credadd;
				War3_SetDiamonds(target,newcred);
				War3_ChatMessage(client,"You gave %s %i diamond(s)",targetname,credadd);
				War3_ChatMessage(target,"You recieved %i diamond(s) from admin %s",credadd,adminname);
				War3Source_Admin_Diamond(client,target);
			}
			else
			{
				int credrem;
				switch(selection)
				{
					case 4:
						credrem=1;
					case 5:
						credrem=5;
					case 6:
						credrem=10;
					case 7:
						credrem=100;
				}
				int newcred=War3_GetDiamonds(target)-credrem;
				if(newcred<0)
					newcred=0;
				War3_SetDiamonds(target,newcred);
				War3_ChatMessage(client,"You removed %i diamond(s) from player %s",credrem,targetname);
				War3_ChatMessage(target,"Admin %s removed %i diamond(s) from you",adminname,credrem);
				War3Source_Admin_Diamond(client,target);
			}
		}
		else
			War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public War3Source_Admin_Platinum(client,target)
{

	if(ValidPlayer(target,false))
	{
		Handle menu=CreateMenu(War3Source_Admin_Platinum_Select);
		SetMenuExitButton(menu,true);
		char playername[64];
		GetClientName(target,playername,sizeof(playername));
		SetMenuTitle(menu,"%T","&&[War3Source:EVO] Select an option for {player}",client,playername);
		char buf[4];
		Format(buf,sizeof(buf),"%d",target);

		char give1platinum[64];
		char give5platinum[64];
		char give10platinum[64];
		char give100platinum[64];
		char remove1platinum[64];
		char remove5platinum[64];
		char remove10platinum[64];
		char remove100platinum[64];

		Format(give1platinum,sizeof(give1platinum),"Give 1 platinum",client);
		Format(give5platinum,sizeof(give5platinum),"Give 5 platinum",client);
		Format(give10platinum,sizeof(give10platinum),"Give 10 platinum",client);
		Format(give100platinum,sizeof(give100platinum),"Give 100 platinum",client);
		Format(remove1platinum,sizeof(remove1platinum),"Remove 1 platinum",client);
		Format(remove5platinum,sizeof(remove5platinum),"Remove 5 platinum",client);
		Format(remove10platinum,sizeof(remove10platinum),"Remove 10 platinum",client);
		Format(remove100platinum,sizeof(remove100platinum),"Remove 100 platinum",client);

		AddMenuItem(menu,buf,give1platinum);
		AddMenuItem(menu,buf,give5platinum);
		AddMenuItem(menu,buf,give10platinum);
		AddMenuItem(menu,buf,give100platinum);
		AddMenuItem(menu,buf,remove1platinum);
		AddMenuItem(menu,buf,remove5platinum);
		AddMenuItem(menu,buf,remove10platinum);
		AddMenuItem(menu,buf,remove100platinum);
		DisplayMenu(menu,client,MENU_TIME_FOREVER);
	}
	else
		War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}
public War3Source_Admin_Platinum_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		char SelectionInfo[4];
		char SelectionDispText[256];
		int SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		int target=StringToInt(SelectionInfo);
		if(ValidPlayer(target,false))
		{
			char adminname[64];
			GetClientName(client,adminname,sizeof(adminname));
			char targetname[64];
			GetClientName(target,targetname,sizeof(targetname));
			if(selection<4) // Give gold
			{
				int credadd;
				switch(selection)
				{
					case 0:
						credadd=1;
					case 1:
						credadd=5;
					case 2:
						credadd=10;
					case 3:
						credadd=100;
				}
				int newcred=War3_GetPlatinum(target)+credadd;
				War3_SetPlatinum(target,newcred);
				War3_ChatMessage(client,"You gave %s %i platinum",targetname,credadd);
				War3_ChatMessage(target,"You recieved %i platinum from admin %s",credadd,adminname);
				War3Source_Admin_Platinum(client,target);
			}
			else
			{
				int credrem;
				switch(selection)
				{
					case 4:
						credrem=1;
					case 5:
						credrem=5;
					case 6:
						credrem=10;
					case 7:
						credrem=100;
				}
				int newcred=War3_GetPlatinum(target)-credrem;
				if(newcred<0)
					newcred=0;
				War3_SetPlatinum(target,newcred);
				War3_ChatMessage(client,"You removed %i platinum from player %s",credrem,targetname);
				War3_ChatMessage(target,"Admin %s removed %i platinum from you",adminname,credrem);
				War3Source_Admin_Platinum(client,target);
			}
		}
		else
			War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public War3Source_Admin_Lvlbank(client,target)
{

	if(ValidPlayer(target,false))
	{
		Handle menu=CreateMenu(War3Source_Admin_Lvlbank_Select);
		SetMenuExitButton(menu,true);
		char playername[64];
		GetClientName(target,playername,sizeof(playername));
		SetMenuTitle(menu,"%T","&&&[War3Source:EVO] Select an option for {player}",client,playername);
		char buf[4];
		Format(buf,sizeof(buf),"%d",target);

		char give1lvlb[64];
		char give5lvlb[64];
		char give10lvlb[64];
		char remove1lvlb[64];
		char remove5lvlb[64];
		char remove10lvlb[64];

		Format(give1lvlb,sizeof(give1lvlb),"%T","Give 1 level in levelbank",client);
		Format(give5lvlb,sizeof(give5lvlb),"%T","Give 5 levels in levelbank",client);
		Format(give10lvlb,sizeof(give10lvlb),"%T","Give 10 levels in levelbank",client);
		Format(remove1lvlb,sizeof(remove1lvlb),"%T","Remove 1 level from levelbank",client);
		Format(remove5lvlb,sizeof(remove5lvlb),"%T","Remove 5 levels from levelbank",client);
		Format(remove10lvlb,sizeof(remove10lvlb),"%T","Remove 10 levels from levelbank",client);

		AddMenuItem(menu,buf,give1lvlb);
		AddMenuItem(menu,buf,give5lvlb);
		AddMenuItem(menu,buf,give10lvlb);
		AddMenuItem(menu,buf,remove1lvlb);
		AddMenuItem(menu,buf,remove5lvlb);
		AddMenuItem(menu,buf,remove10lvlb);
		DisplayMenu(menu,client,MENU_TIME_FOREVER);
	}
	else
		War3_ChatMessage(client,"%T","The player has disconnected from the server",client);

}

public War3Source_Admin_Lvlbank_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		char SelectionInfo[4];
		char SelectionDispText[256];
		new SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		new target=StringToInt(SelectionInfo);
		if(ValidPlayer(target,false))
		{
			char adminname[64];
			GetClientName(client,adminname,sizeof(adminname));
			char targetname[64];
			GetClientName(target,targetname,sizeof(targetname));
			if(selection<3)
			{
				int lvlbadd;
				switch(selection)
				{
					case 0:
						lvlbadd=1;
					case 1:
						lvlbadd=5;
					case 2:
						lvlbadd=10;
				}
				int newlvlb=W3GetLevelBank(target)+lvlbadd;
				W3SetLevelBank(target,newlvlb);
				War3_ChatMessage(client,"%T","You gave {player} {amount} level(s) in levelbank",client,targetname,lvlbadd);
				War3_ChatMessage(target,"%T","You recieved {amount} level(s) in levelbank from admin {player}",target,lvlbadd,adminname);
				War3Source_Admin_Lvlbank(client,target);
			}
			else
			{
				int lvlbrem;
				switch(selection)
				{
					case 3:
						lvlbrem=1;
					case 4:
						lvlbrem=5;
					case 5:
						lvlbrem=10;
				}
				int newlvlb=W3GetLevelBank(target)-lvlbrem;
				if(newlvlb<0)
					newlvlb=0;
				W3SetLevelBank(target,newlvlb);
				War3_ChatMessage(client,"%T","You removed {amount} level(s) from levelbank of {player}",client,lvlbrem,targetname);
				War3_ChatMessage(target,"%T","Admin {player} removed {amount} level(s) from your levelbank",target,adminname,lvlbrem);
				War3Source_Admin_Lvlbank(client,target);
			}
		}
		else
			War3_ChatMessage(client,"%T","The player has disconnected from the server",client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}
