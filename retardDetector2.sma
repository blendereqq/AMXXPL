#include <amxmodx>
#include <amxmisc>
#include <ColorChat>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>
#include <cstrike>

#define MAXP 32 + 1

new g_cmdLine1[512], g_cmdLine2[512], g_cmdLine3[512], g_cmdLine4[512], g_bSuspected[33]
new bool:block[33],name[32];
new kills[33], hs_kills[33], damage[33], hs_streak[33], bool:scanned[33];
new g_AdminChatFlag = ADMIN_CHAT;
new g_iLaser;
new bool:g_bAdmin[33];
new bool:g_IsAlive[33];
new bool:espON[MAXP];

new const g_CheatCvar[][] = {
	"xScript",
	"xHack_",
	"superstref",
	"jumpbug",
	"xdaa",
	"bog",
	"gstrafe",
	"ground",
	"weapon.",
	"set",
	"trigger_",
	"esp_",
	"knf_",
	"misc_",
	"aim_",
	"setburst",
	"superstref",
	"booster_",
	"avecc_",
	"aimbot.",
	"trigger.",
	"antirecoil.",
	"Aimbot_",
	"ESPBox_",
	"CrossHair_",
	"BunnyHop_"
}

new const g_Niepokazuj[][] =  
{
	"chooseteam",
	"menuselect", 
	"say",
	"jointeam",
	"+setlaser",
	"-setlaser",
	"spec_set_ad",
	"cl_setrebuy",
	"cl_setautobuy"
}

public plugin_precache()
	g_iLaser = precache_model("sprites/laserbeam.spr");

public plugin_init() {
	register_plugin("Retard Detector DEV", "1.1", "BlendeR")
	register_clcmd( "say /esp" , "espONOFF" );
	
	new str[1]
	new admin_chat_id
	get_concmd(admin_chat_id, str, 0, g_AdminChatFlag, str, 0, -1)
	
	register_event("DeathMsg", "eDeathMsg", "a", "1>0");
	register_event("ResetHUD", "eResetHud", "be");
	register_event("TextMsg", "eSpecMode", "b", "2&#Spec_M");
	register_event("HLTV", "NR", "a", "1=0", "2=0")
	
	register_logevent("Wall_Kills", 2, "1=Round_End");
	
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack");
}
/*
public plugin_natives() {
	register_native("set_suspected", "_set_suspected")
}*/

public plugin_end()
{
	new pl[32], pnum; get_players(pl, pnum);
	for(new i; i < pnum; i++)
		remove_task(pl[i]);
}	

public client_putinserver(id)
{
	g_bAdmin[id]  = (get_user_flags(id) & ADMIN_KICK) ? true : false;
	g_IsAlive[id] = false;
}

public NR(id)
{
	block[id] = false;
}
public _set_suspected(id) {
	g_bSuspected[id] = true
}

public client_connect( id ){
	espON[ id ] = false;
	kills[id] = 0;
	hs_kills[id] = 0;
	damage[id] = 0;
	scanned[id] = false;
}

