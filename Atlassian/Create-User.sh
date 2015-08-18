#!/bin/bash

ECHO="echo "
# export ECHO

AZ_ADMIN_USER=wagsadmin
BASE_DIR=/home/sysadmin

EXTRACT_FILE="UNIX-Profile.tar.gz"
BASH_PROFILE=".bashrc"
REDHAT_EXT=".RedHat"

NEW_AZ_USER=rms1
USER_GROUP=500
USER_NUMBER=2565
# export AZ_ADMIN_USER NEW_AZ_USER BASE_DIR

PREFIX=pl
POSTFIX="-azatl"

ALL_TYPES="wb ap db"
for thisType in ${ALL_TYPES};do
    VM_START_NUM=1
    VM_END_NUM=5
    case "${thisType}" in
	"ap")
	    VM_START_NUM=2
	    VM_END_NUM=5
	;;
	"db")
	    VM_START_NUM=1
	    VM_END_NUM=2
	;;
	"wb")
	    VM_START_NUM=1
	    VM_END_NUM=1
	;;
    esac
    thisNum=${VM_START_NUM}
    while [ "${thisNum}" -le "${VM_END_NUM}" ];do
	numPrint=$(printf "%02d" "${thisNum}")
	thisVM="${PREFIX}${thisType}${POSTFIX}${numPrint}"
	printf "\n\n"
	printf "PROCESSING: ${thisVM} ADMIN: ${AZ_ADMIN_USER}\n"
	if [ "${thisVM}" = "plap-azatl05" ]; then
	    thisVM="10.217.0.72"
	    printf "PROCESSING: ${thisVM} ADMIN: ${AZ_ADMIN_USER}\n"
	fi

#		homeDir=`eval ~${thisUser} 2>&1 | sed "s/^[^\/]*\(\/\)/\1/g" | sed "s/: .*$//g" | sort -u`; \
#		set -x; \
	ssh ${AZ_ADMIN_USER}@${thisVM} ' \
		ECHO="'${ECHO}'"; \
		baseDir="'${BASE_DIR}'"; thisUser="'${NEW_AZ_USER}'"; \
		userNum="'${USER_NUMBER}'"; groupNum="'${USER_GROUP}'"; \
		homeDir="${baseDir}/${thisUser}"; \
		printf "\n\n\n"; \
		ls -ld ${homeDir};egrep "^${thisUser}:" /etc/passwd;RC=$?; \
		printf "\n\n\n"; \
		if [ ! -d "${baseDir}" ]; then ${ECHO} "sudo mkdir ${baseDir}; \\";fi; \
		if [ ! -d "${homeDir}" ]; then ${ECHO} "sudo mkdir ${homeDir}; \\";fi; \
		if [ "${RC}" != "0" ]; then \
			${ECHO} "sudo useradd -d ${homeDir} -g ${groupNum} -u ${userNum} ${thisUser}; \\"; \
			${ECHO} "sudo usermod -G ${groupAdd} ${thisUser}; \\"; \
			${ECHO} "sudo passwd ${thisUser}; \\"; \
			${ECHO} "sudo chown ${thisUser} ${homeDir}; \\"; \
			${ECHO} "sudo chgrp ${groupNum} ${homeDir}; \\"; \
			${ECHO} "ls -ld ${homeDir}; \\"; \
			${ECHO} "egrep \"^${thisUser}:\" /etc/passwd"; \
		fi \
	' # 2>/dev/null
	ssh ${AZ_ADMIN_USER}@${thisVM}
	ssh ${NEW_AZ_USER}@${thisVM} 'if [ ! -d "tmp" ]; then mkdir tmp;fi'
	scp -p ~/Development/UNIX-Profile/tmp/${EXTRACT_FILE} ${NEW_AZ_USER}@${thisVM}:tmp/
	ssh ${NEW_AZ_USER}@${thisVM} ' \
		if [ ! -d "KSH_SETUP" -a ! -d "SH_SETUP" ]; then \
			gunzip -c tmp/'${EXTRACT_FILE}' | tar -xvf -; \
			bFile="'${BASH_PROFILE}${REDHAT_EXT}'"; \
			ln -s SH_SETUP KSH_SETUP; \
			if [ -f "${bFile}" ]; then set -x;cp -p ${bFile} '${BASH_PROFILE}';fi;set +x; \
		fi'
	ssh ${NEW_AZ_USER}@${thisVM}

	thisNum=$((thisNum+1))
# printf "EXIT 1\n";exit 1
    done
# printf "EXIT 1\n";exit 1
done

