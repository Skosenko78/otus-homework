#!/usr/bin/env bash

LC_TIME=en_US.utf8

MAILTO='rep_rcpt@domain.ru'
LOGFILE='access-4560-644067.log'
TMPFILE='mailreport.txt'
CURRENTDATE='14 Aug 2019 05:00 +0300'
REPORTDT="$(date -d "$CURRENTDATE" '+%d/%b/%G:%H')"

if [ -f $TMPFILE ]; then
	echo "Script is running."
	exit 0
fi

echo "EVENTS from $(date -d "$CURRENTDATE" '+%d/%b/%G:%T %z') to $(date -d "$CURRENTDATE +1 hour" '+%d/%b/%G:%T %z')" > $TMPFILE
echo "Top 20 Source IP addresses:" >> $TMPFILE
grep $REPORTDT $LOGFILE | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -nr | head -20 | awk 'BEGIN {print "Count    IP address"} {print $1 "\t" $2}' >> $TMPFILE
echo "Top 20 Quered addresses:" >> $TMPFILE
grep $REPORTDT $LOGFILE | grep -oE '[A-Z][A-Z]+ /.* HTTP/1.1' | sort | uniq -c | sort -nr | head -20 | awk 'BEGIN {print "Count    Address"} {print $1 "\t" $3}' >> $TMPFILE
echo "All RETURN codes:" >> $TMPFILE
grep $REPORTDT $LOGFILE | grep -oE ' [1-5][0-9]{2} ' | sort | uniq -c |  awk 'BEGIN {print "Count    ReturnCode"} {print $1 "\t" $2}' >> $TMPFILE
echo "Error entries:" >> $TMPFILE
grep $REPORTDT $LOGFILE | grep -E ' [3-5][0-9]{2} ' | sort +4 >> $TMPFILE
mail -s Report $MAILTO < $TMPFILE
rm -f $TMPFILE
exit 0
