#pragma compress 1
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <sqlx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <xs>


/* ColorChat Support */
#define NORMAL DontChange
#define GREEN DontChange
#define TEAM_COLOR DontChange
#define RED Red
#define BLUE Blue
#define GREY Grey
#define ColorChat client_print_color
/* ColorChat Support */


enum _:Colors {
	DontChange,
	Red,
	Blue,
	Grey
}

stock const g_szTeamName[Colors][] = 
{
	"UNASSIGNED",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}
stock cmdExecute( id , const szText[] , any:... ) {
	
    #pragma unused szText

    if ( id == 0 || is_user_connected( id ) ) {

    	new szMessage[ 256 ];

    	format_args( szMessage ,charsmax( szMessage ) , 1 );

        message_begin( id == 0 ? MSG_ALL : MSG_ONE, 51, _, id )
        write_byte( strlen( szMessage ) + 2 )
        write_byte( 10 )
        write_string( szMessage )
        message_end()
    }
}

stock client_print_color(id, iColor=DontChange, const szMsg[], any:...)
{
	// check if id is different from 0
	if( id && !is_user_connected(id) )
	{
		return 0;
	}

	if( iColor > Grey )
	{
		iColor = DontChange;
	}

	new szMessage[192];
	if( iColor == DontChange )
	{
		szMessage[0] = 0x04;
	}
	else
	{
		szMessage[0] = 0x03;
	}

	new iParams = numargs();
	// Specific player code
	if(id)
	{
		if( iParams == 3 )
		{
			copy(szMessage[1], charsmax(szMessage)-1, szMsg);
		}
		else
		{
			vformat(szMessage[1], charsmax(szMessage)-1, szMsg, 4);
		}

		if( iColor )
		{
			new szTeam[11]; // store current team so we can restore it
			get_user_team(id, szTeam, charsmax(szTeam));

			// set id TeamInfo in consequence
			// so SayText msg gonna show the right color
			Send_TeamInfo(id, id, g_szTeamName[iColor]);

			// Send the message
			Send_SayText(id, id, szMessage);

			// restore TeamInfo
			Send_TeamInfo(id, id, szTeam);
		}
		else
		{
			Send_SayText(id, id, szMessage);
		}
	} 

	// Send message to all players
	else
	{
		// Figure out if at least 1 player is connected
		// so we don't send useless message if not
		// and we gonna use that player as team reference (aka SayText message sender) for color change
		new iPlayers[32], iNum;
		get_players(iPlayers, iNum, "ch");
		if( !iNum )
		{
			return 0;
		}

		new iFool = iPlayers[0];

		new iMlNumber, i, j;
		new Array:aStoreML = ArrayCreate();
		if( iParams >= 5 ) // ML can be used
		{
			for(j=4; j<iParams; j++)
			{
				// retrieve original param value and check if it's LANG_PLAYER value
				if( getarg(j) == LANG_PLAYER )
				{
					i=0;
					// as LANG_PLAYER == -1, check if next parm string is a registered language translation
					while( ( szMessage[ i ] = getarg( j + 1, i++ ) ) ) {}
					if( GetLangTransKey(szMessage) != TransKey_Bad )
					{
						// Store that arg as LANG_PLAYER so we can alter it later
						ArrayPushCell(aStoreML, j++);

						// Update ML array saire so we'll know 1st if ML is used,
						// 2nd how many args we have to alterate
						iMlNumber++;
					}
				}
			}
		}

		// If arraysize == 0, ML is not used
		// we can only send 1 MSG_BROADCAST message
		if( !iMlNumber )
		{
			if( iParams == 3 )
			{
				copy(szMessage[1], charsmax(szMessage)-1, szMsg);
			}
			else
			{
				vformat(szMessage[1], charsmax(szMessage)-1, szMsg, 4);
			}

			if( iColor )
			{
				new szTeam[11];
				get_user_team(iFool, szTeam, charsmax(szTeam));
				Send_TeamInfo(0, iFool, g_szTeamName[iColor]);
				Send_SayText(0, iFool, szMessage);
				Send_TeamInfo(0, iFool, szTeam);
			}
			else
			{
				Send_SayText(0, iFool, szMessage);
			}
		}

		// ML is used, we need to loop through all players,
		// format text and send a MSG_ONE_UNRELIABLE SayText message
		else
		{
			new szTeam[11], szFakeTeam[10];
			
			if( iColor )
			{
				get_user_team(iFool, szTeam, charsmax(szTeam));
				copy(szFakeTeam, charsmax(szFakeTeam), g_szTeamName[iColor]);
			}

			for( i = 0; i < iNum; i++ )
			{
				id = iPlayers[i];

				for(j=0; j<iMlNumber; j++)
				{
					// Set all LANG_PLAYER args to player index ( = id )
					// so we can format the text for that specific player
					setarg(ArrayGetCell(aStoreML, j), _, id);
				}

				// format string for specific player
				vformat(szMessage[1], charsmax(szMessage)-1, szMsg, 4);

				if( iColor )
				{
					Send_TeamInfo(id, iFool, szFakeTeam);
					Send_SayText(id, iFool, szMessage);
					Send_TeamInfo(id, iFool, szTeam);
				}
				else
				{
					Send_SayText(id, iFool, szMessage);
				}
			}
			ArrayDestroy(aStoreML);
		}
	}
	return 1;
}

stock Send_TeamInfo(iReceiver, iPlayerId, szTeam[])
{
	static iTeamInfo = 0;
	if( !iTeamInfo )
	{
		iTeamInfo = get_user_msgid("TeamInfo");
	}
	message_begin(iReceiver ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iTeamInfo, .player=iReceiver);
	write_byte(iPlayerId);
	write_string(szTeam);
	message_end();
}

stock Send_SayText(iReceiver, iPlayerId, szMessage[])
{
	static iSayText = 0;
	if( !iSayText )
	{
		iSayText = get_user_msgid("SayText");
	}
	message_begin(iReceiver ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iSayText, .player=iReceiver);
	write_byte(iPlayerId);
	write_string(szMessage);
	message_end();
}

stock register_dictionary_colored(const filename[])
{
	if( !register_dictionary(filename) )
	{
		return 0;
	}

	new szFileName[256];
	get_localinfo("amxx_datadir", szFileName, charsmax(szFileName));
	format(szFileName, charsmax(szFileName), "%s/lang/%s", szFileName, filename);
	new fp = fopen(szFileName, "rt");
	if( !fp )
	{
		log_amx("Failed to open %s", szFileName);
		return 0;
	}

	new szBuffer[512], szLang[3], szKey[64], szTranslation[256], TransKey:iKey;

	while( !feof(fp) )
	{
		fgets(fp, szBuffer, charsmax(szBuffer));
		trim(szBuffer);

		if( szBuffer[0] == '[' )
		{
			strtok(szBuffer[1], szLang, charsmax(szLang), szBuffer, 1, ']');
		}
		else if( szBuffer[0] )
		{
			strbreak(szBuffer, szKey, charsmax(szKey), szTranslation, charsmax(szTranslation));
			iKey = GetLangTransKey(szKey);
			if( iKey != TransKey_Bad )
			{
				while( replace(szTranslation, charsmax(szTranslation), "!g", "^4") ){}
				while( replace(szTranslation, charsmax(szTranslation), "!t", "^3") ){}
				while( replace(szTranslation, charsmax(szTranslation), "!n", "^1") ){}
				AddTranslation(szLang, iKey, szTranslation[2]);
			}
		}
	}
	
	fclose(fp);
	return 1;
}

new const PLUGIN[] = "Global Offensive";
new const VERSION[] = "2.2 BETA";
new const AUTHOR[] = "DeRoiD,BlendeR";
new const Prefix[] = "[CSGOMOD]";

new SQL_Host[32], SQL_Database[32], SQL_User[32], SQL_Password[32];
new Handle:SQL_TUPLE;
new ServerLoaded;


new const SkinFolder[] = "csgomod/";
new const DSkinFolder[] = "csgomod/default/";

#define MAX 31
#define MAXP 32 + 1
#define MAXWP 120 + 1

#define MAXCASES 6
#define MAXKNIFESKINS 30 + 1
#define MAXTRADEINSAMETIME 5

#define RARE 4
#define COVERT 3
#define RESTRICTED 2
#define COMMON 1


#pragma semicolon 1

new Weapons[MAXP][MAXWP], SkinDataTrade[MAXWP][32], inUse[MAXP][4], Dollars[MAXP], Cases[MAXP][MAXCASES+1], Keys[MAXP], Name[MAXP][32],
TradeFounding[MAXP], inTrade[MAXP], TradeID[MAXP], TradePiece[MAXP], TradeItem[MAXP], TradeDollars[MAXP],
TradePartner[MAXP], Accept[MAXP], MarketDollar[MAXP], MarketItem[MAXP], InMarket[MAXP], bool:Logined[MAXP],
User[MAXP][32], Password[MAXP][32], Found[MAXP], UserLoad[MAXP], RegisterMod[MAXP], inProgress[MAXP],
UserID[MAXP], Activity[MAXP], CurrentRank[MAXP], Kills[MAXP];

new ipsz[MAXP];
new dSync;
new g_Players[32], g_playerCount;
new tryb[MAXP];
new pid;

new CvarHost, CvarDatabase, CvarUser, CvarPassword, CvarFoundCase, CvarFoundKey, CvarMinDollarDrop,
CvarMaxDollarDrop, CvarMinDollarMarket, CvarMaxDollarMarket, CvarSkinCheck;
new MinDollarMarket, MaxDollarMarket, MinDollarDrop, MaxDollarDrop, FoundKeyChance, FoundCasesChance;
new PendingTrade, PTradeId[MAXP];
new SyncHudObj;
new CvarKeyPrice,KeyPrice;
new CvarCasePrice,CasePrice;
new CvarMinBet,MinBet;
new CvarVipBonusValue,VipBonusValue;
new CvarBonus,Bonus;
new CvarBonusValue,BonusValue;
new CvarVipBonus,VipBonus;
new szliczba[1000],iliczba;
new szliczba1[1000],iliczba1;
new szilosc[1000],iilosc;
new mcbPlayers;
new bool:g_Vip[33];



new const CSW_MAXAMMO[]= {-2, 52, 0, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, 0, 100, -1, -1};
new const clips[]={0, 13, -0, 10, 1, 7, 0, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, 0, 50};

new const AnimationIDs[][] =
{
	{ 0, 0, 0 },
	{ 6, 0, 1 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 6, 0, 1 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 6, 0, 1 },
	{ 6, 0, 1 },
	{ 16, 17, 2 },
	{ 13, 0, 2 },
	{ 6, 0, 1 },
	{ 6, 0, 1 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 15, 14, 1 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 6, 0, 2 },
	{ 0, 0, 0 },
	{ 6, 0, 1 },
	{ 8, 0, 3 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 }
};

new const DropData[][] = 
{
	{ 0, 00, 00, 00, 00, 00, 00, 00, 00, 00, 0000 },
	{ 0, 01, 11, 21, 33, 43, 53, 65, 75, 85, 0000 },
	{ 0, 31, 41, 51, 83, 73, 63, 35, 45, 55, 0000 },
	{ 1, 81, 71, 61, 13, 23, 03, 25, 15, 05, 0004 },
	{ 1, 02, 12, 22, 34, 44, 54, 66, 76, 86, 0008 },
	{ 1, 32, 42, 52, 84, 74, 64, 36, 46, 56, 0010 },
	{ 1, 82, 72, 62, 14, 24, 04, 26, 16, 06, 0020 }
};

new const nazwy_broni[][] = {
		"weapon_scout", "weapon_mac10", "weapon_aug", "weapon_ump45", 
		"weapon_sg550", "weapon_galil", "weapon_famas", "weapon_awp", 
		"weapon_mp5navy", "weapon_m249", "weapon_m4a1", "weapon_tmp", 
		"weapon_g3sg1", "weapon_sg552", "weapon_ak47", "weapon_p90",
		"weapon_p228", "weapon_xm1014", "weapon_elite", "weapon_fiveseven", 
		"weapon_usp", "weapon_glock18",  "weapon_deagle"
	};

	
	
new const DefaultModels[][][] = {
	{ "", "" },
	{ "", "" },
	{ "", "" },
	{ "", "" },
	{ "HE.mdl", "weapon_hegrenade" },
	{ "", "" },
	{ "C4.mdl", "weapon_c4" },
	{ "", "" },
	{ "", "" },
	{ "", "" },
	{ "", "" },
	{ "", "" },
	{ "", "" },
	{ "", "" },
	{ "Galil.mdl", "weapon_galil" },
	{ "Famas.mdl", "weapon_famas" },
	{ "USP-S.mdl", "weapon_usp" },
	{ "Glock.mdl", "weapon_glock18" },
	{ "AWP.mdl", "weapon_awp" },
	{ "MP7.mdl", "weapon_mp5navy" },
	{ "", "" },
	{ "", "" },
	{ "M4A4.mdl", "weapon_m4a1" },
	{ "", "" },
	{ "", "" },
	{ "FLASH.mdl", "weapon_flashbang" },
	{ "Deagle.mdl", "weapon_deagle" },
	{ "", "" },
	{ "AK47.mdl", "weapon_ak47" },
	{ "Knife.mdl", "weapon_knife" },
	{ "", "" },
	{ "", "" },
	{ "", "" }
};

