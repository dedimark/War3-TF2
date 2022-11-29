#define PLUGIN_VERSION "0.0.0.1"
/* ========================================================================== */
/*                                                                            */
/*   War3source_Custom_HyperCyborg.sp                                         */
/*   (c) 2012 El Diablo                                                       */
/*                                                                            */
/* ========================================================================== */
#pragma semicolon 1


#include <sourcemod>
#include <war3source>
#include <tf2attributes>
public W3ONLY(){} //unload this?
new thisRaceID;
#define RACE_ID_NUMBER 24
#define RACE_LONGNAME "Hyper Cyborg"
#define RACE_SHORTNAME "hyperC"

//global
new ownerOffset;

// Ultimate
//new bool:Sentry_Toggle[MAXPLAYERSCUSTOM];

new SKILL_ACP_SENTRY, SKILL_AUTO_DISPENSER,SKILL_NANO_PRODUCTION;

// ACP SENTRY ROUNDS
new Float:ACP[]={0.0,0.05,0.1,0.15,0.15,0.2,0.2125,0.225,0.2375,0.25,0.2625,0.275};
new Float:ORB[]={0.0,0.8,0.75,0.7,0.65,0.625,0.6,0.575,0.55,0.525,0.5,0.5};

new NANO[]={0,2,5,7,10,11,12,13,14,15,16,17};
new NANO_decrease_health[]={0,1,2,3,4,4,4,4,3,3,3,3};

//// Entity Class Names
#define CLASSNAME_SENTRY "obj_sentrygun"
#define CLASSNAME_DISPENSER "obj_dispenser"
#define CLASSNAME_TELEPORTER "obj_teleporter"

//// Other Global Variables

new MaxSentryShellsByLevel[] = { 150, 200, 200 };
new RepairRateByDispenserLevel[3] = { 5, 10, 20 };
new SentryShellRefillRateByDispenserLevel[3] = { 1, 2, 4 };
new SentryRocketRefillRateByDispenserLevel[3] = { 0, 0, 0 };

new Float:WrenchRateOfFire[] = {1.0, 1.20, 1.30, 1.40, 1.50, 1.55, 1.6, 1.65, 1.7, 1.75, 1.8, 1.85};

//// Global Constants

const MaxSentryRockets = 20;

new Float:TickInterval = 2.0;  //"The interval between ticks, in seconds."
new bool:IsUsingNano[65] = false;
//new Handle:RepairTimer = INVALID_HANDLE;

new MaxDispenserDistance = 150;
const bool:IsSentryRepairEnabled = true;
new bool:IsSentryAntiSapperEnabled = false;
const bool:IsDispenserRepairEnabled = true;
new bool:IsDispenserAntiSapperEnabled = false;
const bool:IsTeleporterRepairEnabled = true;
new bool:IsTeleporterAntiSapperEnabled = false;



new bool:bFrosted[65]; // don't frost before unfrosted

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;
	W3Hook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
	W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnW3TakeDmgBullet, OnW3TakeDmgBullet);
	W3Unhook(W3Hook_OnAbilityCommand, OnAbilityCommand);
}
public OnWar3RaceEnabled(newrace)
{
	if(newrace==thisRaceID)
	{
		Load_Hooks();
	}
}
public OnWar3RaceDisabled(oldrace)
{
	if(oldrace==thisRaceID)
	{
		UnLoad_Hooks();
	}
}

public Plugin:myinfo =
{
	name = "Race - Hyper Cyborg",
	author = "El Diablo",
	description = "A race dedicated for engineer.",
	version = "1.0.0.0",
	url = "http://Www.war3evo.Com"
};
public OnPluginStart()
{
	ownerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
	StartRepairTimer();
	CreateTimer(0.3,AttackspeedCalc,_,TIMER_REPEAT);      // Berserker ASPD Buff timer
}

public Action:OnTick(Handle:timer)
{
	ProcessDispensers();
	return Plugin_Continue;
}


//// Utility Functions

StartRepairTimer()
{
	CreateTimer(
		TickInterval,
		OnTick,
		_,
		TIMER_REPEAT);
}


