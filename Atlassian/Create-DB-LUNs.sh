#!/bin/bash
printf "\n\n\n\n\n\n\n"

CREATE_LUNS="FALSE"
CREATE_MDADM="FALSE"
CREATE_FS="FALSE"

DISK_CHARS="c d e"

MDADM_START=1
MDADM_TOTAL=1
MDADM_SIZE[${MDADM_TOTAL}]="+200G"
MDADM_TOTAL=$((MDADM_TOTAL+1))
MDADM_SIZE[${MDADM_TOTAL}]="+200G"
MDADM_TOTAL=$((MDADM_TOTAL+1))
MDADM_SIZE[${MDADM_TOTAL}]="+40G"
MDADM_TOTAL=$((MDADM_TOTAL+1))
MDADM_SIZE[${MDADM_TOTAL}]="+72G"
MDADM_SIZE[${MDADM_TOTAL}]=

set -x
# MDADM_START=2
# MDADM_TOTAL=1
# DISK_CHARS="c"
set +x

MDADM_PREFIX="md"
MDADM_STARTING_NUMBER="127"
MDADM_PREFIX_FULL="${MDADM_PREFIX}${MDADM_STARTING_NUMBER}"

if [ "${CREATE_LUNS}" = "TRUE" ]; then
    for disk in ${DISK_CHARS};do
	mdadmNum=${MDADM_START}
	INPUT_STRING=
	while [ "${mdadmNum}" -le "${MDADM_TOTAL}" ];do
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
	printf "c\n${INPUT_STRING}w\n"
	printf "\--------------------------------------------\n"
	printf "c\n${INPUT_STRING}w\n" \
		| fdisk /dev/sd${disk}
	printf "\n\n\n"
    done
fi

for disk in ${DISK_CHARS};do
    printf "\n\n\n\n\n"
    printf "c\np\nq\n" | fdisk /dev/sd${disk}
done

MDADM_MAX=$((MDADM_STARTING_NUMBER+$MDADM_TOTAL-1))
if [ "${CREATE_MDADM}" = "TRUE" ]; then
    printf "\n\n\n\n\n"
    mdadmNum=${MDADM_STARTING_NUMBER}
    while [ "${mdadmNum}" -le "${MDADM_MAX}" ];do
	set -x
	mdadm --create /dev/${MDADM_PREFIX}${mdadmNum} --force --level 0 --raid-devices 3 \
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
    mdadmNum=${MDADM_STARTING_NUMBER}
    while [ "${mdadmNum}" -le "${MDADM_MAX}" ];do
	set -x
#	mkfs.ext4 -E lazy_journal_init=1,lazy_itable_init=1 /dev/${MDADM_START}${mdadmNum}
	mkfs.ext4 -E lazy_itable_init=1 /dev/${MDADM_START}${mdadmNum}
	set +x
	mdadmNum=$((mdadmNum+1))
    done
fi
