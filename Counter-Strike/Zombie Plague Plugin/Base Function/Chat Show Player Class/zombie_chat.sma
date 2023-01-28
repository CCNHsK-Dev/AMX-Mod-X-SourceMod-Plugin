/* -------------------------------------------------------------------------------------------------
*
* Plugin generaly made for my friend that begged it from me :P
* Basicly got to thank alot ppl to correct the mistakes ;)
*
* If you want to enable BIOHAZARD zombie mod, delete the doubleslash from begining                */
                                                      /*
--------------------------------------------------------------------------------------------------*/

/* 6/4/2010 */

#include <amxmodx> //inluding main amxx
#include <zombieplague> //inluding zp stuff

#define PLUGIN "[ZP] Chat" //plugin name
#define VERSION "1.4" //version
#define AUTHOR "Lure.d" //author

#define IsZombie zp_get_user_nemesis
#define IsSurvivor zp_get_user_survivor

public plugin_init() 
{
	register_plugin( PLUGIN , VERSION , AUTHOR );
	register_cvar( "zmc_version" , VERSION , FCVAR_SPONLY|FCVAR_SERVER )
	
	register_clcmd( "say" , "say_handle" ); 
	register_clcmd( "say_team" , "say_handle" ); 
}

public say_handle(plr) 
{ 
	static chat[ 175 ], name[ 32 ];
	
	read_args( chat , charsmax( chat ) );
	remove_quotes( chat ); 
	
	if ( equali ( chat[ 0 ] , "/" ) ) return PLUGIN_HANDLED;
	
	get_user_name( plr , name , charsmax( name ) ); 
	
	if (zp_get_user_zombie(plr))
	{
		print( 0 , "\g[%s] \y%s: %s" , IsZombie(plr) ? "復仇者" : "喪屍" , name , chat ); 
		
		log_amx( "%s -> [%s]%s: %s" , PLUGIN , IsZombie(plr) ? "復仇者" : "喪屍" , name , chat ); 
	}
	else
	{
		print( 0 , "\g[%s] \y%s: %s" , IsSurvivor(plr) ? "幸存者" : "人類" , name , chat ); 
		
		log_amx( "%s -> [%s]%s: %s" , PLUGIN , IsSurvivor(plr) ? "幸存者" : "人類" , name , chat ); 
	}
	return PLUGIN_HANDLED;
}

stock print( const id , const input[ ] , any:... ) 
{
	new count = 1 , players[ 32 ] ;
	
	static msg[ 191 ] ;
	vformat( msg , 190 , input , 3 ) ;
	replace_all( msg , 190 , "\g" , "^4" ) ;
	replace_all( msg , 190 , "\y" , "^1" ) ;
	replace_all( msg , 190 , "\t" , "^3" ) ; 
	
	if(id) players[0] = id ; else get_players( players, count,"ch");
	
	for ( new i = 0 ; i < count ; i++ )
	
		if (is_user_connected(players[i])) 
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
			write_byte(players[i]) ; 
			write_string(msg) ;
			message_end() ;
		}
}