public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual(RACE_SHORTNAME,shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Hyper Cyborg",RACE_SHORTNAME,reloadrace_id,"Engineer race");
		SKILL_NANO_PRODUCTION=War3_AddRaceSkill(thisRaceID,"Nano Production","Regenerates 2-17 metal per second.\nNano requires 1-4-3 health/second to rebuild metal.\nMust have at least 50 or more health to regen metal.\n(+ability)",false,10);
		SKILL_AUTO_DISPENSER=War3_AddRaceSkill(thisRaceID,"Auto Dispenser","When buildings are near to dispensers,\nit repairs and refills building (increases by dispenser level & job level).\nIncreases fire rate for melee by 20 to 85% percent.",false,10);
		SKILL_ACP_SENTRY=War3_AddRaceSkill(thisRaceID,"ACP Sentry Rounds","Sentry's Damage Increased by 5 to 27.5% and Victim Slowed by 20 to 50%.",false,10);
		War3_CreateRaceEnd(thisRaceID);
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart(RACE_SHORTNAME);
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd(RACE_SHORTNAME);
}

public OnW3Denyable(W3DENY:event,client)
{
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == War3_GetItemIdByShortname("ring")))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			new Nano_Production_level=War3_GetSkillLevel(client,thisRaceID,SKILL_NANO_PRODUCTION);
			if(Nano_Production_level>0)
			{
				W3Deny();
				War3_ChatMessage(client, "Cyborgs can't feel the effects of these items!");
			}
		}
	}
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == War3_GetItemIdByShortname("gauntlet")))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			new Nano_Production_level=War3_GetSkillLevel(client,thisRaceID,SKILL_NANO_PRODUCTION);
			if(Nano_Production_level>0)
			{
				W3Deny();
				War3_ChatMessage(client, "Cyborgs can't feel the effects of these items!");
			}
		}
	}
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == War3_GetItemIdByShortname("claw")))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			W3Deny();
			War3_ChatMessage(client, "Cyborgs can't feel the effects of these items!");
		}
	}
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == War3_GetItemIdByShortname("orb")))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			W3Deny();
			War3_ChatMessage(client, "Cyborgs can't feel the effects of these items!");
		}
	}
}
//Add support for dmg reduction on sentries.
public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		if(GetClientTeam(victim)==GetClientTeam(attacker))
		{
			return;
		}
	}
	if(IsValidEntity(victim)&&ValidPlayer(attacker,false))
	{
		if(HasEntProp(victim,Prop_Send,"m_hBuilder"))
		{
			new owner = GetEntPropEnt(victim,Prop_Send,"m_hBuilder");//It's a building
			if(ValidPlayer(owner,true))
			{
				if(W3GetPhysicalArmorMulti(owner) != 1.0)
				{
					War3_DamageModPercent(W3GetPhysicalArmorMulti(owner));
				}
			}
		}
	}
}
public OnMapStart()
{
	CreateTimer(1.0, Timer_Ammo_Regen, _, TIMER_REPEAT);
}
public Action:AttackspeedCalc(Handle:timer,any:userid) // Check each 0.5 second if the conditions for Berserkers Blood have changed
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					new client=i;
					new AutoDispenser_level=War3_GetSkillLevel(client,thisRaceID,SKILL_AUTO_DISPENSER);
					
					new weapon = GetPlayerWeaponSlot(client, 2);
					if(IsValidEntity(weapon))
					{
						new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
						if(IsValidEntity(CWeapon))
						{
							if(CWeapon == weapon)
							{
								War3_SetBuff(client,fAttackSpeed,thisRaceID,WrenchRateOfFire[AutoDispenser_level]);
							}
							else
							{
								War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
public void OnAbilityCommand(int client, int ability, bool pressed, bool bypass)
{
	if(War3_GetRace(client)!=thisRaceID)
	{
		return;
	}
	new skill = War3_GetSkillLevel(client, thisRaceID, SKILL_NANO_PRODUCTION);
	if(skill>0 && ability==0 && pressed && IsPlayerAlive(client)&&!Silenced(client))
	{
		if(!IsUsingNano[client])
		{
			PrintHintText(client,"Activated Nano Production");
			IsUsingNano[client] = true;
		}
		else
		{
			PrintHintText(client,"Deactivated Nano Production");
			IsUsingNano[client] = false;
		}
	}
	if(skill==0 && War3_GetRace(client)==thisRaceID)
	{
		PrintHintText(client, "Your Ability is not leveled");
	}
}
public Action:Timer_Ammo_Regen(Handle:timer, any:user)
{
	//PrintToChatAll("Timer called, timestamp: %i", GetTime());
	new iMaxMetal = 200;
	new iMetalToAdd = 0;

	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || TF2_GetPlayerClass(i) != TFClass_Engineer || War3_GetRace(i)!=thisRaceID)
			continue;	// Client isnt valid

		new Nano_Production_level=War3_GetSkillLevel(i,thisRaceID,SKILL_NANO_PRODUCTION);
		if(Nano_Production_level<=0)
			continue;
			
		if(!IsUsingNano[i])
			continue;
			
		iMetalToAdd = NANO[Nano_Production_level];

		new iCurrentMetal = GetEntProp(i, Prop_Data, "m_iAmmo", 4, 3);
		new iNewMetal = iMetalToAdd + iCurrentMetal;
		if (iNewMetal <= iMaxMetal && GetClientHealth(i)>50)
		{
			SetEntProp(i, Prop_Data, "m_iAmmo", iNewMetal, 4, 3);
			War3_DecreaseHP(i,NANO_decrease_health[Nano_Production_level]);
		}
	}
}

/* ***************************  OnRaceChanged *************************************/

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		InitPassiveSkills(client);
	}
	else
	{
		RemovePassiveSkills(client);
	}
}
/* ****************************** OnSkillLevelChanged ************************** */

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
	//nothing
		new AutoDispenser_level=War3_GetSkillLevel(client,thisRaceID,SKILL_AUTO_DISPENSER);
		if(AutoDispenser_level>0)
		{
			switch(AutoDispenser_level)
			{
				case 1:
				{
					MaxDispenserDistance = 100;

					IsSentryAntiSapperEnabled = false;
					IsDispenserAntiSapperEnabled = false;
					IsTeleporterAntiSapperEnabled = false;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 10;
					RepairRateByDispenserLevel[1] = 17;
					RepairRateByDispenserLevel[2] = 25;

					SentryShellRefillRateByDispenserLevel[0] = 5;
					SentryShellRefillRateByDispenserLevel[1] = 10;
					SentryShellRefillRateByDispenserLevel[2] = 15;

					SentryRocketRefillRateByDispenserLevel[0] = 0;
					SentryRocketRefillRateByDispenserLevel[1] = 0;
					SentryRocketRefillRateByDispenserLevel[2] = 0;
				}
				case 2:
				{
					MaxDispenserDistance = 150;

					IsSentryAntiSapperEnabled = false;
					IsDispenserAntiSapperEnabled = false;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 25;
					RepairRateByDispenserLevel[1] = 35;
					RepairRateByDispenserLevel[2] = 50;

					SentryShellRefillRateByDispenserLevel[0] = 15;
					SentryShellRefillRateByDispenserLevel[1] = 20;
					SentryShellRefillRateByDispenserLevel[2] = 25;

					SentryRocketRefillRateByDispenserLevel[0] = 0;
					SentryRocketRefillRateByDispenserLevel[1] = 0;
					SentryRocketRefillRateByDispenserLevel[2] = 1;
				}
				case 3:
				{
					MaxDispenserDistance = 200;

					IsSentryAntiSapperEnabled = true;
					IsDispenserAntiSapperEnabled = false;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 50;
					RepairRateByDispenserLevel[1] = 75;
					RepairRateByDispenserLevel[2] = 100;

					SentryShellRefillRateByDispenserLevel[0] = 25;
					SentryShellRefillRateByDispenserLevel[1] = 35;
					SentryShellRefillRateByDispenserLevel[2] = 45;

					SentryRocketRefillRateByDispenserLevel[0] = 0;
					SentryRocketRefillRateByDispenserLevel[1] = 1;
					SentryRocketRefillRateByDispenserLevel[2] = 2;
				}
				case 4:
				{
					MaxDispenserDistance = 250;

					IsSentryAntiSapperEnabled = true;
					IsDispenserAntiSapperEnabled = true;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 100;
					RepairRateByDispenserLevel[1] = 125;
					RepairRateByDispenserLevel[2] = 150;

					SentryShellRefillRateByDispenserLevel[0] = 45;
					SentryShellRefillRateByDispenserLevel[1] = 60;
					SentryShellRefillRateByDispenserLevel[2] = 75;

					SentryRocketRefillRateByDispenserLevel[0] = 1;
					SentryRocketRefillRateByDispenserLevel[1] = 2;
					SentryRocketRefillRateByDispenserLevel[2] = 3;
				}
				case 5:
				{
					MaxDispenserDistance = 300;

					IsSentryAntiSapperEnabled = true;
					IsDispenserAntiSapperEnabled = true;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 100;
					RepairRateByDispenserLevel[1] = 125;
					RepairRateByDispenserLevel[2] = 150;

					SentryShellRefillRateByDispenserLevel[0] = 45;
					SentryShellRefillRateByDispenserLevel[1] = 60;
					SentryShellRefillRateByDispenserLevel[2] = 75;

					SentryRocketRefillRateByDispenserLevel[0] = 2;
					SentryRocketRefillRateByDispenserLevel[1] = 3;
					SentryRocketRefillRateByDispenserLevel[2] = 4;
				}
				case 6:
				{
					MaxDispenserDistance = 350;

					IsSentryAntiSapperEnabled = true;
					IsDispenserAntiSapperEnabled = true;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 100;
					RepairRateByDispenserLevel[1] = 125;
					RepairRateByDispenserLevel[2] = 150;

					SentryShellRefillRateByDispenserLevel[0] = 45;
					SentryShellRefillRateByDispenserLevel[1] = 60;
					SentryShellRefillRateByDispenserLevel[2] = 75;

					SentryRocketRefillRateByDispenserLevel[0] = 2;
					SentryRocketRefillRateByDispenserLevel[1] = 3;
					SentryRocketRefillRateByDispenserLevel[2] = 4;
				}
				case 7:
				{
					MaxDispenserDistance = 400;

					IsSentryAntiSapperEnabled = true;
					IsDispenserAntiSapperEnabled = true;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 100;
					RepairRateByDispenserLevel[1] = 125;
					RepairRateByDispenserLevel[2] = 150;

					SentryShellRefillRateByDispenserLevel[0] = 45;
					SentryShellRefillRateByDispenserLevel[1] = 60;
					SentryShellRefillRateByDispenserLevel[2] = 75;

					SentryRocketRefillRateByDispenserLevel[0] = 2;
					SentryRocketRefillRateByDispenserLevel[1] = 3;
					SentryRocketRefillRateByDispenserLevel[2] = 4;
				}				
				case 8:
				{
					MaxDispenserDistance = 425;

					IsSentryAntiSapperEnabled = true;
					IsDispenserAntiSapperEnabled = true;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 100;
					RepairRateByDispenserLevel[1] = 125;
					RepairRateByDispenserLevel[2] = 150;

					SentryShellRefillRateByDispenserLevel[0] = 45;
					SentryShellRefillRateByDispenserLevel[1] = 60;
					SentryShellRefillRateByDispenserLevel[2] = 75;

					SentryRocketRefillRateByDispenserLevel[0] = 2;
					SentryRocketRefillRateByDispenserLevel[1] = 3;
					SentryRocketRefillRateByDispenserLevel[2] = 4;
				}
				case 9:
				{
					MaxDispenserDistance = 450;

					IsSentryAntiSapperEnabled = true;
					IsDispenserAntiSapperEnabled = true;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 100;
					RepairRateByDispenserLevel[1] = 125;
					RepairRateByDispenserLevel[2] = 150;

					SentryShellRefillRateByDispenserLevel[0] = 45;
					SentryShellRefillRateByDispenserLevel[1] = 60;
					SentryShellRefillRateByDispenserLevel[2] = 75;

					SentryRocketRefillRateByDispenserLevel[0] = 2;
					SentryRocketRefillRateByDispenserLevel[1] = 3;
					SentryRocketRefillRateByDispenserLevel[2] = 4;
				}
				case 10:
				{
					MaxDispenserDistance = 500;

					IsSentryAntiSapperEnabled = true;
					IsDispenserAntiSapperEnabled = true;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 100;
					RepairRateByDispenserLevel[1] = 125;
					RepairRateByDispenserLevel[2] = 150;

					SentryShellRefillRateByDispenserLevel[0] = 45;
					SentryShellRefillRateByDispenserLevel[1] = 60;
					SentryShellRefillRateByDispenserLevel[2] = 75;

					SentryRocketRefillRateByDispenserLevel[0] = 2;
					SentryRocketRefillRateByDispenserLevel[1] = 3;
					SentryRocketRefillRateByDispenserLevel[2] = 4;
				}
			}

		}

	}
}

