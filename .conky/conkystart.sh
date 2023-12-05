#!/bin/bash
# 2016-05-20 removed sleep options
# 2015-12-26 switched from 'sleep 10 &&' to conky options
#           +bash shortcuts do not work
# /usr/bin/conkystart.sh &
/usr/bin/conky -dc /home/alexk/.conky/conkyrc

# -p10 == pause for 10 secs
# -d daemon mode (fork to background)
# -c locate the config file
/usr/bin/conky -dc /home/alexk/.conky/conkyrc.weather
