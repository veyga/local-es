#!/usr/bin/env bash

# setup some colors
RED='\e[0;31m'
REDBG='\e[0;41m'
BLUE='\e[0;34m'
BLUEBG='\e[0;44m'
GREEN='\e[0;32m'
GREENBG='\e[0;42m'
UL='\e[4mUnderlined'
NC='\e[0m' # No Color. Use this to reset to the default color.



function log () {
    # logs messages at variable levels
    level=$1
    message="$2"
    timestamp=$(date "+%Y%m%d%H%M%S")
    module=${module:-"none"}

    case $level in
        INFO)
            level="${GREENBG}  INFO ${NC}"
            ;;
        WARNING)
            level="${REDBG}WARNING${NC}"
            ;;
        ERROR)
            level="${REDBG} ERROR ${NC}"
            ;;
        DEBUG)
            level="${BLUEBG} DEBUG ${NC}"
            ;;
        *)
            level="${REDBG}UNKNOWN${NC}"
            ;;
    esac

    logline="[$module] $level | ${message}${NC}"
    echo -e $logline
}
