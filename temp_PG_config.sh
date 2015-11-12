#! /bin/bash

ceph osd erasure-code-profile ls
# defult

ceph osd erasure-code-profile get default

# directory=/usr/lib/ceph/erasure-code
# k=2      <=
# m=1      <=
# plugin=jerasure
# technique=reed_sol_van

#  (OSD_SUMM * 100) / k+m   = PG_summ.
#
#  PG_sum / 1024 = POOLS_num   ( without a trace )


 ceph osd pool create <NAME> 1024  # (repeat POOLS_num)
# ceph osd pool create rbd1 1024

ceph -s
