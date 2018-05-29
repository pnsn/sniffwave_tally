# sniffwave-tally
python script and bash wrapper to tally output from earthworm's sniffwave.

# Synopsis
 sniffwave-tally [--fname filename] [--bindir sniffwave-bin-dir] [--outdir output-dir]
ring_name sta chan net loc duration

# Description
sniffwave-tally does what the name implies, it runs the earthworm program sniffwave for a 
specified duration and writes various stats to a file. Currently it only outputs fields 
needed by the eew_stationreport script (https://github.com/pnsn/station-monitor), however, 
it also calculates the average latency and standard deviation.  The latency it outputs 
is defined as the time difference between now and the end of a packet, plus half the 
duration of the packet.

## Arguments
*Required:* 
<dl>
<dt>RING_NAME</dt>
<dd>name of the earthworm ring you want to sniff</dd>
<dt>sta</dt>
<dd>station code, specify *wild* for all</dd>
<dt>chan</dt>
<dd>channel code, specify *wild* for all</dd>
<dt>net</dt>
<dd>network code, specify *wild* for all</dd>
<dt>loc</dt>
<dd>location code, specify *wild* for all, *--* for none</dd>
<dt>duration</dt>
<dd>the number of seconds for which to run sniffwave</dd>
</dl>

*Optional:*
<dl>
<dt>--bindir dirname</dt>
<dd>where dirname is the full absolute path to the directory containing 
the sniffwave binary (not needed if sniffwave in PATH)</dd>
<dt>--outdir dirname</dt>
<dd>where dirname is the full absolute path to the directory that 
you want output files to go (default=/tmp)</dd>
<dt>--fname filename</dt>
<dd>name of output file (default=YYYY-MM-dd_sniffwave-tally.csv, 
where YYYY-MM-dd is today's UTC date)</dd>
</dl>

## Output format
sniffwave-tally appends output to a file (it creates the file if it doesn't exist yet). 
By default the file is named `/tmp/YYYY-MM-dd_sniffwave-tally.csv`, but you can specify a 
different output directory using the --outdir flag. Multiple runs on the same UTC day get
concatenated into the same `YYYY-MM-dd_sniffwave-tally.csv` file, unless a different
filename is specified using the --fname option. Currently there is only one output format, 
a comma-separated-values (csv) file with the following fields:
<dl>
<dt>scnl</dt>
<dd>STA.CHAN.NET.LOC channel description</dd>
<dt>starttime</dt>
<dd>starttime of the earliest packet in measurement time window, in UNIX epoch seconds</dd>
<dt>endtime</dt>
<dd>endtime of the last packet in measurement time window, in UNIX epoch seconds</dd>
<dt>duration</dt>
<dd>total duration of packets processed during the measurement window, in seconds.</dd>
<dt>npackets</dt>
<dd>number of packets processed during the measurement window</dd>
<dt>nlate</dt>
<dd>number of packets with latencies > 3.5s</dd>
<dt>ngap</dt>
<dd>number of gaps between packets</dd>
<dt>gap_dur</dt>
<dd>total duration of gaps, in seconds<dd>
<dt>noverlap</dt>
<dd>number of packets that overlap a previous packet</dd>
<dt>overlap_dur</dt>
<dd>total duration of overlaps, in seconds</dd>
<dt>n_oo</dt>
<dd>number of out-of-order packets</dd>
<dt>oo_dur</dt>
<dd>total duration of out-of-order packets, in seconds</dd>
</dl>

# cron-sniffwave-tally.sh
Shell-script wrapper to run sniffwave-tally as a cron-job.

```
# Can be used to run sniffwave-tally as a cron-job.
# for example, if you want to collect latency and gap information in 10 minute
# intervals, set the DURATION to 600s and let cron run the script every 10 minutes.
# e.g.
# 05,15,25,35,45,55 * * * * /full/path/to/cron-sniffwave-tally.sh > /tmp/cron-sniffwave-tally.out 2>&1
#
# WARNING: this setup appends the output from different sniffwave-tally runs on the same UTC date 
# to the same file, so do not let the sniffwave runs overlap because the output might get jumbled 
# up in the output files.  I.e. don't run this with DURATION = 600 (10 minutes) every 5 minutes.
# If you run this every 10 minutes with a DURATION = 300 (5 minutes), you get numbers relevant for
# only half the time duration (i.e. 6 times 5 minutes, 30 minutes monitored each hour) but sampled 
# over the full hour.

# modify these parameters as needed for your system
EWENV=/home/eworm/.bashrc     # file to source to set earthworm envs
SNIFFWAVE_DIR=/home/eworm/bin # name of directory with sniffwave executable
SCRIPT_DIR=/home/eworm/bin    # directory containing the executable script sniffwave-tally
OUTDIR=/tmp                   # directory that output files from sniffwave-tally will go into
RINGNAME=WAVE_RING            # earthworm wave ring to monitor
DURATION=600                  # duration to run sniffwave for in s
```
# Collecting latency information for eew_stationreport

## Summary
1. install a python script and a shell script on the earthworm machine you want to monitor
2. edit the shell script as needed
3. install a crontab
4. copy daily files over to monitor

## Preparation

