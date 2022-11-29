#include <war3source>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 6

//#pragma semicolon 1	///WE RECOMMEND THE SEMICOLON

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
	name = "Race - Blademaster",
	author = "Cake & Razor",
	description = "Blademaster (Grunt) race for War3Source.",
	version = "1.0",
};
public W3ONLY(){} //unload this?
/* Changelog
 * 1.2 - Fixed speed buff not being removed on race switch
 */
stock TF2_RemoveAllWearables(client)
{
    new i = -1;
    while ((i = FindEntityByClassname(i, "tf_wearable*")) != -1)
    {
        if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue;
        AcceptEntityInput(i, "Kill");
    }
} 
new thisRaceID;

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
}
bool RaceDisabled=true;
public OnWar3RaceEnabled(newrace)
{
	if(newrace==thisRaceID)
	{
		Load_Hooks();

		RaceDisabled=false;
	}
}
public OnWar3RaceDisabled(oldrace)
{
	if(oldrace==thisRaceID)
	{
		RaceDisabled=true;

		UnLoad_Hooks();
	}
}
new SKILL_CRITS, SKILL_BERSERK, SKILL_SALVE, ULT_WARCRY;

// Critical Strike
new Float:CritChance[] = {0.0,0.09,0.18,0.27,0.36,0.395,0.43,0.465,0.5};
new Float:CritMultiplier = 2.0;

// Berserker
new BerserkHP[] = {0,15,30,45,60,70,80,90,100};
new Float:BerserkSpeed[] = {0.0,0.05,0.1,0.15,0.2,0.22,0.24,0.26,0.28};

// Healing Salve
new Float:Regeneration[]={0.0,4.0,8.0,12.0,16.0,18.0,20.0,22.0,24.0};
new bool:OutOfCombat[MAXPLAYERS+1];
new Float:TimeOutOfCombat[MAXPLAYERS+1] = 0.0;

// War Cry
new Float:WarCryMult[] = {1.0,1.075,1.15,1.225,1.3,1.325,1.35,1.375,1.4};
new Float:WarCrySpeed[] = {1.0,1.20,1.238,1.271,1.31,1.32,1.33,1.34,1.35};
new Float:WarCryRange[] = {0.0,525.0,550.0,575.0,600.0,613.0,625.0,638.0,650.0};
new Float:CurrentMultiplier[MAXPLAYERS+1] = 1.0;

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("blademaster",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Blademaster","blademaster",reloadrace_id,"True melee, crits, tank.");
		SKILL_CRITS=War3_AddRaceSkill(thisRaceID,"Precision","Chance to deal 2x damage. 9%-50% chance to proc.",false,8);
		SKILL_BERSERK=War3_AddRaceSkill(thisRaceID,"Berserk","Passive : Gives +15-100 health and +5%-28% movespeed.",false,8);
		SKILL_SALVE=War3_AddRaceSkill(thisRaceID,"Healing Salve","After 2.5 seconds of being out of combat, you gain +4-24 regen per second.",false,8);
		ULT_WARCRY=War3_AddRaceSkill(thisRaceID,"War Cry","Gives damage and movespeed to you and nearby players.\n+7.5-40% damage boost, +20-35% movespeed, 525-650HU radius, lasts 8 seconds.",true,8);
		War3_CreateRaceEnd(thisRaceID);
		
		War3_AddSkillBuff(thisRaceID, SKILL_BERSERK, fMaxSpeed2, BerserkSpeed);
		War3_AddSkillBuff(thisRaceID, SKILL_BERSERK, iAdditionalMaxHealth, BerserkHP);
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("blademaster");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("blademaster");
}
stock int TF2_GetPlayerMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}
GiveBlademasterPerks(client)
{
	new weapon = GetPlayerWeaponSlot(client, 2);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	TF2_RemoveAllWearables(client);
	StopSalve(client);
	TF2_AddCondition(client, TFCond_RestrictToMelee, 9999999.0);
	TF2Attrib_SetByName(client,"cancel falling damage", 1.0);
	TF2Attrib_SetByName(weapon,"melee range multiplier", 1.25);
	TF2Attrib_SetByName(weapon,"is_a_sword", 1.0);
	TF2Attrib_SetByName(client,"dmg taken increased", 0.9);
	TF2Attrib_SetByName(client,"damage force reduction", 0.0);
	TF2Attrib_SetByName(client,"airblast vulnerability multiplier", 0.0);
}
RemoveBlademasterPerks(client)
{
	new weapon = GetPlayerWeaponSlot(client, 2);
	TF2Attrib_RemoveByName(client,"max health additive bonus");
	TF2Attrib_RemoveByName(client,"CARD: move speed bonus");
	TF2Attrib_RemoveByName(client,"cancel falling damage");
	TF2Attrib_RemoveByName(client,"dmg taken increased");
	TF2Attrib_RemoveByName(client,"damage force reduction");
	TF2Attrib_RemoveByName(client,"airblast vulnerability multiplier");
	if(IsValidEntity(weapon))
	{
		TF2Attrib_RemoveByName(weapon,"melee range multiplier");
		TF2Attrib_RemoveByName(weapon,"is_a_sword");
	}
	War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
	War3_SetBuff(client,fMaxSpeed2,thisRaceID,0.0);
}
stock bool:IsValidClient( client, bool:replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsClientConnected( client ) ) return false; 
    if ( GetEntProp( client, Prop_Send, "m_bIsCoaching" ) ) return false; 
    if ( replaycheck )
    {
        if ( IsClientSourceTV( client ) || IsClientReplay( client ) ) return false; 
    }
    return true; 
}
public void OnPluginStart()
{
	CreateTimer(0.25, Timer_CheckSalve, _, TIMER_REPEAT);
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn);
}
public Action:Timer_CheckSalve(Handle:timer)
{
	for(new i = 0; i < MAXPLAYERS + 1; i++)
	{
		if(IsValidClient(i))
		{
			if(War3_GetRace(i)==thisRaceID && OutOfCombat[i] == true)
			{
				new skilllvl = War3_GetSkillLevel(i,thisRaceID,SKILL_SALVE);
				new Float:RegenPerTick = Regeneration[skilllvl];
				new clientHealth = GetClientHealth(i);
				new clientMaxHealth = TF2_GetPlayerMaxHealth(i);
				RegenPerTick = RegenPerTick/4;
				if(clientHealth < clientMaxHealth)
				{
					if(float(clientHealth) + RegenPerTick < clientMaxHealth)
					{
						SetEntityHealth(i, clientHealth+RoundToNearest(RegenPerTick));
					}
					else
					{
						SetEntityHealth(i, clientMaxHealth);
					}
				}
				
			}
		}
	}
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)//on every server frame
{
	if(IsValidClient(client))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_SALVE);
			if(skilllvl > 0)
			{
				if(TimeOutOfCombat[client] >= 2.5)
				{
					OutOfCombat[client] = true;
				}
				TimeOutOfCombat[client] += GetTickInterval();
			}
		}
	}
}
public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client))
		return;
		
	if(War3_GetRace(client)==thisRaceID)
	{
		GiveBlademasterPerks(client);
	}
	else
	{
		RemoveBlademasterPerks(client);
	}
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		GiveBlademasterPerks(client);
	}
	else
	{
		RemoveBlademasterPerks(client);
	}
}
StopSalve(client)
{	
	OutOfCombat[client] = false;
	TimeOutOfCombat[client] = 0.0;
}