/* ****************************** RemovePassiveSkills ************************** */

public RemovePassiveSkills(client)
{
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
}

public Action:OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		if(GetClientTeam(victim)==GetClientTeam(attacker))
		{
			return;
		}
		if(W3HasImmunity(victim,Immunity_Skills))
		{
			return;
		}
	}
	if(IsValidEntity(victim)&&ValidPlayer(attacker,false))
	{
		new sentry_ACP_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_ACP_SENTRY);
		if(sentry_ACP_level>0)
		{
			new inflictor = W3GetDamageInflictor();
			if(isBuildingOwner(attacker,inflictor))
			{
				if(!bFrosted[victim] && ValidPlayer(victim,true))
				{
					new Float:speed_frost=ORB[sentry_ACP_level];
					if(speed_frost<=0.0) speed_frost=0.01; // 0.0 for override removes
					if(speed_frost>1.0)	speed_frost=1.0;
					War3_SetBuff(victim,fSlow,thisRaceID,speed_frost);
					bFrosted[victim]=true;
					CreateTimer(2.0,Unfrost,victim);
				}
				new dmg = RoundToCeil(damage*ACP[sentry_ACP_level]);
				War3_DealDamage(victim,dmg,inflictor,DMG_BULLET,"obj_sentrygun");
			}
		}
	}
}

