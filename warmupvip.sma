#include <amxmodx>  
#include <amxmisc>  
#include <hamsandwich>  
#include <cstrike>  
#include <ColorChat> 
#include <fun>

#define PLUGIN "WarmUp + Vip4BestPlayer"
#define VERSION "1.2"
#define AUTHOR "BlendeR"

#define TIMER_TASK        123456
#define RESTART_TASK      789123
#define FLAGA_VIP ADMIN_LEVEL_H
#define LOSOWANIE_VIP_OD 4

new g_counter  

new g_autorestart
new g_autoenabled
new g_speak
new p_players

new g_SyncRestartTimer

new g_iKills[32];
new g_iHS[32];
new g_iDmg[32];

new iPlayer;
new tmp; 
new warmup;
new oldfreezetime;

new r_weapon;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("TextMsg","RestartTask","a","2&#Game_C")  
	RegisterHam(Ham_Killed, "player", "HamKilledPost", 1);
	register_event("ResetHUD", "ResetHud", "be");
	oldfreezetime =get_cvar_num("mp_freezetime")
	g_autoenabled = register_cvar("amx_warmup_enable","1")
	g_speak = register_cvar("amx_warmup_cds","1")
	g_autorestart = register_cvar("amx_warmup_time","120")
	p_players = register_cvar("amx_warmup_vip_min_players","3")
	g_SyncRestartTimer = CreateHudSyncObj()
	set_task(30.0, "RemVip", .flags="d")
}
public client_disconnect(id)  
{  
	g_iDmg[id] = 0;  
	g_iKills[id] = 0;  
	g_iHS[id] = 0;
	
	if(id == iPlayer){
		remove_user_flags(iPlayer, tmp)
	}
} 
public RestartTask() 
{
	if(!get_pcvar_num(g_autoenabled))
		return PLUGIN_HANDLED
	
	warmup=1
	set_cvar_num("mp_freezetime",0)
	r_weapon = random_num(1, 11)
	set_task(1.0,"TimeCounter",TIMER_TASK,_,_,"a",get_pcvar_num(g_autorestart))
	set_task(get_pcvar_float(g_autorestart),"RestartRound",RESTART_TASK)
	
	return PLUGIN_CONTINUE
}

public TimeCounter() 
{
	g_counter++
	
	new Float:iRestartTime = get_pcvar_float(g_autorestart) - g_counter
	new Float:fSec
	fSec = iRestartTime 
	
	set_hudmessage( random(256), random(256), random(256), -1.0 , 0.25, 0, 0.0, 1.0, 0.0, 0.0, -1)
	ShowSyncHudMsg( 0, g_SyncRestartTimer, "Rozgrzewka^nCzas: %d ", floatround(fSec))
	
	if(get_pcvar_num(g_speak) && get_pcvar_num(g_autorestart) - g_counter < 11 && get_pcvar_num(g_autorestart) - g_counter !=0)
	{
		static szNum[32]
		num_to_word(get_pcvar_num(g_autorestart) - g_counter, szNum, 31)
		client_cmd(0,"speak ^"vox/%s^"", szNum)
	}
	if(g_counter == get_pcvar_num(g_autorestart))
	{
		g_counter = 0
	}
}

public RestartRound() 
{
	warmup=0
	set_cvar_num("mp_freezetime",oldfreezetime)
	for(new i; i < 31; i++)  
	{  
		g_iDmg[i] = 0;  
		g_iHS[i] = 0;  
		g_iKills[i] = 0;  
	}  
	server_cmd("sv_restartround 1")
	iPlayer = get_best_player() 
	new Name[32];
	
	get_user_name(iPlayer, Name, charsmax(Name))
	set_user_flags(iPlayer, get_user_flags(iPlayer) | FLAGA_VIP);
	if(get_playersnum()>= LOSOWANIE_VIP_OD){
		if(get_user_flags(iPlayer) & FLAGA_VIP){
			ColorChat(0, RED, "[WarmUp]^x01 Wygral %s, lecz posiada juz vipa! " ,Name);
			return PLUGIN_HANDLED
		}
		
		
		ColorChat(0, RED, "[WarmUp]^x01Rozgrzewke jak i VIPa na mape wygral %s Gratulacje!", Name)  
	}
	return PLUGIN_CONTINUE;
}

public hamTakeDamage(victim, inflictor, attacker, Float:damage, DamageBits)  
{  
	if( 1 <= attacker <= 32)  
	{  
		if(cs_get_user_team(victim) != cs_get_user_team(attacker))  
			g_iDmg[attacker] += floatround(damage)  
		else  
			g_iDmg[attacker] -= floatround(damage)  
	}  
}  
public EventDeathMsg()  
{  
	new killer = read_data(1)  
	new victim = read_data(2)  
	new is_hs = read_data(3)  
	
	if(killer != victim && killer && cs_get_user_team(killer) != cs_get_user_team(victim))  
	{  
		g_iKills[killer]++;  
		
		if(is_hs)  
			g_iHS[killer]++;  
	}  
	else  
		g_iKills[killer]--;  
}  
get_best_player()  
{  
new players[32], num;  
get_players(players, num);  
SortCustom1D(players, num, "sort_bestplayer")  

return players[0]  
}  
public sort_bestplayer(id1, id2)  
{  
if(g_iKills[id1] > g_iKills[id2])  
	return -1;  
	else if(g_iKills[id1] < g_iKills[id2])  
		return 1;  
	else  
	{  
		if(g_iDmg[id1] > g_iDmg[id2])  
			return -1;  
		else if(g_iDmg[id1] < g_iDmg[id2])  
			return 1;  
		else  
			return 0;  
	}  
return PLUGIN_CONTINUE;
}
public RemVip(){
	ColorChat(iPlayer, TEAM_COLOR, "[WarmUp] Vip zostal usuniety.");
	remove_user_flags(iPlayer, tmp);
}
public HamKilledPost(victim){
	new data[1];
	data[0]=victim;
	set_task(1.0, "ressurect", .parameter=data, .len=1);
}

