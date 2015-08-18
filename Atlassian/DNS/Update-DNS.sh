#!/bin/bash
AZ_ATL_SYSTEMS="plwb-azatl01 plap-azatl02 plap-azatl03 plap-azatl04 plap-azatl05 10.217.0.72 pldb-azatl01 pldb-azatl02"

for sys in ${AZ_ATL_SYSTEMS};do
    scp -p resolv.conf.NEW $sys:tmp/
    echo "sudo -- sh -c 'cp -p tmp/resolv.conf.NEW /etc/; \
printf \"Before:\\n\";ls -ald /etc/resolv.conf*; \
cp -p /etc/resolv.conf /etc/resolv.conf.$(date +%Y-%m-%d:%H-%M); \
cp -p /etc/resolv.conf.NEW /etc/resolv.conf; \
chown rms1 /etc/resolv.conf.*; \
printf \"After:\\n\";ls -ald /etc/resolv.conf*'"
    ssh ${sys}
    printf "Hit Enter to Continue:";read x
done

