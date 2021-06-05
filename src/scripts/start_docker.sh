#!/bin/bash

cd ../../
read Xenv < <(x11docker --home="$PWD/home/$1" --size=$3 --xvfb --showenv --share /home/cha14ka aug-os)
env $Xenv x11vnc -noshm -forever -rfbport $2 -rfbauth $PWD/home/$1/.vnc_pass
