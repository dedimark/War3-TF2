#include <war3source>
#include <tf2attributes>

#define PLUGIN_VERSION "1.0"

#pragma semicolon 1

enum ITEMENUM{
	REDTEARSTONE=0,
	BLUETEARSTONE,
	STORMHEART,
	MARKSMAN,
	WINDPEARL,
	MAGMACHARM,
	SPRINGGEM,
	POISONGEM,
	ATTACKSPEED,
	UBERHEART,
	FREEZE,
	HEATINGPLATES
}
int ItemID[MAXITEMS3];
new bool:DOTStacked[MAXPLAYERS + 1] = false;
public Plugin:myinfo =
{
	name = "War3Evo:Shop items 3",
	author = "Razor",
	description = "Implement sh3 items.",
	version = "1.0",
	url = "no."
};

public void OnAllPluginsLoaded()
{
	W3Hook(W3Hook_OnW3TakeDmgBulletPre, OnW3TakeDmgBulletPre);
	W3Hook(W3Hook_OnWar3EventPostHurt, OnWar3EventPostHurt);
}

public OnPluginStart()
{
	CreateConVar("war3_shopmenu3",PLUGIN_VERSION,"War3Source:EVO shopmenu 3",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	CreateTimer(0.2, Timer_QuickTimer, _, TIMER_REPEAT);
	CreateTimer(3.0, Timer_SlowTimer, _, TIMER_REPEAT);
}

public OnClientPutInServer(client)
{
	SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==20){

		for(int x=0;x<MAXITEMS3;x++)
			ItemID[x]=0;

		//Red - Offensive
		ItemID[REDTEARSTONE]=War3_CreateShopItem3("Red Tearstone","red_tearstone","Gain a 15%% damage boost while at 25%% or below.\nLeveling up increases threshold. Adds 2%% per level.",40,"Red","Red Tearstone",10,"Red Tearstone",0);
		if(ItemID[REDTEARSTONE]==0){
			DP("ERR ITEM ID RETURNED IS ZERO | SH3");
		}
		ItemID[STORMHEART]=War3_CreateShopItem3("Heart of the Storm","stormheart","Adds +2 damage to all hits.\nLeveling up increases additive damage. Adds 0.2 damage per level.",60,"Red","Heart of the Storm",10,"Heart of the Storm",0);
		
		//Yellow - Modifiers
		ItemID[WINDPEARL]=War3_CreateShopItem3("Cloudy Pearl","windpearl","Gives +6%% movespeed.\nLeveling increases movespeed. 1%% increase per level.",30,"Yellow","Cloudy Pearl",10,"Cloudy Pearl",0);
		ItemID[FREEZE]=War3_CreateShopItem3("Frozen Fists","freeze","Hits have a 10% chance to stop enemy movement for 0.2 seconds.\nCannot level up.",60,"Yellow","Frozen Fists",0,"Frozen Fists",0);
		
		//Blue - Survivability
		ItemID[BLUETEARSTONE]=War3_CreateShopItem3("Blue Tearstone","blue_tearstone","Gain a 15%% defense boost while at 25%% or below.\nLeveling up increases threshold. Adds 2%% per level.",30,"Blue","Blue Tearstone",10,"Blue Tearstone",0);
		ItemID[UBERHEART]=War3_CreateShopItem3("Ubered Heart","uberheart","Gives +2.5%% max health.\nLeveling up increases max health. +0.2%% max health per level.",50,"Blue","Ubered Heart",10,"Ubered Heart",0);
		
		//Orange - Red & Yellow
		ItemID[MAGMACHARM]=War3_CreateShopItem3("Magmatic Charm","magmacharm","Ignites target for 1 second on hit.\nCannot level up.",140,"Orange","Magmatic Charm",0,"Magmatic Charm",0);
		ItemID[POISONGEM]=War3_CreateShopItem3("Poison Gem","poisongem","10%% chance to apply 4 ticks of 2 dmg poison on hit.\nLeveling up decreases tickspeed and increases damage.\n -0.05s per tick per level, +0.25 dmg per level.",50,"Orange","Poison Gem",10,"Poison Gem",0);
		
		//Green - Blue & Yellow
		ItemID[SPRINGGEM]=War3_CreateShopItem3("Spring Gem","spring","Gives +1/s combat regen.\nWhile your health is below or equal to 40%%, regen is boosted by 2x.\nUpgrading increases regen. 0.2 regen per level.",60,"Green","Spring Gem",10,"Spring Gem",0);
		ItemID[HEATINGPLATES]=War3_CreateShopItem3("Heating Coils","heat","Gives immunity to slowdowns.\nCannot be leveled up.",50,"Green","Heating Coils",0,"Heating Coils",0);
		
		//Purple - Red & Blue
		ItemID[MARKSMAN]=War3_CreateShopItem3("Marksman's Sign","marksman","Shots to the head deal 10%% more damage and have 10%% lifesteal.\nLeveling up increases lifesteal. +1%% lifesteal per level.",50,"Purple","Marksman's Sign",10,"Marksman's Sign",0);
		ItemID[ATTACKSPEED]=War3_CreateShopItem3("Rage Gem","rage","You gain 0.1%% attackspeed per 1% health missing.\nLeveling up increases attackspeed. +0.005%% attackspeed per level.",55,"Purple","Rage Gem",10,"Rage Gem",0);
	}
}
public Action:Timer_QuickTimer(Handle:timer)
{
	for(new client = 1; client < MaxClients+1; client++)
	{
		if(ValidPlayer(client, true))
		{
			new race = War3_GetRace(client);
			if(War3_GetOwnsItem3(client,race,ItemID[SPRINGGEM]))
			{
				new level = War3_GetItemLevel(client,race,ItemID[SPRINGGEM])+1;
				if(level > 0)
				{
					new Float:RegenPerTick = (4.0 + (level * 0.2));
					
					new clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
					new clientMaxHealth = TF2_GetMaxHealth(client);
					if(clientHealth <= RoundToNearest(clientMaxHealth * 0.4))
					{
						RegenPerTick *= 2.0;
					}
					TF2Attrib_SetByName(client,"SET BONUS: health regen set bonus", RegenPerTick);
				}
			}
			else
			{
				TF2Attrib_RemoveByName(client,"SET BONUS: health regen set bonus");
			}
			
			if(War3_GetOwnsItem3(client,race,ItemID[ATTACKSPEED]))
			{
				new level = War3_GetItemLevel(client,race,ItemID[ATTACKSPEED])+1;
				if(level > 0)
				{
					new Float:ASPD;
					new VictimCurHP = GetClientHealth(client);
					new MaxHP=War3_GetMaxHP(client);
					if(VictimCurHP>=MaxHP){
						ASPD=1.0;
					}
					else{
						new missing=MaxHP-VictimCurHP;
						new Float:percentmissing=float(missing)/float(MaxHP);
						ASPD=1.0+(0.001 + (level * 0.00005))*(percentmissing/0.01);
					}
					War3_SetBuff(client,fAttackSpeed,ItemID[ATTACKSPEED] + 9,1.0/(1.0/ASPD));
				}
			}
			else
			{
				War3_SetBuff(client,fAttackSpeed,ItemID[ATTACKSPEED] + 9,1.0);
			}
		
			if(War3_GetOwnsItem3(client,race,ItemID[REDTEARSTONE]))
			{
				new level = War3_GetItemLevel(client,race,ItemID[REDTEARSTONE])+1;
				if(level > 0)
				{
					if(RoundToNearest(TF2_GetMaxHealth(client) * (0.25 + (level * 0.02))) >= GetClientHealth(client))
					{
						War3_SetBuff(client,fDamageModifier,ItemID[REDTEARSTONE],0.151);
					}
					else
					{
						War3_SetBuff(client,fDamageModifier,ItemID[REDTEARSTONE],0.0);
					}
				}
			}
			else
			{
				War3_SetBuff(client,fDamageModifier,ItemID[REDTEARSTONE],0.0);
			}
		}
	}
}
public Action:Timer_SlowTimer(Handle:timer)
{
	for(new client = 1; client < MaxClients+1; client++)
	{
		if(ValidPlayer(client, true))
		{
			new race = War3_GetRace(client);
			GiveWindPearlPerks(client,race);
			
			if(War3_GetOwnsItem3(client,race,ItemID[FREEZE]))
			{
				War3_SetBuff(client,fBashChance,ItemID[FREEZE],0.1);
				War3_SetBuff(client,fBashDuration,ItemID[FREEZE],0.2);
			}
			else
			{
				War3_SetBuff(client,fBashChance,ItemID[FREEZE],0.0);
				War3_SetBuff(client,fBashDuration,ItemID[FREEZE],0.0);
			}
			if(War3_GetOwnsItem3(client,race,ItemID[UBERHEART]))
			{
				new level = War3_GetItemLevel(client,race,ItemID[UBERHEART])+1;
				War3_SetBuff(client,fMaxHealth,ItemID[UBERHEART],1.025 + (0.002 * level));
			}
			else
			{
				War3_SetBuff(client,fMaxHealth,ItemID[UBERHEART],1.0);
			}
			
			if(War3_GetOwnsItem3(client,race,ItemID[HEATINGPLATES]))
			{
				War3_SetBuff(client,bSlowImmunity,ItemID[HEATINGPLATES],true);
			}
			else
			{
				War3_SetBuff(client,bSlowImmunity,ItemID[HEATINGPLATES],false);
			}
		}
	}
}
GiveWindPearlPerks(client,race)
{
	if(War3_GetOwnsItem3(client,race,ItemID[WINDPEARL]))
	{
		new level = War3_GetItemLevel(client,race,ItemID[WINDPEARL])+1;
		if(level > 0)
		{
			TF2Attrib_SetByName(client,"SET BONUS: move speed set bonus", 1.06 + (level * 0.01));
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
		}
		else
		{
			TF2Attrib_RemoveByName(client,"SET BONUS: move speed set bonus");
		}
	}
}
public Action OnW3TakeDmgBulletPre(int victim, int attacker, float damage, int damagecustom)
{
	if(ValidPlayer(attacker,false) && IsValidEntity(victim) &&victim>0&&attacker>0&&attacker!=victim)
	{
		if(ValidPlayer(victim,true))
		{
			if(GetClientTeam(victim)==GetClientTeam(attacker))
			{
				return;
			}
			if(!Perplexed(victim,false))
			{
				//BLUE
				new victimrace = War3_GetRace(victim);
				if(War3_GetOwnsItem3(victim,victimrace,ItemID[BLUETEARSTONE]))
				{
					new level = War3_GetItemLevel(victim,victimrace,ItemID[BLUETEARSTONE])+1;
					if(level > 0 && RoundToNearest(TF2_GetMaxHealth(attacker) * (0.25 + (level * 0.02))) >= GetClientHealth(victim))
					{
						War3_DamageModPercent(0.9);
					}
				}
			}
		}
		//Attacker Checks.
		if(!Perplexed(attacker,false))
		{
			//RED
			new attackerrace = War3_GetRace(attacker);
			if(ValidPlayer(victim,true))
			{
				if(War3_GetOwnsItem3(attacker,attackerrace,ItemID[POISONGEM]) && GetRandomFloat(0.0,1.0)<=0.1)
				{
					new level = War3_GetItemLevel(attacker,attackerrace,ItemID[POISONGEM])+1;
					if(level > 0)
					{
						DOTStock(victim,attacker,2.0+(level*0.25),-1,0,4,0.5,1.0-(level*0.05));
					}
				}
			}
		}
	}
}
public Action OnWar3EventPostHurt(int victim, int attacker, float dmgamount, char weapon[32], bool isWarcraft, const float damageForce[3], const float damagePosition[3])
{
	if(ValidPlayer(attacker,false) && ValidPlayer(victim,false)&&victim>0&&attacker>0&&attacker!=victim)
	{
		int vteam=GetClientTeam(victim);
		int ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			//Attacker Checks.
			if(!Perplexed(attacker,false))
			{
				new attackerrace = War3_GetRace(attacker);
				//Orange
				if(War3_GetOwnsItem3(attacker,attackerrace,ItemID[MAGMACHARM]))
				{
					new level = War3_GetItemLevel(attacker,attackerrace,ItemID[MAGMACHARM])+1;
					if(level > 0 && !TF2_IsPlayerInCondition(victim, TFCond_OnFire))
					{
						TF2_IgnitePlayer(victim, attacker, 1.0);
					}
				}
			}
		}
	}
}
public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	new bool:changed = false;
	if(hitgroup == 1 && ValidPlayer(attacker,false) && ValidPlayer(victim,false))
	{
		if(!Perplexed(attacker,false))
		{
			new attackerrace = War3_GetRace(attacker);
			//Red
			if(War3_GetOwnsItem3(attacker,attackerrace,ItemID[STORMHEART]))
			{
				new level = War3_GetItemLevel(attacker,attackerrace,ItemID[STORMHEART])+1;
				if(level > 0)
				{
					damage += RoundFloat(2+(level*0.2));
					changed = true;
				}
			}
			//PURPLE
			if(War3_GetOwnsItem3(attacker,attackerrace,ItemID[MARKSMAN]))
			{
				new level = War3_GetItemLevel(attacker,attackerrace,ItemID[MARKSMAN])+1;
				if(level > 0)
				{
					War3_DealDamage(victim,RoundFloat(damage * 0.1),attacker,_,"MARKSMAN",W3DMGORIGIN_ITEM,W3DMGTYPE_PHYSICAL,_,_,true);
					changed = true;
					
					float hp_percent=0.1 + (level * 0.01);
					int add_hp=RoundFloat(damage * hp_percent);
					if(add_hp>40)	add_hp=40;
					War3_HealToBuffHP(attacker,add_hp);
				}
			}
		}
	}
	if(changed)
	{
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
//Stocks
stock TF2_GetMaxHealth(client)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(client, Prop_Data, "m_iMaxHealth") : maxhealth);
}
stock void DOTStock(int victim,int attacker,float damage,int weapon = -1,int damagetype = 1,int repeats = 1,float initialDelay = 0.0,float tickspeed = 1.0)
{
	if(ValidPlayer(victim,true) && DOTStacked[victim] == false && ValidPlayer(attacker,true))
	{
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, victim);
		WritePackCell(hPack, attacker);
		WritePackFloat(hPack, damage);
		WritePackCell(hPack, weapon);
		WritePackCell(hPack, damagetype);
		WritePackCell(hPack, repeats);
		WritePackFloat(hPack, tickspeed);
		CreateTimer(initialDelay,DOTDamage,hPack);
		DOTStacked[victim] = true;
	}
}
public Action:DOTDamage(Handle:timer,any:data)
{
	ResetPack(data);
	new victim = ReadPackCell(data);
	new attacker = ReadPackCell(data);
	new Float:damage = ReadPackFloat(data);
	new weapon = ReadPackCell(data);
	new damagetype = ReadPackCell(data);
	new repeats = ReadPackCell(data);
	new Float:tickspeed = ReadPackFloat(data);
	if(repeats >= 1)
	{
		if(ValidPlayer(victim,true) && ValidPlayer(attacker,true))
		{
			SDKHooks_TakeDamage(victim,attacker,attacker,damage,damagetype,weapon,NULL_VECTOR,NULL_VECTOR);
			repeats--;
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, victim);
			WritePackCell(hPack, attacker);
			WritePackFloat(hPack, damage);
			WritePackCell(hPack, weapon);
			WritePackCell(hPack, damagetype);
			WritePackCell(hPack, repeats);
			WritePackFloat(hPack, tickspeed);
			CreateTimer(tickspeed,DOTDamage,hPack);
		}
	}
	else
	{
		DOTStacked[victim] = false;
	}
	CloseHandle(data);
}