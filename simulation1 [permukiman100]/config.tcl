# set number of nodes
set opt(nn) 100

# set activity file
set opt(af) $opt(config-path)
append opt(af) /activity.tcl

# set mobility file
set opt(mf) $opt(config-path)
append opt(mf) /mobility.tcl

# set start/stop time
set opt(start) 0.0
set opt(stop) 180.0

# set floor size
set opt(x) 1088.12
set opt(y) 1013.84
set opt(min-x) -0.48
set opt(min-y) 1.65

