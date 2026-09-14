# sniffwave_tally
python script and bash wrapper to tally output from earthworm's sniffwave.

# Synopsis
 sniffwave_tally [--fname filename] [--bindir sniffwave-bin-dir] [--outdir output-dir] [--inst institution] [--squac prefix] [--all] 
ring_name sta chan net loc duration

# Description
sniffwave_tally does what the name implies, it runs the earthworm program sniffwave for a
specified duration and writes various stats to a file. The default output contains the
fields needed by the eew_stationreport script (https://github.com/pnsn/station-monitor);
the --all option adds average data latency, average packet length, their standard
deviations, the maximum latency, and the total bytes seen. Latency here is the time
difference between now (current time in sniffwave) and the end of a packet, plus half a
packet length.

With --squac the same measurements are posted to SQUAC.

# Change log

## September 14, 2026

The out-of-order packet logic was wrong and has been rewritten. Everything else in this
release follows from that or is cleanup. Metric values before and after this date are not
directly comparable, so expect a step in the SQUAC time series for the affected channels.

**Out-of-order detection (the main change).** A packet is now out of order when its start
time falls more than TOLERANCE (0.01 s) before the highest start time accepted so far for
that channel. The old test asked whether the packet's *end* time preceded the *previous*
packet's start time, which missed any late packet that started early but overlapped its
predecessor, and missed reordering relative to anything older than the immediately
preceding packet. n_oo and oo_dur read higher than before.

**Out-of-order packets no longer corrupt the gap count (the main consequence).** The old
code rolled prev_starttime, prev_endtime, and endtime back to the stale packet, so the
next normally ordered packet was measured against a time in the past and reported as a
gap of roughly two packet lengths that never happened. The tracking times are now frozen
for out-of-order packets. ngap, gap_dur, and gaps_per_hour read lower and both
completeness metrics read higher on any channel that reorders.

**Gap, overlap, and out-of-order are now mutually exclusive.** A packet is counted in at
most one of the three. Previously a second out-of-order packet overlapping the first could
land in both n_oo and noverlap.

**Backfilled gaps are reported as both a gap and an out-of-order packet, by design.** The
gap was real when the stream skipped the interval; the late packet is real when it
arrives. Nothing retroactively removes a gap that was later filled, so a retransmitting
link shows both.

Other changes:

- overlap_dur is now positive. It was previously negative. The magnitude is unchanged, but
  any alarm or plot written against the old sign needs updating.
- oo_dur is unchanged in definition: the summed *length* of the out-of-order packets.
  Note this is the opposite convention from overlap_dur, which sums a distance in time.
- endtime is now the end of the last in-order packet, so a late packet can no longer roll
  it backward and shrink the window that completeness and gaps_per_hour divide by.
  starttime remains the start of the first packet *seen* for the channel, in arrival order.
- n_oo, oo_dur, noverlap, and overlap_dur are now sent to SQUAC. They were previously
  computed and written to the CSV but never posted. As with all metrics, they must already
  exist in the SQUAC database under the given prefix; missing ones are skipped and their
  names printed at the start of the run.
- The byte total now includes each channel's first packet, which was previously dropped.
- The check that discards packets more than 86400 s from the present used a naive UTC
  timestamp compared against epoch seconds, so the window was shifted by the server's UTC
  offset on any host not set to UTC. Fixed.
- Blank lines from sniffwave no longer raise IndexError, and a run that returns no output
  no longer raises NameError.
- Division by the window length is floored, so a channel contributing a single very short
  packet can no longer raise ZeroDivisionError.
- --latlon is removed. getStationDict uses urllib.urlopen and is Python 2 only, so the
  option raises AttributeError under Python 3.
- TOLERANCE is unchanged at 0.01 s. Note it is absolute, so it is 0.4 samples at 40 sps,
  1 sample at 100 sps, and 2 samples at 200 sps: sub-tolerance gaps and overlaps are
  invisible at high sample rates.

Per-metric documentation: prefix_ring_n_oo.md, prefix_ring_oo_dur.md,
prefix_ring_noverlap.md, prefix_ring_overlap_dur.md.

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
<dt>--squac prefix</dt>
<dd>Also send measurements to the SQUAC api, with prefix prepended to each metric name.
Requires a SQUAC user account with contributor privileges, and implies --all.
Credentials are read from the environment variables SQUACAPI_USER and SQUACAPI_PASSWD.
The cron wrapper sources ~/.squac.env (mode 600) to set them; for interactive runs the
script falls back to reading the file named by SQUACAPI_ENV_FILE, defaulting to
~/.squac.env for the account running it.
Metrics posted: prefix_ring_latency, prefix_ring_latency_max, prefix_ring_latency_le_3.5,
prefix_ring_packet_length, prefix_ring_gaps_per_hour, prefix_ring_completeness,
prefix_ring_completeness_incl_gap_penalty, prefix_ring_n_oo, prefix_ring_oo_dur,
prefix_ring_noverlap, prefix_ring_overlap_dur.
Each must already exist in SQUAC under that prefix; missing ones are named on stdout and
skipped.</dd>
<dt>--all</dt>
<dd>Add average and standard deviation of the measured latencies and packet lengths, the
maximum latency, and total number of bytes to the output.</dd>
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
<dd>starttime of the first packet seen for this channel, in arrival order, in UNIX epoch
seconds. Not necessarily the earliest packet in time, since a backfilled packet arriving
later is not used to move it back.</dd>
<dt>endtime</dt>
<dd>endtime of the last in-order packet for this channel, in UNIX epoch seconds. Packets
counted as out of order do not advance it.</dd>
<dt>duration</dt>
<dd>endtime minus starttime, in seconds, i.e. the span this channel actually covered. This
is normally a little less than the sniffwave run duration, and is the denominator for the
completeness and gaps_per_hour metrics.</dd>
<dt>npackets</dt>
<dd>number of packets processed during the measurement window, including out-of-order and
overlapping ones</dd>
<dt>nlate</dt>
<dd>number of packets with latencies > 3.5s</dd>
<dt>ngap</dt>
<dd>number of gaps, i.e. packets starting more than TOLERANCE after the previous in-order
packet's next expected sample</dd>
<dt>gap_dur</dt>
<dd>total duration of gaps, in seconds</dd>
<dt>noverlap</dt>
<dd>number of packets starting more than TOLERANCE before the previous in-order packet's
next expected sample, i.e. re-delivering data already seen</dd>
<dt>overlap_dur</dt>
<dd>summed time by which those packets started early, in seconds, positive. A distance in
time, not a sum of packet lengths.</dd>
<dt>n_oo</dt>
<dd>number of out-of-order packets, i.e. packets starting more than TOLERANCE before the
highest start time seen so far for this channel</dd>
<dt>oo_dur</dt>
<dd>summed length of those out-of-order packets, in seconds, positive. A sum of packet
lengths, not a distance in time.</dd>
<dt>Added with option --all:</dt>
<dt>latency</dt>
<dd>average data latency (s), defined as
time of packet arrival and reading from ring - time of last sample in most recent packet,
plus half a packet length</dd>
<dt>latency_stdev</dt>
<dd>approximate standard deviation of the latency</dd>
<dt>packet_length</dt>
<dd>average packet length (s)</dd>
<dt>packet_stdev</dt>
<dd>approximate standard deviation of the packet length</dd>
<dt>bytes</dt>
<dd>total size of the data seen, in bytes</dd>
<dt>latency_max</dt>
<dd>maximum latency seen (s). Useful for separating network reordering, a few seconds,
from a station time jump or buffer backfill, which shows latencies far exceeding the run
duration.</dd>
</dl>

Note: gap, overlap, and out-of-order are mutually exclusive; each packet is counted in at
most one of them. A gap that is later backfilled appears in both ngap and n_oo, which is
intended.

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

Note that all diagnostics, including the list of SQUAC metrics that could not be found,
go to stdout and therefore to `/tmp/cron_sniffwave_tally.out`, not into the csv.

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
Running script: /home/eworm/bin/TEMP/sniffwave_tally/sniffwave_tally --all --bindir /home/eworm/bin --outdir /tmp --inst PNSN WAVE_RING wild wild wild wild 2
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
With the --all option:
```
#scnl,starttime,endtime,duration,npackets,nlate,ngap,gap_dur,noverlap,overlap_dur,n_oo,oo_dur,latency,latency_stdev,packet_length,packet_stdev,bytes
SYMB.HNE.CN.--,1573603747.49,1573604349.0,601.50999999,146,114,0,0.0,0,0.0,0,0.0,4.09815068555,1.42174442454,4.11000000124,8.42936970218e-08,248240
WPB.HNZ.CN.--,1573603748.2,1573604349.71,601.50999999,146,104,0,0.0,0,0.0,0,0.0,3.75842465734,0.372774567952,4.10999999961,0.0,248240
LRIV.ENZ.UW.--,1573603750.68,1573604350.67,599.99000001,600,0,0,0.0,0,0.0,0,0.0,1.3828333381,0.0806348077585,0.990000009537,0.0,277936
LUMI.ENE.UW.--,1573603750.68,1573604350.67,599.99000001,600,0,0,0.0,0,0.0,0,0.0,1.44316667144,0.0852250289267,0.990000009537,0.0,277936
...
```
The two examples above predate the September 14, 2026 release; current output carries one
more column, latency_max, after bytes.

5. Delete the csv you just created, set the duration in the shell script to desired value, set up the cronjob e.g.:
05,15,25,35,45,55 * * * * /full/path/to/cron_sniffwave_tally.sh > /tmp/cron_sniffwave_tally.out 2>&1

6. Setup a cronjob to rsync your daily output csv files files to UW every night just after midnight (5pm Pacific).  Be sure the time is DURATION plus 1 minute.  E.g.:
```
11 17 * * * rsync -av -e "ssh -p 7777” /myoutputdir/*.csv user@hostmachine.edu:/home/user/sniffwave_tally_files
```