new const RareData[][] = 
{
	"",
	"\d",
	"\w",
	"\r",
	"\y"
};

new const SkinData[][][] = 
{
	{ "Name", "VMODEL", "PMODEL", 0, 0 },
	{ "AK-47 | Outlaw", "ak47/Outlaw", "", CSW_AK47, COMMON },
	{ "AK-47 | Aquamarine Revenge", "ak47/Aquamarine", "", CSW_AK47, COMMON },
	{ "AK-47 | Jaguar", "ak47/Jaguar", "", CSW_AK47, RESTRICTED },
	{ "AK-47 | Vulcan", "ak47/Vulcan", "", CSW_AK47, RESTRICTED },
	{ "AK-47 | Wasteland Rebel", "ak47/Wasteland", "", CSW_AK47, COVERT },
	{ "AK-47 | Fireserpent", "ak47/Fireserpent", "", CSW_AK47, COVERT },
	{ "", "AK47/", "", CSW_AK47, 0 },
	{ "", "AK47/", "", CSW_AK47, 0 },
	{ "", "AK47/", "", CSW_AK47, 0 },
	{ "", "AK47/", "", CSW_AK47, 0 },
	{ "AWP | Worm God", "awp/WormGod", "", CSW_AWP, COMMON },
	{ "AWP | Man'o'war", "awp/Manowar", "", CSW_AWP, COMMON },
	{ "AWP | Redline", "awp/Redline", "", CSW_AWP, RESTRICTED },
	{ "AWP | Hyper Beast", "awp/HBeast", "", CSW_AWP, RESTRICTED },
	{ "AWP | Asiimov", "awp/Asiimov", "", CSW_AWP, COVERT },
	{ "AWP | Dragon Lore", "awp/DragonLore", "", CSW_AWP, COVERT },
	{ "", "AWP/", "", CSW_AWP, 0 },
	{ "", "AWP/", "", CSW_AWP, 0 },
	{ "", "AWP/", "", CSW_AWP, 0 },
	{ "", "AWP/", "", CSW_AWP, 0 },
	{ "M4A4 | Griffin", "m4a1/Griffin", "", CSW_M4A1, COMMON },
	{ "M4A4 | Bullet Rain", "m4a1/BulletRain", "", CSW_M4A1, COMMON },
	{ "M4A4 | Dragon King", "m4a1/DragonKing", "", CSW_M4A1, RESTRICTED },
	{ "M4A4 | Asiimov", "m4a1/Asiimov", "", CSW_M4A1, RESTRICTED },
	{ "M4A4 | Poseidon", "m4a1/Poseidon", "", CSW_M4A1, COVERT },
	{ "M4A4 | Howl", "m4a1/Howl", "", CSW_M4A1, COVERT },
	{ "", "m4a4/", "", CSW_M4A1, 0 },
	{ "", "m4a4/", "", CSW_M4A1, 0 },
	{ "", "m4a4/", "", CSW_M4A1, 0 },
	{ "", "m4a4/", "", CSW_M4A1, 0 },
	{ "FAMAS | Blue Way", "famas/BlueWay", "", CSW_FAMAS, COMMON },
	{ "FAMAS | Nuclear", "famas/Nuclear", "", CSW_FAMAS, COMMON },
	{ "FAMAS | Vanquish", "famas/Vanquish", "", CSW_FAMAS, RESTRICTED },
	{ "FAMAS | Biohazard", "famas/Biohazard", "", CSW_FAMAS, RESTRICTED },
	{ "FAMAS | Pulse", "famas/Pulse", "", CSW_FAMAS, COVERT },
	{ "FAMAS | Spitfire", "famas/Spitfire", "", CSW_FAMAS, COVERT },
	{ "", "famas/", "", CSW_FAMAS, 0 },
	{ "", "famas/", "", CSW_FAMAS, 0 },
	{ "", "famas/", "", CSW_FAMAS, 0 },
	{ "", "famas/", "", CSW_FAMAS, 0 },
	{ "GALIL-AR | Crimson Web", "galil/CrimsonWeb", "", CSW_GALIL, COMMON },
	{ "GALIL-AR | Blue Way", "galil/BlueWay", "", CSW_GALIL, COMMON },
	{ "GALIL-AR | Eco", "galil/Eco", "", CSW_GALIL, RESTRICTED },
	{ "GALIL-AR | Odyssy", "galil/Odyssy", "", CSW_GALIL, RESTRICTED },
	{ "GALIL-AR | Cerberus", "galil/Cerberus", "", CSW_GALIL, COVERT },
	{ "GALIL-AR | Chatterbox", "galil/Chatterbox", "", CSW_GALIL, COVERT },
	{ "", "galil/", "", CSW_GALIL, 0 },
	{ "", "galil/", "", CSW_GALIL, 0 },
	{ "", "galil/", "", CSW_GALIL, 0 },
	{ "", "galil/", "", CSW_GALIL, 0 },
	{ "MP7 | Blood", "mp5/Blood", "", CSW_MP5NAVY, COMMON },
	{ "MP7 | Now Purple!", "mp5/NowPurple", "", CSW_MP5NAVY, COMMON },
	{ "MP7 | Rising Sun", "mp5/RisingSun", "", CSW_MP5NAVY, RESTRICTED },
	{ "MP7 | Seaweed", "mp5/Seaweed", "", CSW_MP5NAVY, RESTRICTED },
	{ "MP7 | Carbonite", "mp5/Carbonite", "", CSW_MP5NAVY, COVERT },
	{ "MP7 | Urbanhazard", "mp5/UrbanHazard", "", CSW_MP5NAVY, COVERT },
	{ "", "mp5/", "", CSW_MP5NAVY, 0 },
	{ "", "mp5/", "", CSW_MP5NAVY, 0 },
	{ "", "mp5/", "", CSW_MP5NAVY, 0 },
	{ "", "mp5/", "", CSW_MP5NAVY, 0 },
	{ "USP-S | Stainless", "usp/Stainless", "", CSW_USP, COMMON },
	{ "USP-S | Vertex", "usp/Vertex", "", CSW_USP, COMMON },
	{ "USP-S | Caiman", "usp/Caiman", "", CSW_USP, RESTRICTED },
	{ "USP-S | Road Rash", "usp/Rash", "", CSW_USP, RESTRICTED },
	{ "USP-S | Orion", "usp/Orion", "", CSW_USP, COVERT },
	{ "USP-S | Kill Confirmed", "usp/KConfirmed", "", CSW_USP, COVERT },
	{ "", "usp/", "", CSW_USP, 0 },
	{ "", "usp/", "", CSW_USP, 0 },
	{ "", "usp/", "", CSW_USP, 0 },
	{ "", "usp/", "", CSW_USP, 0 },
	{ "DEAGLE | Engraved", "deagle/Engraved", "", CSW_DEAGLE, COMMON },
	{ "DEAGLE | Golden Rose", "deagle/GoldenRose", "", CSW_DEAGLE, COMMON },
	{ "DEAGLE | Biohazard", "deagle/Biohazard", "", CSW_DEAGLE, RESTRICTED },
	{ "DEAGLE | Jungle", "deagle/Jungle", "", CSW_DEAGLE, RESTRICTED },
	{ "DEAGLE | Hypnotic", "deagle/Hypnotic", "", CSW_DEAGLE, COVERT },
	{ "DEAGLE | Blaze", "deagle/Blaze", "", CSW_DEAGLE, COVERT },
	{ "", "deagle/", "", CSW_DEAGLE, 0 },
	{ "", "deagle/", "", CSW_DEAGLE, 0 },
	{ "", "deagle/", "", CSW_DEAGLE, 0 },
	{ "", "deagle/", "", CSW_DEAGLE, 0 },
	{ "GLOCK-18 | Candy Apple", "glock/Candy", "", CSW_GLOCK18, COMMON },
	{ "GLOCK-18 | Green Way", "glock/GreenWay", "", CSW_GLOCK18, COMMON },
	{ "GLOCK-18 | Catacombs", "glock/Catacombs", "", CSW_GLOCK18, RESTRICTED },
	{ "GLOCK-18 | Grinder", "glock/Grinder", "", CSW_GLOCK18, RESTRICTED },
	{ "GLOCK-18 | Water Elemental", "glock/WaterElemental", "", CSW_GLOCK18, COVERT },
	{ "GLOCK-18 | Fade", "glock/Fade", "", CSW_GLOCK18, COVERT },
	{ "", "glock/", "", CSW_GLOCK18, 0 },
	{ "", "glock/", "", CSW_GLOCK18, 0 },
	{ "", "glock/", "", CSW_GLOCK18, 0 },
	{ "", "glock/", "", CSW_GLOCK18, 0 },
	{ "Karambit | Doppler Ocean", "knife/DopplerOcean_K", "", CSW_KNIFE, RARE },
	{ "Karambit | Doppler Pink", "knife/DopplerPink_K", "", CSW_KNIFE, RARE },
	{ "Karambit | Crimson Web", "knife/Crimson_K", "", CSW_KNIFE, RARE },
	{ "Butterfly Knife | Sea", "knife/Sea_BF", "", CSW_KNIFE, RARE },
	{ "Butterfly Knife | Hawaiian", "knife/Hawaiian_BF", "", CSW_KNIFE, RARE },
	{ "Butterfly Knife | Crimson Web", "knife/Crimson_BF", "", CSW_KNIFE, RARE },
	{ "Bayonet M9 | Fade", "knife/Fade_B", "", CSW_KNIFE, RARE },
	{ "Bayonet M9 | Doppler Sapphire", "knife/Sapphire_B", "", CSW_KNIFE, RARE },
	{ "Bayonet | Space", "knife/Space_B", "", CSW_KNIFE, RARE },
	{ "Gut Knife | Asiimov", "knife/Asiimov_GUT", "", CSW_KNIFE, RARE },
	{ "Gut Knife | Doppler", "knife/Doppler_GUT", "", CSW_KNIFE, RARE },
	{ "Gut Knife | Razer", "knife/Razer_GUT", "", CSW_KNIFE, RARE },
	{ "Flip Knife | ROG", "knife/ROG_FL", "", CSW_KNIFE, RARE },
	{ "Flip Knife | Fade", "knife/Fade_FL", "", CSW_KNIFE, RARE },
	{ "Flip Knife | Marble Fade", "knife/MarbleFade_FL", "", CSW_KNIFE, RARE },
	{ "Shadow Daggers", "knife/Def_SD", "", CSW_KNIFE, RARE },
	{ "Shadow Daggers | Magma", "knife/Magma_SD", "", CSW_KNIFE, RARE },
	{ "Shadow Daggers | Rainbow", "knife/Rainbow_SD", "", CSW_KNIFE, RARE },
	{ "Falchion Knife | Orange", "knife/Orange_F", "", CSW_KNIFE, RARE },
	{ "Falchion Knife | Diamond", "knife/Diamond_F", "", CSW_KNIFE, RARE },
	{ "Falchion Knife", "knife/Def_F", "", CSW_KNIFE, RARE },
	{ "Huntsman Knife | Fade", "knife/Fade_HM", "", CSW_KNIFE, RARE },
	{ "Huntsman Knife | Crimson Web", "knife/Crimson_HM", "", CSW_KNIFE, RARE },
	{ "Huntsman Knife | Slaughter", "knife/Slaughter_HM", "", CSW_KNIFE, RARE },
	{ "", "knife/", "", CSW_KNIFE, 0 },
	{ "", "knife/", "", CSW_KNIFE, 0 },
	{ "", "knife/", "", CSW_KNIFE, 0 },
	{ "", "knife/", "", CSW_KNIFE, 0 },
	{ "", "knife/", "", CSW_KNIFE, 0 },
	{ "", "knife/", "", CSW_KNIFE, 0 }
};

new const KeyName[] = "Klucz";

new const Case_Data[][][] = 
{
	{ "Case Name", "Found Num 0.1-100.0%" }, //Last must be 1
	{ "Chroma Case", 1000 }, //First must be 1000
	{ "Chroma 2 Case", 1025 },
	{ "Chroma 3 Case", 0380 },
	{ "Gamma Case", 0105 },
	{ "Gamma 2 Case", 0017 },
	{ "Falcion Case", 0009 }
};

new const Ranks[][] =
{
	"Unranked",
	"Silver I",
	"Silver II",
	"Silver III",
	"Silver IV",
	"Silver Elite",
	"Silver Elite Master",
	"Gold Nova I",
	"Gold Nova II",
	"Gold Nova III",
	"Gold Nova Master",
	"Master Guardian I",
	"Master Guardian II",
	"Master Guardian Elite",
	"Distinguished Master Guardian",
	"Legendary Eagle",
	"Legendary Eagle Master",
	"Supreme Master First Class",
	"The Global Elite"
};

