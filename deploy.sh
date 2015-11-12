#! /bin/bash

################################################
#      for first time work only in ubuntu      #
################################################

 sudo apt-get update > /dev/null
 sudo apt-get install --assume-yes puppet iptables-persistent 
# sudo apt-get install --assume-yes ruby build-essential ruby1.9.1 ruby1.9.1-dev libxml2 zlib-bin zlib1g zlib1g-dev iptables-persistent

 TMP_DIR="TEMP_DIR"

#    cd $TMP_DIR/ceph/
#    mkdir $TMP_DIR/log/
#    sudo  gem install -q bundler > $TMP_DIR/log/gem_install.log
#    bundle install >> $TMP_DIR/log/bundle_install.log

 if [[ -e "/etc/puppet/modules/ceph" ]]
     then rm -rf /etc/puppet/modules/ceph
 fi
 sudo cp -rf $TMP_DIR/ceph  /etc/puppet/modules

 # Install Puppet modules
 cd /etc/puppet/modules
 sudo  puppet module install puppetlabs-stdlib > /dev/null 2>&1
 sudo  puppet module install puppetlabs-apt > /dev/null 2>&1
 sudo  puppet module install puppetlabs-inifile > /dev/null 2>&1
 sudo  puppet module install puppetlabs-apache > /dev/null 2>&1
 sudo  puppet module install puppetlabs-concat > /dev/null 2>&1
 sudo  puppet module install puppetlabs-firewall > /dev/null 2>&1
 sudo  puppet module list

 sudo puppet apply /etc/puppet/modules/ceph/ceph.puppet



###############################################################
