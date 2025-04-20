#!/bin/bash

osname=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/OSname.sh)

dateSTR=$(python3 $HOME/Nextcloud/Linux/scripts/sysInfoUT/date.py)


echo -e "
________________________________________________________ 
\t
    Start time :  "$dateSTR"
    Running for:  $(whoami)@$osname [$(hostname)]
    "

#### Start  --  $(date)


#### End part
# echo -e "\n
#     End time   :  $dateSTR\n"