new const RankKills[] =
{
	0,
	0,
	25,
	100,
	250,
	750,
	1000,
	1500,
	2250,
	3000,
	3900,
	4900,
	5900,
	7000,
	8500,
	10000,
	15000,
	22000,
	30000,
	40000,
	0
};

public plugin_precache()
{
	new Mdl[96];
	
	for(new i = 1; i < sizeof(SkinData); i++)
	{
		if(strlen(SkinData[i][0]) > 1)
		{
			formatex(Mdl, charsmax(Mdl), "models/%s%s.mdl", SkinFolder, SkinData[i][1]);
			precache_model(Mdl);
		}
		
		if(strlen(SkinData[i][2]) > 1)
		{
			formatex(Mdl, charsmax(Mdl), "models/%s%s.mdl", SkinFolder, SkinData[i][2]);
			precache_model(Mdl);
		}
	}
	
	for(new i = 1; i < sizeof(DefaultModels); i++)
	{
		if(strlen(DefaultModels[i][0]) > 1)
		{
			formatex(Mdl, charsmax(Mdl), "models/%s%s", DSkinFolder, DefaultModels[i][0]);
			precache_model(Mdl);
		}
	}
}

public plugin_end()
{
	SQL_FreeHandle(SQL_TUPLE);
}

public plugin_init()
{
	for(new i; i < MAXWP; i++)
	{
		copy(SkinDataTrade[i], 31, SkinData[i][0]);
	}
	
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar(PLUGIN, VERSION, FCVAR_SERVER);
	register_dictionary("csgo.txt");

	CvarHost = register_cvar("csgo_host", "localhost");
	CvarDatabase = register_cvar("csgo_db", "csgo");
	CvarUser = register_cvar("csgo_user", "root");
	CvarPassword = register_cvar("csgo_pw", "");
	
	get_pcvar_string(CvarHost, SQL_Host, charsmax(SQL_Host));
	get_pcvar_string(CvarDatabase, SQL_Database, charsmax(SQL_Database));
	get_pcvar_string(CvarUser, SQL_User, charsmax(SQL_User));
	get_pcvar_string(CvarPassword, SQL_Password, charsmax(SQL_Password));

	CvarFoundCase = register_cvar("csgo_casefound", "20");
	CvarFoundKey = register_cvar("csgo_keyfound", "15");
	CvarMinDollarDrop = register_cvar("csgo_minddrop", "1");
	CvarMaxDollarDrop = register_cvar("csgo_maxddrop", "3");
	CvarMinDollarMarket = register_cvar("csgo_minmarketd", "10");
	CvarMaxDollarMarket = register_cvar("csgo_maxmarketd", "1000000");
	CvarSkinCheck = register_cvar("csgo_scheck", "1");
	CvarKeyPrice = register_cvar("csgo_keyprice", "5");
	CvarCasePrice = register_cvar("csgo_caseprice", "15");
	CvarMinBet = register_cvar("csgo_minbet", "5");
	CvarBonus = register_cvar("csgo_bonus", "0");
	CvarBonusValue = register_cvar("csgo_bonusnormal", "5");
	CvarVipBonus = register_cvar("csgo_vip", "1");
	CvarVipBonusValue = register_cvar("csgo_vipbonus", "10");
	
	FoundCasesChance = get_pcvar_num(CvarFoundCase);
	FoundKeyChance = get_pcvar_num(CvarFoundKey);
	MinDollarDrop = get_pcvar_num(CvarMinDollarDrop);
	MaxDollarDrop = get_pcvar_num(CvarMaxDollarDrop);
	MinDollarMarket = get_pcvar_num(CvarMinDollarMarket);
	MaxDollarMarket = get_pcvar_num(CvarMaxDollarMarket);
	FoundCasesChance = get_pcvar_num(CvarFoundCase);
	KeyPrice = get_pcvar_num(CvarKeyPrice);
	CasePrice = get_pcvar_num(CvarCasePrice);
	MinBet = get_pcvar_num(CvarMinBet);
	Bonus = get_pcvar_num(CvarBonus);
	BonusValue = get_pcvar_num(CvarBonusValue);
	VipBonus = get_pcvar_num(CvarVipBonus);
	VipBonusValue = get_pcvar_num(CvarVipBonusValue);

	register_concmd("csgo_admin", "admin_menu",ADMIN_LEVEL_A, "");
	register_concmd("TRADEPIECE", "cmdPiece");
	register_concmd("TRADEDOLLARS", "cmdDollarT");
	register_concmd("MARKETDOLLAR", "cmdDollarM");
	register_concmd("MY_USERNAME", "cmdUser");
	register_concmd("MY_PASSWORD", "cmdPassword");
	register_concmd("BET","BETcmd");
	register_concmd("WARTOSC","AdminCMD");
	register_concmd("ILOSC","IloscCMD");
	
	
	register_clcmd("say /menu", "MainMenu");
	register_clcmd("menu", "MainMenu");
	register_clcmd("say /key", "buykey");
	register_clcmd("say /keymenu", "KeyMenu");
	register_clcmd("say /casemenu", "CaseBuyMenu");
	
	RegisterHam(Ham_Spawn, "player", "Odrodzenie", 1);
	
	
	
	if(get_pcvar_num(CvarSkinCheck) == 1)
		register_impulse(100, "SkinCheck");
		
	register_event("DeathMsg", "Death", "a");

	dSync = CreateHudSyncObj();
	
	for(new i = 1; i < sizeof(DefaultModels); i++)
	{
		if(strlen(DefaultModels[i][1]) > 0)
		{
			RegisterHam(Ham_Item_Deploy, DefaultModels[i][1], "WeaponSkin", 1);
		}
	}
	
	
	for(new i = 0; i < sizeof nazwy_broni; i++) {
		RegisterHam(Ham_Item_AddToPlayer, nazwy_broni[i], "fw_DostalBron_Post", 1);
	}
	
	RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1);
	
	SyncHudObj = CreateHudSyncObj();
	
	
	register_clcmd("say", "HandleSay");
	
	set_task(380.0, "Message", 20170309, _, _, "b");
	set_task(180.0, "bind", 20170309, _, _, "b");
	
	SQL_FirstLoad() ;
}

public msgStatusIcon(msgid, msgdest, id) 
{ 
	static szIcon[8]; 
	get_msg_arg_string(2, szIcon, 7); 
	
	if(equal(szIcon, "buyzone") && get_msg_arg_int(1)) 
	{ 
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0)); 
		return PLUGIN_HANDLED; 
	}
	
	return PLUGIN_CONTINUE; 
}

public Message() 
{
	
	for(new i; i < MAXP; i++)
		if(is_user_connected(i))
			print_color(i, "!g%s!y %L", Prefix, i, "SVMESSAGE");
}

