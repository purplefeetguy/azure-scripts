#!/bin/bash
printf "\n\n\n\n\n\n\n"

CREATE_LUNS="TRUE"
CREATE_MDADM="FALSE"
CREATE_FS="FALSE"

DISK_CHARS="c d e"

MDADM_MAX=1
MDADM_SIZE[${MDADM_MAX}]="+200G"
MDADM_MAX=$((MDADM_MAX+1))
MDADM_SIZE[${MDADM_MAX}]="+200G"
MDADM_MAX=$((MDADM_MAX+1))
MDADM_SIZE[${MDADM_MAX}]="+40G"
MDADM_MAX=$((MDADM_MAX+1))
MDADM_SIZE[${MDADM_MAX}]="+72G"
MDADM_SIZE[${MDADM_MAX}]=

set -x
# MDADM_MAX=1
# DISK_CHARS="c"
set +x

MDADM_PREFIX="md"
MDADM_START_NUM="10"
MDADM_START="${MDADM_PREFIX}${MDADM_START_NUM}"

if [ "${CREATE_LUNS}" = "TRUE" ]; then
    for disk in ${DISK_CHARS};do
	mdadmNum=1
	INPUT_STRING=
	while [ "${mdadmNum}" -le "${MDADM_MAX}" ];do
	    thisPartition=
	    if [ "${mdadmNum}" -gt "1" ]; then
		thisPartition="${mdadmNum}\n"
	    fi
	    thisSize="${MDADM_SIZE[${mdadmNum}]}"
	    thisInput="n\np\n${mdadmNum}\n\n${thisSize}\nt\n${thisPartition}fd\n"
	    INPUT_STRING="${INPUT_STRING}${thisInput}"
	    mdadmNum=$((mdadmNum+1))
	done
	printf "PROCESSING:\n"
	printf "${INPUT_STRING}w\n"
	printf "\--------------------------------------------\n"
	printf "${INPUT_STRING}w\n" \
		| fdisk /dev/sd${disk}
	printf "\n\n\n"
    done
fi

for disk in ${DISK_CHARS};do
    printf "\n\n\n\n\n"
    echo "p\n" | fdisk /dev/sd${disk}
done

if [ "${CREATE_MDADM}" = "TRUE" ]; then
    printf "\n\n\n\n\n"
    mdadmNum=1
    while [ "${mdadmNum}" -le "${MDADM_MAX}" ];do
	set -x
	mdadm --create /dev/${MDADM_START}${mdadmNum} --level 0 --raid-devices 3 \
		/dev/sdc${mdadmNum} \
		/dev/sdd${mdadmNum} \
		/dev/sde${mdadmNum}
	set +x
	mdadmNum=$((mdadmNum+1))
    done
    ls -al /dev/${MDADM_PREFIX}*
fi

if [ "${CREATE_FS}" = "TRUE" ]; then
    printf "\n\n\n\n\n"
    mdadmNum=1
    while [ "${mdadmNum}" -le "${MDADM_MAX}" ];do
#    for mdadmNum in 126 124 127 125
	set -x
#	mkfs.ext4 -E lazy_journal_init=1,lazy_itable_init=1 /dev/${MDADM_START}${mdadmNum}
#	mkfs.ext4 -E lazy_itable_init=1 /dev/${MDADM_START}${mdadmNum}
	mkfs.ext4 -E lazy_itable_init=1 /dev/${MDADM_PREFIX}${mdadmNum}
	set +x
	mdadmNum=$((mdadmNum+1))
    done
fi
