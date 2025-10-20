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
  CMD="sudo ./nr-uesoftmodem --rfsim -O $CONF_DIR/sl_sync_ref.conf --sl-mode 2 --sa --sync-ref --rfsimulator.serveraddr server --rfsimulator.serverport 4048"

elif [[ "$MODE" == "--rfsim" && "$ROLE" == "--ue1" ]]; then
  CMD="sudo ./nr-uesoftmodem --rfsim -O $CONF_DIR/sl_ue1.conf --sl-mode 2 --sa --rfsimulator.serveraddr 11.0.20.1 --rfsimulator.serverport 4048"

elif [[ "$MODE" == "--rfsim" && "$ROLE" == "--ue2" ]]; then
  CMD="sudo ./nr-uesoftmodem --rfsim -O $CONF_DIR/sl_ue2.conf --sl-mode 2 --sa --rfsimulator.serveraddr 11.0.20.1 --rfsimulator.serverport 4048"

#  USRP MODE
elif [[ "$MODE" == "--usrp" && "$ROLE" == "--syncref" ]]; then
  CMD="sudo ./nr-uesoftmodem -O $CONF_DIR/sl_sync_ref.conf --sa -E --sl-mode 2 --sync-ref --usrp-args \"type=b200,master_clock_rate=46.08e6,enable_gps=true\" --ue-txgain 10 --ue-rxgain 100 --thread-pool -1,-1,-1,-1 --clock-source 2 --time-source 2"

elif [[ "$MODE" == "--usrp" && "$ROLE" == "--ue1" ]]; then
  CMD="sudo ./nr-uesoftmodem -O $CONF_DIR/sl_ue1.conf --sa -E --sl-mode 2 --usrp-args \"type=b200,master_clock_rate=46.08e6,enable_gps=true\" --ue-txgain 10 --ue-rxgain 100 --thread-pool -1,-1,-1,-1 --clock-source 2 --time-source 2"

elif [[ "$MODE" == "--usrp" && "$ROLE" == "--ue2" ]]; then
  CMD="sudo ./nr-uesoftmodem -O $CONF_DIR/sl_ue2.conf --sa -E --sl-mode 2 --usrp-args \"type=b200,master_clock_rate=46.08e6,enable_gps=true\" --ue-txgain 10 --ue-rxgain 100 --thread-pool -1,-1,-1,-1 --clock-source 2 --time-source 2"

else
  echo "Invalid options!"
  echo "Usage: $0 (--rfsim|--usrp) (--syncref|--ue1|--ue2) [--telnet]"
  exit 1
fi

# Append telnet option if requested
CMD="$CMD $TELNET_OPTION"

echo "Executing: $CMD"
eval $CMD