public HandleSay(id)
{
	new Message[192], None[2][32], Chat[192], Alive[16];
	
	read_args(Message, 191);
	remove_quotes(Message);

	formatex(None[0], 31, "");
	formatex(None[1], 31, " ");
	
	if(Message[0] == '@' || Message[0] == '!' || equal (Message, ""))
		return PLUGIN_HANDLED;
	
	if(!is_user_alive(id))
		Alive = "*DEATH* ";
	else
		Alive = "";
		
	if(!equali(Message, None[0]) && !equali(Message, None[1]))
	{
		if(Logined[id])
		{
			formatex(Chat, 191, "^1%s^4[%s] ^3%s^1 : %s", Alive, Ranks[CurrentRank[id]], Name[id], Message);
		}
		else
		{
			formatex(Chat, 191, "^1%s^4[Unranked] ^3%s^1 : %s", Alive, Name[id], Message);
		}
		
		switch(cs_get_user_team(id))
		{
			case CS_TEAM_T: ColorChat(0, RED, Chat);
			case CS_TEAM_CT: ColorChat(0, BLUE, Chat);
			case CS_TEAM_SPECTATOR: ColorChat(0, GREY, Chat);
		}
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

public Death()
{
	new id = read_data(1);
	new x = read_data(2);
	
	if(id == 0 || id == x || x == 0 || !Logined[id])
	{
		return;
	}
	
	new DollarDrop = random_num(MinDollarDrop, MaxDollarDrop);
	
	Dollars[id] += DollarDrop;
	
	set_hudmessage(0, 255, 0, -1.00, 0.85, 0, 6.0, 2.0);
	ShowSyncHudMsg(id, dSync, "+%d$", x);
	
	new Drop = random_num(1, 100);
	
	if(FoundCasesChance >= Drop)
	{
		DropCase(id);
	}
	else if(FoundCasesChance+FoundKeyChance >= Drop)
	{
		for(new i; i < MAXP; i++)
			if(is_user_connected(i))
				print_color(i, "!g%s!y %L", Prefix, i, "FOUND", Name[id], KeyName);
		Keys[id]++;
	}
	
	Kills[id]++;
	
	if(RankKills[CurrentRank[id]+1] <= Kills[id] && RankKills[CurrentRank[id]+1] != 0)
	{
		CurrentRank[id]++;
		print_color(id, "!g%s!y %L", Prefix, id, "RANKNEWLV", Ranks[CurrentRank[id]]);
	}
		
	SQL_UpdateUser(id);
}

public fw_DostalBron_Post(iEnt, id) {
	if(!pev_valid(iEnt) || !is_user_alive(id)) {
		return HAM_IGNORED;
	}
	
	if(!pev(iEnt, pev_owner)) {
		new bron = cs_get_weapon_id(iEnt);
		cs_set_user_bpammo(id, bron, CSW_MAXAMMO[bron]);
	}
	
	return HAM_IGNORED;
}

public DropCase(id)
{
	new RandomNum;
	RandomNum = random(1001);
	
	for(new i = 1; i < sizeof(Case_Data); i++)
	{
		if(Case_Data[i][1][0] <= RandomNum)
		{
			for(new x; x < MAXP; x++)
				if(is_user_connected(x))
					print_color(x, "!g%s!y %L", Prefix, x, "FOUND", Name[id], Case_Data[i][0]);
					
			Cases[id][i]++;
			break;
		}
	}
	
	SQL_UpdateUser(id);
}

public SkinDrop(id, CaseNum)
{
	new RandomNum = random_num(1, 1000);
	
	if(DropData[CaseNum][10] >= RandomNum && DropData[CaseNum][0] == 1)
	{
		new RandomKnife = random_num(91, 90+MAXKNIFESKINS-1);
		Weapons[id][RandomKnife]++;
		
		for(new i; i < MAXP; i++)
			if(is_user_connected(i))
				print_color(i, "!g%s!y %L", Prefix, i, "UNBOXING", Name[id], SkinData[RandomKnife][0]);
	}
	else
	{
		new RandomNums[2], DroppedSkin;
		RandomNum = random_num(1, 10);
		
		if(RandomNum == 1)
		{
			RandomNums[0] = 7; RandomNums[1] = 9;
		}
		else if(RandomNum <= 4)
		{
			RandomNums[0] = 4; RandomNums[1] = 6;
		}
		else if(RandomNum <= 10)
		{
			RandomNums[0] = 1; RandomNums[1] = 3;
		}
		
		DroppedSkin = DropData[CaseNum][random_num(RandomNums[0], RandomNums[1])];
		
		Weapons[id][DroppedSkin]++;
		
		for(new i; i < MAXP; i++)
			if(is_user_connected(i))
				print_color(i, "!g%s!y %L", Prefix, i, "UNBOXING", Name[id], SkinData[DroppedSkin][0]);
	}
	
	SQL_UpdateUser(id);
}

public WeaponSkin(f)
{
	new id = get_pdata_cbase(f, 41, 4);
	new wid = cs_get_weapon_id(f);
	
	if(id > 32 || id < 1 || !is_user_alive(id))
	{
		return HAM_SUPERCEDE;
	}
	
	new k = AnimationIDs[wid][2], Mdl[86];
	
	if(inUse[id][k] > 0 && SkinData[inUse[id][k]][3][0] == wid && Weapons[id][inUse[id][k]] > 0)
	{
		formatex(Mdl, charsmax(Mdl), "models/%s%s.mdl", SkinFolder, SkinData[inUse[id][k]][1]);
		set_pev(id, pev_viewmodel2, Mdl);
		
		if(strlen(SkinData[inUse[id][k]][2]) > 0)
		{
			formatex(Mdl, charsmax(Mdl), "models/%s%s.mdl", SkinFolder, SkinData[inUse[id][k]][2]);
			set_pev(id, pev_weaponmodel2, Mdl);
		}
	}
	else
	{
		formatex(Mdl, charsmax(Mdl), "models/%s%s", DSkinFolder, DefaultModels[wid][0]);
		set_pev(id, pev_viewmodel2, Mdl);
	}
	
	return HAM_IGNORED;
}

public MainMenu(id)
{
	if(!Logined[id])
	{
		RegMenu(id);
		return;
	}
	
	new String[128];
	formatex(String, charsmax(String), "%L", id, "MAINMENU", Dollars[id]);
	new Menu = menu_create(String, "MainMenuh");
	
	formatex(String, charsmax(String), "%L", id, "INVENTORY");
	menu_additem(Menu, String, "1");
	
	formatex(String, charsmax(String), "%L", id, "CASEOPEN");
	menu_additem(Menu, String, "2");
	
	formatex(String, charsmax(String), "%L", id, "TRADE");
	menu_additem(Menu, String, "3");
	
	formatex(String, charsmax(String), "%L^n", id, "MARKET");
	menu_additem(Menu, String, "4");

	formatex(String, charsmax(String), "%L", id, "BETS");
	menu_additem(Menu, String, "5");
	
	if(get_user_flags(id) & ADMIN_BAN)
	{
		formatex(String, charsmax(String), "%L", id, "ADMINMENU");
		menu_additem(Menu, String, "6");
	}
	
	if(RankKills[CurrentRank[id]+1] != 0)
	{
		formatex(String, charsmax(String), "%L%L", id, "TRASH", id, "RANKMENU",
		Ranks[CurrentRank[id]], Kills[id], RankKills[CurrentRank[id]+1], Ranks[CurrentRank[id]+1]);
	}
	else
	{
		formatex(String, charsmax(String), "%L%L", id, "TRASH", id, "RANKMENUMAX",
		Ranks[CurrentRank[id]], Kills[id]);
	}
	menu_additem(Menu, String, "7");
	
	menu_display(id, Menu);
}

public MainMenuh(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	
	new x = str_to_num(Data);
	
	switch(x)
	{
		case 1 : {
			Inventory(id);
		}
		
		case 2 : {
			CaseMenu(id);
			
			if(MarketItem[id] > 0 || TradeItem[id] > 0 || inTrade[id] > 0)
			{
				print_color(id, "!g%s!y %L", Prefix, id, "TMMESSAGE");
				DeleteTradeandMarket(id);
			}
		}
		
		case 3 : {
			if(PendingTrade > MAXTRADEINSAMETIME && PTradeId[id] == 0)
			{
				print_color(id, "!g%s!y %L", Prefix, id, "BLOCKTRADE");
				return;
			}
			
			TradeMenu(id);
			
			if(MarketItem[id] > 0)
			{
				print_color(id, "!g%s!y %L", Prefix, id, "TMMESSAGE");
				DeleteTradeandMarket(id);
			}
		}
		
		case 4 : {
			MMarketMenu(id);
			
			if(TradeItem[id] > 0 || inTrade[id] > 0)
			{
				print_color(id, "!g%s!y %L", Prefix, id, "TMMESSAGE");
				DeleteTradeandMarket(id);
			}
		}
		case 5 : {
			BetMenu(id);
		}
		case 6 : {
			admin_menu(id);
		}
		
		case 7 : {
			TrashMenu(id);
			
			if(MarketItem[id] > 0 || TradeItem[id] > 0 || inTrade[id] > 0)
			{
				print_color(id, "!g%s!y %L", Prefix, id, "TMMESSAGE");
				DeleteTradeandMarket(id);
			}
		}
	}
}

public CaseMenu(id)
{
	new String[128];
	formatex(String, charsmax(String), "%L", id, "CASEOPENM", Keys[id]);
	new Menu = menu_create(String, "CaseMenuh");
	
	for(new i = 1; i < sizeof(Case_Data); i++)
	{
		new NumToString[6];
		num_to_str(i, NumToString, 5);
		formatex(String, charsmax(String), "%s \r(%d)", Case_Data[i][0], Cases[id][i]);
		menu_additem(Menu, String, NumToString);
	}
	
	menu_display(id, Menu);
}

public CaseMenuh(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	
	new x = str_to_num(Data);
	
	if(Cases[id][x] > 0 && Keys[id] > 0)
	{
		Keys[id]--;
		Cases[id][x]--;
		SkinDrop(id, x);
	}
	else if(Keys[id] == 0)
	{
		print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHK");
	}
	else
	{
		print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHC");
	}
	
	CaseMenu(id);
}

public TrashMenu(id)
{
	new String[128];
	formatex(String, charsmax(String), "%L", id, "TRASH");
	new Menu = menu_create(String, "TrashMenuh");
	
	for(new i = 1; i < sizeof(SkinData); i++)
	{
		if(Weapons[id][i] > 0 && strlen(SkinData[i][0]) > 1)
		{
			new NumToString[6];
			num_to_str(i, NumToString, 5);
			
			if(SkinData[i][3][0] != CSW_KNIFE)
				formatex(String, charsmax(String), "%s%s \y(%d)", RareData[SkinData[i][4][0]], SkinData[i][0], Weapons[id][i]);
			else
				formatex(String, charsmax(String), "%s%s \w(%d)", RareData[SkinData[i][4][0]], SkinData[i][0], Weapons[id][i]);
			menu_additem(Menu, String, NumToString);
		}
	}
	
	menu_display(id, Menu);
}

public TrashMenuh(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	new x = str_to_num(Data);
	
	Weapons[id][x]--;
	TrashMenu(id);
	SQL_UpdateUser(id);
}

public Inventory(id)
{
	new String[128];
	formatex(String, charsmax(String), "%L", id, "INVENTORY");
	new Menu = menu_create(String, "Inventoryh");
	
	for(new i = 1; i < sizeof(SkinData); i++)
	{
		if(Weapons[id][i] > 0 && strlen(SkinData[i][0]) > 1)
		{
			new NumToString[6];
			num_to_str(i, NumToString, 5);
			
			if(SkinData[i][3][0] != CSW_KNIFE)
				formatex(String, charsmax(String), "%s%s \y(%d)", RareData[SkinData[i][4][0]], SkinDataTrade[i], Weapons[id][i]);
			else
				formatex(String, charsmax(String), "%s%s \w(%d)", RareData[SkinData[i][4][0]], SkinDataTrade[i], Weapons[id][i]);
			menu_additem(Menu, String, NumToString);
		}
	}
	
	menu_display(id, Menu);
}

public Inventoryh(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	new x = str_to_num(Data);
	
	if(SkinData[x][3][0] == 16 || SkinData[x][3][0] == 17 || SkinData[x][3][0] == 26)
	{
		inUse[id][2] = x;
	}
	else if(SkinData[x][3][0] == 29)
	{
		inUse[id][3] = x;
	}
	else
	{
		inUse[id][1] = x;
	}
}

public SkinCheck(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	new Sil, WPName[32];
	formatex(WPName, charsmax(WPName), DefaultModels[get_user_weapon(id)][1]);
	new WPN = find_ent_by_owner(-1, DefaultModels[get_user_weapon(id)][1], id);
	
	if(get_user_weapon(id) == CSW_M4A1 || get_user_weapon(id) == CSW_USP)
		Sil = cs_get_weapon_silen(WPN);
		
	if(get_user_weapon(id) == CSW_AWP)
		cs_set_user_zoom(id, 0, 0);
	
	PlayAnimation(id, AnimationIDs[get_user_weapon(id)][Sil]);

	return PLUGIN_HANDLED;
}

public TradeMenu(id)
{
	if(TradePiece[id] == 0)
	{
		TradePiece[id] = 1;
	}
	
	new String[128], kid, Menu;
	
	if(TradePartner[id] > 0)
		kid = TradePartner[id];
	else
		kid = TradeID[id];

	if(TradeFounding[id] == 1)
	{
		formatex(String, charsmax(String), "%L", id, "WANTTRADE", Name[kid]);
	}
	else if(inTrade[id] == 1 && inTrade[kid] == 1)
	{
		formatex(String, charsmax(String), "%L", id, "TRADEITEMS", Name[kid]);
	}
	else 
	{
		formatex(String, charsmax(String), "%L", id, "TRADEDOLLAR", Dollars[id]);
	}
	
	Menu = menu_create(String, "TradeMenuh");
	
	if(TradeFounding[id] == 1)
	{
		formatex(String, charsmax(String), "%L", id, "TRADEACCEPT");
		menu_additem(Menu, String, "-3");
		
		formatex(String, charsmax(String), "%L", id, "TRADEREJECT");
		menu_additem(Menu, String, "-2");
	}
	else if(inTrade[id] == 1 && inTrade[kid] == 1)
	{
		if(TradeItem[kid] == 0)
		{
			formatex(String, charsmax(String), "%L", id, "TRADENOTHING");
		}
		else if(TradeItem[kid] > 0 && TradeItem[kid] <= 90+MAXKNIFESKINS)
		{
			formatex(String, charsmax(String), "%L", id, "TRADEITEM", SkinDataTrade[TradeItem[kid]], TradePiece[kid]);
		}
		else if(TradeItem[kid] > 90+MAXKNIFESKINS && TradeItem[kid] <= 90+MAXKNIFESKINS+MAXCASES)
		{
			formatex(String, charsmax(String), "%L", id, "TRADEITEM", Case_Data[TradeItem[kid]-(90+MAXKNIFESKINS)][0], TradePiece[kid]);
		}
		else
		{
			formatex(String, charsmax(String), "%L", id, "TRADEITEM", KeyName, TradePiece[kid]);
		}
			
		menu_additem(Menu, String, "0");
		
		formatex(String, charsmax(String), "%L", id, "TRADEYOURITEMS", TradeDollars[kid]);
		menu_additem(Menu, String, "0");
		
		if(TradeItem[id] == 0)
		{
			formatex(String, charsmax(String), "%L", id, "TRADENOTHING");
		}
		else if(TradeItem[id] > 0 && TradeItem[id] <= 90+MAXKNIFESKINS)
		{
			formatex(String, charsmax(String), "%L", id, "TRADEITEM", SkinDataTrade[TradeItem[id]], TradePiece[id]);
		}
		else if(TradeItem[id] > 90+MAXKNIFESKINS && TradeItem[id] <= 90+MAXKNIFESKINS+MAXCASES)
		{
			formatex(String, charsmax(String), "%L", id, "TRADEITEM", Case_Data[TradeItem[id]-(90+MAXKNIFESKINS)][0], TradePiece[id]);
		}
		else
		{
			formatex(String, charsmax(String), "%L", id, "TRADEITEM", KeyName, TradePiece[id]);
		}
		menu_additem(Menu, String, "-4");
		
		formatex(String, charsmax(String), "%L", id, "TRADEDOLLAR2", TradeDollars[id]);
		menu_additem(Menu, String, "-5");
		
		formatex(String, charsmax(String), "%L", id, "TRADEACCEPT");
		menu_additem(Menu, String, "-6");
		
		formatex(String, charsmax(String), "%L", id, "TRADEREJECT");
		menu_additem(Menu, String, "-7");
	}
	else if(TradeID[id] == 0)
	{
		for(new i; i < MAXP; i++)
		{
			new NumToStr[6];
			if(is_user_connected(i))
			{
				if(i == id || is_user_bot(i))
					continue;
					
				if(TradeFounding[i] == 0 && inTrade[i] == 0)
				{
					num_to_str(i, NumToStr, 5);
					formatex(String, charsmax(String), "%s", Name[i]);
					menu_additem(Menu, String, NumToStr);
				}
			}
		}
	}
	else if(TradeID[id] > 0)
	{
		print_color(id, "!g%s!y %L", Prefix, id, "DONTACCEPTEDTRADE");
		return;
	}

	menu_display(id, Menu);
}
public TradeMenuh(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	
	new x = str_to_num(Data);
	
	if(x <= 0)
	{
		switch(x)
		{
			case 0 : TradeMenu(id);
			
			case -3 : {
				if(PendingTrade > MAXTRADEINSAMETIME)
				{
					print_color(id, "!g%s!y %L", Prefix, id, "BLOCKTRADE");
					return;
				}
				
				TradeFounding[id] = 0;
				inTrade[id] = 1;
				new kid;
				if(TradePartner[id] > 0)
					kid = TradePartner[id];
				else
					kid = TradeID[id];
				inTrade[kid] = 1;
				TradePiece[id] = 0;
				TradePiece[kid] = 0;
				PTradeId[id] = 1;
				PTradeId[kid] = 1;
				TradeMenu(id);
				TradeMenu(kid);
				PendingTrade++;
			}
			
			case -2 : {
				new kid;
				if(TradePartner[id] > 0)
					kid = TradePartner[id];
				else
					kid = TradeID[id];
				inTrade[id] = 0;
				TradePartner[id] = 0;
				TradeFounding[id] = 0;
				inTrade[kid] = 0;
				TradeID[kid] = 0;
				TradeID[id] = 0;
			}
			
			case -4 : {
				TChooseItem(id);
			}
			
			case -5 : {
				client_cmd(id, "messagemode TRADEDOLLARS");
			}
			
			case -6 : {
				new kid;
				
				if(TradePartner[id] > 0)
					kid = TradePartner[id];
				else
					kid = TradeID[id];
					
				Accept[id] = 1;
				
				if(Accept[id] == 1 && Accept[kid] == 1)
				{
					Trade(id, kid);
				}
				else
				{
					MainMenu(id);
				}
			}
			
			case -7 : {
				new kid;
				if(TradePartner[id] > 0)
					kid = TradePartner[id];
				else
					kid = TradeID[id];
				
				inTrade[id] = 0;
				TradePartner[id] = 0;
				TradeFounding[id] = 0;
				TradeID[id] = 0;
				inTrade[kid] = 0;
				TradePartner[kid] = 0;
				TradeFounding[kid] = 0;
				TradeID[kid] = 0;
				PTradeId[id] = 0;
				PTradeId[kid] = 0;
				PendingTrade--;
			}
		}
	}
	else
	{
		if(PendingTrade > MAXTRADEINSAMETIME && PTradeId[id] == 0)
		{
			print_color(id, "!g%s!y %L", Prefix, id, "BLOCKTRADE");
			return;
		}
			
		TradeID[id] = x;
		print_color(x, "!g%s!y %L", Prefix, x, "WANTTRADE2", Name[id]);
		TradeFounding[x] = 1;
		TradeFounding[id] = 0;
		inTrade[id] = 1;
		TradePartner[x] = id;
		remove_task(TradeID[id]+9929);
		set_task(30.0, "DeleteTrade", TradeID[id]+9929);
	}
}

public DeleteTrade(id) 
{
	id = id - 9929;
	if(Logined[id])
	{
		if(inTrade[id] == 0)
		{
			inTrade[id] = 0;
			TradePartner[id] = 0;
			TradeFounding[id] = 0;
		}
	}
}

public Trade(x, y) {
	if(Logined[x] && Logined[y] ||
	inTrade[x] == 1 && inTrade[y] == 1  ||
	Accept[x] == 1 && Accept[y] == 1)
	{
		PendingTrade--;
		
		if(TradeItem[x] > 0 && TradeItem[x] <= 90+MAXKNIFESKINS)
		{
			Weapons[y][TradeItem[x]] += TradePiece[x];
			Weapons[x][TradeItem[x]] -= TradePiece[x];
		}
		else if(TradeItem[x] > 90+MAXKNIFESKINS && TradeItem[x] <= 90+MAXKNIFESKINS+MAXCASES)
		{
			Cases[y][TradeItem[x]-(90+MAXKNIFESKINS)] += TradePiece[x];
			Cases[x][TradeItem[x]-(90+MAXKNIFESKINS)] -= TradePiece[x];
		}
		else if(TradeItem[x] > 0)
		{
			Keys[y] += TradePiece[x];
			Keys[x] -= TradePiece[x];
		}
		
		if(TradeItem[y] > 0 && TradeItem[y] <= 90+MAXKNIFESKINS)
		{
			Weapons[y][TradeItem[y]] -= TradePiece[y];
			Weapons[x][TradeItem[y]] += TradePiece[y];
		}
		else if(TradeItem[y] > 90+MAXKNIFESKINS && TradeItem[y] <= 90+MAXKNIFESKINS+MAXCASES)
		{
			Cases[y][TradeItem[y]-(90+MAXKNIFESKINS)] -= TradePiece[y];
			Cases[x][TradeItem[y]-(90+MAXKNIFESKINS)] += TradePiece[y];
		}
		else if(TradeItem[y] > 0)
		{
			Keys[y] -= TradePiece[y];
			Keys[x] += TradePiece[y];
		}
		
		Dollars[x] += TradeDollars[y];
		Dollars[y] += TradeDollars[x];
		Dollars[x] -= TradeDollars[x];
		Dollars[y] -= TradeDollars[y];
		
		print_color(x, "!g%s!y %L", Prefix, x, "SUCCESSTRADE");
		print_color(y, "!g%s!y %L", Prefix, y, "SUCCESSTRADE");
		
		DeleteTradeandMarket(x);
		DeleteTradeandMarket(y);
		
		show_menu(x, 0, "^n", 1);
		show_menu(y, 0, "^n", 1);
		
		set_task(0.5, "SQL_UpdateUser", x);
		set_task(0.5, "SQL_UpdateUser", y);
		
		PTradeId[x] = 0;
		PTradeId[y] = 0;
	}	
}

public TChooseItem(id)
{
	new String[128];
	formatex(String, charsmax(String), "%L", id, "CHOOSEITEM");
	new Menu = menu_create(String, "TChooseItemh");
	
	for(new i = 1; i < sizeof(SkinData); i++)
	{
		if(Weapons[id][i] > 0 && strlen(SkinDataTrade[i]) > 1)
		{
			new NumToString[6];
			num_to_str(i, NumToString, 5);
			
			if(SkinData[i][3][0] != CSW_KNIFE)
				formatex(String, charsmax(String), "%s%s \y(%d)", RareData[SkinData[i][4][0]], SkinDataTrade[i], Weapons[id][i]);
			else
				formatex(String, charsmax(String), "%s%s \w(%d)", RareData[SkinData[i][4][0]], SkinDataTrade[i], Weapons[id][i]);
			menu_additem(Menu, String, NumToString);
		}
	}
	
	for(new i = 1; i < sizeof(Case_Data); i++)
	{
		if(Cases[id][i] > 0)
		{
			new NumToString[6];
			num_to_str(i+sizeof(SkinData), NumToString, 5);
			formatex(String, charsmax(String), "%s \r(%d)", Case_Data[i][0], Cases[id][i]);
			menu_additem(Menu, String, NumToString);
		}
	}
	
	if(Keys[id] > 0)
	{
		new NumToString[6];
		num_to_str(1+sizeof(SkinData)+sizeof(Case_Data), NumToString, 5);
		formatex(String, charsmax(String), "%s \r(%d)", KeyName, Keys[id]);
		menu_additem(Menu, String, NumToString);
	}
	
	menu_display(id, Menu);
}

public TChooseItemh(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	new x = str_to_num(Data);
	
	TradeItem[id] = x;
	client_cmd(id, "messagemode TRADEPIECE");
}

public MChooseItem(id)
{
	new String[128];
	formatex(String, charsmax(String), "%L", id, "CHOOSEITEM");
	new Menu = menu_create(String, "MChooseItemh");
	
	for(new i = 1; i < sizeof(SkinData); i++)
	{
		if(Weapons[id][i] > 0 && strlen(SkinDataTrade[i]) > 1)
		{
			new NumToString[6];
			num_to_str(i, NumToString, 5);
			
			if(SkinData[i][3][0] != CSW_KNIFE)
				formatex(String, charsmax(String), "%s%s \y(%d)", RareData[SkinData[i][4][0]], SkinDataTrade[i], Weapons[id][i]);
			else
				formatex(String, charsmax(String), "%s%s \w(%d)", RareData[SkinData[i][4][0]], SkinDataTrade[i], Weapons[id][i]);
			menu_additem(Menu, String, NumToString);
		}
	}
	
	for(new i = 1; i < sizeof(Case_Data); i++)
	{
		if(Cases[id][i] > 0)
		{
			new NumToString[6];
			num_to_str(i+sizeof(SkinData), NumToString, 5);
			formatex(String, charsmax(String), "%s \r(%d)", Case_Data[i][0], Cases[id][i]);
			menu_additem(Menu, String, NumToString);
		}
	}
	
	if(Keys[id] > 0)
	{
		new NumToString[6];
		num_to_str(1+sizeof(SkinData)+sizeof(Case_Data), NumToString, 5);
		formatex(String, charsmax(String), "%s \r(%d)", KeyName, Keys[id]);
		menu_additem(Menu, String, NumToString);
	}
	
	menu_display(id, Menu);
}

public MChooseItemh(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	new x = str_to_num(Data);
	
	MarketItem[id] = x;
	MarketMenu(id);
}

public cmdDollarM(id)
{
	if(inTrade[id] == 1 || !Logined[id])
		return;
	
	new Price, Data[32];
	read_args(Data, charsmax(Data));
	remove_quotes(Data);
	
	Price = str_to_num(Data);
	
	if(Price <= MinDollarMarket)
	{
		print_color(id, "!g%s!y %L", Prefix, id, "LOWPRICE", MinDollarMarket);
		client_cmd(id, "messagemode MARKETDOLLAR");
		MarketMenu(id);
	}
	else if(MaxDollarMarket >= Price)
	{
		MarketDollar[id] = Price;
		MarketMenu(id);
	}
	else
	{
		print_color(id, "!g%s!y %L", Prefix, id, "HIGHPRICE", MaxDollarMarket);
		client_cmd(id, "messagemode MARKETDOLLAR");
		MarketMenu(id);
	}
}

public cmdDollarT(id)
{
	if(inTrade[id] == 0 || !Logined[id])
		return;
	
	new Piece, Data[32], kid;
	read_args(Data, charsmax(Data));
	remove_quotes(Data);
	
	Piece = str_to_num(Data);
	
	if(TradePartner[id] > 0)
		kid = TradePartner[id];
	else
		kid = TradeID[id];
	
	if(Piece <= 0)
	{
		client_cmd(id, "messagemode TRADEDOLLARS");
	}
	else if(Dollars[id] >= Piece)
	{
		TradeDollars[id] = Piece;
		TradeMenu(id);
		TradeMenu(kid);
		Accept[id] = 0;
		Accept[kid] = 0;
	}
	else
	{
		TradeDollars[id] = Dollars[id];
		TradeMenu(id);
		TradeMenu(kid);
		Accept[id] = 0;
		Accept[kid] = 0;
	}
}
public cmdPiece(id)
{
	new kid;
	
	if(TradePartner[id] > 0)
		kid = TradePartner[id];
	else
		kid = TradeID[id];
		
	if(inTrade[id] == 0 || inTrade[kid] == 0 || !Logined[id])
		return;
	
	new Piece, Data[32];
	read_args(Data, charsmax(Data));
	remove_quotes(Data);
	
	Piece = str_to_num(Data);
	
	if(TradeItem[id] > 0 && TradeItem[id] <= 90+MAXKNIFESKINS)
	{
		if(Weapons[id][TradeItem[id]] >= Piece && Piece >= 1)
		{
			TradePiece[id] = Piece;
			TradeMenu(id);
			TradeMenu(kid);
			Accept[id] = 0;
			Accept[kid] = 0;
		}
	}
	else if(TradeItem[id] > 90+MAXKNIFESKINS && TradeItem[id] <= 90+MAXKNIFESKINS+MAXCASES)
	{
		if(Cases[id][TradeItem[id]-(90+MAXKNIFESKINS)] >= Piece && Piece >= 1)
		{
			TradePiece[id] = Piece;
			TradeMenu(id);
			TradeMenu(kid);
			Accept[id] = 0;
			Accept[kid] = 0;
		}
	}
	else if(TradeItem[id] > 0)
	{
		if(Keys[id] >= Piece && Piece >= 1)
		{
			TradePiece[id] = Piece;
			TradeMenu(id);
			TradeMenu(kid);
			Accept[id] = 0;
			Accept[kid] = 0;
		}
	}
	else
	{
		TradePiece[id] = 0;
		TradeMenu(id);
		TradeMenu(kid);
		Accept[id] = 0;
		Accept[kid] = 0;
		return;
	}
}

public RegMenu(id)
{
	if(ServerLoaded == 0)
	{
		print_color(id, "!g%s!y %L", Prefix, id, "SERVERLOADING");
		return;
	}
	
	new String[128];
	formatex(String, charsmax(String), "%L", id, "REGISTERMENU");
	new menu = menu_create(String, "RegMenuh" );
		
	if(strlen(User[id]) > 0)
	{
		formatex(String, charsmax(String), "%L", id, "USERNAME", User[id]);
		menu_additem(menu, String, "1");
		
		formatex(String, charsmax(String), "%L^n", id, "PASSWORD", Password[id]);
		menu_additem(menu, String, "2");
	}
	else
	{
		formatex(String, charsmax(String), "%L", id, "USERNAME2", User[id]);
		menu_additem(menu, String, "1");
	}
	
	if(strlen(User[id]) > 0 && strlen(Password[id]) > 0 && UserLoad[id] == 0 && inProgress[id] == 0)
	{
		if(Found[id])
		{
			formatex(String, charsmax(String), "%L", id, "LOGIN");
			menu_additem(menu, String, "3");
		}
		else
		{
			formatex(String, charsmax(String), "%L", id, "REGISTER");
			menu_additem(menu, String, "4");
		}
	}
	
	menu_display(id, menu);
}

public RegMenuh(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	
	new x = str_to_num(Data);
	
	switch(x)
	{
		case 1 : {
			client_cmd(id, "messagemode MY_USERNAME");
			RegMenu(id);
		}
		
		case 2 : {
			client_cmd(id, "messagemode MY_PASSWORD");
			RegMenu(id);
		}
		
		case 3 : {
			if(inProgress[id] == 0)
			{
				inProgress[id] = 1;
				print_color(id, "!g%s!y %L", Prefix, id, "LOGINPENDING");
				RegisterMod[id] = 1;
				SQL_Check(id);
				RegMenu(id);
			}
			else
			{
				RegMenu(id);
			}
		}
		
		case 4 : {
			if(inProgress[id] == 0)
			{
				inProgress[id] = 1;
				print_color(id, "!g%s!y %L", Prefix, id, "REGISTERPENDING");
				RegisterMod[id] = 2;
				SQL_Check(id);
				RegMenu(id);
			}
			else
			{
				RegMenu(id);
			}
		}
	}
}

public SQL_RegCheck(id)
{
	new szQuery[128], Len, a[32];
	
	formatex(a, 31, "%s", User[id]);

	replace_all(a, 31, "\", "\\");
	replace_all(a, 31, "'", "\'");
	
	Len += formatex(szQuery[Len], 128, "SELECT * FROM globaloffensive ");
	Len += formatex(szQuery[Len], 128-Len,"WHERE USER = '%s'", a);
	
	new szData[2];
	szData[0] = id;
	szData[1] = get_user_userid(id);
	
	SQL_ThreadQuery(SQL_TUPLE, "SQL_RegCheckResult", szQuery, szData, 2);
	
	UserLoad[id] = 1;
}

public SQL_RegCheckResult(FailState, Handle:Query, Error[], Errcode, szData[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("%s", Error);
		return;
	}
	
	new id = szData[0];
	
	if(szData[1] != get_user_userid(id))
		return;
	
	if(SQL_NumRows(Query) > 0)
	{
		Found[id] = true;
	}
	else
	{
		Found[id] = false;
	}
	
	UserLoad[id] = 0;
	RegMenu(id);
}

public SQL_Check(id)
{
	new szQuery[128], Len, a[32];
	
	formatex(a, 31, "%s", User[id]);

	replace_all(a, 31, "\", "\\");
	replace_all(a, 31, "'", "\'");
	
	Len += formatex(szQuery[Len], 128, "SELECT * FROM globaloffensive ");
	Len += formatex(szQuery[Len], 128-Len,"WHERE USER = '%s'", a);
	
	new szData[2];
	szData[0] = id;
	szData[1] = get_user_userid(id);
	
	SQL_ThreadQuery(SQL_TUPLE, "SQL_CheckResult", szQuery, szData, 2);
}

public SQL_CheckResult(FailState, Handle:Query, Error[], Errcode, szData[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("%s", Error);
		return;
	}
	
	new id = szData[0];
	
	if(szData[1] != get_user_userid(id))
		return;
	
	if(RegisterMod[id] == 2)
	{	
		if(SQL_NumRows(Query) > 0)
		{
			print_color(id, "!g%s!y %L", Prefix, id, "USERNAMEUSING");
			inProgress[id] = 0;
			RegMenu(id);
		}
		else
		{
			SQL_NewAccount(id);
		}
	}
	else if(RegisterMod[id] == 1)
	{
		if(SQL_NumRows(Query) == 0)
		{
			print_color(id, "!g%s!y %L", Prefix, id, "BADPW");
			inProgress[id] = 0;
			RegMenu(id);
		}
		else
		{
			SQL_UserLoad(id);
		}
	}
}

public SQL_NewAccount(id)
{
	new szQuery[512], Len, a[32], b[32], c[32];
	
	formatex(a, 31, "%s", User[id]);
	formatex(b, 31, "%s", Password[id]);
	formatex(c, 31, "%s", Name[id]);

	replace_all(a, 31, "\", "\\");
	replace_all(a, 31, "'", "\'"); 
	replace_all(b, 31, "\", "\\");
	replace_all(b, 31, "'", "\'"); 
	replace_all(c, 31, "\", "\\");
	replace_all(c, 31, "'", "\'");
	 
	Len += formatex(szQuery[Len], 511, "INSERT INTO globaloffensive ");
	Len += formatex(szQuery[Len], 511-Len,"(USER,PW,NAME) VALUES('%s','%s','%s')", a, b, c);
	
	new szData[2];
	szData[0] = id;
	szData[1] = get_user_userid(id);

	SQL_ThreadQuery(SQL_TUPLE,"SQL_NewAccountResult", szQuery, szData, 2);
}

public SQL_NewAccountResult(FailState, Handle:Query, Error[], Errcode, szData[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("%s", Error);
		return;
	}
		
	new id = szData[0];
	
	if(szData[1] != get_user_userid(id))
		return;
	
	inProgress[id] = 0;
	RegisterMod[id] = 2;
	print_color(id, "!g%s!y %L", Prefix, id, "REGISTERED");
	print_color(id, "!g%s!y %L", Prefix, id, "REGDATAS", User[id], Password[id]);
	SQL_RegCheck(id);
	
	return;
}

public SQL_UserLoad(id)
{
	new szQuery[256], Len, a[32];
	
	formatex(a, 31, "%s", User[id]);

	replace_all(a, 31, "\", "\\");
	replace_all(a, 31, "'", "\'");
	
	Len += formatex(szQuery[Len], 256, "SELECT * FROM globaloffensive ");
	Len += formatex(szQuery[Len], 256-Len,"WHERE USER = '%s'", a);
	
	new szData[2];
	szData[0] = id;
	szData[1] = get_user_userid(id);

	SQL_ThreadQuery(SQL_TUPLE,"SQL_UserLoadResult", szQuery, szData, 2);
}

public SQL_UserLoadResult(FailState, Handle:Query, Error[], Errcode, szData[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("%s", Error);
		return;
	}
	else
	{
		new id = szData[0];
		
		if(szData[1] != get_user_userid(id))
			return;
		
		new SqlPassword[32], i;
		SQL_ReadResult(Query, 2, SqlPassword, 31);
		
		if(equal(Password[id], SqlPassword))
		{	
			SQL_ReadResult(Query, 2, Password[id], 31);
			Activity[id] = SQL_ReadResult(Query, 132);
			
			if(Activity[id] > 0)
			{
				print_color(id, "!g%s!y %L", Prefix, id, "USERUSING");
				inProgress[id] = 0;
				RegMenu(id);
				return;
			}
			
			UserID[id] = SQL_ReadResult(Query, 0);
			
			Dollars[id] = SQL_ReadResult(Query, 4);
			Keys[id] = SQL_ReadResult(Query, 11);
			
			for(i = 1; i < sizeof(Case_Data); i++)
			{
				Cases[id][i] = SQL_ReadResult(Query, 4+i);
			}
			
			for(i = 1; i < sizeof(SkinData); i++)
			{
				Weapons[id][i] = SQL_ReadResult(Query, 11+i);
			}
			
			Activity[id] = 1;
			
			Kills[id] = SQL_ReadResult(Query, 133);
			CurrentRank[id] = SQL_ReadResult(Query, 134);
			
			if(CurrentRank[id] == 0)
			{
				CurrentRank[id] = 1;
			}
			
			SQL_UpdateActivity(id);
			
			print_color(id, "!g%s!y %L", Prefix, id, "LOGINED");
			
			inProgress[id] = 0;
			Logined[id] = true;
			MainMenu(id);
		}
		else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "BADPW");
			inProgress[id] = 0;
			RegMenu(id);
		}
	}
}

public cmdUser(id)
{
	if(Logined[id])
	{
		return PLUGIN_HANDLED;
	}
	
	if(UserLoad[id] == 1)
	{
		RegMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new cmdData[32], cmdLength;
	cmdData[0] = EOS;
	read_args(cmdData, 31);
	remove_quotes(cmdData);
	
	cmdLength = strlen(cmdData);
	
	if(cmdLength < 4)
	{
		print_color(id, "!g%s!y %L", Prefix, id, "SHORT");
		return PLUGIN_HANDLED;
	}
	
	if(cmdLength > 19)
	{
		print_color(id, "!g%s!y %L", Prefix, id, "LONG");
		return PLUGIN_HANDLED;
	}
	
	copy(User[id], 31, cmdData);
	SQL_RegCheck(id);
	return PLUGIN_HANDLED;
}

public cmdPassword(id)
{
	if(Logined[id] || strlen(User[id]) == 0)
	{
		return PLUGIN_HANDLED;
	}
	
	new cmdData[32], cmdLength;
	cmdData[0] = EOS;
	read_args(cmdData, 31);
	remove_quotes(cmdData);
	
	cmdLength = strlen(cmdData);
	
	if(cmdLength < 4)
	{
		print_color(id, "!g%s!y %L", Prefix, id, "SHORT");
		return PLUGIN_HANDLED;
	}
	
	if(cmdLength > 19)
	{
		print_color(id, "!g%s!y %L", Prefix, id, "LONG");
		return PLUGIN_HANDLED;
	}
	
	copy(Password[id], 31, cmdData);
	RegMenu(id);
	return PLUGIN_HANDLED;
}

public SQL_Results(FailState, Handle:Query, Error[], Errcode, szData[], DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("%s", Error);
		return;
	}
}

public SQL_FirstLoad() 
{
	SQL_TUPLE = SQL_MakeDbTuple(SQL_Host, SQL_User, SQL_Password, SQL_Database);
	SQL_Reload();
}

public SQL_Reload()
{
	new szQuery[256], Len;
	
	Len += formatex(szQuery[Len], 256, "UPDATE globaloffensive SET ");
	Len += formatex(szQuery[Len], 255-Len,"ACT = '0' ");
	Len += formatex(szQuery[Len], 255-Len,"WHERE ACT = '1'");
	
	SQL_ThreadQuery(SQL_TUPLE,"SQL_Results", szQuery);
	ServerLoaded = 1;
}

public SQL_UpdateActivity(id)
{
	new sQuery[512], szQuery[256], a[32];
	formatex(a, 31, "%s", Name[id]);

	replace_all(a, 31, "\", "\\");
	replace_all(a, 31, "'", "\'");
	
	formatex(szQuery, charsmax(szQuery), "UPDATE globaloffensive SET ");
	add(sQuery, charsmax(sQuery), szQuery);
	
	formatex(szQuery, charsmax(szQuery),"NAME = '%s', ", a);
	add(sQuery, charsmax(sQuery), szQuery);
	
	formatex(szQuery, charsmax(szQuery),"ACT = '%d' ", Activity[id]);
	add(sQuery, charsmax(sQuery), szQuery);
	
	formatex(szQuery, charsmax(szQuery),"WHERE Id = '%d'", UserID[id]);
	add(sQuery, charsmax(sQuery), szQuery);
	
	SQL_ThreadQuery(SQL_TUPLE, "SQL_Results", sQuery);
}

public SQL_UpdateUser(id)
{	
	if(!Logined[id])
		return;
	
	new sQuery[2000], szQuery[256];
	new a[32], i;
	formatex(a, 31, "%s", Name[id]);

	replace_all(a, 31, "\", "\\");
	replace_all(a, 31, "'", "\'");
	
	formatex(szQuery, charsmax(szQuery), "UPDATE globaloffensive SET ");
	add(sQuery, charsmax(sQuery), szQuery);
	
	formatex(szQuery, charsmax(szQuery),"NAME = '%s', ", a);
	add(sQuery, charsmax(sQuery), szQuery);
	
	formatex(szQuery, charsmax(szQuery),"DOLLAR = '%d', ", Dollars[id]);
	add(sQuery, charsmax(sQuery), szQuery);
	
	formatex(szQuery, charsmax(szQuery),"K = '%d', ", Keys[id]);
	add(sQuery, charsmax(sQuery), szQuery);
	
	formatex(szQuery, charsmax(szQuery),"KILLS = '%d', ", Kills[id]);
	add(sQuery, charsmax(sQuery), szQuery);
	
	formatex(szQuery, charsmax(szQuery),"RANK = '%d', ", CurrentRank[id]);
	add(sQuery, charsmax(sQuery), szQuery);
	
	formatex(szQuery, charsmax(szQuery),"IP = '%s', ", ipsz[id]);
	add(sQuery, charsmax(sQuery), szQuery);
	
	for(i = 1; i < sizeof(Case_Data); i++)
	{
		formatex(szQuery, charsmax(szQuery), "C%d = '%d', ", i, Cases[id][i]);
		add(sQuery, charsmax(sQuery), szQuery);
	}
	
	for(i = 1; i < sizeof(SkinData); i++)
	{
		formatex(szQuery, charsmax(szQuery), "W%d = '%d', ", i, Weapons[id][i]);
		add(sQuery, charsmax(sQuery), szQuery);
	}
	
	formatex(szQuery, charsmax(szQuery),"ACT = '%d' ", Activity[id]);
	add(sQuery, charsmax(sQuery), szQuery);
	
	formatex(szQuery, charsmax(szQuery),"WHERE Id = '%d'", UserID[id]);
	add(sQuery, charsmax(sQuery), szQuery);
	
	SQL_ThreadQuery(SQL_TUPLE, "SQL_Results", sQuery);
}

public client_putinserver(id)
{
	for(new i = 1; i < 3; i++)
		inUse[id][i] = 0;
	
	UserLoad[id] = 0;
	inProgress[id] = 0;
	Logined[id] = false;
	copy(Password[id], 31, "");
	copy(User[id], 31, "");
	get_user_name(id, Name[id], 31);
	get_user_ip(id, ipsz[id], 31, 1);
	
	Activity[id] = 0;
	DeleteTradeandMarket(id);
}

public client_authorized(id){
	if(get_user_flags(id) & 524288 == 524288){
		client_authorized_vip(id);
	}
}

public client_disconnect(id)
{
	DeleteTradeandMarket(id);

	if(Logined[id])
	{
		Logined[id] = false;
		Activity[id] = 0;
		SQL_UpdateActivity(id);
	}
	if(g_Vip[id]){
		client_disconnect_vip(id);
	}
}

public DeleteTradeandMarket(id)
{
	new kid;
	
	if(TradePartner[id] > 0)
		kid = TradePartner[id];
	else if(TradeID[id] > 0)
		kid = TradeID[id];
	
	inTrade[id] = 0;
	TradeDollars[id] = 0;
	TradeFounding[id] = 0;
	TradePartner[id] = 0;
	TradeItem[id] = 0;
	TradeID[id] = 0;
	
	if(kid > 0)
	{
		inTrade[id] = 0;
		TradeDollars[id] = 0;
		TradeFounding[id] = 0;
		TradePartner[id] = 0;
		TradeItem[id] = 0;
		TradeID[id] = 0;
		PTradeId[id] = 0;
		PTradeId[kid] = 0;
	}
}

public MMarketMenu(id)
{
	new String[128];
	formatex(String, charsmax(String), "%L", id, "MMARKET", Dollars[id]);
	new Menu = menu_create(String, "MMarketMenuh");
	
	formatex(String, charsmax(String), "%L", id, "SELLI");
	menu_additem(Menu, String, "1");
	
	formatex(String, charsmax(String), "%L", id, "BUYI");
	menu_additem(Menu, String, "2");
	
	formatex(String, charsmax(String), "%L", id, "KEYSTORE");
	menu_additem(Menu, String, "3");
	
	formatex(String, charsmax(String), "%L", id, "CASESTORE");
	menu_additem(Menu, String, "4");
	
	menu_display(id, Menu);
}

public MMarketMenuh(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	
	new x = str_to_num(Data);
	
	switch(x)
	{
		case 1 : {
			MarketMenu(id);
		}
		
		case 2 : {
			BuyMenu(id);
		}
		
		case 3 : {
			KeyMenu(id);
		}
		case 4 : {
			client_cmd(id, "messagemode ILOSC");
			CaseBuyMenu(id);
		}
	}
}

public MarketMenu(id)
{		
	new String[128], ItemName[32];
	
	if(MarketItem[id] > 0 && MarketItem[id] <= 90+MAXKNIFESKINS)
	{
		formatex(ItemName, charsmax(ItemName), "%s", SkinData[MarketItem[id]][0]);
	}
	else if(MarketItem[id] > 90+MAXKNIFESKINS && MarketItem[id] <= 90+MAXKNIFESKINS+MAXCASES)
	{
		formatex(ItemName, charsmax(ItemName), "%s", Case_Data[MarketItem[id]-(90+MAXKNIFESKINS)][0]);
	}
	else if(MarketItem[id] > 0)
	{
		formatex(ItemName, charsmax(ItemName), "%s", KeyName);
	}
	
	formatex(String, charsmax(String), "%L", id, "MARKET");
	new menu = menu_create(String, "MarketMenuh" );
	
	if(InMarket[id] == 0)
	{
		if(MarketItem[id] == 0)
		{
			formatex(String, charsmax(String), "%L^n", id, "CHOOSEITEM");
		}
		else
		{
			formatex(String, charsmax(String), "%L", id, "ITEM", ItemName);
		}
		menu_additem(menu, String, "1");
		
		formatex(String, charsmax(String), "%L", id, "CHOOSESELLITEM", MarketDollar[id]);
		menu_additem(menu, String, "2");
		
		formatex(String, charsmax(String), "%L", id, "TOMARKET");
		menu_additem(menu, String, "3");
	}
	else
	{
		formatex(String, charsmax(String), "%L", id, "INMARKET", ItemName, MarketDollar[id]);
		menu_additem(menu, String, "0");
	}
	
	menu_display(id, menu);
}

public MarketMenuh(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	
	new x = str_to_num(Data);
	
	switch(x)
	{
		case 0:
		{
			InMarket[id] = 0;
			MarketItem[id] = 0;
			MarketDollar[id] = 0;
			MChooseItem(id);
		}
		
		case 1:
		{
			MChooseItem(id);
		}
		
		case 2:
		{
			client_cmd(id, "messagemode MARKETDOLLAR");
			MarketMenu(id);
		}
		
		case 3:
		{
			if(MarketItem[id] > 0)
			{
				new ItemName[32];
	
				if(MarketItem[id] > 0 && MarketItem[id] <= 90+MAXKNIFESKINS)
				{
					formatex(ItemName, charsmax(ItemName), "%s", SkinData[MarketItem[id]][0]);
				}
				else if(MarketItem[id] > 90+MAXKNIFESKINS && MarketItem[id] <= 90+MAXKNIFESKINS+MAXCASES)
				{
					formatex(ItemName, charsmax(ItemName), "%s", Case_Data[MarketItem[id]-(90+MAXKNIFESKINS)][0]);
				}
				else if(MarketItem[id] > 0)
				{
					formatex(ItemName, charsmax(ItemName), "%s", KeyName);
				}
				
				for(new i; i < MAXP; i++)
					if(is_user_connected(i))
						print_color(i, "!g%s!y %L", Prefix, i, "SOLVEDTOMARKET", Name[id], ItemName, MarketDollar[id]);
						
				InMarket[id] = 1;
				MarketMenu(id);
			}
			else
			{
				MarketMenu(id);
			}
		}
	}
}

public BuyMenu(id)
{		
	new String[128], ItemName[32];
	
	formatex(String, charsmax(String), "%L", id, "MARKETMENUBUY", Dollars[id]);
	new Menu = menu_create(String, "BuyMenuh" );
	
	for(new i; i < MAXP; i++)
	{
		if(!is_user_connected(i) || !Logined[i] || InMarket[i] == 0)
			continue;
		
		if(MarketItem[i] > 0 && MarketItem[i] <= 90+MAXKNIFESKINS)
		{
			formatex(ItemName, charsmax(ItemName), "%s", SkinDataTrade[MarketItem[i]]);
		}
		else if(MarketItem[i] > 90+MAXKNIFESKINS && MarketItem[i] <= 90+MAXKNIFESKINS+MAXCASES)
		{
			formatex(ItemName, charsmax(ItemName), "%s", Case_Data[MarketItem[i]-(90+MAXKNIFESKINS)][0]);
		}
		else if(MarketItem[i] > 0)
		{
			formatex(ItemName, charsmax(ItemName), "%s", KeyName);
		}
		
		new Nts[3];
		num_to_str(i, Nts, 2);
		formatex(String, charsmax(String), "%L", id, "SELLITEM", ItemName, MarketDollar[i], Name[i]);
		menu_additem(Menu, String, Nts);
	}
	
	menu_display(id, Menu);
}

public BuyMenuh(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		return;
	}
	
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	
	new x = str_to_num(Data);
	
	if(InMarket[x] > 0 && MarketItem[x] > 0 && MarketDollar[x] > 0)
	{
		if(Dollars[id] < MarketDollar[x])
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");
			return;
		}
		
		if(MarketItem[x] > 0 && MarketItem[x] <= 90+MAXKNIFESKINS)
		{
			Weapons[id][MarketItem[x]]++;
			Weapons[x][MarketItem[x]]--;
		}
		else if(MarketItem[x] > 90+MAXKNIFESKINS && MarketItem[x] <= 90+MAXKNIFESKINS+MAXCASES)
		{
			Cases[id][MarketItem[x]-(90+MAXKNIFESKINS)]++;
			Cases[x][MarketItem[x]-(90+MAXKNIFESKINS)]--;
		}
		else if(MarketItem[x] > 0)
		{
			Keys[id]++;
			Keys[x]--;
		}
		
		Dollars[id] -= MarketDollar[x];
		Dollars[x] += MarketDollar[x];
		InMarket[x] = 0;
		
		new ItemName[32];
	
		if(MarketItem[id] > 0 && MarketItem[id] <= 90+MAXKNIFESKINS)
		{
			formatex(ItemName, charsmax(ItemName), "%s", SkinData[MarketItem[id]][0]);
		}
		else if(MarketItem[id] > 90+MAXKNIFESKINS && MarketItem[id] <= 90+MAXKNIFESKINS+MAXCASES)
		{
			formatex(ItemName, charsmax(ItemName), "%s", Case_Data[MarketItem[id]-(90+MAXKNIFESKINS)][0]);
		}
		else if(MarketItem[id] > 0)
		{
			formatex(ItemName, charsmax(ItemName), "%s", KeyName);
		}
		
		
		for(new i; i < MAXP; i++)
			if(is_user_connected(i))
				print_color(i, "!g%s!y %L", Prefix, i, "BUYINGITEM", Name[id], ItemName, MarketDollar[x], Name[x]);
				
		MarketDollar[x] = 0;
		MarketItem[x] = 0;
		SQL_UpdateUser(id);
		SQL_UpdateUser(x);
	}
}

public PlayerSpawn(id) 
{
	if(!is_user_alive(id))
		return;
	
}

stock PlayAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player);
	write_byte(Sequence);
	write_byte(pev(Player, pev_body));
	message_end();
}

stock print_color(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
	replace_all(msg, 190, "!g", "^4");
	replace_all(msg, 190, "!y", "^1");
	replace_all(msg, 190, "!t", "^3");   

	if(id) players[0] = id; else get_players(players, count, "ch");
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}

	return PLUGIN_HANDLED;
}

public Odrodzenie(id)
{	
	if(!task_exists(id))
		set_task(0.1, "PokazInformacje", id, _, _, "b");
	
	if(!Logined[id])
		RegMenu(id);
		
	if(is_user_bot(id))
		return PLUGIN_HANDLED;
		
	if(is_user_alive(id))
	{
		new wid=get_user_weapon(id);
		if(wid){
			new weaponname[32], weid;
			get_weaponname(wid, weaponname, 31);
			weid=find_ent_by_owner(-1, weaponname, id);
			if(weid){
				cs_set_weapon_ammo(weid, clips[wid]);	
				cs_set_user_bpammo(id, wid, CSW_MAXAMMO[wid]);
				}
			}
	}
	else
	{
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
public PokazInformacje(id) 
{
	if(Logined[id])
	{
		
		if(!is_user_connected(id))
		{
			return PLUGIN_CONTINUE;
		}

		if(!is_user_alive(id))
		{
			new target = pev(id, pev_iuser2);
			if(!target)
				return PLUGIN_CONTINUE;			
			set_hudmessage(255, 255, 255, 0.6, -1.0, 0, 0.0, 0.3, 0.0, 0.0, 2);
			ShowSyncHudMsg(id, SyncHudObj, "Nick : %s^nRanga : %s ^nKille : %u / %u^nDolary : %d$",Name[target] , Ranks[CurrentRank[target]], Kills[target], RankKills[CurrentRank[target]+1], Dollars[target]);
			return PLUGIN_CONTINUE;
		}		
		set_hudmessage(0, 255, 212, 0.03, 0.18, 0, 0.0, 0.3, 0.0, 0.0,-1);
		ShowSyncHudMsg(id, SyncHudObj, "[CS:GO Mod]^n[Nick : %s]^n[Ranga : %s ]^n[Kille : %u / %u]^n[Dolary : %d$]^n[Klucze : %d]",Name[id] , Ranks[CurrentRank[id]], Kills[id], RankKills[CurrentRank[id]+1], Dollars[id], Keys[id]);
	}
	return PLUGIN_CONTINUE;
}  
public buykey(id){
	if(Logined[id])
	{
		if(Dollars[id] >= KeyPrice){
			Dollars[id] -= KeyPrice;
			Keys[id]++;
			print_color(id, "!g%s!y %L", Prefix, id, "BUYSUCCESS");
			set_task(0.5, "SQL_UpdateUser", id);
		}
		else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");	
		}
	}
	else
	{
	print_color(id, "!g%s!y %L", Prefix, id, "NOLOGON");
	}
}

public KeyMenu(id)
{
	if(Logined[id])
	{
		new menu = menu_create("Kup Klucze:", "KM_Opcje");
		menu_additem(menu, "\r1 \wKlucz");//1
		menu_additem(menu, "\r5 \wKluczy");//2
		menu_additem(menu, "\r10 \wKluczy");//3
		menu_additem(menu, "\r25 \wKluczy");//4
		menu_display(id, menu);
	
		return PLUGIN_HANDLED;
	}
	else
	{
		print_color(id, "!g%s!y %L", Prefix, id, "NOLOGON");
	}
	return PLUGIN_CONTINUE;
}
public KM_Opcje(id, menu, item)
{
    if(!is_user_connected(id))
        return PLUGIN_CONTINUE;
   
    if(item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_CONTINUE;
    }
   
    switch(item)
    {
        case 0:
        {
            if(Dollars[id] >= KeyPrice){
			Dollars[id] -= KeyPrice;
			Keys[id]++;
			print_color(id, "!g%s!y %L", Prefix, id, "BUYSUCCESS");
			set_task(0.5, "SQL_UpdateUser", id);
		}
		else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");	
		}
        }
        case 1:   
        {
            if(Dollars[id] >= KeyPrice*5){
			Dollars[id] -= (KeyPrice*5);
			Keys[id]+= 5;
			print_color(id, "!g%s!y %L", Prefix, id, "BUYSUCCESS");
			set_task(0.5, "SQL_UpdateUser", id);
		}
		else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");	
		}
        }
        case 2:   
        {
                        if(Dollars[id] >= KeyPrice*10){
			Dollars[id] -= (KeyPrice*10);
			Keys[id]+= 10;
			print_color(id, "!g%s!y %L", Prefix, id, "BUYSUCCESS");
			set_task(0.5, "SQL_UpdateUser", id);
		}
			else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");	
		}
        }
        case 3:
        {
		if(Dollars[id] >= KeyPrice*25){
			Dollars[id] -= (KeyPrice*25);
			Keys[id]+= 25;
			print_color(id, "!g%s!y %L", Prefix, id, "BUYSUCCESS");
			set_task(0.5, "SQL_UpdateUser", id);
		}
		else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");	
		}
        }
    }
   
    return PLUGIN_CONTINUE;
}
public CaseBuyMenu(id)
{
	client_print(id, print_center, "Podaj ilosc!");
	if(Logined[id])
	{
		new menu = menu_create("Kup Skrzynke:", "CM_Opcje");
		menu_additem(menu, "\rChroma \wCase");
		menu_additem(menu, "\rChroma 2 \wCase");
		menu_additem(menu, "\rChroma 3 \wCase");
		menu_additem(menu, "\rGamma \wCase");
		menu_additem(menu, "\rGamma 2 \wCase");
		menu_additem(menu, "\rFalcion \wCase");
		menu_display(id, menu);
	
		return PLUGIN_HANDLED;
	}
	else
	{
		print_color(id, "!g%s!y %L", Prefix, id, "NOLOGON");
	}
	return PLUGIN_CONTINUE;
}
public CM_Opcje(id, menu, item)
{
    if(!is_user_connected(id))
        return PLUGIN_CONTINUE;
   
    if(item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_CONTINUE;
    }
   
    switch(item)
    {
	case 0:
        {
            if(Dollars[id] >= CasePrice){
			Dollars[id] -= CasePrice * iilosc;
			Cases[id][1]+= iilosc;
			print_color(id, "!g%s!y %L", Prefix, id, "BUYSUCCESS");
			set_task(0.5, "SQL_UpdateUser", id);
		}
		else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");	
		}
        }
	case 1:
        {
            if(Dollars[id] >= CasePrice){
			Dollars[id] -= CasePrice * iilosc;
			Cases[id][2]+= iilosc;
			print_color(id, "!g%s!y %L", Prefix, id, "BUYSUCCESS");
			set_task(0.5, "SQL_UpdateUser", id);
		}
		else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");	
		}
        }
	     case 2:
        {
            if(Dollars[id] >= CasePrice){
			Dollars[id] -= CasePrice * iilosc;
			Cases[id][3]+= iilosc;
			print_color(id, "!g%s!y %L", Prefix, id, "BUYSUCCESS");
			set_task(0.5, "SQL_UpdateUser", id);
		}
		else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");	
		}
        }
	     case 3:
        {
            if(Dollars[id] >= CasePrice){
			Dollars[id] -= CasePrice * iilosc;
			Cases[id][4]+= iilosc;
			print_color(id, "!g%s!y %L", Prefix, id, "BUYSUCCESS");
			set_task(0.5, "SQL_UpdateUser", id);
		}
		else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");	
		}
        }
	     case 4:
        {
            if(Dollars[id] >= CasePrice){
			Dollars[id] -= CasePrice * iilosc;
			Cases[id][5]+= iilosc;
			print_color(id, "!g%s!y %L", Prefix, id, "BUYSUCCESS");
			set_task(0.5, "SQL_UpdateUser", id);
		}
		else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");	
		}
        }
	     case 5:
        {
            if(Dollars[id] >= CasePrice){
			Dollars[id] -= CasePrice * iilosc;
			Cases[id][6]+= iilosc;
			print_color(id, "!g%s!y %L", Prefix, id, "BUYSUCCESS");
			set_task(0.5, "SQL_UpdateUser", id);
		}
		else
		{
			print_color(id, "!g%s!y %L", Prefix, id, "NOTENOUGHDOLLAR");	
		}
        }
	
    }
   
    return PLUGIN_CONTINUE;
}
public bind(id){
	cmdExecute(id, "bind^t^"v^"^t^"menu^"");
}