public OnMapStart()
{
	UnLoad_Hooks();
}

public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(RaceDisabled)
		return;

	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		if(GetClientTeam(victim)==GetClientTeam(attacker))
		{
			return;
		}
	}
	if(IsValidEntity(victim)&&ValidPlayer(attacker,false))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new skilllvl = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CRITS);
			if(skilllvl > 0)
			{
				new Float:Chance = GetRandomFloat(0.0, 1.0);
				if(!ValidPlayer(victim,false) && CritChance[skilllvl] >= Chance)
				{
					War3_DamageModPercent(CritMultiplier); // Chance to deal double damage.
					PrintHintText(attacker,"2x damage! Precision crit.");
				}
				if(ValidPlayer(victim,false) && CritChance[skilllvl] >= Chance &&!W3HasImmunity(victim,Immunity_Skills))
				{
					War3_DamageModPercent(CritMultiplier); // Chance to deal double damage.
					PrintHintText(attacker,"2x damage! Precision crit.");
				}
			}
		}
		if(ValidPlayer(victim,true) && War3_GetRace(victim)==thisRaceID)
		{
			StopSalve(victim);
		}
		if(CurrentMultiplier[attacker] > 1.0)
		{
			if(!ValidPlayer(victim,false))
			{
				War3_DamageModPercent(CurrentMultiplier[attacker]);
			}
			if(ValidPlayer(victim,false)&&!W3HasImmunity(victim,Immunity_Ultimates))
			{
				War3_DamageModPercent(CurrentMultiplier[attacker]);
			}
		}
	}
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(RaceDisabled)
		return;
		
	if(War3_GetRace(client)==thisRaceID)	
	{
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_SALVE);
		if(skilllvl > 0)
		{
			StopSalve(client);
		}
	}
}
public Action:WarCryOff(Handle:timer,any:client)
{	
	TF2Attrib_RemoveByName(client, "major move speed bonus");
	CurrentMultiplier[client] = 1.0;
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,ULT_WARCRY);
		if(HasLevels(client,skill_level,1))
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_WARCRY,true ))
			{
				new Float:Range = WarCryRange[skill_level];
				new Float:AttackerPos[3];
				GetClientAbsOrigin(client,AttackerPos);
				new AttackerTeam = GetClientTeam(client);
				float VictimPos[3];
				bool victimfound = false;
				for(int i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true))
					{
						int VictimTeam = GetClientTeam(i);
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(AttackerPos,VictimPos)<Range && VictimTeam == AttackerTeam)
						{
							GetClientAbsOrigin(i,VictimPos);
							CreateTimer(8.0,WarCryOff,i);
							
							TF2Attrib_SetByName(i,"major move speed bonus",WarCrySpeed[skill_level]);
							CurrentMultiplier[i] = WarCryMult[skill_level];
							TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.2);
							TF2_AddCondition(i, TFCond_SpeedBuffAlly, 0.2);
							W3Hint(i,HINT_COOLDOWN_NOTREADY,3.0,"You were inspired! Increased damage and movespeed.");
							victimfound = true;
						}
					}
				}
				if(victimfound)
				{
					War3_CooldownMGR(client,45.0,thisRaceID,ULT_WARCRY,_,_);
				}
				if(victimfound == false)
				{
					W3MsgNoTargetFound(client,Range);
				}
			}
		}
	}
}