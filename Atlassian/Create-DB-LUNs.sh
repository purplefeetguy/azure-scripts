#!/bin/bash
printf "\n\n\n\n\n\n\n\n\n\n"

CREATE_LUNS="FALSE"
CREATE_MDADM="FALSE"
CREATE_FS="TRUE"

MDADM_NUMS="1 2 3 4"
MDADM_PREFIX="md"
MDADM_START_NUM="10"
MDADM_START="${MDADM_PREFIX}${MDADM_START_NUM}"

if [ "${CREATE_LUNS}" = "TRUE" ]; then
    for disk in c d e;do
	set -x
	(
	for num in 1 2;do
	    size="+200G"
	    printf "n\np\n${num}\n\n${size}\nt\n${num}\nfd\n"
	done; \
	for num in 3;do
	    size="+40G"
	    printf "n\np\n${num}\n\n${size}\nt\n${num}\nfd\n"
	done; \
	for num in 4;do
	    size="+72G"
	    size=
	    printf "n\np\n${num}\n\n${size}\nt\n${num}\nfd\n"
	done; \
	printf "w\n" \
	) | fdisk /dev/sd${disk}
	set +x
	printf "\n\n\n\n\n\n\n\n\n\n"
    done
fi

for disk in c d e;do
    printf "\n\n\n\n\n\n\n\n\n\n"
    echo "p\n" | fdisk /dev/sd${disk}
done

if [ "${CREATE_MDADM}" = "TRUE" ]; then
    printf "\n\n\n\n\n\n\n\n\n\n"
    for mdadmNum in ${MDADM_NUMS};do
	set -x
	mdadm --create /dev/${MDADM_START}${mdadmNum} --level 0 --raid-devices 3 \
		/dev/sdc${mdadmNum} \
		/dev/sdd${mdadmNum} \
		/dev/sde${mdadmNum}
	set +x
    done
fi

if [ "${CREATE_FS}" = "TRUE" ]; then
    printf "\n\n\n\n\n\n\n\n\n\n"
    for mdadmNum in ${MDADM_NUMS};do
	set -x
	mkfs.ext4 -E lazy_journal_init=1,lazy_itable_init=1 /dev/${MDADM_START}${mdadmNum}
	set +x
    done
fi
