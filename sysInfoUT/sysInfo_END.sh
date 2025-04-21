#!/bin/bash

#### UPDATE formatted date
dateSTR=$(python3 $HOME/Nextcloud/Linux/scripts/sysInfoUT/date.py)

echo -e "\t
    End time   :  $dateSTR\n
    \t"