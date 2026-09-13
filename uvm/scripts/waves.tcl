# Batch run for `make sim WAVES=1`: record every HDL signal into the .wdb named on the xsim
# command line. xsim cannot record UVM class members - probe through interface signals instead.
log_wave -recursive *
run all
quit
