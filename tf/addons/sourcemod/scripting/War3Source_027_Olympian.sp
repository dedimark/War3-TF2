#include <war3source>
#include <tf2attributes>
#include <sdkhooks>
#include <sdktools>
#assert GGAMEMODE == MODE_WAR3SOURCE

#define RACE_ID_NUMBER 27

#define ExplosionSound "weapons/airstrike_small_explosion_03.wav"

//#pragma semicolon 1	///WE RECOMMEND THE SEMICOLON

//#include <sourcemod>
//#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo =
{
	name = "Race - Olympian",
	author = "Razor",
	description = "Olympian race for War3Source.",
	version = "1.0",
};
public W3ONLY(){}

new thisRaceID;
int jumpoffset;

bool HooksLoaded = false;
public void Load_Hooks()
{
	if(HooksLoaded) return;
	HooksLoaded = true;

	W3Hook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Hook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
}
public void UnLoad_Hooks()
{
	if(!HooksLoaded) return;
	HooksLoaded = false;

	W3Unhook(W3Hook_OnUltimateCommand, OnUltimateCommand);
	W3Unhook(W3Hook_OnAbilityCommand, OnAbilityCommand);
	W3Unhook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
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
//	if(RaceDisabled)
//		return;

new SKILL_ACRO, SKILL_STR, SKILL_ENERGIZE, ULT_SPEAR;

//Acrobatics
new Float:AcroSpeed[] = {1.0,1.05,1.05,1.05,1.05,1.05,1.10,1.15,1.20};
new Float:AcroJumpHeight[] = {1.0,1.0,1.2,1.2,1.2,1.2,1.2,1.2,1.2};
new Float:AcroAirControl[] = {1.0,1.0,1.0,1.25,1.25,1.35,1.35,1.35,1.35};
new Float:AcroJumps[] = {0.0,0.0,0.0,0.0,1.0,1.0,1.0,1.0,1.0};
//Olympian's Strength
new Float:allDamageMult[] = {1.0,1.02,1.04,1.06,1.08,1.10,1.12,1.14,1.16};
new Float:meleeDamageMult[] = {1.0,1.2,1.3,1.4,1.5,1.55,1.6,1.65,1.7};
//Energize
new Float:energizeDuration[] = {0.0,3.0,4.0,5.0,6.0,6.5,7.0,7.5,8.0};
//Spear Throw
new Float:spearDamage[] = {0.0,80.0,85.0,90.0,100.0,105.0,110.0,115.0,120.0};

public OnWar3LoadRaceOrItemOrdered2(num,reloadrace_id,String:shortname[])
{
	if(num==RACE_ID_NUMBER||(reloadrace_id>0&&StrEqual("olympian",shortname,false)))
	{
		thisRaceID=War3_CreateNewRace("Olympian","olympian",reloadrace_id,"Scout Race");
		SKILL_ACRO=War3_AddRaceSkill(thisRaceID,"Acrobatics","Each level increases mobility.\nGives 5 to 20% movespeed, 20% jump height at lvl 2, 25% to 35% air control, and an extra jump at lvl 4.",false,8);
		SKILL_STR=War3_AddRaceSkill(thisRaceID,"Olympian's Strength","Overall damage increased by 2 to 16%, but melee damage is drastically increased by 20 to 70%.",false,8);
		SKILL_ENERGIZE=War3_AddRaceSkill(thisRaceID,"Energize","Gives a short burst of speed. Lasts 3 to 8 seconds.",false,8);
		ULT_SPEAR=War3_AddRaceSkill(thisRaceID,"Spear Throw","Throw a spear that deals heavy damage. Explodes on impact.\nSpear does 80 to 120 damage.",true,8);
		War3_CreateRaceEnd(thisRaceID);
	}
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
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn);
	PrecacheSound(ExplosionSound);
	jumpoffset = FindSendPropInfo("CTFPlayer", "m_iAirDash");
}
public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client))
		return;
		
	if(War3_GetRace(client)==thisRaceID)
	{
		GiveOlympianPerks(client);
	}
	else
	{
		RemoveOlympianPerks(client);
	}
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(IsValidClient(client) && War3_GetRace(client)==thisRaceID)
	{
		if(GetEntityFlags(client) & FL_ONGROUND)
		{
			new skill_level = War3_GetSkillLevel(client,thisRaceID,SKILL_ACRO);
			if(skill_level > 0)
			{
				SetEntData(client, jumpoffset, 0-RoundToNearest(AcroJumps[skill_level]));
				//PrintToChat(client,"bruh.");
			}
		}
	}
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		GiveOlympianPerks(client);
	}
	else
	{
		RemoveOlympianPerks(client);
	}
}
GiveOlympianPerks(client)
{
	if(IsValidClient(client))
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,SKILL_ACRO);
		if(skill_level > 0)
		{
			TF2Attrib_SetByName(client,"move speed penalty", AcroSpeed[skill_level]);
			TF2Attrib_SetByName(client,"major increased jump height", AcroJumpHeight[skill_level]);
			TF2Attrib_SetByName(client,"increased air control", AcroAirControl[skill_level]);
			//TF2Attrib_SetByName(client,"air dash count", AcroJumps[skill_level]);
		}
	}
}
RemoveOlympianPerks(client)
{
	if(IsValidClient(client))
	{
		
		TF2Attrib_RemoveByName(client,"move speed penalty");
		TF2Attrib_RemoveByName(client,"major increased jump height");
		TF2Attrib_RemoveByName(client,"increased air control");
	}
}
public OnAllPluginsLoaded()
{
	War3_RaceOnPluginStart("olympian");
}