public client_disconnected(id) {
	g_bSuspected[id] = false
	
	if(g_bAdmin[id])
		remove_task(id);
}
// Detekcja Wpisywania Komendy
public client_command(id)
{
	get_user_name(id, name, charsmax(name))
	read_argv(0, g_cmdLine1, 511)
	read_argv(1, g_cmdLine2, 511)
	read_argv(2, g_cmdLine3, 511)
	read_argv(3, g_cmdLine4, 511)
	
	if(!g_bSuspected[id]) {
		for (new i = 0; i < sizeof(g_Niepokazuj); i++) {
			if(containi(g_cmdLine1, g_Niepokazuj[i]) != -1) {
				return PLUGIN_CONTINUE
			}
		}
	}
	
	for (new i = 0; i < sizeof(g_CheatCvar); i++) {
	if(containi(g_cmdLine1, g_CheatCvar[i]) != -1) {
		powiadomienie(id);
		}
		
	}
	return PLUGIN_CONTINUE
}
public powiadomienie(id){
		for(new i; i < MAXP; i++)
		if(is_user_connected(i))	
			if(get_user_flags(i) & ADMIN_LEVEL_A){
				ColorChat(i, GREY,"^x04[Retard]^x01 Gracz^x03 %s ^x01 uzyl komendy ^x04 %s %s %s %s", name, g_cmdLine1, g_cmdLine2, g_cmdLine3, g_cmdLine4);
				return PLUGIN_CONTINUE
			}
			else
			{
			}
		return PLUGIN_CONTINUE			
}
// Koniec Detekcji Wpisywania Komendy
// Detekcja Walla
public Wall_Kills()
{
	for(new id = 1; id <= get_playersnum(); id++){
		if(kills[id] >= 2){
			new name[33];
			get_user_name(id, name, charsmax(name));
			for(new player = 1; player <= get_playersnum(); player++){
				if(is_user_connected(player) && !is_user_bot(player) && !is_user_hltv(player) && get_user_flags(player) & ADMIN_BAN){
					ColorChat(player, GREY, "^x04[Retard]^x01 Gracz^x03 %s^x01 w tej rundzie skanujac zabil^x04 %i^x01 (w tym^x04 %i^x01 z HS)!", name, kills[id], hs_kills[id]);
					continue;
				}
			}
		}
		else if(damage[id] >= 200){
			new name[33];
			get_user_name(id, name, charsmax(name));
			for(new player = 1; player <= get_playersnum(); player++){
				if(is_user_connected(player) && !is_user_bot(player) && !is_user_hltv(player) && get_user_flags(player) & ADMIN_BAN){
					ColorChat(player, GREY, "^x04[Retard]^x01 Gracz^x03 %s^x01 w tej rundzie skanujac zadal^x04 %i^x01 obrazen!", name, damage[id]);
					continue;
				}
			}
		}

		kills[id] = 0;
		hs_kills[id] = 0;
		damage[id] = 0;
		scanned[id] = false;
	}
}

public TraceAttack(iVictim, iAttacker, Float:flDamage, Float:vDirection[3], ptr, Bits)
{
	if(!is_user_alive(iAttacker) || get_user_weapon(iAttacker) == CSW_KNIFE || get_user_flags(iAttacker) & ADMIN_BAN)
		return HAM_IGNORED;
		
	static Float:vStart[3], Float:vEnd[3], Float:flFraction;
		
	get_tr2(ptr, TR_vecEndPos, vEnd);
	get_tr2(ptr, TR_flFraction, flFraction);
		
	xs_vec_mul_scalar(vDirection, -1.0, vDirection);
	xs_vec_mul_scalar(vDirection, flFraction * 9999.0, vStart);
	xs_vec_add(vStart, vEnd, vStart);
		
	new iTarget = trace_line(iVictim, vEnd, vStart, vEnd);
		
	if(!iTarget){
		scanned[iVictim] = true;
		damage[iAttacker] += floatround(flDamage);
	}
	else
		scanned[iVictim] = false;

	return HAM_IGNORED;
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if(killer == victim  || get_user_flags(killer) & ADMIN_BAN)
		return;
		
	if(scanned[victim])
	{
		kills[killer]++;
		if(hitplace == HIT_HEAD)
			hs_kills[killer]++;
	}
		
	if(hitplace == HIT_HEAD)
	{
		hs_streak[killer]++;
		if(hs_streak[killer] >= 5 && hs_streak[killer]%2 != 0)
		{
			new name[33];
			get_user_name(killer, name, charsmax(name));
			for(new player = 1; player <= get_playersnum(); player++){
				if(is_user_connected(player) && !is_user_bot(player) && !is_user_hltv(player) && get_user_flags(player) & ADMIN_BAN){
					ColorChat(player, GREY, "^x04[Retard]^x01 Gracz^x03 %s^x01 zabil z HS^x04 %i^x01 z rzedu!", name, hs_streak[killer]);
					continue;
				}
			}
		}
	}
	else
		hs_streak[killer] = 0;
}
// Koniec Detekcji Walla
//ESP
 
public espONOFF( id ){
	if( !( get_user_flags( id ) & ADMIN_BAN ) ){
		return PLUGIN_HANDLED;
	}
	
	espON[ id ]	=	!espON[ id ];
	if(espON[ id ]){
		ColorChat(id, GREY,"[Retard] ESP ON");
				
	}
	else{
		ColorChat(id, GREY,"[Retard] ESP OFF");
	}
	return PLUGIN_HANDLED;
}

 public eDeathMsg()
	g_IsAlive[read_data(2)] = false;

public eResetHud(id)
	g_IsAlive[id] = true;

public eSpecMode(id)
{
	if(!g_bAdmin[id]) return;

	if(entity_get_int(id, EV_INT_iuser1) == 4)
		set_task(0.3, "EspTimer", id, .flags="b");
	else
		remove_task(id);
}

