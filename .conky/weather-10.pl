#!/usr/bin/perl

# $Id: weather.pl,v 1.0 2016/09/18 00:00:00 alexkemp Exp $

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

my $HELP = "
USAGE:   $0 <locationcode> <responsetype>
  example: $0 EGNX ALT_HP  (=='barometer at East Midlands')

list of location codes:
  http://weather.rap.ucar.edu/surface/stations.txt

list of possible responses:
  ALT          (eg '30.150112643' inches)
  ALT_HP       (eg '1021'      millibars)
  SKY          (eg 'Broken at 2300ft'   )
  TEMP_C       (eg '15'   temperature °C)
  TEMP_F       (eg '59.0' temperature °F)
  TIME         (eg '11:20 UTC'          )
  VISIBILITY   (eg '9999 meters'        )
  WIND_DIR_ABB (eg 'WSW'                )
  WIND_DIR_DEG (eg '260'                )
  WIND_DIR_ENG (eg 'West/Southwest'     )
  WIND_KTS     (eg '05'         knots   )
  WIND_MPH     (eg '5.75389725' mph     )
  WIND_MS      (eg '2.57222222' m/sec   )\n";

# Get the site code.
my ($METAR_CODE,$TYPE) = @ARGV;

die $HELP unless ($METAR_CODE && $TYPE);

# Get the modules we need.
use Geo::METAR;
use LWP::UserAgent;
use Switch;
use strict;

my $ua = new LWP::UserAgent;

my $req = new HTTP::Request GET =>
  "https://www.aviationweather.gov/metar/data?ids=$METAR_CODE";

my $response = $ua->request($req);

if (!$response->is_success) {

    print $response->error_as_HTML;
    my $err_msg = $response->error_as_HTML;
    warn "$err_msg\n\n";
    die "$!";

} else {

    # get the data and find the METAR.
    my $m = new Geo::METAR;
    my $data;
    $data = $response->as_string;               # grab response
    $data =~ s/\n//go;                          # remove newlines
    $data =~ m/($METAR_CODE\s\d+Z.*?)</go;      # find the METAR string
    my $metar = $1;                             # keep it

    # Sanity check
    if (length($metar)<10) {
        die "METAR is too short! Something went wrong.";
    }

    # pass the data to the METAR module.
    $m->metar($metar);
#    print "\$metar=$metar\n";
#    $m->dump;
    switch ($TYPE) {
       case "ALT"          {print $m->ALT}
       case "ALT_HP"       {print $m->ALT_HP}
       case "TEMP_C"       {print $m->TEMP_C}
       case "TEMP_F"       {print $m->TEMP_F}
       case "TIME"         {print $m->TIME}
       case "VISIBILITY"   {print $m->VISIBILITY}
       case "WIND_DIR_ABB" {print $m->WIND_DIR_ABB}
       case "WIND_DIR_DEG" {print $m->WIND_DIR_DEG}
       case "WIND_DIR_ENG" {print $m->WIND_DIR_ENG}
       case "WIND_KTS"     {print $m->WIND_KTS}
       case "WIND_MPH"     {print $m->WIND_MPH}
       case "WIND_MS"      {print $m->WIND_MS}
    }
}

exit;

__END__
