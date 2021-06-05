#!/bin/bash
mkdir ../../home/$1
unzip ../scripts/home.zip -d ../../home/$1
x11vnc -storepasswd $2 ../../home/$1/.vnc_pass
chmod -R 777 ../../home/$1