public Action:Unfrost(Handle:timer,any:client)
{
	bFrosted[client]=false;
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
}

public OnWar3EventSpawn(client){
	if( bFrosted[client])
	{
		bFrosted[client]=false;
		War3_SetBuff(client,fSlow,thisRaceID,1.0);
	}
}

bool:isBuildingOwner(client,pBuilding)
{
	if(ValidPlayer(client))
	{
		if(IsValidEntity(pBuilding)&&TF2_GetPlayerClass(client)==TFClass_Engineer)
		{
			decl String:netclass[32];
			GetEntityNetClass(pBuilding, netclass, sizeof(netclass));

			if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectTeleporter") == 0 || strcmp(netclass, "CObjectDispenser") == 0)
			{
				if (GetEntDataEnt2(pBuilding, ownerOffset) == client)
					return true;
			}
		}
	}

	return false;
}


FindDispenser(previousDispenserEntity)
{
	return FindEntityByClassname(previousDispenserEntity, "obj_dispenser");
}

GetEntLevel(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iUpgradeLevel", 1);
}

GetEntTeam(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iTeamNum", 1);
}

stock float[3] GetEntLocation(entity, Float:positionVector[3])
{
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", positionVector);
	return positionVector;
}

GetEntHealth(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iHealth");
}

