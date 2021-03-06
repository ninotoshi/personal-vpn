#!/bin/sh -eu

image=${1:?"usage: $0 openvpn_image"}

source ./vars.sh

build_dir="`cd ${self_dir}/..; pwd`/docker-push"

ta_dir="`mktemp -d ${tmp_dir}/XXXXXXXX`"
trap "rm -fr ${ta_dir}" EXIT SIGINT SIGQUIT SIGTERM

function _build_openvpn() {
    cd ${build_dir}
    make build
    cd -
}

# for preventing DOS
# https://community.openvpn.net/openvpn/wiki/Hardening#Useof--tls-auth
function create_psk() {
    _build_openvpn

    docker run -t --rm \
        -v ${ta_dir}:/mnt \
        --cap-add NET_ADMIN \
        ${image} \
        --genkey --secret /mnt/ta.key
}

function _copy_psk() {
    key=$1
    dest=$2

    if [ -d "${dest}" ]; then
        cp ${key} ${dest}
        echo "TLS auth key has been copied to ${dest}"
    else
        echo "ERROR: ${dest} is not a directory" > /dev/stderr
    fi
}

function copy_psk() {
    _copy_psk ${ta_dir}/ta.key ${server_dir}
    _copy_psk ${ta_dir}/ta.key ${client_dir}
}

create_psk
copy_psk
