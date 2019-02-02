#include <amxmodx>
#include <amxmisc>
#include <ColorChat>

#define MAXP 32 + 1

new g_cmdLine1[512], g_cmdLine2[512], g_cmdLine3[512], g_cmdLine4[512], g_bSuspected[33]
new bool:block[33];
new g_AdminChatFlag = ADMIN_CHAT;
new name[32];

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

public plugin_init() {
	register_plugin("Retard Detector", "1.0", "BlendeR")
	register_event("HLTV", "NR", "a", "1=0", "2=0")
	new str[1]
	new admin_chat_id
	get_concmd(admin_chat_id, str, 0, g_AdminChatFlag, str, 0, -1)
}

public plugin_natives() {
	register_native("set_suspected", "_set_suspected")
}
public NR(id)
{
	block[id] = false;
}
public _set_suspected(id) {
	g_bSuspected[id] = true
}

public client_disconnected(id) {
	g_bSuspected[id] = false
}

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
				ColorChat(i, GREY,"[Retard] %s uzyl komendy %s %s %s %s", name, g_cmdLine1, g_cmdLine2, g_cmdLine3, g_cmdLine4);
				return PLUGIN_CONTINUE
			}
			else
			{
			}
		return PLUGIN_CONTINUE			
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
