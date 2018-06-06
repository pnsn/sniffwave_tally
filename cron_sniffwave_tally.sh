#!/bin/sh

# Can be used to run sniffwave_tally as a cron-job.
# for example, if you want to collect latency and gap information in 10 minute
# intervals, set the DURATION to 600s and let cron run the script every 10 minutes.
# e.g.
# 05,15,25,35,45,55 * * * * /full/path/to/cron_sniffwave_tally.sh > /tmp/cron_sniffwave_tally.out 2>&1
#
# WARNING: this setup appends the output from different sniffwave_tally runs on the same UTC date 
# to the same file, so do not let the sniffwave runs overlap because the output might get jumbled 
# up in the output files.  I.e. don't run this with DURATION = 600 (10 minutes) every 5 minutes.
# If you run this every 10 minutes with a DURATION = 300 (5 minutes), you get numbers relevant for
# only half the time duration (i.e. 6 times 5 minutes, 30 minutes monitored each hour) but sampled 
# over the full hour.

# modify these parameters as needed for your system
EWENV=/home/eworm/.bashrc     # file to source to set earthworm envs
SNIFFWAVE_DIR=/home/eworm/bin # name of directory with sniffwave executable
SCRIPT_DIR=/home/eworm/bin    # directory containing the executable script sniffwave_tally
OUTDIR=/tmp                   # directory that output files from sniffwave_tally will go into
RINGNAME=WAVE_RING            # earthworm wave ring to monitor
DURATION=600                  # duration to run sniffwave for in s
INSTITUTION=PNSN              # institution identifier for output files

# sniffwave needs to know the earthworm environment variables
if [ -f ${EWENV} ]; then
    source ${EWENV}
else
    echo "${EWENV} does not exist."
    echo "Change EWENV in this script to name of file with earthworm environment variables."
    exit 1
fi

# exit if EW_PARAMS still not known
if [ "x${EW_PARAMS}x" = "xx" ]; then
    echo "environment variable EW_PARAMS not set, required to run sniffwave"
    exit 1
fi

cmd="${SCRIPT_DIR}/sniffwave_tally --bindir ${SNIFFWAVE_DIR} --outdir ${OUTDIR} --inst ${INSTITUTION} $RINGNAME wild wild wild wild $DURATION"
echo "running: ${cmd}"
`$cmd`
