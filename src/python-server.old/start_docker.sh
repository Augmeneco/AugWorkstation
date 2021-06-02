#!/bin/bash

AUGWORK_DIR="/home/cha14ka/Desktop/cha14ka/prog/AugWorkstation"
read Xenv < <(x11docker --home="$AUGWORK_DIR/home/$1" --size=$3 --xvfb --showenv --share /home/cha14ka aug-os)
env $Xenv x11vnc -noshm -forever -rfbport $2 -rfbauth $AUGWORK_DIR/home/$1/.vnc_pass