GetEntMaxHealth(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iMaxHealth");
}

AddEntHealth(entity, amount)
{
	SetVariantInt(amount);
	AcceptEntityInput(entity, "AddHealth");
}

bool:IsEntBeingBuilt(entity)
{
	return (GetEntProp(entity, Prop_Send, "m_bBuilding", 1) == 1);
}

bool:IsEntBeingPlaced(entity)
{
	return (GetEntProp(entity, Prop_Send, "m_bPlacing", 1) == 1);
}

bool:IsEntBeingSapped(entity)
{
	return (GetEntProp(entity, Prop_Send, "m_bHasSapper", 1) == 1);
}

ProcessDispensers()
{
	for (new dispenserEntity = FindDispenser(-1);
		dispenserEntity != -1;
		dispenserEntity = FindDispenser(dispenserEntity))
	{
		if (IsEntBeingBuilt(dispenserEntity)
			|| IsEntBeingPlaced(dispenserEntity)
			|| IsEntBeingSapped(dispenserEntity))
		{
			continue;
		}

		for(new i=0;i<=MaxClients;i++)
		{
			if(ValidPlayer(i))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					new AutoDispenser_level=War3_GetSkillLevel(i,thisRaceID,SKILL_AUTO_DISPENSER);
					if(AutoDispenser_level>0&&isBuildingOwner(i,dispenserEntity))
					{
						ProcessDispenser(dispenserEntity);
					}
				}
			}
		}
	}
}

