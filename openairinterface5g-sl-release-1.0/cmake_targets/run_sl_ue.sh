#!/bin/bash

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "Usage: $0 (--rfsim|--usrp) (--syncref|--ue1|--ue2) [--telnet]"
  exit 1
fi

# Navigate to the correct build directory
cd ran_build/build || exit 1

MODE=$1
ROLE=$2
TELNET_OPTION=""
CONF_DIR=../../../targets/PROJECTS/NR-SIDELINK/CONF

# Check for optional telnet parameter
if [ $# -eq 3 ] && [ "$3" == "--telnet" ]; then
  TELNET_OPTION="--rfsimulator.options chanmod --telnetsrv"
fi

#  RFSIM MODE
if [[ "$MODE" == "--rfsim" && "$ROLE" == "--syncref" ]]; then
  CMD="sudo LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH -E ./nr-uesoftmodem -O $CONF_DIR/sl_sync_ref.conf --sa --sl-mode 2 --sync-ref --rfsim --thread-pool -1,-1,-1,-1 --rfsimulator.serveraddrsl server --rfsimulator.serverportsl 4048"

elif [[ "$MODE" == "--rfsim" && "$ROLE" == "--ue1" ]]; then
  CMD="sudo LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH -E ./nr-uesoftmodem -O $CONF_DIR/sl_ue1.conf --sa --sl-mode 2 --rfsim --thread-pool -1,-1,-1,-1 --rfsimulator.serveraddrsl 11.0.20.1 --rfsimulator.serverportsl 4048"


else
  echo "Invalid options!"
  echo "Usage: $0 (--rfsim|--usrp) (--syncref|--ue1|--ue2) [--telnet]"
  exit 1
fi

# Append telnet option if requested
CMD="$CMD $TELNET_OPTION"

echo "Executing: $CMD"
eval $CMD
