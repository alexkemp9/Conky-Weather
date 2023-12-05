#!/usr/bin/perl

# $Id: weather.pl,v 1.2 2020/11/19 16:39:25 alexkemp Exp $

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
#          (and others)

# Here are some example airports:
# East Midlands : EGNX
# LA            : KLAX
# Dallas        : KDFW
# Detroit       : KDTW
# Chicago       : KMDW
#
# 2020-11-19 v 1.2   added $DATE + $CSV (store barometer csv)
#                  changed $ERR to "" (empty string)
#                  changed order: check cache timeout first (reduce remote accesses)
# 2018-05-02 v 1.1   added file caching (reduce hammer on remote site)
# 2016-09-18 v 1.0 started

my $HELP = "
USAGE:   $0 <locationCode> <responseType>
  example: $0 EGNX ALT_HP
           (East Midlands for barometer-in-mbar)

list of location codes:
  http://weather.rap.ucar.edu/surface/stations.txt
METAR source code:
  http://jeremy.zawodny.com/perl/Geo-METAR/METAR.html

list of possible responses (date_time: 2020/11/08 22:20):
  ALT          (eg '30.061522694'     inches)
  ALT_HP       (eg '1018'          millibars)
  CSV          (eg '~/.conky/barometer.csv' )
  DATE         (eg '2020-11-08'          UTC)
  DEW_C        (eg '11'       temperature °C)
  DEW_F        (eg '51.8'     temperature °F)
  RH           (eg '100' relative humidity %)
  SKY          (eg 'Sky Clear'              )
  TEMP_C       (eg '11'       temperature °C)
  TEMP_F       (eg '51.8'     temperature °F)
  TIME         (eg '22:20 UTC'              )
  TYPE         (eg 'Routine Weather Report' )
  VISIBILITY   (eg '0600 meters'            )
  WEATHER      (eg 'No significant weather' )
  WIND_DIR_ABB (eg 'S'                      )
  WIND_DIR_DEG (eg '170'                    )
  WIND_DIR_ENG (eg 'South'                  )
  WIND_KTS     (eg '03'          knots      )
  WIND_MPH     (eg '3.45233835'  mph        )
  WIND_MS      (eg '1.543333332' m/sec      )
  WIND_VAR     (eg ''                       )
  METAR        (eg 'EGNX 082220Z 17003KT 0600 R27/P1500 RA FG BKN002 OVC010 11/11 Q1018')

Version: v1.2 2020-11-17\n";

# remote site(s) providing metar info
my $REMOTE = "https://www.aviationweather.gov/metar/data";
#my $REMOTE = "https://tgftp.nws.noaa.gov/data/observations/metar/stations";
# Get the site code requested
my ($LOCATION,$TYPE) = @ARGV;
# cache parameters
# file location
my $CACHE = "~/.conky/.metar_cache";
# update interval, secs
my $CACHE_UI = 1200;
# file location
my $CSV = "~/.conky/barometer.csv";

die $HELP unless ($LOCATION && $TYPE);

# Get the modules we need.
use strict;
use utf8;
use Capture::Tiny ':all';
use Date::Calc ':all';
use Geo::METAR;
use LWP::UserAgent;
use POSIX qw(strftime);
use Switch;
use Time::Local;

# expand the tilde (file-open will NOT auto-expand it)
$CACHE =~ s{ ^ ~ ( [^/]* ) }
           { $1
              ? (getpwnam($1))[7]
              : ($ENV{HOME} || $ENV{LOGDIR} || (getpwuid($>))[7])
           }ex;
# hash array
my %CACHE_HASH;
# expand the tilde (file-open will NOT auto-expand it)
$CSV =~ s{ ^ ~ ( [^/]* ) }
         { $1
            ? (getpwnam($1))[7]
            : ($ENV{HOME} || $ENV{LOGDIR} || (getpwuid($>))[7])
         }ex;
# get cache-file mod timestamp + time-now (secs since Epoch)
my $NOW = time();
my $CACHE_MTIME = (stat $CACHE)[9];
my $SKY;
my $WEATHER;
my $tmp;
my $ERR = "";

