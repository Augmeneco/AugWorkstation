#!/bin/bash
AUGWORK_DIR="/home/cha14ka/Desktop/cha14ka/prog/AugWorkstation"

mkdir $AUGWORK_DIR/home/$1
unzip $AUGWORK_DIR/api/home.zip -d $AUGWORK_DIR/home/$1
x11vnc -storepasswd $2 $AUGWORK_DIR/home/$1/.vnc_pass
chmod -R 777 $AUGWORK_DIR/home/$1