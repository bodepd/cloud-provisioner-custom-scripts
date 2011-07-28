#!/bin/bash
LEVEL='--debug --verbose --trace'
# the first argument can override the random value
LOCAL_RANDOM="${1:-$RANDOM}"
SSLDIR=~/.puppet/ssl-$LOCAL_RANDOM
CREATE_MASTER='yes'
CONNECT_OPTIONS="--server $DNSNAME --ssldir $SSLDIR"
KEY=dans-new-key

if [ -z "${1}" ]; then
  # create the puppetmaster
  echo "puppet node create -i ami-06ad526f --keypair $KEY --type m1.small --group puppet $LEVEL | tee /tmp/$LOCAL_RANDOM"
  puppet node create -i ami-06ad526f --keypair $KEY --type m1.small --group puppet $LEVEL | tee /tmp/$LOCAL_RANDOM
  DNSNAME=`tail -1 /tmp/$LOCAL_RANDOM`
  echo "puppet node install --keyfile ~/.ssh/$KEY --login ubuntu --install-script=master_source_dev $LEVEL $DNSNAME | tee /tmp/$LOCAL_RANDOM"
  puppet node install --keyfile ~/.ssh/$KEY.pem --login ubuntu --install-script=master_source_dev $LEVEL $DNSNAME | tee /tmp/$LOCAL_RANDOM
  mkdir $SSLDIR
  # get our controller nodes certificate set up correctly
  CA_OPTIONS='--ca-location remote'
  CONNECT_OPTIONS="--server $DNSNAME --ssldir $SSLDIR"
  echo "puppet certificate generate `hostname` $CONNECT_OPTIONS $CA_OPTIONS"
  puppet certificate generate `hostname` $CONNECT_OPTIONS $CA_OPTIONS
  echo "puppet certificate find ca $CONNECT_OPTIONS $CA_OPTIONS"
  puppet certificate find ca $CONNECT_OPTIONS $CA_OPTIONS
  echo "puppet certificate find `hostname` $CONNECT_OPTIONS $CA_OPTIONS"
  puppet certificate find `hostname` $CONNECT_OPTIONS $CA_OPTIONS
fi
DNSNAME="${DNSNAME:-$2}"
CONNECT_OPTIONS="--server $DNSNAME --ssldir $SSLDIR"


puppet node bootstrap -i ami-06ad526f --keypair $KEY --type m1.small --group puppet $LEVEL --keyfile ~/.ssh/$KEY.pem --login ubuntu $CONNECT_OPTIONS $LEVEL --certname `hostname` | tee /tmp/$LOCAL_RANDOM-3
