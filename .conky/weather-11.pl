#!/usr/bin/perl

# $Id: weather.pl,v 1.1 2018/05/02 01:38:27 alexkemp Exp $

# Brief Description
# =================
#
# utility to replace conky weather using aviationweather.gov (US Govt)
# conky weather stopped working 2016 August
# (weather.noaa.gov/pub/data/observations/metar/stations/ withdrawn)
#
# Given an airport site code on the command line, weather.pl
# fetches the weather and displays it on the command-line.

# Requires libgeo-metar-perl
#          libswitch-perl

# Here are some example airports:
# East Midlands : EGNX
# LA            : KLAX
# Dallas        : KDFW
# Detroit       : KDTW
# Chicago       : KMDW
#
# 2018-05-02 v 1.1 added file caching (reduce hammer on remote site)
# 2016-09-18 v 1.0 started

my $HELP = "
USAGE:   $0 <locationCode> <responseType>
  example: $0 EGNX ALT_HP
           (East Midlands for barometer-in-mbar)

list of location codes:
  http://weather.rap.ucar.edu/surface/stations.txt
METAR source code:
  http://jeremy.zawodny.com/perl/Geo-METAR/METAR.html

list of possible responses (date_time: 301820Z):
  ALT          (eg '29.766222864'    inches)
  ALT_HP       (eg '1008'         millibars)
  DEW_C        (eg '-01'     temperature °C)
  DEW_F        (eg '30.2'    temperature °F)
  RH           (eg '55' relative humidity %)
  SKY          (eg 'Few at 4600ft'         )
  TEMP_C       (eg '08'      temperature °C)
  TEMP_F       (eg '46.4'    temperature °F)
  TIME         (eg '18:20 UTC'             )
  TYPE         (eg 'Routine Weather Report')
  VISIBILITY   (eg '9999 meters'           )
  WIND_DIR_ABB (eg 'NNW'                   )
  WIND_DIR_DEG (eg '330'                   )
  WIND_DIR_ENG (eg 'North/Northwest'       )
  WIND_KTS     (eg '13'          knots     )
  WIND_MPH     (eg '14.96013285' mph       )
  WIND_MS      (eg '6.687777772' m/sec     )
  WIND_VAR     (eg ''                      )
  METAR        (eg 'EGNX 301820Z 33013KT 9999 FEW046 08/M01 Q1008')

Version: v1.1 2018-05-02\n";

# remote site providing metar info
my $REMOTE = "https://www.aviationweather.gov/metar/data";
# Get the site code requested
my ($METAR_CODE,$TYPE) = @ARGV;
# cache parameters
# file location
my $CACHE = "~/.conky/.metar_cache";
# update interval, secs
my $CACHE_UI = 1200;

die $HELP unless ($METAR_CODE && $TYPE);

# Get the modules we need.
use Geo::METAR;
use LWP::UserAgent;
use Switch;
use Time::Local;
use utf8;
use strict;

# expand the tilde (file-open will NOT auto-expand it)
$CACHE =~ s{ ^ ~ ( [^/]* ) }
           { $1
              ? (getpwnam($1))[7]
              : ($ENV{HOME} || $ENV{LOGDIR} || (getpwuid($>))[7])
           }ex;
# hash for cache
my %CACHE_HASH;
# get cache-file mod timestamp + time-now (secs since Epoch)
my $NOW = time();
my $CACHE_MTIME = (stat $CACHE)[9];
if(!$CACHE_MTIME) {
   # cache is removed
	# create value that will cause file re-create
   $CACHE_MTIME = $NOW - $CACHE_UI - 1;
}
# run from cache if remote site unavailable
my $REMOTE_IS_UP = 0; # false
my $ua = new LWP::UserAgent;
my $req = new HTTP::Request HEAD => "$REMOTE?ids=$METAR_CODE";
my $response = $ua->request($req);

if($response->is_success) {$REMOTE_IS_UP = 1;} # true
# print $response->headers()->as_string;
# aviationweather.gov does not send Last-Modified (tsk tsk)

