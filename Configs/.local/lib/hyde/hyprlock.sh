#! /bin/bash

# source variables
ScrDir=$(dirname "$(realpath "$0")")
source ${ScrDir}/globalcontrol.sh


fn_cava() {
:
}

fn_"${1}"
