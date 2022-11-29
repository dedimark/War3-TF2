/**
* File: War3Source_Addon_Hud_Info.sp
* Description: Shows an RPG style HUD with a whole lot of useful information
* Author(s): Remy Lebeau (based on [RUS] SenatoR's concept)
* Current functions:     
*                   * Displays self or 1st person spec player
                    * Can be toggled on/off through either console sm_hud, or in chat "hud"
                    * Includes a native function to over-ride the HUD for custom game types
                            * INCLUDE DETAILS OF HOW TO USE IT HERE    
*/


#include <sourcemod>
#include <war3source>
#include <smlib>
#include <RemyFunctions>
#include <clientprefs>
#pragma semicolon 1
#pragma tabsize 0

public Plugin:myinfo = 
{
    name = "War3Source - Engine - HUD Info",
    author = "Remy Lebeau (based on [RUS] SenatoR's concept)",
    description = "Show player information in Hud",
    version = "5.3",
    url = "war3source.com"
};

new g_bShowHUD[MAXPLAYERS];
new MoneyOffsetCS;
new Handle:g_hMyCookie;
new Handle:ShowOtherPlayerItemsCvar;
new String:HUD_Text_Buffer[MAXPLAYERS][1024];
new String:MiniHUD_Text_Buffer[MAXPLAYERS][1024];
new String:HUD_Text_Add[MAXPLAYERS][1024];
new bool:g_bCustomHUD = false;
new Float:g_fHUDDisplayTime = 0.5;
new Handle:g_hPlayerHUDMenu = INVALID_HANDLE;
/*
public LoadCheck()
{
    if (GameTF())
    {
        return true;
    }
    if(GameCS())
    {
        return true;
    }
    PrintToServer("[HUD Info] ERROR ONLY TF2 & CSS ARE SUPPORTED.");
    return false;
}*/

public APLRes:AskPluginLoad2Custom(Handle:myself, bool:late, String:error[], err_max)
{
   CreateNative("HUD_Message", Native_HUD_Message);
   CreateNative("HUD_Override", Native_HUD_Override);
   CreateNative("HUD_Add", Native_HUD_Add);
   return APLRes_Success;
}


public Native_HUD_Message(Handle:plugin, numParams)
{
    new client = GetClientOfUserId(GetNativeCell(1));

    if(ValidPlayer(client))
    {
        GetNativeString(2, HUD_Text_Buffer[client], 1024);
        return 1;   
    }
    return 0;
}

public Native_HUD_Add(Handle:plugin, numParams)
{
    new client = GetClientOfUserId(GetNativeCell(1));

    if(ValidPlayer(client))
    {
        GetNativeString(2, HUD_Text_Add[client], 1024);
        return 1;   
    }
    return 0;
}

public Native_HUD_Override(Handle:plugin, numParams)
{
    g_bCustomHUD = GetNativeCell(1);
    return 0;   
}

public OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);    
	
    RegConsoleCmd("sm_hud", Command_ToggleHUD, "Toggles the HUD on/off");
    RegConsoleCmd("say hud", Command_ToggleHUD, "Toggles the HUD on/off");
    RegConsoleCmd("say_team hud", Command_ToggleHUD, "Toggles the HUD on/off");
   /* if(GameCS())
    {
        MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
    }*/
    g_hMyCookie = RegClientCookie("w3shud_toggle", "W3S HUD Visibility Toggle", CookieAccess_Protected);
}

public OnMapStart()
{
    ShowOtherPlayerItemsCvar = FindConVar("war3_show_playerinfo_other_player_items");
}

public OnClientPutInServer(client)
{
    g_bShowHUD[client] = 0;
}

public Action:Command_ToggleHUD(client, args)
{
    if(ValidPlayer(client))
    {
    
        if (g_hPlayerHUDMenu != INVALID_HANDLE)
        {
            CloseHandle(g_hPlayerHUDMenu);
            g_hPlayerHUDMenu = INVALID_HANDLE;
        }
        g_hPlayerHUDMenu = CreateMenu(Menu_HUD);
        
        SetMenuTitle(g_hPlayerHUDMenu, "HUD Settings (persistent)");

        AddMenuItem(g_hPlayerHUDMenu, "minimal", "Minimal HUD (currently bugged - flashing)"); //0 in prefs
        AddMenuItem(g_hPlayerHUDMenu, "off", "Disable HUD"); // 1 in prefs
        AddMenuItem(g_hPlayerHUDMenu, "left", "Larger HUD on LEFT (non flashing)"); // 2 in prefs
        AddMenuItem(g_hPlayerHUDMenu, "right", "Larger HUD on RIGHT (non flashing)"); // 3 in prefs
        DisplayMenu(g_hPlayerHUDMenu, client, 15);
    }
    return Plugin_Handled;
}


