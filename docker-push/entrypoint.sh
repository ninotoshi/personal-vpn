#!/bin/sh

set -u

# `/dev` is mounted at the run time.
# Files created under `/dev` at the build time will be all lost.
if [ ! -e /dev/net/tun ]; then
    mkdir /dev/net
    mknod /dev/net/tun c 10 200
fi
chmod 660 /dev/net/tun

iptables --check POSTROUTING \
    --table nat \
    --source 10.8.0.0/24 \
    --out-interface eth0 \
    --jump MASQUERADE

if [ $? -ne 0 ]; then
    # this must be done at the run time because
    #`docker image build` does not accept `--cap-add`
    # and causes a privilege error
    iptables --append POSTROUTING \
        --table nat \
        --source 10.8.0.0/24 \
        --out-interface eth0 \
        --jump MASQUERADE

    iptables --list POSTROUTING \
        --table nat
fi

exec openvpn "$@"