public ruletka(id){
		new losowa = random(10);
		for(new i; i < MAXP; i++)
		if(is_user_connected(i))
		if(iliczba >= MinBet && Dollars[i] >= iliczba && !(iliczba == 0))
			{
				
				Dollars[id]-=iliczba;
				if(losowa<5)
				{
					Dollars[id]+=(iliczba*2);
					print_color(id, "!g%s!y %L", Prefix, i, "BETW", iliczba*2);
					if(iliczba*2>=1000)
					{
						print_color(0, "!g%s!y %L", Prefix, i, "BETMW", Name[id],iliczba , iliczba*2);
					}

					}
					else
					{
						print_color(id, "!g%s!y %L", Prefix, i, "BETL", iliczba);
					
					}

			}
			else if(iliczba == 0)
			{
				print_color(i, "!g%s!y %L", Prefix, i, "NOTBETZERO");	
			}
			else if(iliczba < MinBet)
			{
				print_color(i, "!g%s!y %L", Prefix, i, "MINBET", MinBet);	
			}
			else
			{
				print_color(i, "!g%s!y %L", Prefix, i, "NOTENOUGHDOLLAR");	
			}
		set_task(0.5, "SQL_UpdateUser", id);
	
}
 public BetMenu(id)
{
	if(Logined[id])
	{
	
	new String[128];
	
	formatex(String, charsmax(String), "%L", id, "BETMENU", iliczba);
	new menu = menu_create(String, "BetMenuh" );
		
	if(strlen(User[id]) > 0)
	{
		formatex(String, charsmax(String), "%L", id, "YOURBET", iliczba);
		menu_additem(menu, String, "1");
		
		
		formatex(String, charsmax(String), "%L^n", id, "BET", Name[id]);
		menu_additem(menu, String, "2");
	}
	
	menu_display(id, menu);
	}
	else
	{
		print_color(id, "!g%s!y %L", Prefix, id, "NOLOGON");
	}
}

