#Collect metrics every 5 seconds for entire day. 5 * 24*60*60/5
#Run this file once the system reboots or once a day

mkdir -p "/home/centos/yb/metrics"
log="/home/centos/yb/metrics/cpu_usage-$(date "+%Y%m%d-%H%m").txt"
sar -u 5 17280 >> $log &