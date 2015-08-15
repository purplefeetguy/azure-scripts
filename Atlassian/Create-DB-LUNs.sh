#!/bin/bash
printf "\n\n\n\n\n\n\n"

CREATE_LUNS="FALSE"
CREATE_MDADM="FALSE"
CREATE_FS="FALSE"
CREATE_ORAVG="FALSE"
CREATE_ORALVS="FALSE"
CREATE_ORAFSS="FALSE"
CREATE_DIRS="TRUE"

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

ORA_BASE_DIR="/usr/local/oracle"
ORA_BASE_DIR_LEN=$(echo "${ORA_BASE_DIR}" | wc -c)
ALL_DIRS=
ALL_DIRS="${ALL_DIRS} /usr/local/dba"
ALL_DIRS="${ALL_DIRS} /usr/local/grid"
ALL_DIRS="${ALL_DIRS} ${ORA_BASE_DIR}"
ALL_DIRS="${ALL_DIRS} ${ORA_BASE_DIR}/exports"
ALL_DIRS="${ALL_DIRS} ${ORA_BASE_DIR}/log"
ALL_DIRS="${ALL_DIRS} ${ORA_BASE_DIR}/backup"
ALL_DIRS="${ALL_DIRS} /u01"
ALL_DIRS="${ALL_DIRS} /u02"

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

if [ "${CREATE_ORAVG}" = "TRUE" ]; then
    set -x
    vgcreate oravg /dev/md130
    set +x
fi

if [ "${CREATE_ORALVS}" = "TRUE" ]; then
    set -x
    lvcreate -L 5029504K -n localdba oravg
    lvcreate -L 5029504K -n localgrid oravg
    lvcreate -L 10190136K -n localoracle oravg
    lvcreate -L 51475068K -n localoraexport oravg
    lvcreate -L 41153856K -n localoralog oravg
    set +x
fi

if [ "${CREATE_ORAFSS}" = "TRUE" ]; then
    set -x
    mkfs.ext4 /dev/mapper/oravg-localdba
    mkfs.ext4 /dev/mapper/oravg-localgrid
    mkfs.ext4 /dev/mapper/oravg-localoracle
    mkfs.ext4 /dev/mapper/oravg-localoraexport
    mkfs.ext4 /dev/mapper/oravg-localoralog
    set +x
fi

if [ "${CREATE_DIRS}" = "TRUE" ]; then
    for thisDir in ${ALL_DIRS}; do
	testDir=$(echo "${thisDir}" | cut -c-${ORA_BASE_DIR_LEN})
	mountTest=$(mount | egrep "${ORA_BASE_DIR}" 2>/dev/null)
	mountTest=$(echo "${mountTest}" | egrep " on ${ORA_BASE_DIR} " 2>/dev/null)
	mountTest=$(echo "${mountTest}" | sed 's/^.* on \//\//g')
	mountTest=$(echo "${mountTest}" | sed 's/^\([A-Za-z0-9\/\-\_]*\) .*$/\1/g')
	if [ "${mountTest}" = "${ORA_BASE_DIR}" -o "${testDir}" != "${ORA_BASE_DIR}/" ]; then
	    if [ ! -d "${thisDir}" ]; then
		set -x
		mkdir ${thisDir}
		set +x
	    else
		printf "Directory: ${thisDir} Already Created!\n"
	    fi
	else
	    printf "NEED to mkdir ${thisDir} AFTER ${ORA_BASE_DIR} mounted!\n"
	fi
    done
fi

printf "Now edit /etc/fstab\n\n"