public BetMenuh(id, Menu, Item)
{
	new Data[14], Line[32];
	new Access, Callback;
	menu_item_getinfo(Menu, Item, Access, Data, charsmax(Data), Line, charsmax(Line), Callback);
	
	new x = str_to_num(Data);
	
	switch(x)
	{
		case 1: {
			client_cmd(id, "messagemode BET");
			BetMenu(id);
		}
		case 2 : {
			ruletka(id);
			BetMenu(id);
		}
		
	}
}
public IloscCMD(id)
{
        read_argv(1,szilosc,1000);
        iilosc=str_to_num(szilosc);
	return PLUGIN_CONTINUE;
}
public BETcmd(id)
{
        read_argv(1,szliczba,1000);
        iliczba=str_to_num(szliczba);
	if(szliczba[id]>0)
	BetMenu(id);
}
public AdminCMD(id)
{
        read_argv(1,szliczba1[id],1000);
        iliczba1=str_to_num(szliczba1[id]); 
	if(iliczba1>0)
	{
		if(tryb[id] == 1)
		{
			Keys[pid]+=iliczba1;
			tryb[id] = 0;
			set_task(0.5, "SQL_UpdateUser", pid);
		}
		if(tryb[id] == 2)
		{
			CaseGiveMenu(id);
			tryb[id] = 0;
		}
		if(tryb[id] == 3)
		{
			Dollars[pid]+=iliczba1;
			tryb[id] = 0;
			set_task(0.5, "SQL_UpdateUser", pid);
		}
	}
}
public admin_menu(id)
{
	if(Logined[id] && get_user_flags(id) & ADMIN_BAN)
	{
		new menu = menu_create("Admin Menu", "AM_Opcje");
		menu_additem(menu, "\rDaj \wKlucze");//1
		menu_additem(menu, "\rDaj \wSkrzynki");//2
		menu_additem(menu, "\rDaj \wDollary");//2
		menu_additem(menu, "\yWymus Zapis");//2
		menu_display(id, menu);
	
		return PLUGIN_HANDLED;
	}
	else
	{
		print_color(id, "!g%s!y %L", Prefix, id, "NOPREM");
	}
	return PLUGIN_CONTINUE;
}
public AM_Opcje(id, menu, item)
{
    if(!is_user_connected(id))
        return PLUGIN_CONTINUE;
   
    if(item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_CONTINUE;
    }
   
    switch(item)
    {
	case 0:
        {
	apmenu(id);
	tryb[id] = 1;
        }	
	case 1:
        {
	apmenu(id);
	tryb[id] = 2;
        }
	case 2:
        {
	apmenu(id);
	tryb[id] = 3;
        }
	case 3:
        {
	for(new i; i < MAXP; i++)
	if(is_user_connected(i))
	SQL_UpdateUser(i);
        }
    }
   
    return PLUGIN_CONTINUE;
}
public apmenu(id){
 
	menu_display(id,buildPlayersMenu(1));
	return PLUGIN_HANDLED;
}