public EspTimer(id)
{
	switch(g_IsAlive[id])
	{
		case false:
		{
			
			static iTarget; iTarget = entity_get_int(id, EV_INT_iuser2);

			if(iTarget && is_user_alive(iTarget) && is_valid_ent(iTarget) && espON[ id ])
				SendQuadro(id, iTarget);
		}
		case true: remove_task(id);
		
	}	
}

SendQuadro(id, iTarget)
{
	static pl[32], pnum, my_team;
	static Float:my_origin[3], Float:target_origin[3], Float:v_middle[3], Float:v_hitpoint[3];
	static Float:distance, Float:distance_to_hitpoint, Float:distance_target_hitpoint, Float:scaled_bone_len;
	static Float:v_bone_start[3], Float:v_bone_end[3], Float:offset_vector[3], Float:eye_level[3];

	entity_get_vector(iTarget, EV_VEC_origin, my_origin);
	my_team = get_user_team(iTarget);
	get_players(pl, pnum, "ah");
	for(new i; i < pnum; i++)
	{
		if(pl[i] == iTarget) continue;
		if(my_team == get_user_team(pl[i])) continue;

		entity_get_vector(pl[i], EV_VEC_origin, target_origin);
		distance = vector_distance(my_origin, target_origin);

		trace_line(-1, my_origin, target_origin, v_hitpoint);
		
		subVec(target_origin, my_origin, v_middle);
		normalize(v_middle, offset_vector, (distance_to_hitpoint = vector_distance(my_origin, v_hitpoint)) - 10.0);

		copyVec(my_origin, eye_level);
		eye_level[2] += 17.5;
		addVec(offset_vector, eye_level);

		copyVec(offset_vector, v_bone_start);
		copyVec(offset_vector, v_bone_end);
		v_bone_end[2] -= (scaled_bone_len = distance_to_hitpoint / distance * 50.0);

		if(distance_to_hitpoint == distance)
			continue;
		
		distance_target_hitpoint = (distance - distance_to_hitpoint) / 12;
		MakeQuadrate(id, v_bone_start, v_bone_end, floatround(scaled_bone_len * 3.0), (distance_target_hitpoint < 170.0) ? (255 - floatround(distance_target_hitpoint)) : 85)
	}
}

stock normalize(Float:Vec[3], Float:Ret[3], Float:multiplier)
{
	static Float:len; len = vector_distance(Vec, Float:{ 0.0, 0.0, 0.0 });
	copyVec(Vec, Ret);

	Ret[0] /= len;
	Ret[1] /= len;
	Ret[2] /= len;
	Ret[0] *= multiplier;
	Ret[1] *= multiplier;
	Ret[2] *= multiplier;
}

stock copyVec(Float:Vec[3], Float:Ret[3])
{
	Ret[0] = Vec[0];
	Ret[1] = Vec[1];
	Ret[2] = Vec[2];
}

stock subVec(Float:Vec1[3], Float:Vec2[3], Float:Ret[3])
{
	Ret[0] = Vec1[0] - Vec2[0];
	Ret[1] = Vec1[1] - Vec2[1];
	Ret[2] = Vec1[2] - Vec2[2];
}

stock addVec(Float:Vec1[3], Float:Vec2[3])
{
	Vec1[0] += Vec2[0];
	Vec1[1] += Vec2[1];
	Vec1[2] += Vec2[2];
}

MakeQuadrate(id, Float:Vec1[3], Float:Vec2[3], width, brightness)
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, id);
	write_byte(0);
	write_coord(floatround(Vec1[0]));
	write_coord(floatround(Vec1[1]));
	write_coord(floatround(Vec1[2]));
	write_coord(floatround(Vec2[0]));
	write_coord(floatround(Vec2[1]));
	write_coord(floatround(Vec2[2]));
	write_short(g_iLaser);
	write_byte(3);
	write_byte(0);
	write_byte(3);
	write_byte(width);
	write_byte(0);
	static iTarget; iTarget = entity_get_int(id, EV_INT_iuser2);
	if(cs_get_user_team(iTarget) == CS_TEAM_T)
	{
		write_byte(0);
		write_byte(0);
		write_byte(255);
	}
	else if(cs_get_user_team(iTarget) == CS_TEAM_CT)
	{
		write_byte(255);
		write_byte(0);
		write_byte(0);
	}
	else
	{
		write_byte(0);
		write_byte(0);
		write_byte(0);
	}
	write_byte(brightness);
	write_byte(0);
	message_end();
}
// Koniec ESP
 
 
 
 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
