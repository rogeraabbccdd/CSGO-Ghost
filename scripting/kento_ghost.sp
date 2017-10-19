#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define SPEC 1
#define TR 2
#define CT 3

bool bWarmUp;

public Plugin myinfo = 
{
	name = "[CS:GO] Ghost",
	author = "Kento",
	description = "Happy Halloween",
	version = "1.0",
	url = "http://steamcommunity.com/id/kentomatoryoshika/"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	
	CreateConVar("sm_ghost_time", "0.0", "Ghost appear time, 0.0 = Disappear in next round start.", FCVAR_NOTIFY, true, 0.0);
	CreateConVar("sm_ghost_warmup", "0", "Ghost appear in warmup? 1 = yes, 0 = no", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar("sm_ghost_warmup_time", "10.0", "Ghost appear time in warmup. 0.0 = Forever.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar("sm_ghost_team_color", "0", "Set ghost color depending on client team? 1 = yes, 0 = no", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "kento_ghost");
}

public void OnMapStart()
{
	AddFileToDownloadsTable("particles/ghosts.pcf");
	AddFileToDownloadsTable("materials/effects/largesmoke.vmt");
	AddFileToDownloadsTable("materials/effects/largesmoke.vtf");
	AddFileToDownloadsTable("materials/effects/animatedeyes/animated_eyes.vmt");
	AddFileToDownloadsTable("materials/effects/animatedeyes/animated_eyes.vtf");
	
	PrecacheGeneric("particles/ghosts.pcf", true);
	PrecacheEffect("ParticleEffect");
	PrecacheParticleEffect("Ghost_Cyan");
	PrecacheParticleEffect("Ghost_Green");
	PrecacheParticleEffect("Ghost_Red");
	PrecacheParticleEffect("Ghost_Orange");
}

// https://forums.alliedmods.net/showpost.php?p=2471747&postcount=4
stock void PrecacheEffect(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("EffectDispatch");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}

stock void PrecacheParticleEffect(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("ParticleEffectNames");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}  

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidClient(victim))	return;
	
	// In warmup and ghost disable in warmup.
	if (bWarmUp && !GetConVarBool(FindConVar("sm_ghost_warmup")))	return;
	
	int m_unEnt = CreateEntityByName("info_particle_system");
	
	if (IsValidEntity(m_unEnt))
	{
		DispatchKeyValue(m_unEnt, "start_active", "1");
		
		if(GetConVarBool(FindConVar("sm_ghost_team_color")))
		{
			if(GetClientTeam(victim) == TR)	DispatchKeyValue(m_unEnt, "effect_name", "Ghost_Red");
			else if(GetClientTeam(victim) == CT)	DispatchKeyValue(m_unEnt, "effect_name", "Ghost_Cyan");
		}
		else if(!GetConVarBool(FindConVar("sm_ghost_team_color")))
		{
			switch(GetRandomInt(1, 4))
			{
				case 1:
				{
					DispatchKeyValue(m_unEnt, "effect_name", "Ghost_Cyan");
				}
				case 2:
				{
					DispatchKeyValue(m_unEnt, "effect_name", "Ghost_Green");
				}
				case 3:
				{
					DispatchKeyValue(m_unEnt, "effect_name", "Ghost_Red");
				}
				case 4:
				{
					DispatchKeyValue(m_unEnt, "effect_name", "Ghost_Orange");
				}
			}
		}
		
		DispatchSpawn(m_unEnt);
		
		float m_flPosition[3];
		GetClientAbsOrigin(victim, m_flPosition);
		m_flPosition[2] -= 50.0;

		TeleportEntity(m_unEnt, m_flPosition, NULL_VECTOR, NULL_VECTOR);
		
		ActivateEntity(m_unEnt);
		AcceptEntityInput(m_unEnt, "Start");
	}
	
	if(GetConVarFloat(FindConVar("sm_ghost_time")) > 0.0 && !bWarmUp)
		CreateTimer(GetConVarFloat(FindConVar("sm_ghost_time")), KillGhost, m_unEnt);
	
	if(GetConVarFloat(FindConVar("sm_ghost_warmup_time")) > 0.0 && bWarmUp)
		CreateTimer(GetConVarFloat(FindConVar("sm_ghost_warmup_time")), KillGhost, m_unEnt);
}

public Action KillGhost(Handle tmr, int entity)
{
	if(!IsValidEntity(entity))	return;
		
	AcceptEntityInput(entity, "DestroyImmediately");
	CreateTimer(0.1, KillGhostParticle, entity); 
}

public Action KillGhostParticle(Handle timer, int entity)
{
	if(IsValidEntity(entity))	AcceptEntityInput(entity, "kill");
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public void OnGameFrame()
{
	if(GameRules_GetProp("m_bWarmupPeriod") == 1)	bWarmUp = true;
	else bWarmUp = false;
}