ProcessDispenser(dispenserEntity)
{
	new dispenserTeam = GetEntTeam(dispenserEntity);
	new dispenserLevel = GetEntLevel(dispenserEntity);
	decl Float:dispenserLocation[3];
	GetEntLocation(dispenserEntity, dispenserLocation);
	ProcessOtherBuildings(
		dispenserEntity,
		dispenserLevel,
		dispenserTeam,
		dispenserLocation,
		CLASSNAME_SENTRY);
	ProcessOtherBuildings(
		dispenserEntity,
		dispenserLevel,
		dispenserTeam,
		dispenserLocation,
		CLASSNAME_DISPENSER);
	ProcessOtherBuildings(
		dispenserEntity,
		dispenserLevel,
		dispenserTeam,
		dispenserLocation,
		CLASSNAME_TELEPORTER);
}

ProcessOtherBuildings(
	dispenserEntity,
	dispenserLevel,
	dispenserTeam,
	Float:dispenserLocation[3],
	String:otherBuildingClassname[])
{
	new bool:isSentry =
		(strcmp(otherBuildingClassname, CLASSNAME_SENTRY) == 0);
	new bool:isDispenser =
		(strcmp(otherBuildingClassname, CLASSNAME_DISPENSER) == 0);
	new bool:isTeleporter =
		(strcmp(otherBuildingClassname, CLASSNAME_TELEPORTER) == 0);

	new otherBuildingEntity = -1;
	for (
		otherBuildingEntity =
			FindEntityByClassname(otherBuildingEntity, otherBuildingClassname);
		otherBuildingEntity != -1;
		otherBuildingEntity =
			FindEntityByClassname(otherBuildingEntity, otherBuildingClassname))
	{
		if (dispenserEntity == otherBuildingEntity)
		{
			// The other building IS the dispenser.
			// Skip it. (Don't let dispensers heal themselves.)
			continue;
		}

		new otherBuildingTeam = GetEntTeam(otherBuildingEntity);
		new Float:otherBuildingLocation[3];
		GetEntLocation(otherBuildingEntity, otherBuildingLocation);

		new Float:actualDistance =
			GetVectorDistance(dispenserLocation, otherBuildingLocation);
		if (actualDistance > MaxDispenserDistance)
		{
			// The other building is too far from the dispenser.
			// Skip it.
			continue;
		}

		if (otherBuildingTeam != dispenserTeam)
		{
			// The other building is on a different team than the dispenser.
			// Skip it.
			continue;
		}

		if (IsEntBeingBuilt(otherBuildingEntity)
			|| IsEntBeingPlaced(otherBuildingEntity))
		{
			// The other building is being built or placed.
			// Skip it.
			continue;
		}

		// I'd really like to define a ProcessBuilding functag:
		//   functag public ProcessBuilding(entity, dispenserLevel);
		// then pass a callback to the appropriate building's function, but as
		// far as I can tell there's no way to invoke a callback from a
		// SourcePawn script... so I'll just do if/else/if/else/if...
		if (isSentry)
		{
			RepairBuilding(
				otherBuildingEntity,
				dispenserLevel,
				IsSentryRepairEnabled,
				IsSentryAntiSapperEnabled);
			RefillSentryShells(otherBuildingEntity, dispenserLevel);
			RefillSentryRockets(otherBuildingEntity, dispenserLevel);
		}
		else if (isDispenser)
		{
			RepairBuilding(
				otherBuildingEntity,
				dispenserLevel,
				IsDispenserRepairEnabled,
				IsDispenserAntiSapperEnabled);
		}
		else if (isTeleporter)
		{
			RepairBuilding(
				otherBuildingEntity,
				dispenserLevel,
				IsTeleporterRepairEnabled,
				IsTeleporterAntiSapperEnabled);
		}
	}
}

