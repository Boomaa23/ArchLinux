#!/bin/bash

dp_conn="$(cat /sys/class/drm/card0-DP-1/status)"
lvds_act="$(cat /sys/class/drm/card0-LVDS-1/enabled)"
dp_res="$(xrandr | grep '*')"

if [ "$dp_conn" == "connected" -a "$lvds_act" == "enabled" ]; then
	xrandr --output LVDS1 --off --output DP1 --auto 
	echo "Switched display to external monitor"
fi
if [ "$dp_conn" == "disconnected" -a "$lvds_act" == "disabled" ]; then
	xrandr --output DP1 --off --output LVDS1 --auto	
	echo "Switched display to internal monitor"
fi
if [ "$dp_conn" == "connected" -a "$dp_res" != *"1920x1080"* ]; then
	xrandr --output DP1 --auto --output LVDS1 --off
	echo "Set external display to proper resolution"
fi
