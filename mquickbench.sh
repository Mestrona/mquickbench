#!/bin/bash
cd /root

export LANG=C

apt-get update > /dev/null
apt-get install -y sysbench > /dev/null

gb=1  # how much diskspace is needed (in GiB) - we set this to 1 by default now to be able to run on smaller VMs

echo -n "# Hostname "
hostname -f 


echo "## Specs"

echo "### CPU"

echo -n "Number of Cores: "
cat /proc/cpuinfo |grep processor|wc -l
cat /proc/cpuinfo |grep "model name"|uniq

echo "## CPU benchmark (single thread)"

# finding 20000 primes equals 321238 operations
sysbench --num-threads=1 cpu --cpu-max-prime=20000 run|grep --color=never "total time:"|sed "s/.*total time:\\s*\(.*\)s/\1/" | awk '{ print 321238 / $1 " operations / second"}'

echo "## Memory benchmark"
sysbench --num-threads=1 memory --memory-block-size=1M --memory-total-size=100G run | grep --color=never transferred


# Repare RW bench
sysbench fileio --file-total-size=${gb}G --file-num=1024 prepare > /dev/null
ulimit -n 65000

echo "## Disk random read write benchmark"
sysbench --num-threads=1 fileio --file-total-size=${gb}G --file-num=1024 --file-test-mode=rndrw --max-time=300 --max-requests=0 --file-extra-flags=direct --file-fsync-freq=1 run |grep --color=never -A 2 Throughput
sysbench fileio --file-total-size=${gb}G --file-num=1024 cleanup > /dev/null


echo "## Sequential Disk write benchmark (${gb}GB) writing"

dd if=/dev/zero of=test.file bs=1M count=${gb}000 oflag=direct|grep -v records

echo "## Sequential Disk read benchmark (${gb}GB) reading"
dd if=test.file of=/dev/null bs=1M count=${gb}000|grep -v records

rm test.file


