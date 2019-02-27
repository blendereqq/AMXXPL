#include <amxmodx>
#include <amxmisc>
#include <engine> 
#include <nvault>
#include <fun>
#include <fakemeta>
#include <cstrike>


#define PLUGIN "Kosy"
#define VERSION "1.0" 
#define AUTHOR "BlendeR"

/*
Knife Menu z Animacj¹ podgl¹du kosy pod f i zapisem nvault ostatniej kosy
Paczka Modeli - blendereqq.000webhostapp.com/pliki/kosyv2.zip
*/

new knife_model[33] ;
new g_Menu;
new g_vault;

stock PlayAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player);
	write_byte(Sequence);
	write_byte(pev(Player, pev_body));
	message_end();
}

public plugin_init() { 
	
	register_plugin(PLUGIN, VERSION, AUTHOR) 
	g_Menu = register_menuid("Knife Mod")
	register_menucmd(g_Menu, 1023, "knifemenu")
	register_impulse(100, "SkinCheck");
	register_event("CurWeapon","CurWeapon","be","1=1") 
	register_clcmd("say /knife", "display_knife")
	register_clcmd("say_team /knife", "display_knife")
	register_clcmd("say /kosa", "display_knife")
	register_clcmd("say_team /kosa", "display_knife")
}

public plugin_cfg()
{
	g_vault = nvault_open("Kosy");
	
	if(g_vault == INVALID_HANDLE)
	{
		set_fail_state("Error opening nVault");
	}
}

public plugin_end()
	nvault_close(g_vault)

public client_putinserver(id)
	LoadData(id)

public client_disconnect(id)
{
	new authid[35]
	get_user_authid(id, authid, charsmax(authid))
	
	SaveData(id, authid)
}

public plugin_precache() { 
	precache_model("models/kosy/v_bayo_def.mdl") 
	precache_model("models/kosy/v_bayo_sl.mdl") 
	precache_model("models/kosy/v_butt_def.mdl")
	precache_model("models/kosy/v_butt_crim.mdl")
	precache_model("models/kosy/v_flip_def.mdl") 
	precache_model("models/kosy/v_flip_ruby.mdl")
	precache_model("models/kosy/v_falc_def.mdl") 
	precache_model("models/kosy/v_falc_gamma.mdl") 
	precache_model("models/kosy/v_kara_def.mdl") 
	precache_model("models/kosy/v_kara_fade.mdl")
	precache_model("models/kosy/v_m9_def.mdl") 
	precache_model("models/kosy/v_m9_mar.mdl") 
	precache_model("models/kosy/p_bayonet.mdl")
	precache_model("models/kosy/p_butterfly.mdl")
	precache_model("models/kosy/p_falchion.mdl")
	precache_model("models/kosy/p_flip.mdl")
	precache_model("models/kosy/p_karambit.mdl")
	precache_model("models/kosy/p_m9.mdl")
} 

public display_knife(id) {
	new menuBody[512]
	add(menuBody, 511, "\rKnife Skin\w^n^n")
	add(menuBody, 511, "\r1.\w Default^n")
	add(menuBody, 511, "\r2.\w Bayonet^n")
	add(menuBody, 511, "\r3.\w Butterfly^n")
	add(menuBody, 511, "\r4.\w Flip^n")
	add(menuBody, 511, "\r5.\w Falchion^n")
	add(menuBody, 511, "\r6.\w Karambit^n")
	add(menuBody, 511, "\r7.\w M9 ^n")
	add(menuBody, 511, "\r0.\w Wyjdz^n")
	
	new keys = ( 1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<4 | 1<<5 | 1<<6 | 1<<7  |1<<9 )
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
			case 6: SetKnife(id , 6)
			
		default: return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
} 
public CurWeapon(id)
{
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
			if(has_flag(id,"t,s")) {
				format(vModel,55,"models/kosy/v_bayo_sl.mdl")
				format(pModel,55,"models/kosy/p_bayonet.mdl")
			}
			else
			{
				format(vModel,55,"models/kosy/v_bayo_def.mdl")
				format(pModel,55,"models/kosy/p_bayonet.mdl")
			}
		}
		case 2: {
			if(has_flag(id,"t,s")) {
				format(vModel,55,"models/kosy/v_butt_crim.mdl")
				format(pModel,55,"models/kosy/p_butterfly.mdl")
			}
			else
			{
				format(vModel,55,"models/kosy/v_butt_def.mdl")
				format(pModel,55,"models/kosy/p_butterfly.mdl")
			}
		}
		case 3: {
			if(has_flag(id,"t,s")) {
				format(vModel,55,"models/kosy/v_flip_ruby.mdl")
				format(pModel,55,"models/kosy/p_flip.mdl")
			}
			else
			{
				format(vModel,55,"models/kosy/v_flip_def.mdl")
				format(pModel,55,"models/kosy/p_flip.mdl")
			}
		}
		case 4: {
			if(has_flag(id,"t,s")) {
				format(vModel,55,"models/kosy/v_falc_gamma.mdl")
				format(pModel,55,"models/kosy/p_falchion.mdl")
			}
			else
			{
				format(vModel,55,"models/kosy/v_falc_def.mdl")
				format(pModel,55,"models/kosy/p_falchion.mdl")
			}
		}
		case 5: {
			if(has_flag(id,"t,s")) {
				format(vModel,55,"models/kosy/v_kara_fade.mdl")
				format(pModel,55,"models/kosy/p_falchion.mdl")
			}
			else
			{
				format(vModel,55,"models/kosy/v_kara_def.mdl")
				format(pModel,55,"models/kosy/p_karambit.mdl")
			}
		}
		case 6: {
			if(has_flag(id,"t,s")) {
				format(vModel,55,"models/kosy/v_m9_mar.mdl")
				format(pModel,55,"models/kosy/p_m9.mdl")
			}
			else
			{
				format(vModel,55,"models/kosy/v_m9_def.mdl")
				format(pModel,55,"models/kosy/p_m9.mdl")
			}
		}
	} 
	
	entity_set_string(id, EV_SZ_viewmodel, vModel)
	entity_set_string(id, EV_SZ_weaponmodel, pModel)
	
	return PLUGIN_HANDLED;  
}

public SkinCheck(id)
{
	new Clip,Ammo;
	new Weapon = get_user_weapon(id, Clip, Ammo);
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	if(Weapon==CSW_KNIFE&&!(knife_model[id] ==  0))
	{
		PlayAnimation(id, 8);
	}
	else
	{
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_HANDLED;
}

public SaveData(id, authid[35])
{
	new vaultkey[64], vaultdata[256]
	
	format(vaultkey, charsmax(vaultkey), "%s", authid)
	format(vaultdata, charsmax(vaultdata), "%i#", knife_model[id])
	nvault_set(g_vault, vaultkey, vaultdata)
	
	return PLUGIN_CONTINUE
}

LoadData(id)
{
	new authid[35]
	get_user_authid(id, authid, charsmax(authid))

	new vaultkey[64], vaultdata[256]

	format(vaultkey, charsmax(vaultkey), "%s", authid)
	format(vaultdata, charsmax(vaultdata), "%i#", knife_model[id])
	nvault_get(g_vault, vaultkey, vaultdata, charsmax(vaultdata))
	replace_all(vaultdata, charsmax(vaultdata), "#", " ")

	new  kosa[8];

	parse(vaultdata,kosa,charsmax(kosa))

	new kosastr = str_to_num(kosa)

	knife_model[id] = kosastr

	return PLUGIN_CONTINUE
}  
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
