#!/bin/bash
sudo pacman -Qknq | cut -d' ' -f 1 | sudo pacman -S -
