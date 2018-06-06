# sniffwave_tally
python script and bash wrapper to tally output from earthworm's sniffwave.

# Synopsis
 sniffwave_tally [--fname filename] [--bindir sniffwave-bin-dir] [--outdir output-dir]
ring_name sta chan net loc duration

# Description
sniffwave_tally does what the name implies, it runs the earthworm program sniffwave for a 
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
<dd>name of output file (default=YYYY-MM-dd_sniffwave_tally.csv, 
where YYYY-MM-dd is today's UTC date)</dd>
<dt>--inst institution</dt>
<dd>name of institution identifier to append to output file.
 If fname not given default will be: YYYY-MM-dd_sniffwave_tally.INST.csv </dd>
</dl>

## Output format
sniffwave_tally appends output to a file (it creates the file if it doesn't exist yet). 
By default the file is named `/tmp/YYYY-MM-dd_sniffwave_tally.csv`, but you can specify a 
different output directory using the --outdir flag. Using the --institution flag will make
the default filename `/tmp/YYYY-MM-dd_sniffwave_tally.institution.csv` Multiple runs on 
the same UTC day get concatenated into the same `YYYY-MM-dd_sniffwave_tally.csv` file, 
unless a different filename is specified using the --fname option. Currently there is 
only one output format, a comma-separated-values (csv) file with the following fields:
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

# cron_sniffwave_tally.sh
Shell-script wrapper to run sniffwave_tally as a cron-job.

```
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
INSTITUTION=PNSN              # an identifier for your institution
```
# Collecting latency information for eew_stationreport

## Step by step:
1. test out sniffwave (for 1 sec) on your earthworm machine
```
[eworm@ewserver1 bin]$ sniffwave WAVE_RING wild wild wild wild 1
Sniffing WAVE_RING for wild.wild.wild.wild
sniffwave: inRing flushed 20012 packets of 8011336 bytes total.
CAVE.HHN.UO.-- (0x32 0x30) 0 i4 100 100.0 2018/06/06 06:33:48.97 (1528266828.9684) 2018/06/06 06:33:49.96 (1528266829.9584) 0x20 0x20 i2 m71 t19 len 464 [D:2584.0s F: 0.0s]
CAVE.HHE.UO.-- (0x32 0x30) 0 i4 100 100.0 2018/06/06 06:33:48.97 (1528266828.9684) 2018/06/06 06:33:49.96 (1528266829.9584) 0x20 0x20 i2 m71 t19 len 464 [D:2584.0s F: 0.0s]
CAVE.ENZ.UO.-- (0x32 0x30) 0 i4 100 100.0 2018/06/06 06:33:48.97 (1528266828.9684) 2018/06/06 06:33:49.96 (1528266829.9584) 0x20 0x20 i2 m71 t19 len 464 [D:2584.0s F: 0.0s]
...
```

2. install the sniffwave_tally and cron_sniffwave_tally.sh on the earthworm machine you want to monitor.
```
[eworm@ewserver1 bin]$ git clone https://github.com/pnsn/sniffwave_tally         
```
(or just download a zip file from this webpage via green "clone or download" button)

3. Edit the parameters in “cron_sniffwave_tally.sh” as needed.

4. Give the cron script a test drive using a small duration, e.g. 2s.
```
[eworm@ewserver1 sniffwave_tally]$ ./cron_sniffwave_tally.sh 
Running script: /home/eworm/bin/TEMP/sniffwave_tally/sniffwave_tally --bindir /home/eworm/bin --outdir /tmp --inst PNSN WAVE_RING wild wild wild wild 2
writing  to  /tmp/2018-06-06_sniffwave_tally.PNSN.csv
sniffwave command:  /home/eworm/bin/sniffwave WAVE_RING wild wild wild wild 2
sniffwave: inRing flushed 17076 packets of 8089792 bytes total.
[eworm@ewserver1 sniffwave_tally]$ 
```
The output should look something like:
```
[eworm@ewserver1 sniffwave_tally]$ head /tmp/2018-06-06_sniffwave_tally.PNSN.csv
# scnl,starttime,endtime,duration,npackets,nlate,ngap,gap_dur,noverlap,overlap_dur,n_oo,oo_dur
IRON.HHN.UW.--,1528267214.97,1528267220.96,5.99000000954,6,0,0,0.0,0,0.0,0,0.0
MAUP.HNN.UW.--,1528267216.2,1528267222.21,6.01499986649,7,0,0,0.0,0,0.0,0,0.0
BULL.HNN.UW.--,1528267216.73,1528267221.89,5.15500020981,6,0,0,0.0,0,0.0,0,0.0
LEVE.HNZ.UW.--,1528267215.82,1528267221.83,6.01499986649,7,0,0,0.0,0,0.0,0,0.0
...
```
5. Delete the csv you just created, set the duration in the shell script to desired value, set up the cronjob e.g.:
05,15,25,35,45,55 * * * * /full/path/to/cron_sniffwave_tally.sh > /tmp/cron_sniffwave_tally.out 2>&1

6. Setup a cronjob to rsync your daily output csv files files to UW every night just after midnight.  Be sure the time is DURATION plus 1 minute.  E.g.:
```
11 00 * * * rsync -av -e "ssh -p 7777” /myoutputdir/*.csv user@hostmachine.edu:/home/user/sniffwave_tally_files
```

