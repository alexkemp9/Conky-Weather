# *Conky-Weather*
## *How-To Setup a Desktop Barometer + Weather Stats*

![conky desktop view](https://github.com/alexkemp9/Conky-Weather/blob/main/Screenshot_2023-12-05_02-03-04.png)

*Conky* is a method to auto-place text, graphics & all sorts of useful stuff on your desktop. In this case we are emphasising placing the local current-weather report (gathered across the ’net from your nearest Airport) plus an analogue Barometer on the desktop. I work under Devuan (a systemD-free variant of Debian) so all my help is going to come from the assumption that you have a similar setup to work with.

Above is a screenshot from my desktop. Apart from the [Blue Marble](https://en.wikipedia.org/wiki/The_Blue_Marble), the two links at top LHS (used to enlarge/reduce text-sizes) and the indigo background, *everything* on that screen is produced via *Conky*. The barometer at bottom left is produced via `.conky/conkyrc.weather`, whilst the clock, system-stats + weather reports on the right-hand side are produced via `.conky/conkyrc`.

The rest of this README will introduce the elements of adding, setting-up & using Conky and, in particular, how to use Conky & NOT upset the [NOAA](https://www.noaa.gov/weather) ([wiki](https://en.wikipedia.org/wiki/National_Oceanic_and_Atmospheric_Administration)) so that they remove everyone’s access to *Conky* once again.

### *Install Conky*
This is easy under Linux:

```bash
$ apt search conky
Sorting... Done
Full Text Search... Done
conky/stable 1.18.3-1 all
  highly configurable system monitor (transitional package)

conky-all/stable,now 1.18.3-1 amd64 [installed]
  highly configurable system monitor (all features enabled)

conky-cli/stable 1.18.3-1 amd64
  highly configurable system monitor (basic version)

conky-std/stable 1.18.3-1 amd64
  highly configurable system monitor (default version)
```
Therefore, a `$ sudo apt install conky-all` will be sufficient to install Conky in your system.

### *Setup Conky*
My Desktop Manager is XFCE (version 4.18) and it provides a login-autostart facilty at `menu:Settings | Session and Startup | Application Autostart`. I’ve provided a shell-script at `.conky/conkystart.sh` which will launch both *Conkys*. Note that the `.desktop` file is also provided here for your convenience at `.config/autostart/Conky.desktop`. You will need to edit `conkystart.sh` to replace my username with your own within the script and, I am afraid, that will turn out to be needed within almost every script. Sorry about that.

It is useful to have a *Startup* menu command for *Conky* plus a *Restart* command in case it gets stuck (these are just scripts after all, and will sometimes glitch). Those are called `.conky/conkystart.sh` + `.conky/conkyrestart.sh` and are activated here in `.local/share/applications` (which is also the place in your system to get them into `menu:Accessories`) by `Conky_start.desktop` & `Conky_restart.desktop`.

### *Using Conky*
The whole of making use of *Conky* boils down to the LUA commands that are placed within the `conkyrc` scripts. This is not the place for a *how-to lua*, nor that matter for a *how-to conky*, but it *is* the place for a *How-To Acquire Weather Stats*, and that is what we shall deal with next.

#### *Getting the Weather from Your Local Airport*
Every Airport hosts a *Weather Station* so that they can inform aeroplanes close to them on the state of the weather; that is particularly important for planes coming in to land, and those about to take off. The USA [National Oceanic and Atmospheric Administration](https://www.noaa.gov/weather) (NOAA) is responsible for broadcasting that info, and does so for most Airports worldwide as METARs (METeorological Aerodrome Reports) ([wiki](https://en.wikipedia.org/wiki/METAR)). At the heart of acquiring the METAR is a 4-char code for the Airport (find yours [here](http://weather.rap.ucar.edu/surface/stations.txt) or look at `.conky/metar-stations.txt` (10,270 lines)). The one that I use is *EGNX == East Midlands*. Also look at `.conky/weather.pl` (which is the PERL script that is used to decode the METAR).

Having decided on the Airport that you will use to collect the METAR from, and having discovered it’s 4-char CODE, you will need to change every *‘EGNX’* into *your* Airport’s code within `.conky/conkyrc`

#### *Don’t DDOS the NOAA*
Acquiring weather stats via METARs became popular 10 or 15 years ago and the number of people doing it began to swell enormously. Unfortunately, the commonsense to do so courteously did not spread at the same rate, and the addition of thousands of people constantly collecting METARs every second or so acted as a [DDOS](https://en.wikipedia.org/wiki/Denial-of-service_attack) upon the NOAA and they removed access to the link that was formerly used to  collect the METAR. My first notice of this was in 2016 August. The latest change was 2023 October, and these changes have been yearly in between.

The obvious fix is to first cache the result, and second to use the cache for subsequent accesses. Here is the heart of that code:
```bash
# file location
my $CACHE = "~/.conky/.metar_cache";
# update interval, secs
my $CACHE_UI = 1200;
```
The Cache is saved as a Hash. Access is to the cache first until Timeout, when the cache is replaced after a fresh site access.

### *File List*
There follows a complete list of files supplied with this Repository. First note the following:     
- .conky/conkyrc.weather is a hard-link to .conky/conkyrc-11.weather
- .conky/weather.pl is a hard-link to .conky/weather-13.pl
- .lua/scripts/weather.lua is a hard-link to .lua/scripts/weather-11.lua

```
   Date      Time    Attr         Size   Compressed  Name
------------------- ----- ------------ ------------  ------------------------
2023-12-05 02:25:37 D....            0            0  .config
2023-12-05 08:43:02 D....            0            0  .config/autostart
2023-12-05 08:40:54 D....            0            0  .conky
2023-12-05 02:25:37 D....            0            0  .local
2023-12-05 02:25:37 D....            0            0  .local/share
2023-12-05 08:45:19 D....            0            0  .local/share/applications
2023-12-05 02:25:37 D....            0            0  .lua
2023-12-05 08:47:36 D....            0            0  .lua/scripts
2015-12-26 00:00:00 ....A       794624      1525985  20151226_Conky--successful-autostart-setup.html
2023-12-05 02:25:37 ....A        35149               LICENSE
2023-12-05 02:25:37 ....A           65               README.md
2023-12-05 02:25:37 ....A       913885               Screenshot_2023-12-05_02-03-04.png
2017-07-22 00:21:40 ....A          216       190183  .config/autostart/Conky.desktop
2023-10-17 10:51:55 ....A         5710               .conky/conkyrc
2020-11-23 14:36:18 ....A         1728               .conky/conkyrc-11.weather
2020-11-23 14:36:18 ....A         1728               .conky/conkyrc.weather
2020-11-23 14:03:30 ....A           36               .conky/conkyrestart.sh
2016-09-19 23:34:21 ....A          367               .conky/conkystart.sh
2019-10-15 11:00:25 ....A         5303               .conky/convert.lua
2023-02-07 13:08:29 ....A       825676               .conky/metar-stations.txt
2017-07-22 10:06:20 ....A         3099               .conky/weather-10.pl
2018-05-10 19:10:32 ....A         7978               .conky/weather-11.pl
2020-11-19 16:39:25 ....A        10995               .conky/weather-12.pl
2023-10-17 13:23:49 ....A        11372               .conky/weather-13.pl
2023-10-17 13:23:49 ....A        11372               .conky/weather.pl
2016-09-15 06:50:12 ....A         1833               .conky/weather.sh
2016-05-20 15:59:37 ....A          235               .local/share/applications/Conky_restart.desktop
2016-05-20 16:50:45 ....A          238               .local/share/applications/Conky_start.desktop
2015-12-27 01:14:11 ....A         9395               .lua/scripts/clock_rings.lua
2020-10-06 21:04:49 ....A        38881               .lua/scripts/weather-10.lua
2020-11-23 13:55:11 ....A        40996               .lua/scripts/weather-11.lua
2020-11-23 13:55:11 ....A        40996               .lua/scripts/weather.lua
------------------- ----- ------------ ------------  ------------------------
2023-12-05 08:47:36            2761877      1716168  24 files, 8 folders
```
