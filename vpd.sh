#!/bin/bash
source /home/ff/eecs151/asic/eecs151.bashrc
# cd /home/tmp/eecs151/fa22/class/eecs151-aer/asicProject
cd /home/cc/eecs151/fa22/class/eecs151-aal/fa22_asic_team10
make sim-rtl test_bmark_short=$1.vpd
cd bmark_short_output
dve -vpd $1.vpd &