# choose between remote access if cache not exist/old + remote is accessible, else use cache
if(($REMOTE_IS_UP) && (($NOW - $CACHE_UI) > $CACHE_MTIME)) {
   # refresh local cache from remote site
   # get the remote data and find the METAR.
   my $ua = new LWP::UserAgent;
   my $req = new HTTP::Request GET => "$REMOTE?ids=$METAR_CODE";
   my $response = $ua->request($req);

   if(!$response->is_success) {
      print $response->error_as_HTML;
      my $err_msg = $response->error_as_HTML;
      warn "$err_msg\n\n";
      die "$!";
   } else {  # if(!$response->is_success)
      # get the data and find the METAR.
      my $m = new Geo::METAR;
      my $data;
      $data = $response->as_string;               # grab response
      $data =~ s/\n//go;                          # remove newlines
      $data =~ m/($METAR_CODE\s\d+Z.*?)</go;      # find the METAR string
      my $METAR = $1;                             # keep it

      # Sanity check
      if( length( $METAR ) < 10 ) {
         die "METAR is too short! Something went wrong.";
      }

      # pass the data to the METAR module.
      $m->metar($METAR);
#     print "\$METAR=$METAR\n";
#     $m->dump;
      # from long experience with Geo::METAR v1.15, some result array values may
		# contain errors of indeterminate length. Each is thus checked & placed in
		# a hash for current & future access via file.
		my $tmp;
		my $ERR = "(Error)";
		# Relative Humidity (RH) (accurate for RH > 50%)
		# https://en.wikipedia.org/wiki/Dew_point#Simple_approximation
		# 100 - 5*(TEMP_C - DEW_C)
		# 100*(6.1094^((17.625*TD)/(243.04+TD))/6.1094^((17.625*T)/(243.04+T))) ??
		my $RH = 100 - (5*($m->TEMP_C - $m->DEW_C));
		$CACHE_HASH{'ALT'         } = $m->ALT;
		$CACHE_HASH{'ALT_HP'      } = $m->ALT_HP;
		$CACHE_HASH{'DEW_C'       } = $m->DEW_C;
		$CACHE_HASH{'DEW_F'       } = $m->DEW_F;
		$CACHE_HASH{'SKY'         } = $m->SKY;
		$CACHE_HASH{'RH'          } = $RH;
		$CACHE_HASH{'TEMP_C'      } = $m->TEMP_C;
		$CACHE_HASH{'TEMP_F'      } = $m->TEMP_F;
		$CACHE_HASH{'TIME'        } = $m->TIME;
		$CACHE_HASH{'TYPE'        } = $m->TYPE;
		$CACHE_HASH{'VISIBILITY'  } = $m->VISIBILITY;
		$CACHE_HASH{'WIND_DIR_ABB'} = $m->WIND_DIR_ABB;
		$CACHE_HASH{'WIND_DIR_DEG'} = $m->WIND_DIR_DEG;
		$CACHE_HASH{'WIND_DIR_ENG'} = $m->WIND_DIR_ENG;
		$CACHE_HASH{'WIND_KTS'    } = $m->WIND_KTS;
		$CACHE_HASH{'WIND_MPH'    } = $m->WIND_MPH;
		$CACHE_HASH{'WIND_MS'     } = $m->WIND_MS;
		$CACHE_HASH{'WIND_VAR'    } = $m->WIND_VAR;
		$CACHE_HASH{'METAR'       } = $m->METAR;
		for(keys %CACHE_HASH) {
		   $tmp = $CACHE_HASH{$_};
			if($tmp =~ m/error/i) { $CACHE_HASH{$_} = $ERR; }
			if(ref($tmp) eq "ARRAY") { $CACHE_HASH{$_} = $ERR; }
		}

      use Storable qw( nstore_fd );
      use Fcntl qw(:DEFAULT :flock);
      sysopen( DF, $CACHE, O_RDWR|O_CREAT, 0666) 
         or die "can't open $CACHE: $!";
      flock( DF, LOCK_EX)
         or die "can't lock $CACHE: $!";
      nstore_fd( \%CACHE_HASH, *DF )
         or die "can't store hash\n";
      truncate( DF, tell( DF ));
      close( DF );
   }  # if(!$response->is_success) else
} else {  # if(($REMOTE_IS_UP) && (($NOW - $CACHE_UI) > $CACHE_MTIME))
   # obtain local cache of remote site
   use Storable qw( fd_retrieve );
   use Fcntl qw(:DEFAULT :flock);
   open(DF, "< $CACHE")
	   or die "can't open $CACHE: $!";
   flock(DF, LOCK_SH)
	   or die "can't lock $CACHE: $!";
   %CACHE_HASH = %{ fd_retrieve(*DF)};
   close(DF);
}  # if(($REMOTE_IS_UP) && (($NOW - $CACHE_UI) > $CACHE_MTIME))

switch ($TYPE) {
   case "ALT"          { print $CACHE_HASH{'ALT'         };}
   case "ALT_HP"       { print $CACHE_HASH{'ALT_HP'      };}
   case "DEW_C"        { print $CACHE_HASH{'DEW_C'       };}
   case "DEW_F"        { print $CACHE_HASH{'DEW_F'       };}
   case "SKY"          { print $CACHE_HASH{'SKY'         };}
   case "RH"           { print $CACHE_HASH{'RH'          };}
   case "TEMP_C"       { print $CACHE_HASH{'TEMP_C'      };}
   case "TEMP_F"       { print $CACHE_HASH{'TEMP_F'      };}
   case "TIME"         { print $CACHE_HASH{'TIME'        };}
   case "TYPE"         { print $CACHE_HASH{'TYPE'        };}
   case "VISIBILITY"   { print $CACHE_HASH{'VISIBILITY'  };}
   case "WIND_DIR_ABB" { print $CACHE_HASH{'WIND_DIR_ABB'};}
   case "WIND_DIR_DEG" { print $CACHE_HASH{'WIND_DIR_DEG'};}
   case "WIND_DIR_ENG" { print $CACHE_HASH{'WIND_DIR_ENG'};}
   case "WIND_KTS"     { print $CACHE_HASH{'WIND_KTS'    };}
   case "WIND_MPH"     { print $CACHE_HASH{'WIND_MPH'    };}
   case "WIND_MS"      { print $CACHE_HASH{'WIND_MS'     };}
   case "WIND_VAR"     { print $CACHE_HASH{'WIND_VAR'    };}
   else                { print $CACHE_HASH{'METAR'       };}
} # switch ($TYPE)

exit;

__END__
