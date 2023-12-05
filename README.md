# Conky-Weather
## How-To Setup a Desktop Barometer + Weather Stats

![conky desktop view](https://github.com/alexkemp9/Conky-Weather/blob/main/Screenshot_2023-12-05_02-03-04.png)

Conky is a method to auto-place text, graphics & all sorts of useful stuff on your desktop. In this case we are emphasising placing the local weather report (gathered across the ’net from your nearest Airport) plus an analogue Barometer on the desktop. I work under Devuan (a systemD-free variant of Debian) so all my help is going to come from the assumption that you have a similar setup to work with.

Above is a screenshot from my desktop. Apart from the [Blue Marble](https://en.wikipedia.org/wiki/The_Blue_Marble) (the central photo of the Earth, taken on December 7, 1972 during the Apollo 17 mission, and the very first photograph of this planet taken from outside of itself), the two links at top LHS (used to enlarge/reduce text-sizes) and the Indigo background, *everything* on that screen is produced via *Conky*.

The rest of this README will introduce the elements of adding, setting-up & using Conky and, in particular, how to use Conky & NOT upset the [NOAA](https://www.noaa.gov/weather) [wiki](https://en.wikipedia.org/wiki/National_Oceanic_and_Atmospheric_Administration) so that they remove everyone’s access to Conky once again.