if(!$CACHE_MTIME) {
   # cache is removed
	# create value that will cause file re-create
   $CACHE_MTIME = $NOW - $CACHE_UI - 1;
}
# 2020-11-19 change order to check cache timeout first
#            this is to save many HEAD-checks on remote
# if cache has timed out then refresh the cache from remote
# else provide response from cache
if(($NOW - $CACHE_UI) > $CACHE_MTIME) { # cache has timed-out
   # update cache from remote unless remote site unavailable
   # first a HEAD request to make sure site is up
   my $ua = new LWP::UserAgent;
   my $req = new HTTP::Request HEAD => "$REMOTE?ids=$LOCATION";
   #my $req = new HTTP::Request HEAD => "$REMOTE/$LOCATION.TXT";
   my $response = $ua->request($req);
   if($response->is_success) { # true; remote site is responding
# print $response->headers()->as_string;
      # aviationweather.gov does not send Last-Modified (tsk tsk)
      # tgftp.nws.noaa.gov DOES send Last-Modified

      # refresh local cache from remote site
      # get the remote data and find the METAR.
      my $ua = new LWP::UserAgent;
      my $req = new HTTP::Request GET => "$REMOTE?ids=$LOCATION";
      #my $req = new HTTP::Request GET => "$REMOTE/$LOCATION.TXT";
      my $response = $ua->request($req);

      if($response->is_success) {
         # get the data and find the METAR.
         my $m = new Geo::METAR;
         my $data = $response->as_string;      # grab response
         $data =~ s/\n//go;                    # remove newlines
         $data =~ m/($LOCATION\s\d+Z.*?)</go;  # find the METAR string
         my $METAR = $1;                       # keep it

         # Sanity check
         if( length( $METAR ) < 10 ) {
            die "METAR is too short! Something went wrong.";
         }

         # pass the data to the METAR module.
         $m->metar($METAR);
# print "\$METAR=$METAR\n";
# $m->dump;
         #
         # $m->SKY, $m->WEATHER + $m->WEATHER_LOG are arrays
         # (see https://idefix.net/~koos/perl/Geo-METAR/METAR.html)
         # DUMP shows 1st array, but a bug affects each individual access
         my $stdout = capture_stdout { $m->dump; };
         $stdout =~ /SKY: (.*)/;         # find the SKY string
         $SKY = $1;                      # keep it
         $stdout =~ /WEATHER: (.*)/;     # find the WEATHER string
         $WEATHER = $1;                  # keep it
         #
         # Relative Humidity (RH) (accurate for RH > 50%)
         # https://en.wikipedia.org/wiki/Dew_point#Simple_approximation
         # 100 - 5*(TEMP_C - DEW_C)
         # 100*(6.1094^((17.625*TD)/(243.04+TD))/6.1094^((17.625*T)/(243.04+T))) ??
         my $RH = 100 - (5*($m->TEMP_C - $m->DEW_C));
         #
         # handle midnight (METAR-day may actually be yesterday):
         my $DATE;
         my $gmt = 1;                      # true
         my ($year,$month,$today) = Today($gmt);
         my $day = $m->DATE;               # actually UTC day of month, 2-digits
         if($day != $today) {              # METAR-day is yesterday
            ($year,$month,$day) = Add_Delta_Days($year,$month,$today, -1);
            $DATE = "$year-$month-$day";
         } else {
            $DATE = strftime "%F", gmtime; # ISO 8601 GMT/UTC date (YYYY-MM-DD, no DST)
         }
         $CACHE_HASH{'ALT'         } = $m->ALT;
         $CACHE_HASH{'ALT_HP'      } = $m->ALT_HP;
         $CACHE_HASH{'CSV'         } = $CSV;
         $CACHE_HASH{'DATE'        } = $DATE;
         $CACHE_HASH{'DEW_C'       } = $m->DEW_C;
         $CACHE_HASH{'DEW_F'       } = $m->DEW_F;
         $CACHE_HASH{'SKY'         } = $SKY;
         $CACHE_HASH{'RH'          } = $RH;
         $CACHE_HASH{'TEMP_C'      } = $m->TEMP_C;
         $CACHE_HASH{'TEMP_F'      } = $m->TEMP_F;
         $CACHE_HASH{'TIME'        } = $m->TIME;
         $CACHE_HASH{'TYPE'        } = $m->TYPE;
         $CACHE_HASH{'VISIBILITY'  } = $m->VISIBILITY;
         $CACHE_HASH{'WEATHER'     } = $WEATHER;
         $CACHE_HASH{'WIND_DIR_ABB'} = $m->WIND_DIR_ABB;
         $CACHE_HASH{'WIND_DIR_DEG'} = $m->WIND_DIR_DEG;
         $CACHE_HASH{'WIND_DIR_ENG'} = $m->WIND_DIR_ENG;
         $CACHE_HASH{'WIND_KTS'    } = $m->WIND_KTS;
         $CACHE_HASH{'WIND_MPH'    } = $m->WIND_MPH;
         $CACHE_HASH{'WIND_MS'     } = $m->WIND_MS;
         $CACHE_HASH{'WIND_VAR'    } = $m->WIND_VAR;
         $CACHE_HASH{'METAR'       } = $m->METAR;
         # Some result array values may contain errors of indeterminate length. Each is
         # checked & placed in a hash for current & future access via file.
         for(keys %CACHE_HASH) {
            $tmp = $CACHE_HASH{$_};
            if($tmp =~ m/error/i)    { $CACHE_HASH{$_} = $ERR; }
         if(ref($tmp) eq "ARRAY") { $CACHE_HASH{$_} = $ERR; }
         }
#print "dumping contents of \$m:\n";
#$m->dump;
#print "dump complete.\n\n";

         # store $CACHE_HASH built from remote into cache
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
      } else { #  if($response->is_success) (GET succeeded)
         print $response->error_as_HTML;
         my $err_msg = $response->error_as_HTML;
         warn "$err_msg\n\n";
         die "$!";
		} #  if($response->is_success) else
   } #  if($response->is_success) (HEAD succeeded)
} else { # if(($NOW - $CACHE_UI) > $CACHE_MTIME) cache has timed-out
   # use local cache of remote site
   use Storable qw( fd_retrieve );
   use Fcntl qw(:DEFAULT :flock);
   open(DF, "< $CACHE")
	   or die "can't open $CACHE: $!";
   flock(DF, LOCK_SH)
	   or die "can't lock $CACHE: $!";
   %CACHE_HASH = %{ fd_retrieve(*DF)};
   close(DF);
} # if(($NOW - $CACHE_UI) > $CACHE_MTIME) else

#for(keys %CACHE_HASH) {
#	print "$_ = $CACHE_HASH{$_}\n";
#}

switch ($TYPE) {
   case "ALT"          { print $CACHE_HASH{'ALT'         };}
   case "ALT_HP"       { print $CACHE_HASH{'ALT_HP'      };}
   case "CSV"          { print $CACHE_HASH{'CSV'         };}
   case "DATE"         { print $CACHE_HASH{'DATE'        };}
   case "DEW_C"        { print $CACHE_HASH{'DEW_C'       };}
   case "DEW_F"        { print $CACHE_HASH{'DEW_F'       };}
   case "SKY"          { print $CACHE_HASH{'SKY'         };}
   case "RH"           { print $CACHE_HASH{'RH'          };}
   case "TEMP_C"       { print $CACHE_HASH{'TEMP_C'      };}
   case "TEMP_F"       { print $CACHE_HASH{'TEMP_F'      };}
   case "TIME"         { print $CACHE_HASH{'TIME'        };}
   case "TYPE"         { print $CACHE_HASH{'TYPE'        };}
   case "VISIBILITY"   { print $CACHE_HASH{'VISIBILITY'  };}
   case "WEATHER"      { print $CACHE_HASH{'WEATHER'     };}
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
