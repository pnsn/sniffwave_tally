# sniffwave-tally
Python script and bash wrapper to tally output from earthworm's sniffwave.

Usage:
 sniffwave-tally [--fname absolute-path-to-outputfile] [--bindir absolute-path-to-sniffwave-bin-dir] 
ring_name sta chan net loc duration

Examples:
 sniffwave-tally WAVE_RING wild wild wild wild 600

# Collecting latency information for eew_stationreport

## Summary
1. install a python script and a shell script on the earthworm machine you want to monitor
2. edit the shell script as needed
3. install a crontab
4. copy daily files over to monitor

## Preparation