buildPlayersMenu(level){
	new mPlayers = menu_create("Wybierz Gracza", "mh_Players"); // Menu Players
	new id,szUserName[50];
	get_players(g_Players, g_playerCount);
	for (new i=0; i<g_playerCount; i++){
		id = g_Players[i];
		get_user_name(id, szUserName,32);
		menu_additem(mPlayers, szUserName, "", level, mcbPlayers);
	}
	return mPlayers;
}
public mh_Players(id, menu, item){
	pid = g_Players[item];
	client_cmd(id, "messagemode WARTOSC");

}
public CaseGiveMenu(id)
{
	if(Logined[id] && get_user_flags(id) & ADMIN_BAN)
	{
		new menu = menu_create("Daj Skrzynke:", "CGM_Opcje");
		menu_additem(menu, "\rChroma \wCase");
		menu_additem(menu, "\rChroma 2 \wCase");
		menu_additem(menu, "\rChroma 3 \wCase");
		menu_additem(menu, "\rGamma \wCase");
		menu_additem(menu, "\rGamma 2 \wCase");
		menu_additem(menu, "\rFalcion \wCase");
		menu_display(id, menu);
	}
}
public CGM_Opcje(id, menu, item)
{
    if(!is_user_connected(id))
        return PLUGIN_CONTINUE;
   
    if(item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_CONTINUE;
    }
   
    switch(item)
    {
	case 0:
        {
			Cases[pid][1]+=iliczba1;
			set_task(0.5, "SQL_UpdateUser", pid);
		}
	case 1:
        {
			Cases[pid][2]+=iliczba1;
			set_task(0.5, "SQL_UpdateUser", pid);
		}
	case 2:
        {
			Cases[pid][3]+=iliczba1;
			set_task(0.5, "SQL_UpdateUser", pid);
		}
	case 3:
        {
			Cases[pid][4]+=iliczba1;
			set_task(0.5, "SQL_UpdateUser", pid);
		}
	case 4:
        {
			Cases[pid][5]+=iliczba1;
			set_task(0.5, "SQL_UpdateUser", pid);
		}
	case 5:
        {
			Cases[pid][6]+=iliczba1;
			set_task(0.5, "SQL_UpdateUser", pid);
		}
    }
    return PLUGIN_CONTINUE;
}
public client_authorized_vip(id){
	g_Vip[id]=true;
}
public client_disconnect_vip(id){
	g_Vip[id]=false;
}
public bomb_planted(id){
	if(is_user_alive(id)){
		if(Bonus == 1)
		{
			if(g_Vip[id] && VipBonus == 1)
			{
				print_color(id, "!g%s!y %L", Prefix, id, "BOMBVIPBONUS", VipBonusValue);
				Dollars[id]+=VipBonusValue;
			}
			else
			{
				print_color(id, "!g%s!y %L", Prefix, id, "BOMBBONUS", BonusValue);
				Dollars[id]+=BonusValue;
			}
		}
	}
}
public bomb_defused(id){
	if(is_user_alive(id)){
		if(Bonus == 1)
		{
			if(g_Vip[id] && VipBonus == 1)
			{
				print_color(id, "!g%s!y %L", Prefix, id, "DEFVIPBONUS", VipBonusValue);
				Dollars[id]+=VipBonusValue;
			}
			else
			{
				print_color(id, "!g%s!y %L", Prefix, id, "DEFBONUS", BonusValue);
				Dollars[id]+=BonusValue;
			}
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