RepairBuilding(
	buildingEntity,
	dispenserLevel,
	bool:isRepairEnabled,
	bool:isAntiSapperEnabled)
{
	new buildingMaxHealth = GetEntMaxHealth(buildingEntity);
	new buildingHealth = GetEntHealth(buildingEntity);

	if (buildingHealth >= buildingMaxHealth)
	{
		// This building is already at full health.
		// Skip it.
		return;
	}

	if (dispenserLevel < 1)
	{
		// The dispenser level is below 1. This is unexpected.
		// Skip the building.
		// TODO: Log this.
		return;
	}

	if (dispenserLevel > 3)
	{
		// The dispenser level is above 3. This is unexpected.
		// Clip it to 3 for the purpose of establishing the repair rate.
		dispenserLevel = 3;
		// TODO: Log this.
	}

	new healthIncrement = RepairRateByDispenserLevel[dispenserLevel - 1];

	if (IsEntBeingSapped(buildingEntity))
	{
		// The building is being sapped.
		if (isAntiSapperEnabled)
		{
			// Anti-sapper is enabled.
			// Repair the building at one fifth normal speed.
			//healthIncrement /= 5;
		}
		else
		{
			// Anti-sapper is disabled.
			// Skip the building.
			return;
		}
	}
	else if (!isRepairEnabled)
	{
		// The building is not being sapped, but repair is disabled.
		// Skip the building.
		return;
	}

	if ((buildingHealth + healthIncrement) > buildingMaxHealth)
	{
		// The increase in the building's health would exceed its maximum
		// health.
		// Clip the increment to the amount necessary to reach maximum health.
		healthIncrement = buildingMaxHealth - buildingHealth;
	}

	AddEntHealth(buildingEntity, healthIncrement);
}

RefillSentryShells(sentryEntity, dispenserLevel)
{
	new sentryLevel = GetEntLevel(sentryEntity);
	new shells = GetEntProp(sentryEntity, Prop_Send, "m_iAmmoShells");
	shells += SentryShellRefillRateByDispenserLevel[dispenserLevel - 1];
	if (shells > MaxSentryShellsByLevel[sentryLevel - 1])
	{
		shells = MaxSentryShellsByLevel[sentryLevel - 1];
	}

	SetEntProp(sentryEntity, Prop_Send, "m_iAmmoShells", shells);
}

RefillSentryRockets(sentryEntity, dispenserLevel)
{
	new sentryLevel = GetEntLevel(sentryEntity);
	if (sentryLevel < 3)
	{
		// The sentry is below level 3, so it doesn't have rockets.
		return;
	}

	new sentryRockets = GetEntProp(sentryEntity, Prop_Send, "m_iAmmoRockets");
	sentryRockets += SentryRocketRefillRateByDispenserLevel[dispenserLevel - 1];
	if (sentryRockets > MaxSentryRockets)
	{
		sentryRockets = MaxSentryRockets;
	}

	SetEntProp(sentryEntity, Prop_Send, "m_iAmmoRockets", sentryRockets);
}