#!/bin/bash
Break=180
Sleep=11
pingpadding=30 # if no response ping takes longer to run
log=/var/log/connTest
pinglog=/tmp/ping.log
#
# one-time setup of our GPIO pin so we can control it
pin=26
cd /sys/class/gpio
echo $pin > export
cd gpio$pin
echo out > direction

# divert STDOUT and STDERR to log file
exec 1>>$log
exec 2>&1
echo "Internet Check at "$(date)
# report our external IP
#curl -s ipinfo.io|head -2|tail -1

try1=$(curl -is --connect-timeout 6 www.google.com|wc -c)
[[ $try1 -lt 300 ]] && {
  echo google came up short. Trying amazon next. characters: $try1
  sleep 10
  try2=$(curl -is --connect-timeout 6 https://www.amazon.com|wc -c)
  [[ $try2 -lt 300 ]] && {
    echo "#################"
    echo "We have a connection problem at "$(date)
    echo character counts. google: $try1, amazon, $try2
    echo "Power cycling router and waiting for $Break seconds"
# start a ping job
    ping -c $Break 1.1.1.1 > $pinglog 2>&1 &

# this will shut power off
    echo 1 > value
    sleep 20
# and this will turn it back on
    echo 0 > value
# this prevents us from too aggressively power-cycling
    sleep 180
# report on ping results
    echo printing last three lines from ping results log:
    tail -3 $pinglog
    line=`tail -2 $pinglog|head -1`
    t1=`echo -n $line|awk '{print $1}'`
    t2=`echo -n $line|awk '{print $4}'`
#  downtime=$(($t1-$t2))
# test for integer inputs
    [[ "$t1" =~ ^[0-9]+$ ]] && [[ "$t2" =~ ^[0-9]+$ ]] && downtime=$(($t1-$t2))
    echo  DOWNTIME: $downtime seconds
# report our external IP
    curl -s ipinfo.io|head -2|tail -1
    echo "#################"
  }
}
echo "Internet Appears Functional"