public OnPluginEnd()
{
	if(LibraryExists("RaceClass"))
		War3_RaceOnPluginEnd("olympian");
}
public OnMapStart()
{
	UnLoad_Hooks();
}
public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(RaceDisabled)
	return;
	if(War3_GetRace(attacker)!=thisRaceID)
	return;
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
		new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_STR);
		if(skill_level>0)
		{
			if(War3_IsUsingMeleeWeapon(attacker))
			{
				War3_DamageModPercent(meleeDamageMult[skill_level]);
			}
			else
			{
				War3_DamageModPercent(allDamageMult[skill_level]);
			}
		}
	}
}
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_ENERGIZE);
		if(skill_level>0&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_ENERGIZE,true)&&!Silenced(client))
		{
			PrintHintText(client, "Energize used!");
			War3_CooldownMGR(client,15.0,thisRaceID,SKILL_ENERGIZE,false,true);
			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, energizeDuration[skill_level]);
		}
	}
}
public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	}
}
public void OnUltimateCommand(int client, int race, bool pressed, bool bypass)
{
	if(RaceDisabled)
		return;

	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,ULT_SPEAR);
		if(HasLevels(client,skill_level,1))
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_SPEAR,true ))
			{
				War3_CooldownMGR(client,30.0,thisRaceID,ULT_SPEAR,false,true);
				PrintHintText(client, "Spear Thrown!");
				new iEntity = CreateEntityByName("tf_projectile_arrow");
				if (IsValidEdict(iEntity)) 
				{
					new Float:fAngles[3];
					new Float:fOrigin[3];
					new Float:vBuffer[3];
					new Float:fVelocity[3];
					new Float:fwd[3];
					new iTeam = GetClientTeam(client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
					SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
					SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
					SetEntProp(iEntity, Prop_Send, "m_bCritical", 1);
								
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client,fAngles);
					
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					GetAngleVectors(fAngles,fwd, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(fwd, 30.0);
					
					AddVectors(fOrigin, fwd, fOrigin);
					
					new Float:Speed = 3000.0;
					fVelocity[0] = vBuffer[0]*Speed;
					fVelocity[1] = vBuffer[1]*Speed;
					fVelocity[2] = vBuffer[2]*Speed;
					SetEntPropVector(iEntity, Prop_Send, "m_vInitialVelocity", fVelocity );
					TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
					DispatchSpawn(iEntity);
					SDKHook(iEntity, SDKHook_Touch, ExplosiveArrowCollision);
					CreateTimer(4.0, SelfDestruct, EntIndexToEntRef(iEntity));
				}
			}
		}
	}
}
public Action:ExplosiveArrowCollision(entity, client)
{		
	if(!IsValidEntity(entity))
		return Plugin_Continue;

	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(owner))
		return Plugin_Continue;
		
	new Float:targetvec[3];
	new Float:projvec[3];
	
	if(HasEntProp(entity, Prop_Data, "m_vecOrigin"))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", projvec);
		for(new i=1; i<=MaxClients; i++)
		{
			if(!IsValidClient(i)){continue;}
			GetClientAbsOrigin(i, targetvec);
			if(!IsClientObserver(i) && GetClientTeam(i) != GetClientTeam(owner) && GetVectorDistance(projvec, targetvec, false) < 200.0)
			{
				if(owner != i)
				{
					new skill_level = War3_GetSkillLevel(owner,thisRaceID,ULT_SPEAR);
					DoExplosion(owner, spearDamage[skill_level], 400.0, projvec, i);					
					AcceptEntityInput(entity,"Kill");
					return Plugin_Continue;
				}
			}
		}
	}
	decl String:strName[128];
	GetEntityClassname(client, strName, 128);
	if(StrContains(strName,"trigger_",false) || StrEqual(strName,"tf_projectile_arrow",false) || client == -1)
	{	
		if(StrEqual(strName,"tf_projectile_arrow",false))
		{
			new Float:origin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
			origin[0] += GetRandomFloat(-4.0,4.0);
			origin[1] += GetRandomFloat(-4.0,4.0);
			TeleportEntity(entity, origin,NULL_VECTOR,NULL_VECTOR);
		}
	}
	return Plugin_Stop;
}
stock DoExplosion(owner, Float:damage, Float:radius, Float:pos[3], victim)
{
	ExplodeDamage(victim, damage, radius, DMG_BLAST, owner);
	new particle = CreateEntityByName( "info_particle_system" );
	if ( IsValidEntity( particle ) )
	{
		TeleportEntity( particle, pos, NULL_VECTOR, NULL_VECTOR );
		DispatchKeyValue( particle, "effect_name", "ExplosionCore_MidAir" );
		DispatchSpawn( particle );
		ActivateEntity( particle );
		AcceptEntityInput( particle, "start" );
		SetVariantString( "OnUser1 !self:Kill::8:-1" );
		AcceptEntityInput( particle, "AddOutput" );
		AcceptEntityInput( particle, "FireUser1" );
		EmitSoundToAll(ExplosionSound, owner);
	}
}
stock ExplodeDamage(client, Float:dmg, Float:distance, damagetype, enemy)
{
	if(!W3HasImmunity(client,Immunity_Ultimates) && War3_DealDamage(client, RoundToNearest(dmg), enemy, DMG_FALL, "spearThrow" ))
	{
		War3_NotifyPlayerTookDamageFromSkill(client, enemy, RoundToNearest(dmg), ULT_SPEAR);
	}
	new Float:uservec[3], Float:targetvec[3];
	GetClientAbsOrigin(client, uservec);
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		GetClientAbsOrigin(i, targetvec);
		if(GetClientTeam(i) == GetClientTeam(client) && GetVectorDistance(uservec, targetvec, false) < distance)
		{
			if(client != i && !W3HasImmunity(i,Immunity_Ultimates))
			{
				War3_DealDamage(i, RoundToNearest(dmg), enemy ,DMG_BLAST, "spearThrow");
			}
		}
	}
}