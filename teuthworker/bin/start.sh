#!/bin/bash
source /home/teuthworker/.profile
/home/teuthworker/bin/worker_start ceph 2 > /dev/null 2>&1 

# for debug
# /home/teuthworker/bin/worker_start ceph 2 > /home/teuthworker/archive/worker_logs/process_logs 2>&1

