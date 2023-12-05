# Conky-Weather
## How-To Setup a Desktop Barometer + Weather Stats

![conky desktop view](https://github.com/alexkemp9/Conky-Weather/blob/main/Screenshot_2023-12-05_02-03-04.png)

*Conky* is a method to auto-place text, graphics & all sorts of useful stuff on your desktop. In this case we are emphasising placing the local current-weather report (gathered across the ’net from your nearest Airport) plus an analogue Barometer on the desktop. I work under Devuan (a systemD-free variant of Debian) so all my help is going to come from the assumption that you have a similar setup to work with.

Above is a screenshot from my desktop. Apart from the [Blue Marble](https://en.wikipedia.org/wiki/The_Blue_Marble) (the central photo of the Earth, taken on December 7, 1972 during the Apollo 17 mission, and the very first photograph of this planet taken from outside of itself), the two links at top LHS (used to enlarge/reduce text-sizes) and the Indigo background, *everything* on that screen is produced via *Conky*. The barometer at bottom left is produced via `conky/conkyrc.weather`, whilst the clock, system-stats + weather reports on the right-hand side are produced via `conky/conkyrc`.

The rest of this README will introduce the elements of adding, setting-up & using Conky and, in particular, how to use Conky & NOT upset the [NOAA](https://www.noaa.gov/weather) ([wiki](https://en.wikipedia.org/wiki/National_Oceanic_and_Atmospheric_Administration)) so that they remove everyone’s access to *Conky* once again.

### Install Conky
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
### Setup Conky
My Desktop Manager is XFCE (version 4.18) and it provides an autostart facilty when logging in at `menu:Settings | Session and Startup | Application Autostart`. I've provided a shell-script at `.conky/conkystart.sh` and it will launch both *Conkys*. Note that the `.desktop` file is provided here for your convenience at `.config/autostart/Conky.desktop`.

