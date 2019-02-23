#include <amxmodx>
#include <amxmisc>
#include <csgo>

#define PLUGIN "D0NCIAK GO:MOD Crack"
#define VERSION "1.0"
#define AUTHOR "BlendeR"


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
}
public plugin_natives()
{
	register_native("SprawdzLicencje05938", "nat_SprawdzLicencje", 1);
	return 0;
}
public nat_SprawdzLicencje()
{
	return 1;
}
//
//Crack http://d0naciak.pl/?p=145
//
