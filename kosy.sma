#include <amxmodx>
#include <amxmisc>
#include <engine> 
#include <vault>
#include <fun>

#define PLUGIN "Kosy"
#define VERSION "1.0" 
#define AUTHOR "BlendeR"
 

new knife_model[33] 
new g_Menu


public plugin_init() { 
	
	register_plugin(PLUGIN, VERSION, AUTHOR) 
	g_Menu = register_menuid("Knife Mod")
	register_menucmd(g_Menu, 1023, "knifemenu")
	register_event("CurWeapon","CurWeapon","be","1=1") 
	register_clcmd("say /knife", "display_knife")
	register_clcmd("say_team /knife", "display_knife")
	register_clcmd("say /kosa", "display_knife")
	register_clcmd("say_team /kosa", "display_knife")
}

public plugin_precache() { 
	precache_model("models/kosy/v_bayo.mdl") 
	precache_model("models/kosy/v_butt.mdl")
	precache_model("models/kosy/v_flip.mdl") 
	precache_model("models/kosy/v_gut.mdl")
	precache_model("models/kosy/v_hunt.mdl")
	precache_model("models/kosy/v_kar.mdl")
	precache_model("models/kosy/v_m9.mdl") 
	precache_model("models/v_knife.mdl")
	precache_model("models/p_knife.mdl")
} 

public display_knife(id) {
	new menuBody[512]
	add(menuBody, 511, "\rWybor Kosy\w^n^n")
	add(menuBody, 511, "\r1.\w Domyslny Noz^n")
	add(menuBody, 511, "\r2.\w Bayonet^n")
	add(menuBody, 511, "\r3.\w Butterfly^n")
	add(menuBody, 511, "\r4.\w Flip^n")
	add(menuBody, 511, "\r5.\w Gut^n")
	add(menuBody, 511, "\r6.\w Huntsman^n")
	add(menuBody, 511, "\r7.\w Karambit \r(VIP)\w^n")
	add(menuBody, 511, "\r8.\w M9 \r(VIP)\w^n")
	add(menuBody, 511, "\r0.\w Wyjdz^n")
	
	new keys = ( 1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<4 | 1<<5 | 1<<6 | 1<<7 | 1<<8 |1<<9 )
	show_menu(id, keys, menuBody, -1, "Knife Mod")
}

public knifemenu(id, key) {
	switch(key) 
	{
		case 0: SetKnife(id , 0)
		case 1: SetKnife(id , 1)
		case 2: SetKnife(id , 2)
		case 3: SetKnife(id , 3)
		case 4: SetKnife(id , 4)
		case 5: SetKnife(id , 5)
		case 6: if(has_flag(id,"t,s")) 
			{
				SetKnife(id , 6)
			}
			else
			{
				client_print(0,print_chat,"[AMXX] Ta kosa jest tylko dla vipow!")
				SetKnife(id , 0)
			}
		case 7: if(has_flag(id,"t,s")) 
			{
				SetKnife(id , 7)
			}
			else
			{
				client_print(0,print_chat,"[AMXX] Ta kosa jest tylko dla vipow!")
				SetKnife(id , 0)
			}
		case 8: SetKnife(id , 8)
		default: return PLUGIN_HANDLED
	}
} 

public CurWeapon(id)
	{
	new Weapon = read_data(2)	
	// Set Knife Model
	SetKnife(id, knife_model[id])   
	
	return PLUGIN_HANDLED   
	
}

public SetKnife(id , Knife) {
	knife_model[id] = Knife
	
	new Clip, Ammo, Weapon = get_user_weapon(id, Clip, Ammo) 
	if ( Weapon != CSW_KNIFE )
		return PLUGIN_HANDLED
	
	new vModel[56],pModel[56]
	
	switch(Knife)
	{
		case 0: {
			format(vModel,55,"models/v_knife.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 1: {
			format(vModel,55,"models/kosy/v_bayo.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 2: {
			format(vModel,55,"models/kosy/v_butt.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 3: {
			format(vModel,55,"models/kosy/v_flip.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 4: {
			format(vModel,55,"models/kosy/v_gut.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 5: {
			format(vModel,55,"models/kosy/v_hunt.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 6: {
			format(vModel,55,"models/kosy/v_kar.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
		case 7: {
			format(vModel,55,"models/kosy/v_m9.mdl")
			format(pModel,55,"models/p_knife.mdl")
		}
	} 
	
	entity_set_string(id, EV_SZ_viewmodel, vModel)
	entity_set_string(id, EV_SZ_weaponmodel, pModel)
	
	return PLUGIN_HANDLED;  
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
