#!/bin/bash

DISK="/"

read used total percent <<< $(df -h "$DISK" | awk 'NR==2 {print $3, $2, $5}')
read inodes_used inodes_total <<< $(df -i "$DISK" | awk 'NR==2 {print $3, $2}')

lsblk_info=$(lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v loop)

tooltip="Disk: $DISK\nUsed: $used / $total ($percent)\nInodes: $inodes_used / $inodes_total\n\nMounts:\n$lsblk_info"

cat <<JSON
{"text":"Disk: $percent", "tooltip":"$tooltip"}
JSON