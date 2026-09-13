#!/usr/bin/env bash
# Pass/fail verdict for one xsim run.
#
#   check_log.sh <xsim log> <label>
#
# xsim exits 0 on UVM_ERROR, UVM_FATAL, and even an unknown +UVM_TESTNAME, so its exit code
# says nothing. A run passes only if it reached the UVM report summary with zero UVM errors and
# fatals, and printed no simulator errors. The last check matters because SVA and $error
# failures print "Error:" and never reach UVM's counters.

log=$1
label=$2

if [[ ! -f $log ]]; then
    echo "FAIL $label (no log at $log - did xsim start?)"
    exit 1
fi

if ! grep -q -- '--- UVM Report Summary ---' "$log"; then
    echo "FAIL $label (no UVM report summary: simulator error, crash, or \$finish before UVM ended)  $log"
    exit 1
fi

uvm_errors=$(sed -n 's/^UVM_ERROR :[[:space:]]*\([0-9]*\).*/\1/p' "$log" | tail -1)
uvm_fatals=$(sed -n 's/^UVM_FATAL :[[:space:]]*\([0-9]*\).*/\1/p' "$log" | tail -1)
sim_errors=$(grep -cE '^(ERROR|Error|Fatal|FATAL_ERROR):' "$log")

if [[ $uvm_errors == 0 && $uvm_fatals == 0 && $sim_errors == 0 ]]; then
    echo "PASS $label"
    exit 0
fi

echo "FAIL $label (UVM_ERROR=$uvm_errors UVM_FATAL=$uvm_fatals simulator errors=$sim_errors)  $log"
exit 1
