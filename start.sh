#!/bin/bash

PATH="/home/teuthworker/src/teuthology_master/virtualenv/bin:$PATH"
/home/teuthworker/bin/worker_start ceph 1 > /home/teuthworker/archive/worker_logs/process_logs 2>&1


