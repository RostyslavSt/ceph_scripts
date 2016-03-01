#!/bin/bash

source /home/teuthworker/.profile
/home/teuthworker/bin/worker_start ceph 1 > /home/teuthworker/archive/worker_logs/process_logs 2>&1


