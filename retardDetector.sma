#include <amxmodx>
#include <amxmisc>


new g_cmdLine1[512], g_cmdLine2[512], g_cmdLine3[512], g_cmdLine4[512], g_bSuspected[33]

new const g_CheatComm[][] = {
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


public plugin_init() {
	register_plugin("Retard Detector", "1.0", "BlendeR")

}
public plugin_precache() {
	precache_sound("events/task_complete.wav")
}	

public plugin_natives() {
	register_native("set_suspected", "_set_suspected")
}

public _set_suspected(id) {
	g_bSuspected[id] = true
}

public client_disconnected(id) {
	g_bSuspected[id] = false
}

public client_command(id)
{
	new name[32]
	get_user_name(id, name, charsmax(name))
	read_argv(0, g_cmdLine1, 511)
	read_argv(1, g_cmdLine2, 511)
	read_argv(2, g_cmdLine3, 511)
	read_argv(3, g_cmdLine4, 511)
	
	for (new i = 0; i < sizeof(g_CheatComm); i++) {
		if(containi(g_cmdLine1, g_CheatComm[i]) != -1) {
			if(is_user_connected(i) && get_user_flags(i) & ADMIN_BAN){
				client_cmd(i, "spk ^"events/task_complete.wav^"" );
				client_print(i, print_chat, "[Retard] ^"%s^" uzyl komendy %s %s %s %s", name, g_cmdLine1, g_cmdLine2, g_cmdLine3, g_cmdLine4);

			}
		}
	}
	return PLUGIN_CONTINUE
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