public Menu_HUD(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        new String:info[16];
        new client = param1;
 
        /* Get item info */
        new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
        
        if (found)
        {
            decl String:sCookieValue[11];
            if( StrEqual( info, "minimal" ) )
            {
                IntToString(0, sCookieValue, sizeof(sCookieValue));
                SetClientCookie(client, g_hMyCookie, sCookieValue);
                g_bShowHUD[client] = 0;
            }
            if( StrEqual( info, "off" ) )
            {
                IntToString(1, sCookieValue, sizeof(sCookieValue));
                SetClientCookie(client, g_hMyCookie, sCookieValue);
                g_bShowHUD[client] = 1;
            }
            if( StrEqual( info, "left" ) )
            {
                IntToString(2, sCookieValue, sizeof(sCookieValue));
                SetClientCookie(client, g_hMyCookie, sCookieValue);
                g_bShowHUD[client] = 2;
            }
        
            if( StrEqual( info, "right" ) )
            {
                IntToString(3, sCookieValue, sizeof(sCookieValue));
                SetClientCookie(client, g_hMyCookie, sCookieValue);
                g_bShowHUD[client] = 3;
            }
        }
    }

}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(0.4, HudInfo_Timer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    if (AreClientCookiesCached(client))
    {
        decl String:sCookieValue[11];
        GetClientCookie(client, g_hMyCookie, sCookieValue, sizeof(sCookieValue));
        new cookieValue = StringToInt(sCookieValue);
        g_bShowHUD[client] = cookieValue;
    }
}

public Action:StopHUD(Handle:timer, any:client)
{
    if(ValidPlayer(client))
    {
        g_bShowHUD[client] = 1;
    }
}

