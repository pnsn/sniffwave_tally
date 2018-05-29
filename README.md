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
 RING_NAME	name of the earthworm ring you want to sniff
 sta		station code, specify *wild* for all
 chan		channel code, specify *wild* for all
 net		network code, specify *wild* for all
 loc		location code, specify *wild* for all, *--* for none
 duration	the number of seconds for which to run sniffwave

*Optional:*
 --bindir dirname where dirname is the full absolute path to the directory containing 
the sniffwave binary (not needed if sniffwave in PATH)
 --outdir dirname where dirname is the full absolute path to the directory that 
you want output files to go (default=/tmp)
 --fname filename name of output file (default=YYYY-MM-dd_sniffwave-tally.csv, 
where YYYY-MM-dd is today's UTC date)

## Output format
Currently there is only one output format, a comma-separated-values (csv) file with the following fields:
scnl: ,starttime,endtime,duration,npackets,nlate,ngap,gap_dur,noverlap,overlap_dur,n_oo,oo_durxamples
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

# Collecting latency information for eew_stationreport

## Summary
1. install a python script and a shell script on the earthworm machine you want to monitor
2. edit the shell script as needed
3. install a crontab
4. copy daily files over to monitor

## Preparation

