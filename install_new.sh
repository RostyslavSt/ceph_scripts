#! /bin/bash

set -e
set -o pipefail

# for example:
# MONS="mon_host1 mon_host2 mon_host3"
# CLIENTS="client_host1 client_host2"
# OSDS="osd_host1 osd_host2 osd_host3"


MONS=${MONS:-""}
CLIENTS=${CLIENTS:-""}
OSDS=${OSDS:-""}

#  WARNING !! use format <OSD_DISK>:<OSD_JORNAL>
#  DISKS="sda:sdb1 sdd:sdb2 sdg: sdk:"

DISKS=${DISKS:-""}

##############################################################################
# if you want to specify KEYs, insert them here
# else, leave this parameters empty and keys will be generated automatically
####
ADMIN_KEY=${ADMIN_KEY:-""}
MON_KEY=${MON_KEY:-""}
OSD_KEY=${OSD_KEY:=""}
UUID=${UUID_KEY:=""}



SC_DIR=$(pwd)
TMP_DIR=$(mktemp -d)
###

tests () {
    if [ -z "$MONS" ]; then
       echo "! ERROR missing argument: MONS !"
       exit 1
    fi

    if [ -z "$OSDS" ]; then
       echo "! ERROR missing argument: OSDS !"
       exit 1
    fi

    if [ -z "$DISKS" ]; then
       echo "! ERROR missing argument: DISKS !"
       exit 1
    fi
}

get_ips () {
    node_ip=$(ping -c 1 $node | grep icmp | awk {'print $5'} | sed "s/(//g" | sed "s/)://g")     # "
    NODES_IP_LIST=${NODES_IP_LIST:-$node_ip}
    NODES_IP_LIST=$(echo "$node_ip,$NODES_IP_LIST")
}

config_ceph_puppet () {

  if [ -z "$ADMIN_KEY" ]; then
   ADMIN_KEY=$($SC_DIR/gen.py)
  fi

  if [ -z "$MON_KEY" ]; then
   MON_KEY=$($SC_DIR/gen.py)
  fi

  if [ -z "$OSD_KEY" ]; then
   OSD_KEY=$($SC_DIR/gen.py)
  fi

  if [ -z "$UUID" ]; then
   UUID=$(uuidgen)
  fi


  MONS_CEPH_PUPPET=$(echo "${MONS// /,}")
  OSDS_CEPH_PUPPET=$(echo "${OSDS// /,}")
  CLIENTS_CEPH_PUPPET=$(echo "${CLIENTS// /,}")

  MONS_IP=$NODES_IP_LIST

  sed -i "s/UUID/$UUID/g" ceph.puppet
  sed -i "s%ADMIN_KEY%$ADMIN_KEY%g" ceph.puppet
  sed -i "s%MON_KEY%$MON_KEY%g" ceph.puppet
  sed -i "s%OSD_KEY%$OSD_KEY%g" ceph.puppet

  sed -i "s/MON_HOSTS/$MONS_IP/g" ceph.puppet

  sed -i "s/\/OSDS\//$OSDS_CEPH_PUPPET/g" ceph.puppet
  sed -i "s/\/MONS\//$MONS_CEPH_PUPPET/g" ceph.puppet
  sed -i "s/\/CLIENTS\//$CLIENTS_CEPH_PUPPET/g" ceph.puppet

  sed -i "s%TEMP_DIR%$TMP_DIR%g" $SC_DIR/deploy.sh


  for i in $DISKS; do
     A=$(echo $i | awk -F ":" {'print $1'})
     B=$(echo $i | awk -F ":" {'print $2'})
    if [ -z "$B" ]; then
        sed -i "s/DISKS/DISKS\n\t'\/dev\/$A':\n\t\t journal => '';/g" ceph.puppet;
     else
        sed -i "s/DISKS/DISKS\n\t'\/dev\/$A':\n\t\t journal => '\/dev\/$B';/g" ceph.puppet;
    fi
  done

sed -i "s/DISKS/#/g" ceph.puppet
}



if test -f "ceph.puppet"; then
    echo "ceph.puppet found! using him to deploy"
else
    cp ceph.puppet.origin ceph.puppet
    config_ceph_puppet
    for node in $MONS; do get_ips; done
    unset node

fi

unset NODES_IP_LIST
unset node_ip

tests

cd $TMP_DIR
git clone https://github.com/stackforge/puppet-ceph.git > /dev/null
cp -rf $SC_DIR/metadata.json $TMP_DIR/puppet-ceph
cp -rf $SC_DIR/deploy.sh $TMP_DIR/puppet-ceph
cp -rf $SC_DIR/ceph.puppet $TMP_DIR/puppet-ceph
mv puppet-ceph ceph
tar cfvz ceph.tar.gz ceph >/dev/null


SSH="ssh -o LogLevel=quiet -o StrictHostKeyChecking=no"

deploy () {
    node=$node
    echo "copy tarball to $node and start deploying"
    $SSH $node "mkdir -p $TMP_DIR"
    scp $TMP_DIR/ceph.tar.gz $node:$TMP_DIR/ceph.tar.gz
    $SSH $node "cd $TMP_DIR; tar xvfz $TMP_DIR/ceph.tar.gz >/dev/null"
    $SSH $node "$TMP_DIR/ceph/deploy.sh"
    $SSH $node "rm -rf $TMP_DIR/ceph.tar.gz"
}


for node in $MONS; do deploy & done
wait
unset node

for node in $OSDS; do deploy & done
wait
unset node

for node in $CLIENTS; do deploy & done
wait
unset node

sed -i "s%$TMP_DIR%TEMP_DIR%g" $SC_DIR/deploy.sh