public Action:HudInfo_Timer(Handle:timer, any:client)
{
    if (ValidPlayer(client) && !IsFakeClient(client))
    {

        if(g_bShowHUD[client] != 1)
        {
            new display = client; 
            new observed = -1;
            if(!g_bCustomHUD)
            {
                if(!IsPlayerAlive(display))
                {
                    if(OBS_MODE_IN_EYE == Client_GetObserverMode(display))
                        observed = Client_GetObserverTarget(display); 
                    if(ValidPlayer(observed, true))
                        client = observed;
                }   
                new race=War3_GetRace(client);
                if (race > 0)
                {                    
                    new String:HUD_Text[1024];
					new String:MiniHUD_Text[1024];
                    new String:racename[64];
                    War3_GetRaceName(race,racename,sizeof(racename));
                    new level=War3_GetLevel(client, race);
   
                    Format(HUD_Text, sizeof(HUD_Text), "Type w3e for info.\nRace: %s\nLevel: %i/%i - XP: %i/%i\nGold: %i | Diamonds: %i | Platinum: %i", 
                        racename,
                        level,
                        W3GetRaceMaxLevel(race),
                        War3_GetXP(client, race),
                        W3GetReqXP(level+1),
                        War3_GetGold(client),
						War3_GetDiamonds(client),
						War3_GetPlatinum(client));

                    new Float:speedmulti=1.0;
                    if(!W3GetBuffHasTrue(client,bBuffDenyAll)){
                        speedmulti=W3GetBuffMaxFloat(client,fMaxSpeed)+W3GetBuffSumFloat(client,fMaxSpeed2);
                    }
                    if(W3GetBuffHasTrue(client,bStunned)||W3GetBuffHasTrue(client,bBashed)){
                        speedmulti=0.0;
                    }
                    if(!W3GetBuffHasTrue(client,bSlowImmunity)){
                        speedmulti = speedmulti * W3GetBuffStackedFloat(client,fSlow); 
                        speedmulti = speedmulti * W3GetBuffStackedFloat(client,fSlow2); 
                    }
                    
                    if(speedmulti != 1.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nSpeed: x%.2f",MiniHUD_Text, speedmulti);
                    }
                    
                    if(W3GetBuffMinFloat(client,fLowGravitySkill) != 1.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nGravity: x%.2f",MiniHUD_Text, W3GetBuffMinFloat(client,fLowGravitySkill));
                    }
                    
                    new Float:falpha=1.0;
                    if(!W3GetBuffHasTrue(client,bInvisibilityDenySkill))
                    {
                        falpha = falpha * W3GetBuffMinFloat(client,fInvisibilitySkill);
                        
                    }
                    new Float:itemalpha=W3GetBuffMinFloat(client,fInvisibilityItem);
                    if(falpha!=1.0){
                        //PrintToChatAll("has skill invis");
                        //has skill, reduce stack
                        itemalpha=Pow(itemalpha,0.75);
                    }
                    falpha = falpha * itemalpha;
                    
                    if(falpha != 1.0  )
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nInvis: x%.2f",MiniHUD_Text, falpha);
                    }
                    //PhysicalArmorMulti
                    if(W3GetBuffSumFloat(client, fDodgeChance) != 0.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nEvade: %.1f pct", MiniHUD_Text,W3GetBuffSumFloat(client, fDodgeChance) * 100.0);
                    }
                    if(W3GetBuffStackedFloat(client, fAttackSpeed) != 1.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nAttack Spd: x%.2f", MiniHUD_Text,W3GetBuffStackedFloat(client, fAttackSpeed));
                    }
                    if(W3GetBuffSumFloat(client, fDamageModifier) != 0.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nBonus Damage: x%.2f",MiniHUD_Text, W3GetBuffSumFloat(client, fDamageModifier)+1.0);
                    }
                    if(W3GetBuffSumInt(client, iAdditionalMaxHealth) != 0.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nAdditive Health: +%i hp",MiniHUD_Text, W3GetBuffSumInt(client, iAdditionalMaxHealth));
                    }
                    if(W3GetBuffSumFloat(client, fHPRegen) != 0.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nRegen: +%.2f hp/s",MiniHUD_Text, W3GetBuffSumFloat(client, fHPRegen));
                    }
                    if(W3GetBuffSumFloat(client, fHPDecay) != 0.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nHealth Decay: -%.2f hp/s",MiniHUD_Text, W3GetBuffSumFloat(client, fHPDecay));
                    }
                    if(W3GetBuffSumFloat(client, fVampirePercent) != 0.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nLifesteal: x%.2f",MiniHUD_Text, W3GetBuffSumFloat(client, fVampirePercent));
                    }
                    if(W3GetBuffSumFloat(client, fBashChance) != 0.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nBash Chance: %.0fpct",MiniHUD_Text, W3GetBuffSumFloat(client, fBashChance)*100.0);
                    }
                    if(W3GetBuffSumFloat(client, fBashDuration) != 0.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nBash Duration: %.1fs",MiniHUD_Text, W3GetBuffSumFloat(client, fBashDuration));
                    }
                    if(W3GetPhysicalArmorMulti(client) != 1.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nPhys Reduction: x%.2f",MiniHUD_Text, W3GetPhysicalArmorMulti(client));
                    }
                    if(W3GetMagicArmorMulti(client) != 1.0)
                    {
                        Format(MiniHUD_Text, sizeof(MiniHUD_Text), "%s\nMagic Reduction: x%.2f",MiniHUD_Text, W3GetMagicArmorMulti(client));
                    }
                    if(W3GetBuffHasTrue(client,bSlowImmunity) || W3GetBuffHasTrue(client,bImmunitySkills) || W3GetBuffHasTrue(client,bImmunityUltimates) || W3GetBuffHasTrue(client,bImmunityWards))
                    {
                        StrCat(MiniHUD_Text, sizeof(MiniHUD_Text), "\nImmune: ");
                        if(W3GetBuffHasTrue(client,bSlowImmunity))
                            StrCat(MiniHUD_Text, sizeof(MiniHUD_Text), "Sl|");
                        if(W3GetBuffHasTrue(client,bImmunitySkills))
                            StrCat(MiniHUD_Text, sizeof(MiniHUD_Text), "Sk|");
                        if(W3GetBuffHasTrue(client,bImmunityWards))
                            StrCat(MiniHUD_Text, sizeof(MiniHUD_Text), "Wa|");  
                        if(W3GetBuffHasTrue(client,bImmunityUltimates))
                            StrCat(MiniHUD_Text, sizeof(MiniHUD_Text), "Ult|");
    
                    }
                    
    
                    
                    if(GetConVarBool(ShowOtherPlayerItemsCvar)&&client!=display)
                    {
                        new bool:itemsonce = true;
                        new String:itemname[64];
                        new moleitemid=War3_GetItemIdByShortname("mole");
                        new ItemsLoaded = W3GetItemsLoaded();
                        for(new itemid=1;itemid<=ItemsLoaded;itemid++)
                        {
                            if(War3_GetOwnsItem(client,itemid)&&itemid!=moleitemid)
                            {
                                if(itemsonce)
                                {
                                    StrCat(MiniHUD_Text, sizeof(MiniHUD_Text), "\nItems: ");
                                    itemsonce = false;
                                }
                                W3GetItemShortname(itemid,itemname,sizeof(itemname));
                                Format(MiniHUD_Text,sizeof(MiniHUD_Text),"%s%s | ",MiniHUD_Text,itemname);
                            }
                        }
                    }
                    else if(client==display)
                    {
                        new bool:itemsonce = true;
                        
                        new String:itemname[64];
                        new ItemsLoaded = W3GetItemsLoaded();
                        for(new itemid=1;itemid<=ItemsLoaded;itemid++)
                        {
                            if(War3_GetOwnsItem(client,itemid))
                            {
                                if(itemsonce)
                                {
                                    StrCat(MiniHUD_Text, sizeof(MiniHUD_Text), "\nItems: ");
                                    itemsonce = false;
                                }
                                W3GetItemShortname(itemid,itemname,sizeof(itemname));
                                Format(MiniHUD_Text,sizeof(MiniHUD_Text),"%s%s | ",MiniHUD_Text,itemname);
                            }
                        }
                    }
					Format(HUD_Text,sizeof(HUD_Text),"%s\n--- Cooldowns ---",HUD_Text);
  					for(new i = 1;i <= War3_GetRaceSkillCount(race);i++)
					{
						new cooldown = War3_CooldownRemaining(client,race,i);
						if(cooldown > 0)
						{
							new String:skillname[64];
							W3GetRaceSkillName(race,i,skillname,sizeof(skillname));
							Format(HUD_Text,sizeof(HUD_Text), "%s\n%s: %is",HUD_Text,skillname,cooldown);
						}
					}
                    if(!IsPlayerAlive(display) && observed == -1)
                    {
                        
                    }
                    else
                    {
                        if(g_bShowHUD[display] != 1)
                        {
                            StrCat(HUD_Text, sizeof(HUD_Text), HUD_Text_Add[display]);
                            //Client_PrintKeyHintText(display, "%s",HUD_Text);

                            
                            decl String:sCookieValue[11];
                            GetClientCookie(display, g_hMyCookie, sCookieValue, sizeof(sCookieValue));
                            new cookieValue = StringToInt(sCookieValue);
                            switch(cookieValue)
                            {
                                case 0:
                                {
									Client_PrintKeyHintText(client, "%s",MiniHUD_Text);
									SetHudTextParams(0.01, 0.01, g_fHUDDisplayTime, 255, 255, 255, 255, 0);
									ShowHudText(client, 10, HUD_Text);
                                }
                                case 2:
                                {
                                    new Handle:gH_HUD = INVALID_HANDLE;

                                    gH_HUD = CreateHudSynchronizer();                       
                                    SetHudTextParams(0.01, 0.25, g_fHUDDisplayTime, 255, 255, 255, 255, 0);
                                    ShowSyncHudText(display, gH_HUD, HUD_Text);
                                    CloseHandle(gH_HUD);
                                }
                                case 3:
                                {
                                    new Handle:gH_HUD = INVALID_HANDLE;

                                    gH_HUD = CreateHudSynchronizer();                       
                                    SetHudTextParams(0.7, 0.2, g_fHUDDisplayTime, 255, 255, 255, 255, 0);
                                    ShowSyncHudText(display, gH_HUD, HUD_Text);
                                    CloseHandle(gH_HUD);
                                }
                            
                            }
                        }   
                    }
                }
            }
            else
            {
                decl String:sCookieValue[11];
                GetClientCookie(client, g_hMyCookie, sCookieValue, sizeof(sCookieValue));
                new cookieValue = StringToInt(sCookieValue);
                switch(cookieValue)
                {
                
                    case 1:
                    {
						Client_PrintKeyHintText(client, "%s",MiniHUD_Text_Buffer[client]);
						SetHudTextParams(0.01, 0.01, g_fHUDDisplayTime, 255, 255, 255, 255, 0);
						ShowHudText(client, 10, HUD_Text_Buffer[client]);
                    }
                    case 2:
                    {
                        new Handle:gH_HUD = INVALID_HANDLE;

                        gH_HUD = CreateHudSynchronizer();                       
                        SetHudTextParams(0.01, 0.25, g_fHUDDisplayTime, 255, 255, 255, 255, 0);
                        ShowSyncHudText(display, gH_HUD, HUD_Text_Buffer[client]);
                        CloseHandle(gH_HUD);
                    }
                    case 3:
                    {
                        new Handle:gH_HUD = INVALID_HANDLE;

                        gH_HUD = CreateHudSynchronizer();                       
                        SetHudTextParams(0.7, 0.2, g_fHUDDisplayTime, 255, 255, 255, 255, 0);
                        ShowSyncHudText(display, gH_HUD, HUD_Text_Buffer[client]);
                        CloseHandle(gH_HUD);
                    }
                
                }
            }
        }    
    }
    else
    {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}
stock GetMoney(player)
{
    return GetEntData(player,MoneyOffsetCS);
}