public ressurect(data[]){
	new victim=data[0]; 
	if(warmup==1&&get_playersnum() < p_players)
	{ 
		ExecuteHamB(Ham_CS_RoundRespawn, victim);
	}
}
public ResetHud(id)
{
	if(warmup)
	{
		set_task(0.5, "task_give", id);
	} 
}
public task_give(id)
{
	if (!is_user_alive(id))
		return;
	strip_user_weapons(id);
	switch(r_weapon)
	{
		case 1 :
		{
			cs_set_user_money (id , 0);
			give_item(id, "weapon_scout");
			cs_set_user_bpammo(id, CSW_SCOUT, 90);
			give_item(id,"ammo_762nato");
			give_item(id,"ammo_762nato");
			give_item(id,"ammo_762nato");
		}
		case 2 :
		{
			cs_set_user_money (id , 0);
			give_item(id, "weapon_galil");
			cs_set_user_bpammo(id, CSW_GALIL, 90);
			give_item(id,"ammo_556nato");
			give_item(id,"ammo_556nato");
			give_item(id,"ammo_556nato");
		}
		case 3 :
		{
			cs_set_user_money (id , 0);
			give_item(id, "weapon_famas");
			cs_set_user_bpammo(id, CSW_FAMAS, 90);
			give_item(id,"ammo_556nato");
			give_item(id,"ammo_556nato");
			give_item(id,"ammo_556nato");
		}
		case 4 :
		{
			cs_set_user_money (id , 0); 
			give_item(id, "weapon_usp");
			cs_set_user_bpammo(id, CSW_USP, 90);
			give_item(id,"ammo_45acp");
			give_item(id,"ammo_45acp");
			give_item(id,"ammo_45acp");
			give_item(id,"ammo_45acp");
			give_item(id,"ammo_45acp");
			give_item(id,"ammo_45acp");
			give_item(id,"ammo_45acp");
			give_item(id,"ammo_45acp");
			give_item(id,"ammo_45acp");
		}
		case 5 :
		{
			cs_set_user_money (id , 0); 
			give_item(id, "weapon_glock18");
			cs_set_user_bpammo(id, CSW_GLOCK18, 90);
			give_item(id,"ammo_9mm");
			give_item(id,"ammo_9mm");
			give_item(id,"ammo_9mm");
			give_item(id,"ammo_9mm");
		}
		case 6 :
		{
			cs_set_user_armor (id, 100, CS_ARMOR_VESTHELM);
			cs_set_user_money (id , 0);
			give_item(id, "weapon_awp");
			cs_set_user_bpammo(id, CSW_AWP, 90)
			give_item(id,"ammo_338magnum");
			give_item(id,"ammo_338magnum");
			give_item(id,"ammo_338magnum");
		}
		case 7 :
		{
			cs_set_user_money (id , 0); 
			give_item(id, "weapon_mp5navy");
			cs_set_user_bpammo(id, CSW_MP5NAVY, 90)
			give_item(id,"ammo_9mm");
			give_item(id,"ammo_9mm");
			give_item(id,"ammo_9mm");
			give_item(id,"ammo_9mm");
		}
		case 8 :
		{
			cs_set_user_money (id , 0); 
			give_item(id, "weapon_m4a1");
			cs_set_user_bpammo(id, CSW_M4A1, 90)
			give_item(id,"ammo_556nato");
			give_item(id,"ammo_556nato");
			give_item(id,"ammo_556nato");
		}
		case 9 :
		{
			cs_set_user_money (id , 0); 
			give_item(id, "weapon_deagle");
			cs_set_user_bpammo(id, CSW_DEAGLE, 35);
			give_item(id,"ammo_50ae");
			give_item(id,"ammo_50ae");
			give_item(id,"ammo_50ae");
			give_item(id,"ammo_50ae");
			give_item(id,"ammo_50ae");
		}
		case 10 :
		{
			cs_set_user_armor (id, 100, CS_ARMOR_VESTHELM);
			cs_set_user_money (id , 0);
			give_item(id, "weapon_ak47");
			cs_set_user_bpammo(id, CSW_AK47, 90)
			give_item(id,"ammo_762nato")
			give_item(id,"ammo_762nato")
			give_item(id,"ammo_762nato")
		}
		case 11 :
		{
			cs_set_user_money (id , 0);
			give_item(id, "weapon_knife");
		}
	}
}