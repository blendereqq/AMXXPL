#if defined _csgon_included
  #endinput
#endif
#define _csgon_included

native csgo_login(id);
//Sprawdzenie czy jest zalogowany jak tak zwraca 1 jak nie 0
native csgo_get_user_dollars(id);
//Zwracanie ilosci dollarow
native csgo_get_user_keys(id);
//Zwracanie ilosci kluczy
native csgo_get_user_cases(id,cid);
//Zwracanie ilosci skrzyn
native csgo_get_user_kills(id);
//Zwracanie ilosci zabojstw
native csgo_get_user_rank(id);
//Zwraca range
native csgo_set_user_dollars(id, iDollar);
//Ustawia warotsc dollarow
//id - id gracza | iDollar - Warto?? dollarów
native csgo_set_user_keys(id, iKey);
//Ustawia wartosc kluczy
//id - id gracza | iDollar - Warto?? kluczy
native csgo_set_user_cases(id, cid ,iIlosc);
//Ustawia wartosc skrzynek
//id - id gracza | cid - id skrzynki |iIlosc - Warto?? dollarów
native csgo_set_user_kills(id,iKills);
//Ustawia wartosc skrzynek
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
